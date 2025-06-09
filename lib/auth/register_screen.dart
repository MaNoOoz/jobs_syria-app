// lib/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_project/controllers/AuthController.dart';


// import '../core/models.dart'; // No longer directly needed
// import '../home/storage_keys.dart'; // No longer directly needed
// import 'UserModel.dart'; // No longer directly needed

class RegisterScreen extends StatelessWidget {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final role = 'user'.obs; // default role

  // Inject the AuthController
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل مستخدم جديد')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Obx(() => Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text('باحث عن عمل'),
                    value: 'user',
                    groupValue: role.value,
                    onChanged: (val) => role.value = val!,
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text('صاحب عمل'),
                    value: 'employer',
                    groupValue: role.value,
                    onChanged: (val) => role.value = val!,
                  ),
                ),
              ],
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, // Make button full width
              child: ElevatedButton(
                onPressed: () {
                  final username = usernameController.text.trim();
                  final password = passwordController.text.trim();

                  if (username.isEmpty || password.isEmpty) {
                    Get.snackbar('خطأ', 'الرجاء ملء كل الحقول',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white);
                    return;
                  }

                  _authController.register(username, password, role.value); // Call AuthController's register method
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('تسجيل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}