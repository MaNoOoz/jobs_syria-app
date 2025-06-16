// lib/controllers/add_job_form_controller.dart

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import '../controllers/home_controller.dart';
import 'map_picker_screen.dart'; // Make sure MapPickerScreen is imported

// lib/controllers/add_job_form_controller.dart

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../controllers/home_controller.dart';
import 'map_picker_screen.dart'; // Make sure MapPickerScreen is imported

class AddJobFormController extends GetxController {
  final HomeController _jobController = Get.find<HomeController>();
  final AuthService _authService = Get.find<AuthService>();

  final JobModel? initialJob;

  AddJobFormController({this.initialJob}) {
    if (initialJob != null) {
      _populateForm(initialJob!);
    }
  }

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController hashtagsController = TextEditingController();
  final TextEditingController locationTextController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController contactValueController = TextEditingController();
  // Removed minSalaryController and maxSalaryController

  // Reactive state variables
  final RxDouble latitude = 33.5138.obs; // Default to a central point in Syria (e.g., near Damascus)
  final RxDouble longitude = 36.2765.obs;

  final RxList<ContactOption> contactOptions = <ContactOption>[].obs; // Corrected syntax here from `]}` to `[]`
  final Rx<ContactType?> chosenContactType = Rx<ContactType?>(null);
  final RxString selectedJobType = 'دوام كامل'.obs; // Default to full-time
  final RxBool isLoading = false.obs;

  // New reactive variable for the 'وظيفة عن بعد؟' switch
  final RxBool isRemote = false.obs;

  // Job type options
  final List<String> jobTypes = [
    'دوام كامل',
    'دوام جزئي',
    'عن بعد',
    'مؤقت'
  ];

  // Cities for the dropdown, based on your previous `home_view.dart`
  static const List<String> cities = ['دمشق', 'حلب', 'حمص', 'اللاذقية', 'طرطوس'];

  // Store the last valid non-remote location for easy revert
  double? _lastValidLat;
  double? _lastValidLng;
  String? _lastValidLocationText;
  String? _lastValidCity;
  String? _lastValidJobType = 'دوام كامل'; // Store the last valid non-remote job type

  @override
  void onInit() {
    super.onInit();

    // Initialize form fields if an initial job is provided (for editing)
    if (initialJob != null) {
      _populateForm(initialJob!);
    } else {
      // For new jobs, initialize with a default location (e.g., Damascus)
      // and immediately try to reverse geocode it.
      if (selectedJobType.value != 'عن بعد') {
        _initializeDefaultLocation();
      }
    }

    // Listener for job type changes to affect location fields
    ever(selectedJobType, (_) {
      _handleJobTypeLocationLogic(selectedJobType.value);
    });

    // Explicitly handle initial state for `isRemote` based on `selectedJobType`
    isRemote.value = (selectedJobType.value == 'عن بعد');
  }

  /// Helper to set initial default location and geocode it
  Future<void> _initializeDefaultLocation() async {
    latitude.value = 33.5138; // Damascus
    longitude.value = 36.2765;
    // locationTextController.text should be updated by reverse geocoding
    await _reverseGeocodeAndSetCity(LatLng(latitude.value, longitude.value));
    _lastValidLat = latitude.value;
    _lastValidLng = longitude.value;
    _lastValidLocationText = locationTextController.text;
    _lastValidCity = cityController.text;
  }

  // New method: Populates the form fields with data from an existing JobModel
  void _populateForm(JobModel job) {
    titleController.text = job.title;
    descController.text = job.description;
    hashtagsController.text = job.hashtags.join(', ');
    locationTextController.text = job.location ?? '';
    cityController.text = job.city;

    if (job.latitude != null && job.longitude != null) {
      latitude.value = job.latitude!;
      longitude.value = job.longitude!;
      _lastValidLat = job.latitude;
      _lastValidLng = job.longitude;
      _lastValidLocationText = job.location;
      _lastValidCity = job.city;
    }

    selectedJobType.value = job.jobType;
    isRemote.value = (job.jobType == 'عن بعد'); // Sync isRemote with jobType
    contactOptions.value = List<ContactOption>.from(job.contactOptions);
  }

