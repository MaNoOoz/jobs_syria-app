// lib/screens/favorites_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import '../models.dart';
import '../services/auth_service.dart'; // Import AuthService
import 'job_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final HomeController _jobController = Get.find<HomeController>();
  final AuthService _authService = Get.find<AuthService>(); // Get AuthService instance

  // _currentUser will be directly observed from AuthService
  final RxList<JobModel> _favoriteJobs = <JobModel>[].obs; // Make favoriteJobs reactive

  // Subscription for the auth service's current user stream
  late final StreamSubscription<UserModel?> _userSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize favorites based on the current user state from AuthService
    _loadFavorites();

    // Listen to changes in the current user from AuthService
    // This will react to login/logout, or updates to the user's Firestore profile (e.g., favorites changes)
    _userSubscription = _authService.currentUser.listen((user) {
      // When the user changes (e.g., logged in/out, profile updated), reload favorites
      _loadFavorites();
      if (user == null) {
        // Optional: If user logs out, you might want to navigate away
        // or just ensure the screen shows no favorites.
        // Get.offAllNamed(Routes.LOGIN); // Example, if you want to force navigation
      }
    });
  }

  @override
  void dispose() {
    _userSubscription.cancel(); // Cancel the subscription to prevent memory leaks
    super.dispose();
  }

  void _loadFavorites() {
    final currentUser = _authService.currentUser.value;

    if (currentUser == null || currentUser.favorites.isEmpty) {
      _favoriteJobs.clear(); // Clear favorites if no user or no favorites
      return;
    }

    // Filter all available jobs to find the ones in the current user's favorites list
    final allJobs = _jobController.jobs; // Assuming JobController.jobs is an RxList
    final List<JobModel> currentFavorites = allJobs
        .where((job) => currentUser.favorites.contains(job.id))
        .toList();

    _favoriteJobs.assignAll(currentFavorites); // Update the reactive list
  }

  void _toggleFavorite(JobModel job) async {
    // Call the AuthService method to toggle favorite status
    // AuthService will handle updating Firestore and its own currentUser observable
    await _authService.toggleFavoriteJob(job.id);

    // The _userSubscription listener will automatically call _loadFavorites()
    // which will update _favoriteJobs. The UI will then react to _favoriteJobs changes via Obx.
    Get.snackbar(
      'المفضلة',
      _authService.currentUser.value!.favorites.contains(job.id)
          ? 'تم إضافة الوظيفة إلى المفضلة'
          : 'أُزيلت الوظيفة من المفضلة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.find<AuthService>().currentUser.value!.favorites.contains(job.id)
          ? Colors.green
          : Colors.orange,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(
      //     'وظائفي المفضلة',
      //     style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
      //   ),
      //   centerTitle: true,
      //   backgroundColor: cs.primaryContainer,
      // ),
      body: Obx(() {
        if (_authService.currentUser.value == null) {
          return Center(
            child: Text(
              'الرجاء تسجيل الدخول لعرض الوظائف المفضلة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(color: cs.onSurfaceVariant, fontSize: 16),
            ),
          );
        }
        if (_favoriteJobs.isEmpty) {
          return Center(
            child: Text(
              'لا توجد وظائف في المفضلة حاليًا.',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(color: cs.onSurfaceVariant, fontSize: 16),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _favoriteJobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final job = _favoriteJobs[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  job.title,
                  style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                subtitle: Text(
                  '${job.city} • ${job.jobType}',
                  style: GoogleFonts.tajawal(color: cs.onSurfaceVariant),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.favorite, color: cs.primary), // Show filled heart as it's a favorite
                  onPressed: () => _toggleFavorite(job), // Use toggle for consistent action
                ),
                onTap: () {
                  Get.to(() => JobDetailsScreen(job: job));
                },
              ),
            );
          },
        );
      }),
    );
  }
}