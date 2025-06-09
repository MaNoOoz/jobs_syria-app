// lib/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_project/controllers/AuthController.dart';



// import '../home/storage_keys.dart'; // No longer directly needed
// import 'UserModel.dart'; // No longer directly needed, AuthController handles models

class LoginScreen extends StatelessWidget {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Inject the AuthController
  final AuthController _authController = Get.find<AuthController>();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // Make button full width
              child: ElevatedButton(
                onPressed: () {
                  final inputUsername = usernameController.text.trim();
                  final inputPassword = passwordController.text.trim();
                  _authController.login(inputUsername, inputPassword); // Call AuthController's login method
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('دخول'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.toNamed('/register'),
              child: const Text('مستخدم جديد؟ سجل الآن'),
            )
          ],
        ),
      ),
    );
  }
}