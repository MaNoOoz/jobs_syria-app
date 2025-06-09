// lib/screens/my_ads_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_project/home/add_job_screen.dart';

import '../controllers/AuthController.dart';
import '../controllers/job_controller.dart';
import '../core/models.dart'; // JobModel
import 'job_details_screen.dart'; // To view job details

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  final AuthController authController = Get.find<AuthController>();
  final JobController jobController = Get.find<JobController>();

  @override
  void initState() {
    super.initState();
    // Fetch user's posted jobs when the screen initializes
    // This will trigger the stream in JobController to start listening
    _fetchUserJobs();

    // Listen for changes in the current user to re-fetch jobs
    // This is important if user logs in/out or their role changes
    ever(authController.currentUser, (_) {
      _fetchUserJobs();
    });
  }

  Future<void> _fetchUserJobs() async {
    final currentUserId = authController.currentUser.value?.id;
    if (currentUserId != null) {
      jobController.fetchOwnerJobs(currentUserId);
    } else {
      // Clear the list if no user is logged in
      jobController.ownerJobs.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('إعلاناتي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_business, color: cs.onPrimary),
            tooltip: 'إضافة إعلان جديد',
            onPressed: () {

            },
          ),
        ],
      ),
      body: Obx(() {
        // First, check if there's a logged-in user and if they have the 'job_owner' role
        if (authController.currentUser.value == null || authController.currentUser.value!.role != AppRoles.employer) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'أنت غير مصرح لك بنشر إعلانات أو عرضها. يرجى التواصل مع الدعم إذا كنت تعتقد أن هذا خطأ.',
                style: GoogleFonts.tajawal(color: cs.error, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Show a loading indicator while jobs are being fetched
        if (jobController.isLoadingOwnerJobs.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // If no jobs are found for the owner
        if (jobController.ownerJobs.isEmpty) {
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
                      Get.to(() => const AddJobScreen()); // Go to post new job screen
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

        // Display the list of owner's jobs
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: jobController.ownerJobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, index) {
            final job = jobController.ownerJobs[index];
            return _UserJobListItem(job: job, cs: cs, jobController: jobController);
          },
        );
      }),
    );
  }
}

// Reusable widget for a single job list item
class _UserJobListItem extends StatelessWidget {
  final JobModel job;
  final ColorScheme cs;
  final JobController jobController;

  const _UserJobListItem({required this.job, required this.cs, required this.jobController});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(job.title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${job.location} • ${job.jobType}', // Displaying location and job type
          style: GoogleFonts.tajawal(color: cs.onSurfaceVariant, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          // Navigate to job details screen
          Get.to(() => JobDetailsScreen(job: job));
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // Keep row compact
          children: [
            // Edit button
            IconButton(
              icon: Icon(Icons.edit, color: cs.primary),
              tooltip: 'تعديل الإعلان',
              onPressed: () {
                // Navigate to EditJobScreen, passing the job data
                // Get.to(() => EditJobScreen(job: job));
              },
            ),
            // Delete button with confirmation dialog
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
                        onPressed: () => Get.back(), // Dismiss dialog
                        child: Text('إلغاء', style: GoogleFonts.tajawal(color: cs.onSurfaceVariant)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          jobController.deleteJob(job.id); // Call delete method
                          Get.back(); // Close the dialog
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
