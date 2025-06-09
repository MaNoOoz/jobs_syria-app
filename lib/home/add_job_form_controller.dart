// lib/controllers/add_job_form_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

import '../controllers/AuthController.dart';
import '../core/models.dart'; // Make sure JobModel and ContactOption/ContactType are here
import '../controllers/job_controller.dart';
import 'map_picker_screen.dart'; // Make sure MapPickerScreen is imported

class AddJobFormController extends GetxController {
  final JobController _jobController = Get.find<JobController>();
  final AuthController _authController = Get.find<AuthController>(); // Injected AuthController

  // Add this property to hold the job being edited (if any)
  final JobModel? initialJob;

  // Modify the constructor to accept the initial job
  AddJobFormController({this.initialJob});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController hashtagsController = TextEditingController();
  final TextEditingController locationTextController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController contactValueController = TextEditingController();

  // Reactive state variables
  final RxDouble latitude = 33.5138.obs; // Default to a central point in Syria (e.g., near Damascus)
  final RxDouble longitude = 36.2765.obs;

  final RxList<ContactOption> contactOptions = <ContactOption>[].obs;
  final Rx<ContactType?> chosenContactType = Rx<ContactType?>(null);
  final RxString selectedJobType = 'دوام كامل'.obs; // Default to full-time
  final RxBool isLoading = false.obs;

  // Job type options
  final List<String> jobTypes = [
    'دوام كامل',
    'دوام جزئي',
    'عن بعد',
    'مؤقت'
  ];

  // Store the last valid non-remote location for easy revert
  double? _lastValidLat;
  double? _lastValidLng;
  String? _lastValidLocationText;
  String? _lastValidCity;

  @override
  void onInit() {
    super.onInit();
    // Initialize form fields if an initial job is provided (for editing)
    if (initialJob != null) {
      _populateForm(initialJob!);
    } else {
      // Original logic for new job if not 'عن بعد' initially.
      if (selectedJobType.value != 'عن بعد') {
        locationTextController.text = '${latitude.value.toStringAsFixed(5)}, ${longitude.value.toStringAsFixed(5)}';
        reverseGeocodeAndSetCity(latitude.value, longitude.value);
        _lastValidLat = latitude.value;
        _lastValidLng = longitude.value;
        _lastValidLocationText = locationTextController.text;
        _lastValidCity = cityController.text;
      }
    }

    // Listener for job type changes to affect location fields
    ever(selectedJobType, (_) {
      // Re-call onJobTypeChanged to ensure correct state after initialization
      // This handles the scenario where initialJob might set jobType to 'عن بعد'
      // and we need to clear location fields.
      onJobTypeChanged(selectedJobType.value);
    });
  }

  // New method: Populates the form fields with data from an existing JobModel
  void _populateForm(JobModel job) {
    titleController.text = job.title;
    descController.text = job.description;
    hashtagsController.text = job.hashtags.join(', ');
    locationTextController.text = job.location ?? ''; // Use null-aware operator for safety
    cityController.text = job.city;

    latitude.value = job.latitude ?? 0.0; // Use null-aware for safety, default to 0.0 if null
    longitude.value = job.longitude ?? 0.0; // Use null-aware for safety, default to 0.0 if null

    // Set initial last valid location based on the job being edited
    _lastValidLat = latitude.value;
    _lastValidLng = longitude.value;
    _lastValidLocationText = locationTextController.text;
    _lastValidCity = cityController.text;

    selectedJobType.value = job.jobType;
    contactOptions.value = List.from(job.contactOptions); // Ensure it's a mutable list
  }


  @override
  void onClose() {
    titleController.dispose();
    descController.dispose();
    hashtagsController.dispose();
    locationTextController.dispose();
    cityController.dispose();
    contactValueController.dispose();
    super.onClose();
  }

