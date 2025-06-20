// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For icons

import '../controllers/home_controller.dart';
import '../models.dart'; // For UserModel and AppRoles (and its extension)
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import '../utils/theme_service.dart';
import 'my_ads_screen.dart'; // For navigation to MyAdsScreen

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
        final bool isLoggedIn = authService.isLoggedIn;

        // Debug print to check the currentUser object
        debugPrint('ProfileScreen - Current User (Observed): ${currentUser?.username}, Email: ${currentUser?.email}, Role: ${currentUser?.role}');

        // Handle case where user is not logged in
        if (!isLoggedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 80, color: cs.primary),
                const SizedBox(height: 20),
                Text(
                  'الرجاء تسجيل الدخول لعرض ملفك الشخصي',
                  style: GoogleFonts.tajawal(fontSize: 18, color: cs.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => Get.offAllNamed(Routes.LOGIN), // Go to login screen
                  icon: const Icon(Icons.login),
                  label: Text('تسجيل الدخول', style: GoogleFonts.tajawal(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => authService.loginAnonymously(), // Allow anonymous login
                  child: Text(
                    'المتابعة كزائر',
                    style: GoogleFonts.tajawal(fontSize: 16, color: cs.primary),
                  ),
                ),
              ],
            ),
          );
        }

        // If logged in, display profile content
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Profile Card
              Container(
                width: double.infinity,
                child: Card(
                  // color: cs.surfaceContainerHigh,
                  elevation: 1,

                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: cs.secondaryContainer,
                          child: Icon(Icons.person, size: 60, color: cs.onSecondaryContainer),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentUser?.username ?? 'مستخدم', // Displays 'مستخدم' if username is null
                          style: GoogleFonts.tajawal(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        if (currentUser?.email != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            currentUser!.email!, // Displays email if not null
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Displaying the user's role
                        // Container(
                        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        //   decoration: BoxDecoration(
                        //     color: cs.primaryContainer,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   child: Text(
                        //     // Use the displayName from the AppRoleExtension
                        //     currentUser!.role,
                        //     style: GoogleFonts.tajawal(
                        //       fontSize: 14,
                        //       fontWeight: FontWeight.bold,
                        //       color: cs.onPrimaryContainer,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),


              // My Ads (if employer)
              if ( authService.firebaseUser.value?.isAnonymous == false) ...[
                ListTile(
                  leading: Icon(FontAwesomeIcons.briefcase, color: cs.primary),
                  title: Text(
                    'إعلاناتي',
                    style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
                  onTap: () {
                    Get.to(() => const MyAdsScreen());
                  },
                  tileColor: cs.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                const SizedBox(height: 12),
              ],

              // Favorite Ads
              // ListTile(
              //   leading: Icon(Icons.favorite, color: cs.error),
              //   title: Text(
              //     'المفضلة',
              //     style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurface),
              //   ),
              //   trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
              //   onTap: () {
              //     Get.toNamed(Routes.FAVORITES);
              //   },
              //   tileColor: cs.surfaceContainerLowest,
              //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              //   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              // ),
              const SizedBox(height: 12),


              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text('تسجيل الخروج', style: GoogleFonts.tajawal(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: cs.error,
                    // foregroundColor: cs.onError,
                    padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await authService.logout();
                    Get.offAllNamed(Routes.LOGIN);
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}