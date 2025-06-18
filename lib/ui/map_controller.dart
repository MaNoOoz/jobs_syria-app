// lib/controllers/map_controller.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For Icons, Colors
import 'package:flutter_map/flutter_map.dart'; // For MapController, Marker
import 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart'; // For PopupController
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart'; // For LatLng, Distance
import 'package:geolocator/geolocator.dart'; // For location services

import '../controllers/home_controller.dart'; // Your JobController
import '../models.dart'; // Your JobModel

class MapControllerX extends GetxController {
  // Get instances of other controllers
  final HomeController _jobController = Get.find<HomeController>();

  // Map related controllers
  final MapController mapController = MapController();
  final PopupController popupController = PopupController();

  // Reactive state variables for the map
  RxnDouble userLat = RxnDouble();
  RxnDouble userLng = RxnDouble();

  RxBool isLoadingLocation = true.obs; // Tracks initial location fetching
  RxString locationError = "".obs; // Stores location permission/service errors

  RxList<JobModel> displayedJobs = <JobModel>[].obs; // Jobs displayed on map (could be filtered by distance)
  RxList<Marker> markers = <Marker>[].obs; // All markers to show on the map

  final double maxDistanceKm = 10000.0; // Max distance for nearby jobs filter (consider making this user-adjustable)
  final Distance _distance = const Distance(); // For distance calculations

  RxBool isDarkMap = false.obs; // Toggle for map style

  // Reactive variables for selected jobs (from cluster or single tap)
  RxList<JobModel> selectedClusterJobs = <JobModel>[].obs;
  Rx<JobModel?> selectedSingleJob = Rx<JobModel?>(null);

  @override
  void onInit() {
    super.onInit();
    // Start determining user position and then filter/display jobs.
    _determinePositionAndFilter();

    // Listen to changes in JobController's jobs and update markers immediately
    ever(_jobController.jobs, (_) {
      _updateDisplayedJobsAndMarkers();
    });
  }

  @override
  void onReady() {
    super.onReady();
    // This method is called AFTER the associated widget (MapScreen) has been rendered.
    // Now it's safe to use mapController.move().
    _initialMapPosition();
  }

  // Toggles the map style (light/dark)
  void toggleMapStyle() {
    isDarkMap.value = !isDarkMap.value;
  }

  // Determines user's current position and triggers job filtering/display
  Future<void> _determinePositionAndFilter() async {
    isLoadingLocation.value = true;
    locationError.value = ""; // Clear previous errors

    try {
      LatLng? currentLocation;

      if (kIsWeb) {
        // Web-specific location handling
        currentLocation = await _getCurrentLocationWeb();
      } else {
        // Mobile-specific location handling
        currentLocation = await _getCurrentLocationMobile();
      }

      if (currentLocation != null) {
        userLat.value = currentLocation.latitude;
        userLng.value = currentLocation.longitude;

        // Now that location is fetched, update jobs and markers
        _updateDisplayedJobsAndMarkers();
      } else {
        // If location fails, still show jobs but without distance filtering
        _updateDisplayedJobsAndMarkers();
      }

    } catch (e) {
      locationError.value = kIsWeb
          ? 'تعذر الحصول على الموقع من المتصفح. يمكنك تصفح الوظائف بدون تحديد موقعك.'
          : 'خطأ في جلب الموقع: $e';
      debugPrint('Location Error: $e');

      // Still show jobs even if location fails
      _updateDisplayedJobsAndMarkers();
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<LatLng?> _getCurrentLocationWeb() async {
    try {
      // For web, we'll be more lenient with location services
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied on web');
          return null; // Return null instead of throwing
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever on web');
        return null;
      }

      // For web, use a longer timeout and medium accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Web location error: $e');
      return null; // Return null instead of throwing
    }
  }

  Future<LatLng?> _getCurrentLocationMobile() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('خدمة الموقع غير مفعّلة');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض صلاحية الموقع. يرجى تفعيلها من الإعدادات.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('صلاحية الموقع مرفوضة نهائيًا. يرجى تفعيلها من الإعدادات.');
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(pos.latitude, pos.longitude);
  }