  /// Converts Coordinates to City Name using geocoding.
  Future<void> reverseGeocodeAndSetCity(double lat, double lng) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        String cityName = place.locality ?? place.administrativeArea ?? '';
        cityController.text = cityName.isNotEmpty ? cityName : 'غير معروفة'; // Set to 'Unknown' if not found
      } else {
        cityController.text = 'غير معروفة';
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
      cityController.text = 'خطأ في تحديد المدينة';
      Get.snackbar('خطأ', 'فشل تحديد المدينة تلقائيًا: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// Handles location picking from the map.
  Future<void> pickLocationOnMap() async {
    // If current job type is 'عن بعد', temporarily set to a default physical location for map picking
    LatLng initialMapLocation = LatLng(latitude.value, longitude.value);
    // If current coords are 0.0, 0.0 (e.g. from a remote job or initial unpicked state),
    // start map at a sensible default (Damascus).
    if (latitude.value == 0.0 && longitude.value == 0.0) {
      initialMapLocation = LatLng(33.5138, 36.2765); // Damascus default for map picker
    }

    final LatLng? picked = await Get.to<LatLng>(
          () => MapPickerScreen(initialLocation: initialMapLocation),
    );

    if (picked != null) {
      latitude.value = picked.latitude;
      longitude.value = picked.longitude;
      locationTextController.text = '${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}';
      await reverseGeocodeAndSetCity(picked.latitude, picked.longitude);

      // If job type was 'عن بعد', automatically change it to 'دوام كامل'
      // when a physical location is picked on the map.
      if (selectedJobType.value == 'عن بعد') {
        selectedJobType.value = 'دوام كامل';
      }

      // Store as last valid for potential revert from remote
      _lastValidLat = latitude.value;
      _lastValidLng = longitude.value;
      _lastValidLocationText = locationTextController.text;
      _lastValidCity = cityController.text;
    }
  }

  /// Opens a dialog to add contact options for the job.
  void openAddContactDialog(BuildContext context) {
    chosenContactType.value = null; // Reset for new dialog
    contactValueController.clear();

    Get.dialog(
      AlertDialog(
        title: const Text('أضف طريقة تواصل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => DropdownButtonFormField<ContactType>(
              decoration: const InputDecoration(labelText: 'اختر النوع'),
              value: chosenContactType.value,
              items: ContactType.values.map((ct) {
                return DropdownMenuItem(
                  value: ct,
                  // Use ct.name for the enum value string (e.g., "email", "phone")
                  child: Text(ct.name),
                );
              }).toList(),
              onChanged: (val) {
                chosenContactType.value = val; // Update reactive variable
              },
            )),
            const SizedBox(height: 10),
            TextField(
              controller: contactValueController,
              decoration: const InputDecoration(labelText: 'القيمة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final raw = contactValueController.text.trim();
              if (chosenContactType.value == null || raw.isEmpty) {
                Get.snackbar('خطأ', 'الرجاء اختيار نوع وإدخال قيمة', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
                return;
              }

              // No need for 'formattedValue' if ContactOption directly stores raw value
              // You can format it later when displaying or acting on it.
              // For now, just store the raw input as per your existing ContactOption usage.
              contactOptions.add(ContactOption(type: chosenContactType.value!, value: raw));
              Get.back(); // Close dialog
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  /// Removes a contact option from the list.
  void removeContactOption(ContactOption option) {
    contactOptions.remove(option);
  }

  /// Submits the job data to Firestore and updates user's posted jobs.
  /// Submits the job data to Firestore and updates user's posted jobs.
  Future<void> submitJob() async {
    if (formKey.currentState!.validate()) {
      // Additional validation for non-remote jobs requiring location
      if (selectedJobType.value != 'عن بعد' && (latitude.value == 0.0 && longitude.value == 0.0)) {
        Get.snackbar('خطأ', 'الرجاء اختيار موقع الوظيفة على الخريطة للوظائف غير البعيدة.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      if (selectedJobType.value != 'عن بعد' && (cityController.text.isEmpty || cityController.text == 'غير معروفة' || cityController.text == 'خطأ في تحديد المدينة')) {
        Get.snackbar('خطأ', 'الرجاء التأكد من تحديد مدينة صالحة لوظائف الدوام الكامل/الجزئي/المؤقت.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final String? currentUserId = _authController.getCurrentUserId();
      if (currentUserId == null) {
        Get.snackbar('خطأ', 'يجب تسجيل الدخول لإضافة أو تعديل وظيفة.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        isLoading.value = false;
        return;
      }

      isLoading.value = true;
      try {
        // Construct the JobModel based on whether we're adding or editing
        JobModel jobToSubmit;

        if (initialJob == null) {
          // ADD NEW JOB
          final newJobId = const Uuid().v4(); // Generate unique ID for the new job
          jobToSubmit = JobModel(
            id: newJobId,
            title: titleController.text.trim(),
            description: descController.text.trim(),
            city: cityController.text.trim(),
            jobType: selectedJobType.value,
            location: locationTextController.text.trim(),
            latitude: latitude.value,
            longitude: longitude.value,
            createdAt: DateTime.now(),
            hashtags: hashtagsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty && e.startsWith('#'))
                .toList(),
            contactOptions: contactOptions.toList(),
            ownerId: currentUserId, // Assign the current user's ID as ownerId
            distanceInKm: null, // Always null on creation, calculated on fetch
          );

          debugPrint('Attempting to add new job: ${jobToSubmit.toMap()}');
          // No 'bool success' check here. We rely on the try-catch for success/failure.
          await _jobController.addJob(jobToSubmit);

          // If addJob completes without throwing, it's a success
          // Update the current user's `myJobs` list in GetStorage
          final UserModel? user = _authController.currentUser.value;
          if (user != null) {
            final updatedMyJobs = List<String>.from(user.myJobs);
            updatedMyJobs.add(newJobId); // Add the newly posted job's ID

            final updatedUser = user.copyWith(myJobs: updatedMyJobs);
            await _authController.updateCurrentUser(updatedUser); // Call AuthController to update user
          }

          _jobController.fetchJobs(); // Refresh jobs after adding
          Get.back(); // Go back to previous screen
          // The snackbar for success is handled by JobController.addJob
          // Get.snackbar('نجاح', 'تمت إضافة الوظيفة بنجاح', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);

        } else {
          // EDIT EXISTING JOB
          jobToSubmit = initialJob!.copyWith(
            title: titleController.text.trim(),
            description: descController.text.trim(),
            city: cityController.text.trim(),
            jobType: selectedJobType.value,
            location: locationTextController.text.trim(),
            latitude: latitude.value,
            longitude: longitude.value,
            // createdAt, ownerId, distanceInKm should remain from initialJob
            hashtags: hashtagsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty && e.startsWith('#'))
                .toList(),
            contactOptions: contactOptions.toList(),
          );
          debugPrint('Attempting to update job: ${jobToSubmit.toMap()}');
          // No 'bool success' check here. We rely on the try-catch for success/failure.
          await _jobController.updateJob(jobToSubmit);

          // If updateJob completes without throwing, it's a success
          _jobController.fetchOwnerJobs(currentUserId); // Refresh owner's jobs after updating
          Get.back(); // Go back from edit screen
          // The snackbar for success is handled by JobController.updateJob
          // Get.snackbar('نجاح', 'تم تحديث الإعلان بنجاح!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        }
      } catch (e) {
        // This catch block will now catch errors rethrown by _jobController.addJob or _jobController.updateJob
        debugPrint('Error during job submission/update in controller: $e');
        // The snackbar for error is handled by JobController methods
        // Get.snackbar('خطأ', 'حدث خطأ غير متوقع: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        isLoading.value = false;
      }
    }
  }

  /// Handles changes in job type, adjusting location fields accordingly.
  void onJobTypeChanged(String? newValue) async {
    if (newValue != null) {
      selectedJobType.value = newValue;
      if (newValue == 'عن بعد') {
        // Store current physical location before clearing for remote
        _lastValidLat = latitude.value;
        _lastValidLng = longitude.value;
        _lastValidLocationText = locationTextController.text;
        _lastValidCity = cityController.text;

        // Clear and set to remote defaults
        cityController.text = 'عن بعد';
        locationTextController.text = 'عن بعد';
        latitude.value = 0.0;
        longitude.value = 0.0;
      } else {
        // If switching from 'عن بعد', try to revert to last valid or default physical location
        if (_lastValidLat != null && _lastValidLng != null &&
            (_lastValidLat != 0.0 || _lastValidLng != 0.0)) { // Ensure last valid was not 0,0
          latitude.value = _lastValidLat!;
          longitude.value = _lastValidLng!;
          locationTextController.text = _lastValidLocationText!;
          cityController.text = _lastValidCity!;
        } else {
          // If no last valid, revert to initial default and re-geocode
          latitude.value = 33.5138;
          longitude.value = 36.2765;
          locationTextController.text = '${latitude.value.toStringAsFixed(5)}, ${longitude.value.toStringAsFixed(5)}';
          await reverseGeocodeAndSetCity(latitude.value, longitude.value);
        }
      }
    }
  }

  /// Generic validation for required text fields.
  String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }
}