import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_project/ui/widgets/job_filter_sort_bottom_sheet.dart';

import '../controllers/home_controller.dart';
import '../models.dart'; // Assuming JobModel is here
import '../services/auth_service.dart';
import 'job_details_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _controller = Get.put(HomeController());

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCity; // null means all
  String? _selectedJobType; // null means all


  void _showFilterSortSheet() {
    Get.bottomSheet(
      const JobFilterSortBottomSheet(),
      isScrollControlled: true, // Allows sheet to take full height if needed
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller.fetchJobs();

    // _searchController.addListener(() {
    //   if (_searchQuery != _searchController.text) {
    //     setState(() {
    //       _searchQuery = _searchController.text;
    //       _applyFilters();
    //     });
    //   }
    // });
    _searchController.addListener(_onSearchChanged);

    ever(_controller.currentQuery.obs, (String query) {
      // Wrap currentQuery in .obs for `ever` to work
      if (_searchController.text != query) {
        _searchController.text = query;
        _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
      }
    });
  }

  void _onSearchChanged() {
    // Only update if the query actually changed to avoid unnecessary calls
    // The query is now updated directly in the controller, so we just call updateFilteredJobs
    _controller.updateFilteredJobs(query: _searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);

    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters({bool byDistance = false}) {
    _controller.updateFilteredJobs(city: _selectedCity ?? '', jobType: _selectedJobType ?? '', query: _searchQuery, filterByDistance: byDistance);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final jobController = Get.find<HomeController>();

    return Scaffold(
      // REMOVED: FloatingActionButton.extended from HomePage
      // It's now solely managed in MainScreen based on user role.
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => Get.to(() => const AddJobScreen()),
      //   icon: const Icon(Icons.add_rounded),
      //   label: const Text('إضافة وظيفة'),
      // ),
      // appBar: AppBar(title: const Text('قائمة الوظائف'), backgroundColor: cs.primary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // البحث
            TextField(
              controller: _searchController,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'ابحث عن وظيفة...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            ),
            const SizedBox(height: 12),

            // Filter & Sort Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align to end
              children: [
                Expanded(
                  child: Text(
                    'النتائج (${_controller.filteredJobs.length})', // Show current job count
                    style: GoogleFonts.tajawal(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ),

                SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Reset all filters and sort order
                      jobController.currentCity = '';
                      jobController.currentJobType = '';
                      jobController.maxDistanceKm.value = 10.0; // Reset to default
                      jobController.resetAllFilters();

                      jobController.changeSortOrder(JobSortOrder.newest); // Reset sort
                      jobController.updateFilteredJobs(); // Apply reset
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      side: BorderSide(color: cs.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    label: Text('الكل', style: GoogleFonts.tajawal(fontSize: 12, color: cs.primary)),
                    icon: Icon(Icons.all_inclusive),

                  ),
                ),

                SizedBox(width: 8),

                ElevatedButton.icon(
                  onPressed: _showFilterSortSheet,
                  icon: const Icon(Icons.filter_list),
                  label: Text('تصفية وفرز', style: GoogleFonts.tajawal(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // قائمة الوظائف
            Expanded(
              child: Obx(() {
                final list = _controller.filteredJobs;
                if (list.isEmpty) {
                  return const Center(child: Text('لا توجد وظائف'));
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => JobListItem(job: list[i], cs: cs, jc: Get.find<AuthService>()),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// job_list_item.dart (No change, just for context)
// lib/screens/job_list_item.dart (or wherever your JobListItem is defined)

// lib/ui/widgets/job_list_item.dart (or wherever your JobListItem is defined)


class JobListItem extends StatelessWidget {
  final JobModel job;

  // We'll pass the ColorScheme and AuthService from HomePage for clarity
  final ColorScheme cs;
  final AuthService jc; // Changed from AuthController to AuthService

  const JobListItem({
    super.key,
    required this.job,
    required this.cs, // Pass ColorScheme
    required this.jc, // Pass AuthService
  });

  // Helper function for random color, keep it as is
  Color _colorFromTitle(String title) {
    final hash = title.codeUnits.fold(0, (p, e) => p + e);
    final colors = [Colors.red.shade200, Colors.green.shade200, Colors.blue.shade200, Colors.orange.shade200, Colors.purple.shade200];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // No need for Get.find<AuthService>() here as it's passed as an argument (jc)
    // If you prefer to Get.find inside, you would do:
    // final AuthService authService = Get.find<AuthService>();

    final itemColor = _colorFromTitle(job.title);

    return Card(
      margin: EdgeInsets.zero, // Remove default margin if ListView.separated handles it
      elevation: 2, // A bit more elevation for a card feel
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => Get.to(() => JobDetailsScreen(job: job)),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              // Leading icon/avatar
              CircleAvatar(backgroundColor: itemColor, radius: 24, child: Text(job.title.substring(0, 1).toUpperCase(), style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              // Job details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${job.city} • ${job.jobType}', style: GoogleFonts.tajawal(fontSize: 13, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    // Display distance if available
                    if (job.distanceInKm != null && job.jobType != 'عن بعد')
                      Text('تبعد: ${job.distanceInKm!.toStringAsFixed(1)} كم', style: GoogleFonts.tajawal(fontSize: 12, color: cs.onSurfaceVariant.withOpacity(0.7)))
                    else if (job.jobType == 'عن بعد')
                      Text('عن بعد', style: GoogleFonts.tajawal(fontSize: 12, color: cs.onSurfaceVariant.withOpacity(0.7))),
                  ],
                ),
              ),
              // Trailing Favorite Icon
              Obx(() {
                // Check if current user is logged in and if this job is in their favorites
                // Ensure jc.currentUser.value is not null before accessing favoriteJobIds
                final isFavorite = jc.currentUser.value?.favorites.contains(job.id) ?? false;
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? cs.error : cs.onSurfaceVariant, // Use theme colors
                    size: 26,
                  ),
                  // This now correctly calls toggleFavoriteJob on the AuthService instance
                  onPressed: () {
                    jc.toggleFavoriteJob(job.id);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}