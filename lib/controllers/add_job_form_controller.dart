// lib/controllers/add_job_form_controller.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'home_controller.dart';
import '../models.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import '../ui/map_picker_screen.dart'; // Make sure MapPickerScreen is imported

class AddJobFormController extends GetxController {
  final HomeController _jobController = Get.find<HomeController>();
  final AuthService _authService = Get.find<AuthService>();

  final JobModel? initialJob;

  AddJobFormController({this.initialJob});

  // --- Form State and Controllers ---
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController hashtagsController = TextEditingController();
  final TextEditingController locationTextController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController contactValueController = TextEditingController();

  final RxDouble latitude = 33.5138.obs;
  final RxDouble longitude = 36.2765.obs;
  final RxList<ContactOption> contactOptions = <ContactOption>[].obs;
  final Rx<ContactType?> chosenContactType = Rx<ContactType?>(null);
  final RxString selectedJobType = 'دوام كامل'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRemote = false.obs;

  final List<String> jobTypes = ['دوام كامل', 'دوام جزئي', 'عن بعد', 'مؤقت'];

  // --- Private State for Location Reverting ---
  double? _lastValidLat;
  double? _lastValidLng;
  String? _lastValidLocationText;
  String? _lastValidCity;
  String? _lastValidJobType = 'دوام كامل';

  @override
  void onInit() {
    super.onInit();
    if (initialJob != null) {
      _populateForm(initialJob!);
    } else if (selectedJobType.value != 'عن بعد') {
      _initializeDefaultLocation();
    }
    ever(selectedJobType, _handleJobTypeLocationLogic);
    isRemote.value = (selectedJobType.value == 'عن بعد');
  }

  @override
  void onClose() {
    // Dispose all controllers
    titleController.dispose();
    descController.dispose();
    hashtagsController.dispose();
    locationTextController.dispose();
    cityController.dispose();
    contactValueController.dispose();
    super.onClose();
  }

  //================================================================================
  // --- Form Initialization and Population ---
  //================================================================================

  void _populateForm(JobModel job) {
    titleController.text = job.title;
    descController.text = job.description;
    // IMPROVEMENT: Join without the '#' for easier parsing later
    hashtagsController.text = job.hashtags.map((h) => h.substring(1)).join(', ');
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
    isRemote.value = (job.jobType == 'عن بعد');
    contactOptions.value = List<ContactOption>.from(job.contactOptions);
  }

  Future<void> _initializeDefaultLocation() async {
    latitude.value = 33.5138; // Damascus
    longitude.value = 36.2765;
    await _reverseGeocodeAndSetCity(LatLng(latitude.value, longitude.value));
    _saveLastValidLocation();
  }

  //================================================================================
  // --- Main Public Methods (Submit, Pick Location, etc.) ---
  //================================================================================

