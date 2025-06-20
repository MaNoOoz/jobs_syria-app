// lib/login_screen.dart
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quiz_project/services/auth_service.dart';
import 'package:quiz_project/utils/Constants.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quiz_project/utils/storage_keys.dart';

import '../routes/app_pages.dart';
import '../utils/SharedWidgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = Get.find<AuthService>();

  final RxBool rememberMe = false.obs;
  bool _isPasswordObscured = true;

  final RxBool _isLoading = false.obs; // Loading state for normal login
  final RxBool _isGuestLoading = false.obs; // NEW: Loading state for guest login button

  @override
  void initState() {
    super.initState();
    _loadRememberMePreferences();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _loadRememberMePreferences() {
    final box = GetStorage();
    if (box.read(StorageKeys.rememberMe) == true) {
      emailController.text = box.read(StorageKeys.rememberedEmail) ?? '';
      passwordController.text = box.read(StorageKeys.rememberedPassword) ?? '';
      rememberMe.value = true;
    }
  }

  void _login() async {
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

    _isLoading.value = true; // Set loading to true
    try {
      await _authService.loginWithEmail(email, password, rememberMe.value);
    } finally {
      _isLoading.value = false; // Set loading to false regardless of success/failure
    }
  }

  // NEW: Method to handle anonymous login with loading state
  void _loginAnonymouslyAction() async {
    _isGuestLoading.value = true; // Set loading to true for guest login
    try {
      await _authService.loginAnonymously();
    } finally {
      _isGuestLoading.value = false; // Set loading to false regardless of success/failure
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    Get.defaultDialog(
      title: 'إعادة تعيين كلمة المرور',
      content: Column(
        children: [
          Text(
            'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Get.theme.colorScheme.onSurfaceVariant),
          ),
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
        'تم إرسال طلب إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل إرسال طلب إعادة تعيين كلمة المرور: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; // Define cs for color scheme

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              duration: 800.ms,
              child: Image.asset(
                'assets/icon/icon.png', // Replace with your actual logo path
                height: 150,
              ),
            ),
            const SizedBox(height: 50),
            FadeInLeft(
              duration: 800.ms,
              child: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInRight(
              duration: 800.ms,
              child: TextField(
                controller: passwordController,
                obscureText: _isPasswordObscured,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                      () => Row(
                    children: [
                      Checkbox(
                        value: rememberMe.value,
                        onChanged: (bool? value) {
                          rememberMe.value = value ?? false;
                        },
                      ),
                      Text('تذكرني', style: TextStyle(color: cs.onSurface)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(color: cs.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Obx( // Observe _isLoading for normal login button
                  () => ElevatedButton(
                onPressed: _isLoading.value ? null : _login, // Disable when loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.theme.primaryColor,
                  foregroundColor: Colors.white,
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
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Get.toNamed(Routes.REGISTER);
              },
              child: Text(
                'ليس لديك حساب؟ تسجيل الآن',
                style: TextStyle(color: cs.primary, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            // NEW: Updated "Guest Login" button with loading state
            Obx(
                  () => ElevatedButton.icon(
                onPressed: _isGuestLoading.value ? null : _loginAnonymouslyAction, // Disable when guest loading
                icon: _isGuestLoading.value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.person),
                label: Text(
                  _isGuestLoading.value ? 'جاري الدخول...' : 'الدخول كزائر',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.secondaryContainer,
                  foregroundColor: cs.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}