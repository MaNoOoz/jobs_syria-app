// lib/login_screen.dart
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quiz_project/services/auth_service.dart'; // Keep this
import 'package:quiz_project/utils/Constants.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quiz_project/utils/storage_keys.dart';

import '../routes/app_pages.dart';
import '../utils/SharedWidgets.dart'; // Make sure this is imported

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = Get.find<AuthService>(); // Get AuthService

  final RxBool rememberMe = false.obs;
  // State variable to toggle password visibility
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreferences();
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _loadRememberMePreferences() {
    final box = GetStorage();
    final savedEmail = box.read(StorageKeys.rememberedEmail);
    final savedPassword = box.read(StorageKeys.rememberedPassword);
    final savedRememberMe = box.read(StorageKeys.rememberMe) ?? false;

    if (savedRememberMe && savedEmail != null && savedPassword != null) {
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      rememberMe.value = true;
    } else {
      rememberMe.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SharedWidgets().buildLogo(),

            // Image.asset(
            //   APP_LOGO,
            //   height: 150,
            // )
            //     .animate()
            //     .fadeIn(duration: 500.ms)
            //     .scale(),

            const SizedBox(height: 30),


            FadeInDown(
              child: TextField(
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
              )
            ),

            const SizedBox(height: 15),

            // --- MODIFIED PASSWORD TEXTFIELD ---
            FadeInUp(
              child: TextField(
                controller: passwordController,
                // Use the state variable to control obscurity
                obscureText: _isPasswordObscured,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  // Add the visibility toggle icon button
                  suffixIcon: IconButton(
                    icon: Icon(
                      // Change icon based on the state
                      _isPasswordObscured ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      // Update the state to toggle visibility
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                  ),
                ),
              ),
            ),
            // --- END OF MODIFICATION ---

            Obx(
                  () => CheckboxListTile(
                title: const Text('تذكرني'),
                controlAffinity: ListTileControlAffinity.leading,
                value: rememberMe.value,
                onChanged: (bool? newValue) {
                  rememberMe.value = newValue!;
                },
              ),
            ).animate().fadeIn(delay: 1325.ms),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text(
                  'نسيت كلمة المرور؟',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ).animate().fadeIn(delay: 1350.ms),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loginWithEmail, // This calls AuthService
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Theme.of(context).primaryColor,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'دخول',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 1400.ms)
                .then()
                .shake(),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loginAnonymously, // This calls AuthService
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'تصفح كضيف',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ).animate().fadeIn(delay: 1500.ms).shake(),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Get.toNamed(Routes.REGISTER),
                  child: const Text(
                    'ليس لديك حساب؟ سجل الآن',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  void _loginWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'خطأ',
        'الرجاء إدخال البريد الإلكتروني وكلمة المرور',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      await _authService.loginWithEmail(email, password, rememberMe.value);
      // AuthService will handle navigation on success
    } catch (e) {
      // AuthService already shows a snackbar for errors, so this might be redundant
      // unless you need more specific UI handling here.
      debugPrint('Login error in LoginScreen: $e');
    }
  }

  void _loginAnonymously() async {
    try {
      await _authService.loginAnonymously();
      // AuthService will handle navigation on success
    } catch (e) {
      debugPrint('Anonymous login error in LoginScreen: $e');
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('استعادة كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل بريدك الإلكتروني لإرسال رابط الاستعادة'),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
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
               _sendPasswordResetEmail(emailController.text.trim());


            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _sendPasswordResetEmail(String email) async {
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'خطأ',
        'الرجاء إدخال بريد إلكتروني صحيح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email);
      Get.back(); // Close dialog
      Get.snackbar(
        'تمام',
        'تم إرسال الطلب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green, // Changed to green for success
        colorText: Colors.white,
      );

    } catch (e) {
      debugPrint('Password reset error in LoginScreen: $e');
    }
  }
}