  @override
  void onClose() {
    titleController.dispose();
    descController.dispose();
    hashtagsController.dispose();
    locationTextController.dispose();
    cityController.dispose();
    contactValueController.dispose();
    // Removed minSalaryController.dispose();
    // Removed maxSalaryController.dispose();
    super.onClose();
  }

  /// Handles the toggling of the 'isRemote' switch.
  void toggleRemote(bool value) {
    isRemote.value = value;
    if (value) {
      selectedJobType.value = 'عن بعد';
    } else {
      // When switching off remote, revert to last non-remote type or default to full-time
      selectedJobType.value = _lastValidJobType ?? 'دوام كامل';
    }
  }

  /// Logic to handle location fields based on job type (remote vs. physical).
  Future<void> _handleJobTypeLocationLogic(String newType) async {
    if (newType == 'عن بعد') {
      // Store current physical location and job type before clearing for remote
      _lastValidLat = latitude.value;
      _lastValidLng = longitude.value;
      _lastValidLocationText = locationTextController.text;
      _lastValidCity = cityController.text;
      _lastValidJobType = initialJob?.jobType ?? selectedJobType.value; // Capture previous job type

      // Clear and set to remote defaults
      cityController.text = 'عن بعد';
      locationTextController.text = 'عن بعد';
      latitude.value = 0.0;
      longitude.value = 0.0;
    } else {
      // When switching from 'عن بعد' to a physical job type
      if (_lastValidLat != null && _lastValidLng != null &&
          (_lastValidLat != 0.0 || _lastValidLng != 0.0)) {
        // Revert to last valid physical location
        latitude.value = _lastValidLat!;
        longitude.value = _lastValidLng!;
        locationTextController.text = _lastValidLocationText!;
        cityController.text = _lastValidCity!;
      } else {
        // If no last valid, revert to initial default and re-geocode
        await _initializeDefaultLocation();
      }
    }
  }