  /// Orchestrates the entire job submission process.
  Future<void> submitJob() async {
    // 1. Validate all form inputs and conditions
    if (!_isFormValid()) return;

    final String? currentUserId = _authService.currentUser.value?.uid;
    if (currentUserId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول لإضافة أو تعديل وظيفة.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      // 2. Build the JobModel with all data
      final jobToSubmit = _buildJobModel(currentUserId);

      // 3. Perform the database operation (add or update)
      await _performDatabaseSubmission(jobToSubmit);

      final successMessage =
      initialJob == null ? 'تمت إضافة الوظيفة بنجاح!' : 'تم تحديث الوظيفة بنجاح!';
      Get.snackbar('نجاح', successMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);

      Get.offAndToNamed(Routes.MAIN);
    } catch (e) {
      debugPrint('Error during job submission/update: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء حفظ الوظيفة: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  /// Handles location picking from the map.
  Future<void> pickLocation(BuildContext context) async {
    LatLng initialMapLocation = (latitude.value == 0.0 && longitude.value == 0.0)
        ? const LatLng(33.5138, 36.2765) // Default to Damascus
        : LatLng(latitude.value, longitude.value);

    final result = await Get.to<LatLng>(() => MapPickerScreen(initialLocation: initialMapLocation));
    if (result != null) {
      latitude.value = result.latitude;
      longitude.value = result.longitude;
      await _reverseGeocodeAndSetCity(result);

      // If user was in "remote" mode, switch them back to a physical job type
      if (selectedJobType.value == 'عن بعد') {
        selectedJobType.value = _lastValidJobType ?? 'دوام كامل';
        isRemote.value = false;
      }

      _saveLastValidLocation();
    }
  }

  //================================================================================
  // --- NEW: Refactored Helper Methods for Submission ---
  //================================================================================

  /// NEW: Centralized validation method.
  bool _isFormValid() {
    if (!formKey.currentState!.validate()) {
      Get.snackbar('خطأ في البيانات', 'الرجاء ملء جميع الحقول المطلوبة بشكل صحيح.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (!isRemote.value) {
      if (latitude.value == 0.0 || longitude.value == 0.0) {
        Get.snackbar('خطأ في الموقع', 'الرجاء اختيار موقع الوظيفة على الخريطة.',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }

      // Relaxed city validation
      if (cityController.text.isEmpty ||
          cityController.text.toLowerCase().contains('خطأ')) {
        Get.snackbar('خطأ في المدينة', 'الرجاء التأكد من تحديد موقع صالح على الخريطة.',
            backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
    }
    if (contactOptions.isEmpty) {
      Get.snackbar('خطأ', 'الرجاء إضافة طريقة تواصل واحدة على الأقل.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    return true;
  }

  /// NEW: Parses hashtags and automatically adds '#' if missing.
  List<String> _parseHashtags() {
    if (hashtagsController.text.trim().isEmpty) return [];

    return hashtagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .map((tag) => tag.startsWith('#') ? tag : '#$tag')
        .toList();
  }

  /// NEW: Builds the final JobModel object.
  JobModel _buildJobModel(String ownerId) {
    final parsedHashtags = _parseHashtags();

    // Determine final location details based on 'isRemote'
    final bool isJobRemote = isRemote.value;
    final String finalCity = isJobRemote ? 'عن بعد' : cityController.text;
    final String finalLocationText = isJobRemote ? 'عن بعد' : locationTextController.text;
    final double finalLatitude = isJobRemote ? 0.0 : latitude.value;
    final double finalLongitude = isJobRemote ? 0.0 : longitude.value;

    if (initialJob == null) {
      // Creating a new job
      return JobModel(
        id: const Uuid().v4(),
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
        ownerId: ownerId,
        distanceInKm: null,
      );
    } else {
      // Updating an existing job
      return initialJob!.copyWith(
        title: titleController.text.trim(),
        description: descController.text.trim(),
        city: finalCity,
        jobType: selectedJobType.value,
        location: finalLocationText,
        latitude: finalLatitude,
        longitude: finalLongitude,
        hashtags: parsedHashtags,
        contactOptions: contactOptions.toList(),
      );
    }
  }

  /// NEW: Handles the final database call for add or update.
  Future<void> _performDatabaseSubmission(JobModel job) async {
    if (initialJob == null) {
      // Add new job
      debugPrint('Attempting to add new job: ${job.toMap()}');
      await _jobController.addJob(job);
      // Also update the user's list of created jobs
      await _authService.addJobToUserList(job.id);
    } else {
      // Update existing job
      debugPrint('Attempting to update job: ${job.toMap()}');
      await _jobController.updateJob(job);
    }
  }

  //================================================================================
  // --- Location and Remote-Work Logic ---
  //================================================================================

  void toggleRemote(bool value) {
    isRemote.value = value;
    if (value) {
      selectedJobType.value = 'عن بعد';
    } else {
      selectedJobType.value = _lastValidJobType ?? 'دوام كامل';
    }
  }

  void _handleJobTypeLocationLogic(String newType) {
    final isNowRemote = (newType == 'عن بعد');

    if (isNowRemote) {
      _saveLastValidLocation();
      cityController.text = 'عن بعد';
      locationTextController.text = 'عن بعد';
      latitude.value = 0.0;
      longitude.value = 0.0;
    } else {
      // Only revert if we have valid previous location
      if (_lastValidLat != null && _lastValidLng != null) {
        _revertToLastValidLocation();
      } else {
        // Initialize default if no previous location
        _initializeDefaultLocation();
      }
    }

    // Update remote status
    isRemote.value = isNowRemote;
  }

  void _saveLastValidLocation() {
    if (!isRemote.value) {
      _lastValidLat = latitude.value;
      _lastValidLng = longitude.value;
      _lastValidLocationText = locationTextController.text;
      _lastValidCity = cityController.text;
      // Also save the job type if it's not 'عن بعد'
      if (selectedJobType.value != 'عن بعد') {
        _lastValidJobType = selectedJobType.value;
      }
    }
  }

  Future<void> _revertToLastValidLocation() async {
    if (_lastValidLat != null && _lastValidLng != null && (_lastValidLat != 0.0 || _lastValidLng != 0.0)) {
      latitude.value = _lastValidLat!;
      longitude.value = _lastValidLng!;
      locationTextController.text = _lastValidLocationText!;
      cityController.text = _lastValidCity!;
    } else {
      await _initializeDefaultLocation();
    }
  }

  //================================================================================
  // --- Geocoding Logic (Split for Web/Mobile) ---
  //================================================================================

  Future<void> _reverseGeocodeAndSetCity(LatLng latLng) async {
    try {
      if (kIsWeb) {
        await _reverseGeocodeForWeb(latLng);
      } else {
        await _reverseGeocodeForMobile(latLng);
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
      cityController.text = 'خطأ في تحديد المدينة';
      locationTextController.text = 'خطأ في تحديد الموقع';
    }
  }

  Future<void> _reverseGeocodeForWeb(LatLng latLng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${latLng.latitude}&lon=${latLng.longitude}&format=json&addressdetails=1');
      final response = await http.get(url, headers: {'Accept-Language': 'ar'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        // Improved city detection
        final city = address?['city'] ??
            address?['town'] ??
            address?['village'] ??
            address?['county'] ??
            address?['state'] ??
            'غير معروفة';

        // Fallback to coordinates if no display name
        final locationName = data['display_name']?.toString() ??
            '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';

        cityController.text = city;
        locationTextController.text = locationName;
      } else {
        // Use coordinates as fallback
        cityController.text = 'موقع غير معروف';
        locationTextController.text = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      // Use coordinates on any error
      cityController.text = 'موقع غير معروف';
      locationTextController.text = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
    }
  }
  Future<void> _reverseGeocodeForMobile(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Improved city detection
        final city = place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            'غير معروفة';

        // Build location text safely
        final locationParts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        cityController.text = city;
        locationTextController.text = locationParts.isNotEmpty
            ? locationParts
            : '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
      } else {
        cityController.text = 'موقع غير معروف';
        locationTextController.text = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      cityController.text = 'موقع غير معروف';
      locationTextController.text = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
    }
  }
  /// Generic validation for required text fields.
  String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }


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

      // If the value doesn't start with '@', prepend it.
        if (!value.startsWith('@')) {
          value = '@$value';
        }

        // Validate username with '@' prepended
        final usernameRegex = RegExp(r'^@[a-zA-Z0-9_]{5,32}$');
        if (!usernameRegex.hasMatch(value)) {
          return '  اسم مستخدم تيليجرام غير صحيح. 5 أحرف على الأقل';
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
            Obx(() => DropdownButtonFormField<ContactType>(
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
            Obx(() {
              // Define hint text based on the selected contact type
              String hintText = '';
              switch (chosenContactType.value) {
                case ContactType.whatsapp:
                  hintText = 'مثال: +9639991234567';
                  break;
                case ContactType.telegram:
                  hintText = 'مثال: username';
                  break;
                case ContactType.email:
                  hintText = 'مثال: example@example.com';
                  break;
                case ContactType.website:
                  hintText = 'مثال: www.example.com';
                  break;
                case ContactType.phone:
                  hintText = 'مثال: +9639991234567';
                  break;
                case ContactType.facebook:
                  hintText = 'مثال: facebook.com/username';
                  break;
                case ContactType.other:
                  hintText = 'أدخل التفاصيل';
                  break;
                default:
                  hintText = 'أدخل القيمة';
              }

              return TextFormField(
                controller: contactValueController,
                decoration: InputDecoration(
                  labelText: 'القيمة',
                  hintText: hintText, // Update hint text based on selected contact type
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              );
            }),
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

}