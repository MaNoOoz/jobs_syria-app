// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  // --- Reactive State ---
  final Rxn<User> firebaseUser = Rxn<User>();
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  // --- Getters for easy access in UI ---
  bool get isGuest => currentUser.value?.isAnonymous ?? true;
  bool get isLoggedIn => firebaseUser.value != null;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    // This worker automatically handles auth state changes.
    ever(firebaseUser, _handleAuthStateChanges);
  }

  //==========================================================================
  // --- Auth State Management ---
  //==========================================================================

  /// Central handler for authentication state changes.
  void _handleAuthStateChanges(User? user) async {
    if (user != null) {
      await _loadUserData(user.uid);
      // Don't navigate if already on a main app screen, to avoid jarring UX.
      if (Get.currentRoute != Routes.MAIN) {
        Get.offAllNamed(Routes.MAIN);
      }
    } else {
      currentUser.value = null; // Clear user data on logout.
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  /// Loads or creates a user profile from Firestore.
  Future<void> _loadUserData(String uid) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      if (doc.exists) {
        currentUser.value = UserModel.fromFirestore(doc);
      } else {
        // This case handles users who signed in (e.g., via Google)
        // but for whom a profile doesn't exist yet. We create one.
        await _createUserProfile(firebaseUser.value!);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load user profile: ${e.toString()}');
      currentUser.value = null;
    }
  }

  //==========================================================================
  // --- Authentication Methods (Register, Login, Logout) ---
  //==========================================================================

  Future<void> registerWithEmail(String email, String password, String username, String role) async {
    await _handleAuthRequest(() async {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _createUserProfile(userCredential.user!, username: username, role: role,isAnonymous: false);
    }, successMessage: 'Registration successful!');
  }

  Future<void> loginWithEmail(String email, String password, bool rememberMe) async {
    await _handleAuthRequest(() async {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _handleRememberMe(email, password, rememberMe);
    }, successMessage: 'Logged in successfully!');
  }

  Future<void> loginAnonymously() async {
    await _handleAuthRequest(() async {
      final userCredential = await _auth.signInAnonymously();
      // Ensure profile exists for the anonymous user.
      await _createUserProfile(userCredential.user!, isAnonymous: true);
      _clearRememberMe();
    }, successMessage: 'Logged in as Guest!');
  }

  Future<void> logout() async {
    await _handleAuthRequest(() async {
      await _auth.signOut();
      _clearRememberMe();
    }, successMessage: 'You have been successfully logged out.');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _handleAuthRequest(
          () => _auth.sendPasswordResetEmail(email: email),
      successMessage: 'Password reset email sent!',
    );
  }

  //==========================================================================
  // --- User Profile Management (Firestore) ---
  //==========================================================================

  /// Creates a new user document in Firestore.
  Future<void> _createUserProfile(User user, {String? username, String? role, bool isAnonymous = false}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: isAnonymous ? null : user.email,
        username: username ?? (isAnonymous ? 'GuestUser-${user.uid.substring(0, 5)}' : user.email?.split('@')[0] ?? ''),
        role: role ?? 'employer',
        isAnonymous: isAnonymous,
        createdAt: DateTime.now(), // Use client time, Firestore will convert
        favorites: [],
        myJobs: [],
      );
      await docRef.set(newUser.toMap());
    }
    // After creating/confirming profile, load it into currentUser.
    await _loadUserData(user.uid);
  }

  /// Generic method to update fields in the user's Firestore document.
  Future<void> updateUserInFirestore(Map<String, dynamic> data) async {
    if (!isLoggedIn) return _showErrorSnackbar('No user logged in to update profile.');

    await _handleAuthRequest(() async {
      await _firestore.collection('users').doc(firebaseUser.value!.uid).update(data);
      await _loadUserData(firebaseUser.value!.uid); // Refresh local data.
    }, successMessage: 'Profile updated successfully!');
  }

  /// NEW: Atomically adds a job ID to the user's `myJobs` list.
  Future<void> addJobToUserList(String jobId) async {
    if (!isLoggedIn) return; // Fail silently if not logged in.

    final updateData = {'myJobs': FieldValue.arrayUnion([jobId])};
    await updateUserInFirestore(updateData);
  }

  /// Toggles a job's favorite status using an atomic update.
  Future<void> toggleFavoriteJob(String jobId) async {
    if (!isLoggedIn) return _showErrorSnackbar('Please log in to manage favorites.');

    final isCurrentlyFavorite = currentUser.value?.favorites.contains(jobId) ?? false;
    final updateData = {
      'favorites': isCurrentlyFavorite
          ? FieldValue.arrayRemove([jobId])
          : FieldValue.arrayUnion([jobId])
    };
    final successMessage = isCurrentlyFavorite ? 'Removed from favorites' : 'Added to favorites';

    // Using a silent update without a snackbar for better UX
    try {
      await _firestore.collection('users').doc(firebaseUser.value!.uid).update(updateData);
      await _loadUserData(firebaseUser.value!.uid); // Refresh local data.
      Get.snackbar('Success', successMessage, snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 1));
    } catch (e) {
      _showErrorSnackbar('Failed to update favorites: ${e.toString()}');
    }
  }

  //==========================================================================
  // --- Helpers & Error Handling ---
  //==========================================================================

  /// REFACTORED: Generic wrapper for auth requests to reduce boilerplate.
  Future<void> _handleAuthRequest(Future<void> Function() request, {String? successMessage}) async {
    try {
      await request();
      if (successMessage != null) {
        Get.snackbar('Success', successMessage, backgroundColor: Colors.green, colorText: Colors.white);
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_mapAuthError(e.code));
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Maps Firebase error codes to user-friendly strings.
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'The email address is already in use.';
      case 'invalid-email': return 'The email address is not valid.';
      case 'weak-password': return 'The password is too weak.';
      case 'user-not-found': return 'No user found for that email.';
      case 'wrong-password': return 'Wrong password provided.';
      case 'network-request-failed': return 'Please check your internet connection.';
      case 'user-disabled': return 'This user account has been disabled.';
      default: return 'An authentication error occurred.';
    }
  }

  /// Helper to show a standardized error snackbar.
  void _showErrorSnackbar(String message) {
    Get.snackbar('Error', message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white);
  }

  void _handleRememberMe(String email, String password, bool remember) {
    if (remember) {
      _box.write(StorageKeys.rememberedEmail, email);
      _box.write(StorageKeys.rememberedPassword, password);
      _box.write(StorageKeys.rememberMe, true);
    } else {
      _clearRememberMe();
    }
  }

  void _clearRememberMe() {
    _box.remove(StorageKeys.rememberedEmail);
    _box.remove(StorageKeys.rememberedPassword);
    _box.remove(StorageKeys.rememberMe);
  }
}