  /// Converts Coordinates to City Name using geocoding.
  Future<void> _reverseGeocodeAndSetCity(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
        // localeIdentifier: 'ar', // This parameter is not always supported consistently
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String displayCity = place.administrativeArea ?? place.locality ?? place.name ?? 'غير معروفة';
        cityController.text = displayCity;

        locationTextController.text = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        if (locationTextController.text.isEmpty) {
          locationTextController.text = 'خطأ في تحديد الموقع';
        }
      } else {
        cityController.text = 'غير معروفة';
        locationTextController.text = 'الموقع غير متاح';
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
      cityController.text = 'خطأ في تحديد المدينة';
      locationTextController.text = 'خطأ في تحديد الموقع';
    }
  }

  /// Handles location picking from the map.
  Future<void> pickLocation(BuildContext context) async {
    LatLng initialMapLocation = LatLng(latitude.value, longitude.value);
    if (latitude.value == 0.0 && longitude.value == 0.0) {
      initialMapLocation = const LatLng(33.5138, 36.2765); // Damascus default for map picker
    }

    final result = await Get.to<LatLng>(() => MapPickerScreen(initialLocation: initialMapLocation));
    if (result != null) {
      latitude.value = result.latitude;
      longitude.value = result.longitude;
      await _reverseGeocodeAndSetCity(result);

      if (selectedJobType.value == 'عن بعد') {
        selectedJobType.value = 'دوام كامل';
        isRemote.value = false;
      }

      _lastValidLat = latitude.value;
      _lastValidLng = longitude.value;
      _lastValidLocationText = locationTextController.text;
      _lastValidCity = cityController.text;
      _lastValidJobType = selectedJobType.value;
    }
  }

  /// Generic validation for required text fields.
  String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  // Removed validateNumber method

  /// Specific validation for hashtags.
  String? validateHashtags(String? value) {
    if (value != null && value.isNotEmpty) {
      final tags = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      for (final tag in tags) {
        if (!tag.startsWith('#')) {
          return 'يجب أن تبدأ الهاشتاجات بعلامة #';
        }
        if (tag.length < 2) {
          return 'يجب أن تحتوي الهاشتاجات على حرف واحد على الأقل بعد #';
        }
      }
    }
    return null;
  }

  /// Validation for contact value based on type.
  String? _validateContactValue(ContactType type, String value) {
    if (value.isEmpty) {
      return 'قيمة التواصل مطلوبة.';
    }

    switch (type) {
      case ContactType.phone:
      case ContactType.whatsapp:
        final phoneRegex = RegExp(r'^\+[0-9]{7,15}$');
        if (!phoneRegex.hasMatch(value)) {
          return 'رقم الهاتف/واتساب غير صحيح. يجب أن يبدأ بـ "+" متبوعًا بـ 7 إلى 15 رقمًا.';
        }
        break;
      case ContactType.email:
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!emailRegex.hasMatch(value)) {
          return 'صيغة البريد الإلكتروني غير صحيحة.';
        }
        break;
      case ContactType.telegram:
        if (value.startsWith('@')) {
          final usernameRegex = RegExp(r'^@[a-zA-Z0-9_]{5,32}$');
          if (!usernameRegex.hasMatch(value)) {
            return 'اسم مستخدم تيليجرام غير صحيح. يجب أن يبدأ بـ "@" ويحتوي على أحرف وأرقام وشرطات سفلية (5-32 حرفًا).';
          }
        } else {
          final phoneRegex = RegExp(r'^\+[0-9]{7,15}$');
          if (!phoneRegex.hasMatch(value)) {
            return 'صيغة تيليجرام غير صحيحة (يجب أن تبدأ بـ "@" أو رقم هاتف دولي).';
          }
        }
        break;
      case ContactType.facebook:
        final urlRegex = RegExp(r'^(https?:\/\/(?:www\.)?facebook\.com\/[a-zA-Z0-9._-]+|@[a-zA-Z0-9._-]+)$');
        if (!urlRegex.hasMatch(value)) {
          return 'رابط فيسبوك غير صحيح أو اسم مستخدم غير صالح.';
        }
        break;
      case ContactType.website:
        final urlRegex = RegExp(
          r'^((https?:\/\/)?' // optional http:// or https://
          r'(www\.)?' // optional www.
          r'(([a-z\d]([a-z\d-]*[a-z\d])*)\.)+[a-z]{2,}' // domain name
          r'(\:\d+)?' // port
          r'(\/[-a-z\d%_.~+]*)*' // path
          r'(\?[;&a-z\d%_.~+=-]*)?' // query string
          r'(\#[-a-z\d_]*)?)$', // fragment locator
          caseSensitive: false,
        );

        if (!urlRegex.hasMatch(value)) {
          return 'الرجاء إدخال رابط موقع صحيح (مثال: example.com أو www.example.com)';
        }

        if (value.length > 200) {
          return 'الرابط طويل جدًا (الحد الأقصى 200 حرف)';
        }
        break;
      case ContactType.other:
        if (value.length < 3 || value.length > 200) {
          return 'القيمة المدخلة قصيرة جدًا أو طويلة جدًا (3-200 حرف).';
        }
        break;
    }
    return null; // Valid
  }

  /// Opens a dialog to add a contact option.
  void openAddContactDialog(BuildContext context) {
    chosenContactType.value = null; // Reset for new dialog
    contactValueController.clear(); // Clear previous input

    Get.dialog(
      AlertDialog(
        title: const Text('أضف طريقة تواصل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() =>
                DropdownButtonFormField<ContactType>(
                  value: chosenContactType.value,
                  hint: const Text('نوع التواصل'),
                  items: ContactType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (type) {
                    chosenContactType.value = type;
                  },
                  validator: (type) {
                    if (type == null) {
                      return 'الرجاء اختيار نوع التواصل';
                    }
                    return null;
                  },
                )),
            const SizedBox(height: 12),
            TextFormField(
              controller: contactValueController,
              decoration: const InputDecoration(
                labelText: 'القيمة (مثال: +9639991234567، username@example.com)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final type = chosenContactType.value;
              final value = contactValueController.text.trim();

              if (type == null) {
                Get.snackbar('خطأ', 'الرجاء اختيار نوع التواصل.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white);
                return;
              }

              final validationError = _validateContactValue(type, value);
              if (validationError != null) {
                Get.snackbar('خطأ', validationError,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white);
                return;
              }

              // Check for duplicate contact options
              if (contactOptions.any((opt) => opt.type == type && opt.value == value)) {
                Get.snackbar('خطأ', 'طريقة التواصل هذه موجودة بالفعل.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white);
                return;
              }

              contactOptions.add(ContactOption(type: type, value: value));
              contactValueController.clear();
              chosenContactType.value = null;
              Get.back();
              Get.snackbar('نجاح', 'تمت إضافة طريقة التواصل.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  /// Removes a contact option from the list.
  void removeContactOption(ContactOption option) {
    contactOptions.remove(option);
    Get.snackbar('إزالة', 'تمت إزالة طريقة التواصل.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white);
  }

  /// Submits the job data, including form validation.
  Future<void> submitJob() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar('خطأ في البيانات', 'الرجاء ملء جميع الحقول المطلوبة بشكل صحيح.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    // Additional validation for non-remote jobs requiring location
    if (!isRemote.value && (latitude.value == 0.0 && longitude.value == 0.0)) {
      Get.snackbar('خطأ في الموقع', 'الرجاء اختيار موقع الوظيفة على الخريطة.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    if (!isRemote.value && (cityController.text.isEmpty || cityController.text == 'غير معروفة' || cityController.text == 'خطأ في تحديد المدينة')) {
      Get.snackbar('خطأ في المدينة', 'الرجاء التأكد من تحديد مدينة صالحة.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    if (contactOptions.isEmpty) {
      Get.snackbar('خطأ', 'الرجاء إضافة طريقة تواصل واحدة على الأقل.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    final String? currentUserId = _authService.currentUser.value?.uid;

    if (currentUserId == null) {
      isLoading.value = false;
      Get.snackbar('خطأ', 'يجب تسجيل الدخول لإضافة أو تعديل وظيفة.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    try {
      JobModel jobToSubmit;
      final parsedHashtags = hashtagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.startsWith('#'))
          .toList();

      // Removed parsing of salaries

      // Ensure that if it's a remote job, location data is consistently 'عن بعد' or 0.0
      String finalLocationText = locationTextController.text;
      String finalCity = cityController.text;
      double finalLatitude = latitude.value;
      double finalLongitude = longitude.value;

      if (isRemote.value) {
        finalLocationText = 'عن بعد';
        finalCity = 'عن بعد';
        finalLatitude = 0.0;
        finalLongitude = 0.0;
      }

      if (initialJob == null) {
        // ADD NEW JOB
        final newJobId = const Uuid().v4();
        jobToSubmit = JobModel(
          id: newJobId,
          title: titleController.text.trim(),
          description: descController.text.trim(),
          city: finalCity,
          jobType: selectedJobType.value,
          location: finalLocationText,
          latitude: finalLatitude,
          longitude: finalLongitude,
          createdAt: DateTime.now(),
          hashtags: parsedHashtags,
          contactOptions: contactOptions.toList(),
          ownerId: currentUserId,
          distanceInKm: null,
        );

        debugPrint('Attempting to add new job: ${jobToSubmit.toMap()}');
        await _jobController.addJob(jobToSubmit);

        final UserModel? user = _authService.currentUser.value;
        if (user != null) {
          final updatedMyJobs = List<String>.from(user.myJobs);
          updatedMyJobs.add(newJobId);
          final updatedUser = user.copyWith(myJobs: updatedMyJobs);
          await _authService.updateUserInFirestore(updatedUser.uid!, updatedUser.toMap());
        }

        Get.snackbar('نجاح', 'تمت إضافة الوظيفة بنجاح!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
        Get.back();
      } else {
        // EDIT EXISTING JOB
        jobToSubmit = initialJob!.copyWith(
          title: titleController.text.trim(),
          description: descController.text.trim(),
          city: finalCity,
          jobType: selectedJobType.value,
          location: finalLocationText,
          latitude: finalLatitude,
          longitude: finalLongitude,
          hashtags: parsedHashtags,
          contactOptions: contactOptions.toList(),
          // ownerId and createdAt should not change during update
        );
        debugPrint('Attempting to update job: ${jobToSubmit.toMap()}');
        await _jobController.updateJob(jobToSubmit);

        Get.snackbar('نجاح', 'تم تحديث الوظيفة بنجاح!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
        Get.back();
      }
    } catch (e) {
      debugPrint('Error during job submission/update: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء حفظ الوظيفة: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
      Get.offAndToNamed(Routes.MAIN);
    }
  }
}