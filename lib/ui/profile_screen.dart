// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_project/controllers/home_controller.dart';

import '../auth/login_screen.dart'; // Ensure this path is correct if you use it
import '../models.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import '../utils/theme_service.dart';
import 'my_ads_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();
    final HomeController jobController = Get.find<HomeController>();
    final ThemeService themeService = Get.find<ThemeService>();
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Obx(() {
        final currentUser = authService.currentUser.value;

        // Show a loading indicator or message if user data is not yet loaded
        if (currentUser == null && authService.firebaseUser.value != null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show guest user message if no user is logged in or user is anonymous
        if (currentUser == null || currentUser.isAnonymous) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: cs.primary),
                  const SizedBox(height: 20),
                  Text(
                    'أنت تستخدم التطبيق كزائر. للاستفادة من جميع الميزات، يرجى تسجيل الدخول أو إنشاء حساب.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Get.offAllNamed(Routes.LOGIN),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('تسجيل الدخول / إنشاء حساب', style: GoogleFonts.tajawal(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        }

        // Display profile for logged-in users
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // User Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(Icons.person, size: 60, color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(height: 15),

                    const SizedBox(height: 5),
                    if (currentUser.email != null)
                      Text(
                        currentUser.email!,
                        style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurfaceVariant),
                      ),
                    const SizedBox(height: 10),
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    //   decoration: BoxDecoration(
                    //     color: cs.secondaryContainer,
                    //     borderRadius: BorderRadius.circular(20),
                    //   ),
                    //   child: Text(
                    //     "${currentUser.}",
                    //     style: GoogleFonts.tajawal(fontSize: 14, color: cs.onSecondaryContainer),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

            // Profile Options
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit, color: cs.primary),
                    title: Text('تعديل الملف الشخصي', style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to an edit profile screen (you might need to create this)
                      Get.snackbar('قريباً', 'ميزة تعديل الملف الشخصي ستتوفر قريباً!',
                          snackPosition: SnackPosition.BOTTOM);
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  if (currentUser.role == AppRoles.employer) // Only show for employers
                    ListTile(
                      leading: Icon(Icons.work, color: cs.primary),
                      title: Text('إعلاناتي', style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        jobController.fetchMyJobs(); // Fetch jobs specific to this owner
                        Get.to(() => const MyAdsScreen());
                      },
                    ),
                  // const Divider(indent: 16, endIndent: 16),
                  // ListTile for Dark Mode - (Moved to SettingsScreen as per previous discussion)
                  // leading: Icon(Icons.dark_mode, color: cs.primary),
                  // title: Text('الوضع الداكن', style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface)),
                  // trailing: Obx(() => Switch(
                  //   value: themeService.isDarkMode.value,
                  //   onChanged: (value) {
                  //     themeService.toggleTheme();
                  //   },
                  //   activeColor: cs.primary,
                  // )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // NEW: Delete Account Button
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: Text('حذف الحساب', style: GoogleFonts.tajawal(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                // backgroundColor: cs.error, // Use error color for deletion
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _showDeleteAccountDialog(context, authService, currentUser);
              },
            ),
            const SizedBox(height: 30), // Spacing below delete button

            // Logout Button (retained)
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text('تسجيل الخروج', style: GoogleFonts.tajawal(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.errorContainer, // A neutral color for logout
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await authService.logout();
              },
            ),
          ],
        );
      }),
    );
  }

  // NEW: Dialog for account deletion confirmation
  void _showDeleteAccountDialog(BuildContext context, AuthService authService, UserModel currentUser) {
    final TextEditingController passwordController = TextEditingController();
    final bool isEmailUser = currentUser.email != null && !currentUser.isAnonymous;
    final ColorScheme cs = Theme.of(context).colorScheme;

    Get.dialog(
      AlertDialog(
        title: Text('تأكيد حذف الحساب', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: cs.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد أنك تريد حذف حسابك؟ ستفقد جميع بياناتك، بما في ذلك إعلانات الوظائف والمفضلة.',
              style: GoogleFonts.tajawal(fontSize: 12, color: cs.onSurface),
            ),
            const SizedBox(height: 5),
            if (isEmailUser)
              Text(
                'الرجاء إدخال كلمة المرور الخاصة بك للمتابعة:',
                style: GoogleFonts.tajawal(fontSize: 12, color: cs.onSurface),
              ),
            if (isEmailUser)
              const SizedBox(height: 10),
            if (isEmailUser)
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.tajawal(),
                ),
              ),
            if (!isEmailUser) // Message for anonymous users
              Text(
                'بصفتك مستخدمًا زائرًا، سيتم حذف حسابك وبياناتك فورًا.',
                style: GoogleFonts.tajawal(fontSize: 14, color: cs.onSurface),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء', style: GoogleFonts.tajawal(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close the dialog immediately
              await authService.deleteAccount(isEmailUser ? passwordController.text : null);
              passwordController.dispose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
            ),
            child: Text('حذف', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }
}