// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // For Colors in Get.snackbar
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';

import '../models.dart';
import '../routes/app_pages.dart';
import '../utils/storage_keys.dart';

class AuthService extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _box = GetStorage();

  Rxn<User> firebaseUser = Rxn<User>();
  Rxn<UserModel> currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    // Bind firebaseUser stream to Firebase Auth state changes
    firebaseUser.bindStream(_auth.authStateChanges());

    // Listen to firebaseUser changes to load UserModel and handle navigation
    ever(firebaseUser, _handleAuthStateChanges);
  }

  void _handleAuthStateChanges(User? user) async {
    if (user != null) {
      await _loadUserData(user.uid);
      Get.offAllNamed(Routes.MAIN);
    } else {
      currentUser.value = null; // Clear current user model on logout
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        currentUser.value = UserModel.fromFirestore(doc);
      } else {
        // This can happen if a user logs in but their Firestore profile isn't created yet
        // (e.g., brand new Firebase user from external provider, or if profile creation failed).
        // You might want to create a default profile here or guide the user to complete it.
        print("User profile not found in Firestore for UID: $uid. Creating a default.");
        // Example: If a user signs up via email/password but the _createUserProfile failed
        // Or if they logged in via Google/Apple, you might create a basic profile here.
        // For now, setting to null, but consider creating a basic profile.
        currentUser.value = null; // Or create a default UserModel
      }
    } catch (e) {
      print("Error loading user data from Firestore: $e");
      Get.snackbar('Error', 'Failed to load user profile: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      currentUser.value = null;
    }
  }

  // Email/Password Registration
  Future<void> registerWithEmail(String email,
      String password,
      String username,
      String role,) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _createUserProfile(
          userCredential.user!,
          username: username,
          email: email, // Pass email explicitly for non-anonymous
          role: role,
        );
        Get.snackbar('Success', 'Registration successful!', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _mapAuthError(e), backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw _mapAuthError(e);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}', backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // Email/Password Login with Remember Me
  Future<void> loginWithEmail(String email, String password, bool rememberMe) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        if (rememberMe) {
          _box.write(StorageKeys.rememberedEmail, email);
          _box.write(StorageKeys.rememberedPassword, password);
          _box.write(StorageKeys.rememberMe, true);
        } else {
          _box.remove(StorageKeys.rememberedEmail);
          _box.remove(StorageKeys.rememberedPassword);
          _box.remove(StorageKeys.rememberMe);
        }
        Get.snackbar('Success', 'Logged in successfully!', backgroundColor: Colors.green, colorText: Colors.white);
        // _handleAuthStateChanges will take care of navigation and user data load
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _mapAuthError(e), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw _mapAuthError(e);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // Anonymous Login
  Future<void> loginAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      if (userCredential.user != null) {
        await _createUserProfile(userCredential.user!, isAnonymous: true);
        // Clear remember me data if logging in anonymously
        _box.remove(StorageKeys.rememberedEmail);
        _box.remove(StorageKeys.rememberedPassword);
        _box.remove(StorageKeys.rememberMe);
        Get.snackbar('Success', 'Logged in as Guest!', backgroundColor: Colors.green, colorText: Colors.white);
        // _handleAuthStateChanges will take care of navigation and user data load
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _mapAuthError(e), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw _mapAuthError(e);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  Future<void> _createUserProfile(User user, {
    String? username,
    String? email, // Email for non-anonymous users
    String? role,
    bool isAnonymous = false,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': isAnonymous ? null : email, // Use passed email for clarity
        'username': username ?? (isAnonymous ? 'GuestUser-${user.uid.substring(0, 5)}' : user.email?.split('@')[0]), // Default username
        'role': role ?? 'employer',
        'isAnonymous': isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'favorites': [],
        'myJobs': [],
      });
    } else {
      // If user profile exists, ensure it's up-to-date or handle updates
      // For example, if a guest user later registers, you might merge profiles.
      // For now, we'll just print a debug message.
      debugPrint('User profile for ${user.uid} already exists. Not overwriting.');
    }
    // After creating/confirming profile, load it into currentUser observable
    await _loadUserData(user.uid);
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'البريد الإلكتروني مسجل بالفعل.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جدًا (الحد الأدنى 6 أحرف).';
      case 'user-not-found':
        return 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني.';
      case 'wrong-password':
        return 'كلمة مرور خاطئة.';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك.';
      case 'user-disabled':
        return 'تم تعطيل حساب المستخدم هذا.';
      default:
        return e.message ?? 'فشل المصادقة.';
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      // Clear remembered credentials on explicit logout
      _box.remove(StorageKeys.rememberedEmail);
      _box.remove(StorageKeys.rememberedPassword);
      _box.remove(StorageKeys.rememberMe);
      Get.snackbar('Logged Out', 'You have been successfully logged out.', backgroundColor: Colors.orange, colorText: Colors.white);
      // _handleAuthStateChanges will take care of navigation
    } catch (e) {
      Get.snackbar('Error', 'Failed to log out: ${e.toString()}', backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw 'Failed to log out: ${e.toString()}';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Success', 'Password reset email sent!', backgroundColor: Colors.green, colorText: Colors.white);
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', _mapAuthError(e), backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw _mapAuthError(e);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}', backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // --- User Profile Management (for Firestore) ---

  // Update a user's specific fields in Firestore and the reactive UserModel
  Future<void> updateUserProfile({
    String? username,
    List<String>? favorites,
    List<String>? myJobs,
    String? role,
  }) async {
    final user = firebaseUser.value;
    if (user == null) {
      Get.snackbar('Error', 'No user logged in to update profile.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    final Map<String, dynamic> updates = {};
    if (username != null) updates['username'] = username;
    if (favorites != null) updates['favorites'] = favorites;
    if (myJobs != null) updates['myJobs'] = myJobs;
    if (role != null) updates['role'] = role;

    if (updates.isEmpty) {
      debugPrint("No profile updates provided.");
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update(updates);
      await _loadUserData(user.uid); // Reload the user data to update currentUser observable
      Get.snackbar('Success', 'Profile updated successfully!', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw 'Failed to update profile: ${e.toString()}';
    }
  }

  // Toggle favorite job directly on the Firestore user document
  Future<void> toggleFavoriteJob(String jobId) async {
    final user = firebaseUser.value;
    if (user == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول لإدارة المفضلة.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      return;
    }

    // Use FieldValue.arrayUnion and FieldValue.arrayRemove for atomic updates
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final currentFavorites = currentUser.value?.favorites ?? [];

      if (currentFavorites.contains(jobId)) {
        await userDocRef.update({
          'favorites': FieldValue.arrayRemove([jobId]),
        });
        Get.snackbar('تم', 'تمت الإزالة من المفضلة', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 1));
      } else {
        await userDocRef.update({
          'favorites': FieldValue.arrayUnion([jobId]),
        });
        Get.snackbar('تم', 'تمت الإضافة إلى المفضلة', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 1));
      }
      // Reload user data after update to reflect changes in currentUser observable
      await _loadUserData(user.uid);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث المفضلة: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      debugPrint('Error toggling favorite: $e');
    }
  }

  // Method to update user data in Firestore
  Future<void> updateUserInFirestore(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      // After updating in Firestore, refresh the local currentUser Rx variable
      await _loadUserData(userId); // Re-load user data to reflect changes
      Get.snackbar('Success', 'User data updated successfully!', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      debugPrint('Error updating user data in Firestore: $e');
      Get.snackbar('Error', 'Failed to update user data: ${e.toString()}', backgroundColor: Colors.redAccent, colorText: Colors.white);
      throw 'Failed to update user data: ${e.toString()}';
    }
  }
}