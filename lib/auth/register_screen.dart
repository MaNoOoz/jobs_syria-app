// lib/register_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quiz_project/services/auth_service.dart'; // Use AuthService

import '../utils/Constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final AuthService _authService = Get.find<AuthService>();

  // State variables to toggle password visibility
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  final RxBool _isLoading = false.obs; // Loading state for normal login

  @override
  void dispose() {
    // Dispose controllers to free up resources
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; // Define cs for color scheme

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل مستخدم جديد'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Image.asset(
              APP_LOGO,
              height: 120,
            ).animate().fadeIn(duration: 500.ms).scale(),

            const SizedBox(height: 30),

            // Email Field
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 15),

            // Username Field
            TextField(
              controller: usernameController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'اسم المستخدم',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 15),

            // --- MODIFIED PASSWORD FIELD ---
            TextField(
              controller: passwordController,
              obscureText: _isPasswordObscured,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            // --- END OF MODIFICATION ---

            const SizedBox(height: 15),

            // --- MODIFIED CONFIRM PASSWORD FIELD ---
            TextField(
              controller: confirmPasswordController,
              obscureText: _isConfirmPasswordObscured,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                    });
                  },
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            // --- END OF MODIFICATION ---

            const SizedBox(height: 30),

            Obx( // Observe _isLoading for normal login button
                  () => ElevatedButton(
                onPressed: _isLoading.value ? null : _registerUser, // Disable when loading
                style: ElevatedButton.styleFrom(
                  // backgroundColor: cs.primary,
                  // foregroundColor: Colors.white,

                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading.value // Show loading indicator
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'تسجيل',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            // Register Button


            const SizedBox(height: 15),

            // Login Link
            TextButton(
              onPressed: () => Get.back(),
              child: RichText(
                text: TextSpan(
                  text: 'لديك حساب بالفعل؟ ',
                  style: TextStyle(color: Colors.grey[600]),
                  children: [
                    TextSpan(
                      text: 'تسجيل الدخول',
                      style: TextStyle(color: cs.primary, fontSize: 16),

                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  void _registerUser() async {
    final email = emailController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validation
    if (email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar(
        'خطأ',
        'الرجاء ملء جميع الحقول',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        'خطأ',
        'الرجاء إدخال بريد إلكتروني صحيح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar(
        'خطأ',
        'كلمات المرور غير متطابقة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (password.length < 6) {
      Get.snackbar(
        'خطأ',
        'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    _isLoading.value = true; // Set loading to true

    try {
      await _authService.registerWithEmail(
        email,
        password,
        username,
        'user',

        // Default role
      );
      // AuthService will handle navigation on success
    } catch (e) {
      debugPrint('Registration error in RegisterScreen: $e');
      // AuthService already shows snackbar for errors
    }
    finally {
      _isLoading.value = false; // Set loading to false regardless of success/failure
    }
  }
}