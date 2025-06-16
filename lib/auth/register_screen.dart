// lib/register_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quiz_project/services/auth_service.dart'; // Use AuthService

import '../utils/Constants.dart';

class RegisterScreen extends StatelessWidget {
  final emailController = TextEditingController(); // New field for email
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final AuthService _authService = Get.find<AuthService>(); // Get AuthService

  RegisterScreen({super.key}); // Add constructor for StatelessWidget

  @override
  Widget build(BuildContext context) {
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
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(),

            const SizedBox(height: 30),

            // Email Field (New)
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
            ).animate().fadeIn(delay: 150.ms), // Adjust delay

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

            // Password Field
            TextField(
              controller: passwordController,
              obscureText: true,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 15),

            // Confirm Password Field
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 30),

            // Register Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _registerUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text(
                  'تسجيل',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms)
                .then()
                .shake(),

            const SizedBox(height: 15),

            // Login Link
            TextButton(
              onPressed: () => Get.back(),
              child: RichText(
                text: TextSpan(
                  text: 'لديك حساب بالفعل؟ ',
                  style: TextStyle(color: Colors.grey[600]),
                  children: const [
                    TextSpan(
                      text: 'تسجيل الدخول',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
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
    final email = emailController.text.trim(); // New
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validation
    if (email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) { // Added email check
      Get.snackbar(
        'خطأ',
        'الرجاء ملء جميع الحقول',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (!GetUtils.isEmail(email)) { // Validate email format
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

    try {
      await _authService.registerWithEmail(
        email,
        password,
        username,
        'user', // Default role
      );
      // AuthService will handle navigation on success
    } catch (e) {
      debugPrint('Registration error in RegisterScreen: $e');
      // AuthService already shows snackbar for errors
    }
  }
}