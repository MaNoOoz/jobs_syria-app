// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure you have this
import 'package:quiz_project/controllers/home_controller.dart';

import '../auth/login_screen.dart';
import '../models.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart'; // Changed from AuthController
import '../utils/theme_service.dart';
import 'my_ads_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Changed from AuthController to AuthService
    final AuthService authService = Get.find<AuthService>();
    final HomeController jobController = Get.find<HomeController>();
    final ThemeService themeService = Get.find<ThemeService>();
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      // appBar: AppBar(
      //   title: Text('الملف الشخصي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
      //   backgroundColor: cs.primaryContainer, // Using primaryContainer for consistency
      //   foregroundColor: cs.onPrimaryContainer, // Using onPrimaryContainer for consistency
      //   centerTitle: true,
      // ),
      body: Obx(() {
        final currentUser = authService.currentUser.value;

        if (currentUser == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('لا يوجد مستخدم مسجل الدخول.', style: GoogleFonts.tajawal(color: cs.onSurfaceVariant, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.offAndToNamed(Routes.LOGIN); // Navigate to login screen
                    },
                    icon: const Icon(Icons.login),
                    label: Text('تسجيل الدخول', style: GoogleFonts.tajawal(fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // User Info Section
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('معلومات الحساب', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary)),
                    const Divider(height: 20, thickness: 1),
                    Row(
                      children: [
                        Icon(Icons.person, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text("الإسم : ", style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface)),
                        // Display username or email if username is null
                        Text(currentUser.username ?? currentUser.email ?? 'لا يوجد اسم', style: GoogleFonts.tajawal(fontSize: 22, color: cs.onSurface, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row(
                    // children: [
                    // Icon(Icons.badge, color: cs.onSurfaceVariant), // Changed icon to badge for role
                    // const SizedBox(width: 8),
                    // Text("نوع الحساب : ", style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface)),
                    // Text(currentUser.role, style: GoogleFonts.tajawal(fontSize: 22, color: cs.onSurface, fontWeight: FontWeight.bold)),
                    // ],
                    // ),
                    const SizedBox(height: 8),
                    if (currentUser.email != null) // Display email if available
                      Row(
                        children: [
                          Icon(Icons.email, color: cs.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text("البريد الإلكتروني : ", style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface)),
                          Expanded(
                            // Use Expanded to prevent overflow for long emails
                            child: Text(
                              currentUser.email!,
                              style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface),
                              overflow: TextOverflow.ellipsis, // Add ellipsis for long emails
                            ),
                          ),
                        ],
                      ),
                    // Add more user details here if available in UserModel
                  ],
                ),
              ),
            ),

            // App Features Section
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.favorite, color: cs.secondary),
                    title: Text('الوظائف المفضلة', style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
                    onTap: () {
                      Get.toNamed(Routes.FAVORITES);
                    },
                  ),
                  const Divider(height: 0, thickness: 1, indent: 16, endIndent: 16),
                  // Only show 'My Ads' if the user is an employer
                  if (currentUser.role == AppRoles.employer)
                    ListTile(
                      leading: Icon(Icons.my_library_books_outlined, color: cs.secondary),
                      title: Text('إعلاناتي', style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
                      onTap: () {
                        Get.to(() => const MyAdsScreen());
                      },
                    ),
                  const Divider(height: 0, thickness: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.work, color: cs.tertiary),
                    title: Text('طلبات التقديم (قريباً)', style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
                    onTap: () {
                      Get.snackbar('قريباً', 'هذه الميزة قيد التطوير!', snackPosition: SnackPosition.BOTTOM, backgroundColor: cs.primaryContainer, colorText: cs.onPrimaryContainer);
                    },
                  ),
                ],
              ),
            ),

            // Settings Section (can add theme toggle here)
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  // ListTile(
                  //   leading: Icon(Icons.brightness_6, color: cs.secondary),
                  //   title: Text('الوضع الليلي', style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface)),
                  //   trailing: Obx(() => Switch(
                  //     value: themeService.isDarkMode.value,
                  //     onChanged: (value) {
                  //       themeService.toggleTheme();
                  //     },
                  //     activeColor: cs.primary,
                  //   )),
                  // ),
                  // Add more settings here
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text('تسجيل الخروج', style: GoogleFonts.tajawal(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.error, // Use error color for logout
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await authService.logout(); // Call logout on AuthService
                  Get.offAndToNamed(Routes.LOGIN); // Navigate to login screen after logout)); // Navigate to login screen after logout
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
