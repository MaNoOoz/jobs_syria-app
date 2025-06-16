// lib/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quiz_project/utils/storage_keys.dart';

import '../auth/UserModel.dart';
import '../controllers/home_controller.dart';
import '../models.dart'; // JobModel, ContactType, etc.
import 'job_details_screen.dart';

// lib/screens/favorites_screen.dart


class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final HomeController _jobController = Get.find<HomeController>();
  final box = GetStorage();

  UserModel? _currentUser;
  final RxList<JobModel> _favoriteJobs = <JobModel>[].obs; // Make favoriteJobs reactive

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndFavorites();

    // Listen for changes to the currentUser's data in GetStorage
    // This handles cases where favorites might be changed from other parts of the app
    // or if the user data itself is updated.
    box.listenKey(StorageKeys.currentUser, (value) {
      if (value is Map<dynamic, dynamic>) {
        // Only update if the user data is actually a Map
        final updatedUser = UserModel.fromJson(Map<String, dynamic>.from(value));
        // Check if the favorites list has truly changed
        // Compare lengths first for quick exit, then compare contents via Sets
        if (_currentUser?.favorites.length != updatedUser.favorites.length ||
            _currentUser!.favorites.toSet() != updatedUser.favorites.toSet()) { // <-- FIXED LINE HERE
          // Only reload if the favorites list has truly changed
          _currentUser = updatedUser; // Update internal user model
          _loadFavorites(); // Reload the displayed favorites
        }
      } else if (value == null) {
        // User logged out
        _currentUser = null;
        _favoriteJobs.clear();
      }
      // If it's another type, the _loadCurrentUserAndFavorites initial check handles it.
    });
  }

  void _loadCurrentUserAndFavorites() {
    final dynamic userData = box.read(StorageKeys.currentUser);
    if (userData != null && userData is Map<dynamic, dynamic>) {
      _currentUser = UserModel.fromJson(Map<String, dynamic>.from(userData));
      _loadFavorites();
    } else {
      // No user or corrupted user data, handle gracefully
      debugPrint('Error: No current user found or data corrupted in FavoritesScreen. Redirecting...');
      // It's generally better for MainScreen to handle initial redirection,
      // but a fallback here is good for robustness.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/login');
      });
    }
  }


  void _loadFavorites() {
    if (_currentUser == null) {
      _favoriteJobs.clear();
      return;
    }

    final allJobs = _jobController.jobs; // Assuming JobController.jobs is an RxList
    final List<JobModel> currentFavorites = allJobs
        .where((job) => _currentUser!.favorites.contains(job.id))
        .toList();

    _favoriteJobs.assignAll(currentFavorites); // Update the reactive list
  }

  void _removeFromFavorites(JobModel job) {
    if (_currentUser == null) return;

    _currentUser!.favorites.remove(job.id);

    // Save the updated user model back to GetStorage
    box.write(StorageKeys.currentUser, _currentUser!.toJson());

    // Update the local reactive list
    _favoriteJobs.removeWhere((favJob) => favJob.id == job.id);

    Get.snackbar(
      'تم',
      'أُزيلت الوظيفة من المفضلة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(

      body: Obx(() { // Wrap with Obx to react to changes in _favoriteJobs
        if (_favoriteJobs.isEmpty) {
          return Center(
            child: Text(
              'لا توجد وظائف في المفضلة',
              style: GoogleFonts.tajawal(color: cs.onSurfaceVariant),
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
                title: Text(job.title,
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                subtitle: Text('${job.city} • ${job.jobType}',
                    style: GoogleFonts.tajawal(
                        color: cs.onSurfaceVariant)),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: cs.error),
                  onPressed: () => _removeFromFavorites(job),
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