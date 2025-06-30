// lib/controllers/home_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart'; // Make sure this is imported

enum JobSortOrder {
  newest,
  oldest,
  distanceAsc,
  titleAsc,
  titleDesc,
}

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  final LocationService _locationService = Get.find<LocationService>();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 4,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  RxList<JobModel> jobs = <JobModel>[].obs; // All jobs from Firestore
  RxList<JobModel> filteredJobs = <JobModel>[].obs; // Jobs after applying filters
  RxList<JobModel> ownerJobs = <JobModel>[].obs;
  RxBool isLoadingOwnerJobs = false.obs;

  RxList<String> availableJobCities = <String>[].obs;

  String currentCity = ''; // Current filter for city
  String currentJobType = ''; // Current filter for job type
  String currentQuery = ''; // Current filter for search query

  Rx<double?> userLat = Rx<double?>(null);
  Rx<double?> userLng = Rx<double?>(null);

  // Removed: var maxDistanceKm = 10.0.obs; // No longer needed for filtering

  Rx<JobSortOrder> currentSortOrder = JobSortOrder.newest.obs; // Default sort order

  @override
  void onInit() {
    super.onInit();
    _logger.d('HomeController onInit: Initializing...');
    fetchJobs(); // This will fetch all jobs and then call updateFilteredJobs initially
    _fetchUserLocation(); // Fetch user location
  }

  // New method to fetch user location using LocationService
  Future<void> _fetchUserLocation() async {
    try {
      _logger.d('Attempting to fetch user location...');
      final locationData = await _locationService.getCurrentLocation();
      userLat.value = locationData['latitude'];
      userLng.value = locationData['longitude'];
      _logger.d('User location obtained: ${userLat.value}, ${userLng.value}');
      // After location is obtained, re-apply filters to recalculate distances for *all* jobs,
      // but without activating the distance filter itself.
      updateFilteredJobs();
    } catch (e) {
      _logger.e('Failed to get user location: $e');
      Get.snackbar('خطأ الموقع', e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      userLat.value = null;
      userLng.value = null;
      // Re-trigger update to ensure list is populated even if location fails
      updateFilteredJobs();
    }
  }

  /// تجلب جميع الوظائف من Firestore وتُحدّث القوائم التفاعلية.
  void fetchJobs() {
    _logger.d('Fetching all jobs from Firestore...');
    _firestore.collection('jobs').orderBy('createdAt', descending: true).snapshots().listen((snap) {
      jobs.value = snap.docs.map((d) => JobModel.fromFirestore(d)).toList();
      _logger.d('Fetched ${jobs.length} jobs. Updating available cities...');

      final cities = jobs.map((job) => job.city).toSet().toList();
      cities.sort();
      availableJobCities.value = ['الكل', ...cities];
      _logger.d('Available job cities updated: ${availableJobCities.value}');

      updateFilteredJobs();
    });
  }

  /// Resets all filters and sorting to their default values.
  void resetAllFilters() {
    _logger.d('Resetting all filters...');
    currentCity = '';
    currentJobType = '';
    currentQuery = '';
    // Removed: maxDistanceKm.value = 10.0; // No longer needed as a filter
    currentSortOrder.value = JobSortOrder.newest; // Reset to default sort
    updateFilteredJobs(); // Apply the reset filters
    _logger.d('All filters reset and updateFilteredJobs called.');
  }

  /// Changes the sorting order for jobs.
  void changeSortOrder(JobSortOrder newOrder) {
    _logger.d('Changing sort order to: $newOrder');
    currentSortOrder.value = newOrder;
    updateFilteredJobs(); // Re-apply filters with new sort order
  }

  /// Updates the list of filtered jobs based on current filtering criteria.
  void updateFilteredJobs({
    String? city,
    String? jobType,
    String? query,
    // The filterByDistance parameter can remain, but it will only activate
    // if you add a specific button/logic that sets it to true elsewhere.
    // Given the request, it will effectively always be false for filtering.
    bool filterByDistance = false,
  }) {
    _logger.d('updateFilteredJobs called: city=$city, jobType=$jobType, query=$query, filterByDistance=$filterByDistance, sortOrder=${currentSortOrder.value}');

    if (city != null) currentCity = city;
    if (jobType != null) currentJobType = jobType;
    if (query != null) currentQuery = query;

    List<JobModel> tempJobList = List<JobModel>.from(jobs);

    _logger.d('Initial jobs count for filtering: ${tempJobList.length}');

    // --- Apply text-based filters (city, job type, search query) ---
    if (currentCity.isNotEmpty && currentCity != 'الكل') {
      tempJobList = tempJobList.where((j) => j.city == currentCity).toList();
      _logger.d('After city filter (${currentCity}): ${tempJobList.length} jobs');
    }
    if (currentJobType.isNotEmpty && currentJobType != 'الكل') {
      tempJobList = tempJobList.where((j) => j.jobType == currentJobType).toList();
      _logger.d('After job type filter (${currentJobType}): ${tempJobList.length} jobs');
    }
    if (currentQuery.isNotEmpty) {
      final q = currentQuery.toLowerCase();
      tempJobList = tempJobList.where((j) =>
      j.title.toLowerCase().contains(q) ||
          j.description.toLowerCase().contains(q) ||
          j.city.toLowerCase().contains(q) ||
          j.location.toLowerCase().contains(q) ||
          j.hashtags.any((tag) => tag.toLowerCase().contains(q))).toList();
      _logger.d('After query filter (${currentQuery}): ${tempJobList.length} jobs');
    }

    // --- Calculate Distances (if user location is available and jobs not remote) ---
    // This part always runs if location is available to set distanceInKm for sorting.
    if (userLat.value != null && userLng.value != null) {
      _logger.d('User location available. Calculating distances for ${tempJobList.length} jobs...');
      final from = LatLng(userLat.value!, userLng.value!);
      final d = const Distance();

      tempJobList = tempJobList.map((j) {
        if (j.jobType == 'عن بعد') {
          return j.copyWith(distanceInKm: null);
        } else {
          final to = LatLng(j.latitude, j.longitude);
          final km = d.as(LengthUnit.Kilometer, from, to);
          return j.copyWith(distanceInKm: km);
        }
      }).toList();
      _logger.d('Distances calculated for ${tempJobList.length} jobs.');
    } else {
      _logger.d('User location NOT available. Distances not calculated.');
      tempJobList = tempJobList.map((j) => j.copyWith(distanceInKm: null)).toList();
    }

    // --- Removed Distance FILTERING Logic ---
    // The previous 'if (filterByDistance && ...)' block for actual filtering is removed,
    // as you only want to sort by distance, not filter by it.

    // --- Apply Sorting ---
    _logger.d('Applying sort order: ${currentSortOrder.value}');
    switch (currentSortOrder.value) {
      case JobSortOrder.newest:
        tempJobList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case JobSortOrder.oldest:
        tempJobList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case JobSortOrder.distanceAsc:
        tempJobList.sort((a, b) {
          if (a.distanceInKm == null && b.distanceInKm == null) return 0;
          if (a.distanceInKm == null) return 1;
          if (b.distanceInKm == null) return -1;
          return a.distanceInKm!.compareTo(b.distanceInKm!);
        });
        break;
      case JobSortOrder.titleAsc:
        tempJobList.sort((a, b) => a.title.compareTo(b.title));
        break;
      case JobSortOrder.titleDesc:
        tempJobList.sort((a, b) => b.title.compareTo(a.title));
        break;
    }
    _logger.d('Final filteredJobs count before update: ${tempJobList.length}');

    filteredJobs.value = tempJobList;
    _logger.d('filteredJobs updated. Obx widgets should now react.');
  }

  // ... (rest of your HomeController code remains the same) ...
  Future<void> addJob(JobModel job) async {
    _logger.d('Adding job: ${job.title}');
    if (_authService.firebaseUser.value?.isAnonymous ?? true) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول بحساب بريد إلكتروني لإضافة إعلان',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }
    final jobWithOwner = job.copyWith(ownerId: _authService.firebaseUser.value!.uid);
    try {
      await _firestore.collection('jobs').doc(jobWithOwner.id).set(jobWithOwner.toMap());
      _logger.d('Job added successfully: ${jobWithOwner.title} with ID: ${jobWithOwner.id}');
      Get.snackbar('نجاح', 'تم إضافة الإعلان بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);

      if (_authService.currentUser.value != null) {
        final updatedMyJobs = List<String>.from(_authService.currentUser.value!.myJobs);
        updatedMyJobs.add(jobWithOwner.id);
        await _authService.updateUserInFirestore({'myJobs': updatedMyJobs});
      }
      fetchMyJobs();
    } catch (e) {
      _logger.e('Error adding job: $e');
      Get.snackbar('خطأ', 'فشل في إضافة الإعلان: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> fetchMyJobs() async {
    if (_authService.firebaseUser.value == null) {
      ownerJobs.clear();
      return;
    }

    isLoadingOwnerJobs.value = true;
    try {
      final userDoc = await _firestore.collection('users').doc(_authService.firebaseUser.value!.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final myJobIds = List<String>.from(userData?['myJobs'] ?? []);
        if (myJobIds.isNotEmpty) {
          final myJobsSnapshot = await _firestore.collection('jobs').where(FieldPath.documentId, whereIn: myJobIds).get();
          ownerJobs.value = myJobsSnapshot.docs.map((d) => JobModel.fromFirestore(d)).toList();
        } else {
          ownerJobs.clear();
        }
      } else {
        ownerJobs.clear();
      }
    } catch (e) {
      _logger.e('Error fetching my jobs: $e');
      Get.snackbar('خطأ', 'فشل في تحميل إعلاناتي: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      ownerJobs.clear();
    } finally {
      isLoadingOwnerJobs.value = false;
    }
  }

  Future<void> updateJob(JobModel job) async {
    try {
      final jobDoc = await _firestore.collection('jobs').doc(job.id).get();
      if (!jobDoc.exists) {
        Get.snackbar('خطأ', 'الإعلان غير موجود',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return;
      }
      final existingJob = JobModel.fromFirestore(jobDoc);

      if (_authService.firebaseUser.value?.uid != existingJob.ownerId) {
        Get.snackbar('خطأ', 'ليس لديك صلاحية لتعديل هذا الإعلان',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return;
      }

      await _firestore.collection('jobs').doc(job.id).update(job.toMap());
      _logger.d('Job updated successfully: ${job.title} with ID: ${job.id}');
      Get.snackbar('نجاح', 'تم تحديث الإعلان بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      fetchMyJobs();
    } catch (e) {
      _logger.e('Error updating job: $e');
      Get.snackbar('خطأ', 'فشل في تحديث الإعلان: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (!jobDoc.exists) {
        Get.snackbar('خطأ', 'الإعلان غير موجود',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return;
      }
      final jobToDelete = JobModel.fromFirestore(jobDoc);

      if (_authService.firebaseUser.value?.uid != jobToDelete.ownerId) {
        Get.snackbar('خطأ', 'ليس لديك صلاحية لحذف هذا الإعلان',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return;
      }

      await _firestore.collection('jobs').doc(jobId).delete();
      _logger.d('Job deleted successfully with ID: $jobId');
      Get.snackbar('نجاح', 'تم حذف الإعلان بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);

      if (_authService.currentUser.value != null) {
        final updatedMyJobs = List<String>.from(_authService.currentUser.value!.myJobs);
        updatedMyJobs.remove(jobId);
        await _authService.updateUserInFirestore({'myJobs': updatedMyJobs});
      }
      fetchMyJobs();
    } catch (e) {
      _logger.e('Error deleting job: $e');
      Get.snackbar('خطأ', 'فشل في حذف الإعلان: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> toggleFavoriteJob(String jobId) async {
    final currentUser = _authService.currentUser.value;
    if (currentUser == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول لإضافة إعلانات إلى المفضلة.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    try {
      List<String> updatedFavorites = List.from(currentUser.favorites);
      if (updatedFavorites.contains(jobId)) {
        updatedFavorites.remove(jobId);
        _logger.d('Removed job $jobId from favorites.');
      } else {
        updatedFavorites.add(jobId);
        _logger.d('Added job $jobId to favorites.');
      }
      await _authService.updateUserInFirestore({'favorites': updatedFavorites});
      _logger.d('User favorites updated in Firestore.');
    } catch (e) {
      _logger.e('Error toggling favorite job: $e');
      Get.snackbar('خطأ', 'فشل في تحديث المفضلة: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }
}