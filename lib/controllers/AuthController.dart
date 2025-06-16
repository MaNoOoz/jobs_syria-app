import 'package:flutter/material.dart'; // Required for Get.snackbar colors
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quiz_project/utils/storage_keys.dart';

import '../models.dart'; // Contains UserModel

class AuthController extends GetxController {
  final box = GetStorage();

  // Reactive variable to hold the current logged-in user
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUserFromStorage();
  }

  // Loads the current user from GetStorage when the controller initializes
  void _loadCurrentUserFromStorage() {
    final userData = box.read(StorageKeys.currentUser);
    if (userData != null) {
      try {
        currentUser.value = UserModel.fromJson(Map<String, dynamic>.from(userData));
      } catch (e) {
        debugPrint("Error loading user from GetStorage: $e");
        logout(); // Clear potentially corrupted data
      }
    }
  }

  // Registers a new user
  Future<void> register(String username, String password, String role) async {
    // 1) Read the existing list of users
    final List<dynamic> existingUsersRaw = box.read<List>(StorageKeys.users) ?? [];
    final List<UserModel> existingUsers = existingUsersRaw
        .map((userMap) => UserModel.fromJson(Map<String, dynamic>.from(userMap)))
        .toList();

    // 2) Check for duplicate username
    if (existingUsers.any((user) => user.username == username)) {
      Get.snackbar(
        'خطأ',
        'اسم المستخدم موجود بالفعل. الرجاء اختيار اسم آخر.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // 3) Create new user model (ID is automatically generated in UserModel constructor)
    final newUser = UserModel(
      username: username,
      password: password,
      role: role,
    );

    // 4) Add the new user to the list
    existingUsers.add(newUser);

    // 5) Save the complete list back to GetStorage
    await box.write(StorageKeys.users, existingUsers.map((u) => u.toJson()).toList());

    // 6) Automatically log in the new user
    await box.write(StorageKeys.currentUser, newUser.toJson());
    currentUser.value = newUser;

    Get.snackbar('نجاح', 'تم التسجيل وتسجيل الدخول بنجاح!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white);

    // Navigate to the main screen after successful registration and login
    Get.offAllNamed('/ui');
  }

  // Logs in an existing user
  Future<void> login(String username, String password) async {
    final List<dynamic> allUsersRaw = box.read<List>(StorageKeys.users) ?? [];
    final List<UserModel> allUsers = allUsersRaw
        .map((userMap) => UserModel.fromJson(Map<String, dynamic>.from(userMap)))
        .toList();

    UserModel? foundUser;
    try {
      foundUser = allUsers.firstWhere(
            (u) => u.username == username && u.password == password,
      );
    } catch (e) {
      // User not found, firstWhere throws if no match and no orElse
      foundUser = null;
    }

    if (foundUser != null) {
      // Save full user data map as current user
      await box.write(StorageKeys.currentUser, foundUser.toJson());
      currentUser.value = foundUser; // Update reactive user

      Get.snackbar('مرحباً', 'تم تسجيل الدخول بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      Get.offAllNamed('/ui'); // Navigate to MainScreen, which is '/ui'
    } else {
      Get.snackbar(
        'خطأ',
        'اسم المستخدم أو كلمة المرور غير صحيحة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // Logs out the current user
  Future<void> logout() async {
    await box.remove(StorageKeys.currentUser);
    currentUser.value = null;
    Get.snackbar('تم تسجيل الخروج', 'إلى اللقاء!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
    // You might want to navigate to the login screen here
    Get.offAllNamed('/login'); // Navigate back to login screen
  }

  // Provides the ID of the currently logged-in user
  String? getCurrentUserId() {
    return currentUser.value?.id;
  }

  // Provides the role of the currently logged-in user
  String? getCurrentUserRole() {
    return currentUser.value?.role;
  }

  // Updates the current user in GetStorage and the reactive variable
  Future<void> updateCurrentUser(UserModel updatedUser) async {
    // 1. Update the user in the global list of all users
    final List<dynamic> allUsersRaw = box.read<List>(StorageKeys.users) ?? [];
    final List<UserModel> allUsers = allUsersRaw
        .map((userMap) => UserModel.fromJson(Map<String, dynamic>.from(userMap)))
        .toList();

    final int index = allUsers.indexWhere((user) => user.id == updatedUser.id);
    if (index != -1) {
      allUsers[index] = updatedUser; // Replace the old user data with updated data
    } else {
      // This case should ideally not happen if you're updating a logged-in user
      debugPrint('Warning: Updated user not found in allUsers list.');
      // If the user isn't found, it implies a logic error or a new user is being passed.
      // For robustness, you might add it, but ideally, this path means `updateCurrentUser`
      // was called with an ID not in your current `allUsers` list.
      // For simplicity, we won't add it here; a new user should go through `register`.
    }
    await box.write(StorageKeys.users, allUsers.map((u) => u.toJson()).toList());

    // 2. Update the currently logged-in user's data in GetStorage
    await box.write(StorageKeys.currentUser, updatedUser.toJson());
    currentUser.value = updatedUser; // Update the reactive observable
  }

  // --- CORRECTED: Toggle Favorite Job for GetStorage ---
  Future<void> toggleFavoriteJob(String jobId) async {
    final user = currentUser.value;
    if (user == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول لإدارة المفضلة.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      return;
    }

    List<String> updatedFavorites = List.from(user.favorites); // Create a mutable copy

    if (updatedFavorites.contains(jobId)) {
      // Remove from favorites
      updatedFavorites.remove(jobId);
      Get.snackbar('تم', 'تمت الإزالة من المفضلة', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 1));
    } else {
      // Add to favorites
      updatedFavorites.add(jobId);
      Get.snackbar('تم', 'تمت الإضافة إلى المفضلة', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 1));
    }

    // Create a new UserModel instance with the updated favorites list
    final updatedUser = user.copyWith(favorites: updatedFavorites);

    try {
      // Use the existing updateCurrentUser method to save changes to GetStorage
      await updateCurrentUser(updatedUser);

      debugPrint('Favorites updated for user ${user.id}: $updatedFavorites');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث المفضلة: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      debugPrint('Error toggling favorite: $e');
    }
  }
}