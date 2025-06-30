// lib/screens/my_ads_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import '../controllers/home_controller.dart';
import 'add_job_screen.dart';
import 'edit_job_screen.dart';
import 'job_details_screen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  final AuthService authService = Get.find<AuthService>();
  final HomeController homeCtrl = Get.find<HomeController>();

  late final StreamSubscription<UserModel?> _userSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserJobs();

    _userSubscription = authService.currentUser.listen((_) {
      _fetchUserJobs();
    });
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchUserJobs() async {
    homeCtrl.fetchMyJobs();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme
        .of(context)
        .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('إعلاناتي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_business, color: cs.onPrimaryContainer),
            tooltip: 'إضافة إعلان جديد',
            onPressed: () {
              if (authService.firebaseUser.value?.isAnonymous ?? true) {
                Get.snackbar(
                  'غير مسموح',
                  'يجب تسجيل الدخول بحساب بريد إلكتروني لإضافة إعلانات',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              } else {
                Get.toNamed(Routes.ADD_NEW);
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        // Check if user is anonymous (not logged in with email)
        if (authService.firebaseUser.value?.isAnonymous ?? true) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 80, color: cs.error),
                  const SizedBox(height: 16),
                  Text(
                    'يجب تسجيل الدخول بحساب بريد إلكتروني لعرض الإعلانات',
                    style: GoogleFonts.tajawal(color: cs.error, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to login screen
                      Get.offAllNamed(Routes.LOGIN);
                    },
                    child: Text('تسجيل الدخول', style: GoogleFonts.tajawal(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // For logged-in email users
        if (homeCtrl.isLoadingOwnerJobs.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (homeCtrl.ownerJobs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 80, color: cs.onSurfaceVariant.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('لم تقم بنشر أي إعلانات بعد.', style: GoogleFonts.tajawal(color: cs.onSurfaceVariant, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => const AddJobScreen());
                    },
                    icon: const Icon(Icons.add),
                    label: Text('انشر إعلانك الأول', style: GoogleFonts.tajawal(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: homeCtrl.ownerJobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, index) {
            final job = homeCtrl.ownerJobs[index];
            return _UserJobListItem(job: job, cs: cs, jobController: homeCtrl);
          },
        );
      }),
    );
  }
  }
class _UserJobListItem extends StatelessWidget {
  final JobModel job;
  final ColorScheme cs;
  final HomeController jobController;

  const _UserJobListItem({required this.job, required this.cs, required this.jobController});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // Slightly increased elevation for better visual separation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          job.title,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: cs.onSurface), // Slightly bolder title
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: RichText(
          text: TextSpan(
            style: GoogleFonts.tajawal(color: cs.onSurfaceVariant, fontSize: 13),
            children: [
              TextSpan(text: job.location),
              const TextSpan(text: ' \u2022 '), // Bullet separator
              TextSpan(text: job.jobType),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Get.to(() => JobDetailsScreen(job: job));
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: cs.primary),
              tooltip: 'تعديل الإعلان',
              onPressed: () {
                Get.to(() => EditJobScreen(job: job));
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: cs.error),
              tooltip: 'حذف الإعلان',
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: Text('تأكيد الحذف', style: GoogleFonts.tajawal()),
                    content: Text('هل أنت متأكد أنك تريد حذف هذا الإعلان؟', style: GoogleFonts.tajawal()),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('إلغاء', style: GoogleFonts.tajawal(color: cs.onSurfaceVariant)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          jobController.deleteJob(job.id);
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: cs.error),
                        child: Text('حذف', style: GoogleFonts.tajawal(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}