  // Set initial map position after the map widget is ready
  void _initialMapPosition() {
    if (userLat.value != null && userLng.value != null) {
      mapController.move(LatLng(userLat.value!, userLng.value!), 12.0);
    } else {
      // Fallback if location not available, center on a default city
      mapController.move(const LatLng(33.5132, 36.2913), 12.0); // Default to Damascus
    }
  }

  // Re-centers the map on the user's current location
  Future<void> goToCurrentLocation() async {
    if (userLat.value != null && userLng.value != null) {
      mapController.move(LatLng(userLat.value!, userLng.value!), 15.0);
    } else {
      // If location is not available, try to fetch it again
      isLoadingLocation.value = true;

      try {
        LatLng? currentLocation;

        if (kIsWeb) {
          currentLocation = await _getCurrentLocationWeb();
        } else {
          currentLocation = await _getCurrentLocationMobile();
        }

        if (currentLocation != null) {
          userLat.value = currentLocation.latitude;
          userLng.value = currentLocation.longitude;
          mapController.move(currentLocation, 15.0);
          _updateDisplayedJobsAndMarkers(); // Update markers with new location
        } else {
          Get.snackbar(
            'تنبيه',
            kIsWeb
                ? 'تعذر الحصول على الموقع الحالي من المتصفح. يرجى السماح للموقع بالوصول للموقع أو تحديد موقعك يدوياً.'
                : 'تعذر الحصول على الموقع الحالي. يرجى التأكد من تفعيل خدمة الموقع والسماح للتطبيق.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        Get.snackbar(
          'خطأ',
          'حدث خطأ في تحديد الموقع: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        isLoadingLocation.value = false;
      }
    }
  }

  // Filters jobs by distance (if user location is available) and builds markers
  void _updateDisplayedJobsAndMarkers() {
    final List<JobModel> currentJobs = _jobController.jobs.toList();
    List<JobModel> filteredJobsList = [];

    if (userLat.value != null && userLng.value != null) {
      final from = LatLng(userLat.value!, userLng.value!);
      filteredJobsList = currentJobs.where((job) {
        // Exclude remote jobs from map display if they don't have real coordinates
        if (job.jobType == 'عن بعد' || (job.latitude == 0.0 && job.longitude == 0.0)) {
          return false; // Don't show remote jobs on map if they don't have coords
        }
        final to = LatLng(job.latitude, job.longitude);
        final distKm = _distance.as(LengthUnit.Kilometer, from, to);
        return distKm <= maxDistanceKm;
      }).toList();
    } else {
      // If user location is not available, display all non-remote jobs with coordinates
      filteredJobsList = currentJobs.where((job) => job.jobType != 'عن بعد' && (job.latitude != 0.0 || job.longitude != 0.0)).toList();
    }

    displayedJobs.assignAll(filteredJobsList);
    _buildAllMarkers();
  }

  // Builds all markers (user location + job locations) for the map
  void _buildAllMarkers() {
    final List<Marker> newMarkers = [];

    // Add user's current location marker
    if (userLat.value != null && userLng.value != null) {
      newMarkers.add(
        Marker(
          width: 40.0,
          height: 40.0,
          point: LatLng(userLat.value!, userLng.value!),
          child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 35.0),
          key: const ValueKey('user_marker'),
        ),
      );
    }

    // Add markers for all displayed jobs
    for (var job in displayedJobs) {
      // Ensure job has valid coordinates before trying to place it on map
      if (job.latitude != 0.0 || job.longitude != 0.0) {
        newMarkers.add(
          Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(job.latitude, job.longitude),
            child: Obx(() => Icon(
              selectedSingleJob.value?.id == job.id
                  ? Icons.location_on // Highlighted icon for selected job
                  : Icons.business_center, // Default job icon
              color: selectedSingleJob.value?.id == job.id
                  ? Get.theme.colorScheme.tertiary // Highlight color
                  : Get.theme.colorScheme.primary, // Default color
              size: selectedSingleJob.value?.id == job.id ? 45.0 : 35.0,
            ),
            ),
            key: ValueKey(job.id), // Use JobModel ID as marker key
          ),
        );
      }
    }
    markers.assignAll(newMarkers); // Update the reactive markers list
  }

