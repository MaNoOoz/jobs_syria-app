// lib/controllers/home_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../services/auth_service.dart';

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

  final Logger _logger = Logger();
  RxList<JobModel> jobs = <JobModel>[].obs;
  RxList<JobModel> filteredJobs = <JobModel>[].obs;
  RxList<JobModel> ownerJobs = <JobModel>[].obs; // Added for owner's specific jobs
  RxBool isLoadingOwnerJobs = false.obs; // Added for loading state of owner's jobs


  RxList<String> availableJobCities = <String>[].obs;

  String currentCity = '';
  String currentJobType = '';
  String currentQuery = '';

  Rx<double?> userLat = Rx<double?>(null);
  Rx<double?> userLng = Rx<double?>(null);

  var maxDistanceKm = 10.0.obs;
  Rx<JobSortOrder> currentSortOrder = JobSortOrder.newest.obs;
  RxList<String> availableHashtags = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchJobs();
    updateFilteredJobs();
  }

  /// تجلب جميع الوظائف من Firestore وتُحدّث القوائم التفاعلية.
  void fetchJobs() {
    _firestore
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      jobs.value = snap.docs.map((d) => JobModel.fromFirestore(d)).toList();
      updateFilteredJobs();
    });
  }

  /// Fetches a one-time list of unique cities from all existing jobs.
  Future<void> loadJobCities() async {
    try {
      QuerySnapshot jobSnapshot = await _firestore.collection('jobs').get();
      Set<String> uniqueCities = {};
      uniqueCities.add('الكل');

      for (var doc in jobSnapshot.docs) {
        final job = JobModel.fromFirestore(doc);
        String city = job.city;
        if (city.isNotEmpty) {
          uniqueCities.add(city);
        }
      }
      List<String> sortedCities = uniqueCities.toList();
      sortedCities.sort((a, b) {
        if (a == 'الكل') return -1;
        if (b == 'الكل') return 1;
        return a.compareTo(b);
      });
      availableJobCities.assignAll(sortedCities);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل المدن المتاحة: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      _logger.e('Error loading available job cities: $e');
    }
  }

  /// Resets all filters and sorting to their default values.
  void resetAllFilters() {
    currentCity = '';
    currentJobType = '';
    currentQuery = '';
    maxDistanceKm.value = 10.0;
    currentSortOrder.value = JobSortOrder.newest;
    updateFilteredJobs();
  }

  /// Changes the sorting order for jobs.
  void changeSortOrder(JobSortOrder newOrder) {
    currentSortOrder.value = newOrder;
    updateFilteredJobs();
  }

  /// Sets the user's current location and triggers a recalculation of filtered jobs.
  void setUserLocation(double lat, double lng) {
    userLat.value = lat;
    userLng.value = lng;
    updateFilteredJobs(filterByDistance: true);
  }

  /// Updates the list of filtered jobs based on current filtering criteria.
  void updateFilteredJobs({
    String? city,
    String? jobType,
    String? query,
    bool filterByDistance = false,
  }) {
    if (city != null) currentCity = city;
    if (jobType != null) currentJobType = jobType;
    if (query != null) currentQuery = query;

    var list = jobs.toList();

    // --- Apply filters sequentially ---
    if (currentCity.isNotEmpty && currentCity != 'الكل') {
      list = list.where((j) => j.city == currentCity).toList();
    }
    if (currentJobType.isNotEmpty && currentJobType != 'الكل') {
      list = list.where((j) => j.jobType == currentJobType).toList();
    }
    if (currentQuery.isNotEmpty) {
      final q = currentQuery.toLowerCase();
      list = list.where((j) =>
      j.title.toLowerCase().contains(q) ||
          j.description.toLowerCase().contains(q) ||
          j.city.toLowerCase().contains(q) ||
          j.location.toLowerCase().contains(q) ||
          j.hashtags.any((tag) => tag.toLowerCase().contains(q))).toList();
    }

    if (userLat.value != null && userLng.value != null) {
      final from = LatLng(userLat.value!, userLng.value!);
      final d = const Distance();

      list = list.map((j) {
        if (j.jobType == 'عن بعد') {
          return j.copyWith(distanceInKm: null);
        } else {
          final to = LatLng(j.latitude, j.longitude);
          final km = d.as(LengthUnit.Kilometer, from, to);
          return j.copyWith(distanceInKm: km);
        }
      }).toList();
    } else {
      list = list.map((j) => j.copyWith(distanceInKm: null)).toList();
    }

    if (filterByDistance && userLat.value != null && userLng.value != null) {
      list = list.where((j) =>
      j.jobType == 'عن بعد' ||
          (j.distanceInKm != null && j.distanceInKm! <= maxDistanceKm.value)
      ).toList();
    }

    switch (currentSortOrder.value) {
      case JobSortOrder.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case JobSortOrder.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case JobSortOrder.distanceAsc:
        list.sort((a, b) {
          if (a.distanceInKm == null && b.distanceInKm == null) return 0;
          if (a.distanceInKm == null) return 1;
          if (b.distanceInKm == null) return -1;
          return a.distanceInKm!.compareTo(b.distanceInKm!);
        });
        break;
      case JobSortOrder.titleAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case JobSortOrder.titleDesc:
        list.sort((a, b) => b.title.compareTo(a.title));
        break;
    }
    filteredJobs.value = list;
  }

  Future<void> addJob(JobModel job) async {
    _logger.d('Adding job: ${job.title}');
    if (_authService.firebaseUser.value == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول لإضافة إعلان',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }
    final jobWithOwner = job.copyWith(ownerId: _authService.firebaseUser.value!.uid);
    try {
      await _firestore
          .collection('jobs')
          .doc(jobWithOwner.id)
          .set(jobWithOwner.toMap());
      debugPrint('Job added successfully: ${jobWithOwner.title} with ID: ${jobWithOwner.id}');
      Get.snackbar('نجاح', 'تم إضافة الإعلان بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);

      if (_authService.currentUser.value != null) {
        final updatedMyJobs =
        List<String>.from(_authService.currentUser.value!.myJobs);
        updatedMyJobs.add(jobWithOwner.id);
        await _authService.updateUserProfile(myJobs: updatedMyJobs);
      }
      // Re-fetch owner jobs after adding a new one
      fetchMyJobs();
    } catch (e) {
      debugPrint('Error adding job: $e');
      Get.snackbar('خطأ', 'فشل في إضافة الإعلان: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  // Updated fetchMyJobs to populate ownerJobs and handle loading state
  Future<void> fetchMyJobs() async {
    if (_authService.firebaseUser.value == null) {
      ownerJobs.clear(); // Clear jobs if no user is logged in
      return;
    }

    isLoadingOwnerJobs.value = true; // Set loading to true
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_authService.firebaseUser.value!.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final myJobIds = List<String>.from(userData?['myJobs'] ?? []);
        if (myJobIds.isNotEmpty) {
          final myJobsSnapshot = await _firestore
              .collection('jobs')
              .where(FieldPath.documentId, whereIn: myJobIds)
              .get();
          ownerJobs.value = myJobsSnapshot.docs.map((d) => JobModel.fromFirestore(d)).toList();
        } else {
          ownerJobs.clear(); // Clear if no job IDs
        }
      } else {
        ownerJobs.clear(); // Clear if user doc doesn't exist
      }
    } catch (e) {
      _logger.e('Error fetching my jobs: $e');
      Get.snackbar('خطأ', 'فشل في تحميل إعلاناتك: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      ownerJobs.clear(); // Clear on error
    } finally {
      isLoadingOwnerJobs.value = false; // Set loading to false
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
      debugPrint('Job updated successfully: ${job.title} with ID: ${job.id}');
      Get.snackbar('نجاح', 'تم تحديث الإعلان بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      // Re-fetch owner jobs after updating one
      fetchMyJobs();
    } catch (e) {
      debugPrint('Error updating job: $e');
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
      debugPrint('Job deleted successfully with ID: $jobId');
      Get.snackbar('نجاح', 'تم حذف الإعلان بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);

      if (_authService.currentUser.value != null) {
        final updatedMyJobs =
        List<String>.from(_authService.currentUser.value!.myJobs);
        updatedMyJobs.remove(jobId);
        await _authService.updateUserProfile(myJobs: updatedMyJobs);
      }
      // Re-fetch owner jobs after deleting one
      fetchMyJobs();
    } catch (e) {
      debugPrint('Error deleting job: $e');
      Get.snackbar('خطأ', 'فشل في حذف الإعلان: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }
}