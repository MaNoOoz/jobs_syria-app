// lib/features/home/presentation/widgets/job_filter_sort_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/home_controller.dart';

class JobFilterSortBottomSheet extends StatefulWidget {
  final VoidCallback? onClearSearch;

  const JobFilterSortBottomSheet({super.key, this.onClearSearch});

  @override
  State<JobFilterSortBottomSheet> createState() => _JobFilterSortBottomSheetState();
}

class _JobFilterSortBottomSheetState extends State<JobFilterSortBottomSheet> {
  final HomeController _jobController = Get.find<HomeController>();

  late String? _localSelectedCity;
  late String? _localSelectedJobType;
  // Removed: late double _localMaxDistanceKm; // No longer needed for a slider
  late JobSortOrder _localSortOrder;

  static const List<String> _jobTypes = ['الكل', 'دوام كامل', 'دوام جزئي', 'عن بعد', 'مؤقت'];

  @override
  void initState() {
    super.initState();
    _localSelectedCity = _jobController.currentCity.isEmpty ? null : _jobController.currentCity;
    _localSelectedJobType = _jobController.currentJobType.isEmpty ? null : _jobController.currentJobType;
    // Removed: _localMaxDistanceKm = _jobController.maxDistanceKm.value; // No longer initialize from controller
    _localSortOrder = _jobController.currentSortOrder.value;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تصفية وفرز الوظائف',
            style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // City Filter
          DropdownButtonFormField<String?>(
            value: _localSelectedCity,
            decoration: InputDecoration(
              labelText: 'المدينة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            hint: const Text('اختر مدينة'),
            items: _jobController.availableJobCities.map((city) {
              return DropdownMenuItem(
                value: city == 'الكل' ? null : city, // Null for 'All'
                child: Text(city),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _localSelectedCity = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Job Type Filter
          DropdownButtonFormField<String?>(
            value: _localSelectedJobType,
            decoration: InputDecoration(
              labelText: 'نوع الوظيفة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            hint: const Text('اختر نوع الوظيفة'),
            items: _jobTypes.map((type) {
              return DropdownMenuItem(
                value: type == 'الكل' ? null : type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _localSelectedJobType = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Removed Distance Filter Slider Section
          // No longer needed as per your request

          // Sort Order
          Text(
            'ترتيب حسب',
            style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
          Wrap(
            spacing: 8.0,
            children: JobSortOrder.values.map((order) {
              return ChoiceChip(
                label: Text(_getSortOrderText(order)),
                selected: _localSortOrder == order,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _localSortOrder = order;
                    });
                  }
                },
                selectedColor: cs.primaryContainer,
                backgroundColor: cs.surfaceVariant,
                labelStyle: GoogleFonts.tajawal(color: _localSortOrder == order ? cs.onPrimaryContainer : cs.onSurfaceVariant),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Reset local states to defaults
                    setState(() {
                      _localSelectedCity = null;
                      _localSelectedJobType = null;
                      // Removed: _localMaxDistanceKm = 10.0; // Reset distance as well
                      _localSortOrder = JobSortOrder.newest; // Reset to default sort
                    });
                    _jobController.resetAllFilters(); // Reset controller's filters
                    Get.back();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.outline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('إعادة تعيين', style: GoogleFonts.tajawal(fontSize: 16, color: cs.onSurfaceVariant)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Apply button: Update filters in HomeController
                    _jobController.updateFilteredJobs(
                      city: _localSelectedCity ?? '',
                      jobType: _localSelectedJobType ?? '',
                      query: _jobController.currentQuery, // Preserve current search query
                      // No filterByDistance: true needed here, as we're not explicitly filtering by distance anymore.
                      // The default `false` will ensure the distance FILTER is skipped.
                    );
                    _jobController.changeSortOrder(_localSortOrder); // Apply the chosen sort order
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('تطبيق', style: GoogleFonts.tajawal(fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Padding for safe area
        ],
      ),
    );
  }

  String _getSortOrderText(JobSortOrder order) {
    switch (order) {
      case JobSortOrder.newest:
        return 'الأحدث أولاً';
      case JobSortOrder.oldest:
        return 'الأقدم أولاً';
      case JobSortOrder.distanceAsc:
        return 'الأقرب أولاً';
      case JobSortOrder.titleAsc:
        return 'الاسم (أ-ي)';
      case JobSortOrder.titleDesc:
        return 'الاسم (ي-أ)';
    }
  }
}