  // Resets all job markers to their default icons
  void resetMarkerIcons() {
    selectedClusterJobs.clear();
    selectedSingleJob.value = null;
    _buildAllMarkers(); // Rebuilds all markers with default styles
  }

  // Highlights markers within a tapped cluster and updates selectedClusterJobs
  void updateMarkerIconsInCluster(List<Marker> clusterMarkers) {
    popupController.hideAllPopups(); // Hide any open popups

    final Set<String> clusterJobIds = clusterMarkers
        .where((m) => m.key is ValueKey<String> && (m.key as ValueKey<String>).value != 'user_marker')
        .map((m) => (m.key as ValueKey<String>).value)
        .toSet();

    // Populate selectedClusterJobs with actual JobModel objects
    selectedClusterJobs.assignAll(displayedJobs.where((job) => clusterJobIds.contains(job.id)).toList());
    selectedSingleJob.value = null; // Clear single job selection

    _buildAllMarkers(); // Rebuilds all markers to reset previous highlight and apply new one
    // Then specifically highlight the cluster markers
    _highlightClusterMarkers(clusterJobIds);
  }

  // Helper to highlight markers belonging to a specific cluster
  void _highlightClusterMarkers(Set<String> clusterJobIds) {
    final List<Marker> newMarkers = [];
    for (var currentMarker in markers) {
      // Only modify job markers, not the user's marker
      if (currentMarker.key is ValueKey<String> && (currentMarker.key as ValueKey<String>).value == 'user_marker') {
        newMarkers.add(currentMarker);
        continue;
      }

      if (currentMarker.key is ValueKey<String> && clusterJobIds.contains((currentMarker.key as ValueKey<String>).value)) {
        newMarkers.add(
          Marker(
            point: currentMarker.point,
            width: currentMarker.width,
            height: currentMarker.height,
            child: Icon(
              Icons.location_on, // Highlighted icon
              color: Get.theme.colorScheme.secondary, // A different highlight color for clusters
              size: 40,
            ),
            key: currentMarker.key,
          ),
        );
      } else {
        newMarkers.add(currentMarker); // Keep other markers as they are
      }
    }
    markers.assignAll(newMarkers);
  }

  // Handles a single job marker tap, highlights it, and updates selectedSingleJob
  void onJobMarkerTap(JobModel job) {
    selectedSingleJob.value = job;
    selectedClusterJobs.clear(); // Clear any cluster selection
    _highlightSingleMarker(job); // Highlight only this marker
    // Optionally, move the map to the tapped job's location
    // We assume the map is ready if a marker was tapped on it.
    mapController.move(LatLng(job.latitude, job.longitude), 15.0);
  }

  // Helper to highlight a single tapped marker
  void _highlightSingleMarker(JobModel jobToHighlight) {
    final List<Marker> newMarkers = [];
    for (var currentMarker in markers) {
      // Only modify job markers, not the user's marker
      if (currentMarker.key is ValueKey<String> && (currentMarker.key as ValueKey<String>).value == 'user_marker') {
        newMarkers.add(currentMarker);
        continue;
      }

      if (currentMarker.key == ValueKey(jobToHighlight.id)) {
        newMarkers.add(
          Marker(
            point: currentMarker.point,
            width: currentMarker.width,
            height: currentMarker.height,
            child: Icon(
              Icons.location_on, // Highlighted icon for single job
              color: Get.theme.colorScheme.tertiary, // Another distinct highlight color
              size: 45,
            ),
            key: currentMarker.key,
          ),
        );
      } else {
        newMarkers.add(currentMarker); // Keep other markers as they are
      }
    }
    markers.assignAll(newMarkers);
  }
}