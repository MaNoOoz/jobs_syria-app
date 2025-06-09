// lib/features/home/presentation/widgets/job_filter_sort_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/job_controller.dart';

class JobFilterSortBottomSheet extends StatefulWidget {
  final VoidCallback? onClearSearch;

  const JobFilterSortBottomSheet({super.key, this.onClearSearch});

  @override
  State<JobFilterSortBottomSheet> createState() => _JobFilterSortBottomSheetState();
}

class _JobFilterSortBottomSheetState extends State<JobFilterSortBottomSheet> {
  final JobController _jobController = Get.find<JobController>();

  late String? _localSelectedCity;
  late String? _localSelectedJobType;
  late double _localMaxDistanceKm;
  late JobSortOrder _localSortOrder;

  // <--- CHANGED: To store the single selected hashtag for the UI

  static const List<String> _cities = ['الكل', 'دمشق', 'حلب', 'حمص', 'اللاذقية', 'طرطوس'];
  static const List<String> _jobTypes = ['الكل', 'دوام كامل', 'دوام جزئي', 'عن بعد', 'مؤقت'];

  @override
  void initState() {
    super.initState();
    _localSelectedCity = _jobController.currentCity.isEmpty ? null : _jobController.currentCity;
    _localSelectedJobType = _jobController.currentJobType.isEmpty ? null : _jobController.currentJobType;
    _localMaxDistanceKm = _jobController.maxDistanceKm.value;
    _localSortOrder = _jobController.currentSortOrder.value;

    // <--- CHANGED: Initialize local selected hashtag from controller's current filter
  }

  @override
  void dispose() {
    // No specific controllers to dispose for chips here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16.0, right: 16.0, top: 16.0),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          Center(child: Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('تصفية وفرز الوظائف', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 20),

          // --- City Dropdown ---
          Text('المدينة', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            decoration: InputDecoration(
              hintText: 'اختر المدينة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _localSelectedCity,
            items: _cities.map((city) => DropdownMenuItem<String?>(value: city == 'الكل' ? null : city, child: Text(city))).toList(),
            onChanged: (v) {
              setState(() {
                _localSelectedCity = v;
              });
            },
          ),
          const SizedBox(height: 16),

          // --- Job Type Dropdown ---
          Text('نوع الوظيفة', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            decoration: InputDecoration(
              hintText: 'اختر نوع الوظيفة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _localSelectedJobType,
            items: _jobTypes.map((type) => DropdownMenuItem<String?>(value: type == 'الكل' ? null : type, child: Text(type))).toList(),
            onChanged: (v) {
              setState(() {
                _localSelectedJobType = v;
              });
            },
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 8),

          const SizedBox(height: 16),

          // --- Distance Slider ---
          Text('المسافة القصوى: ${_localMaxDistanceKm.toStringAsFixed(0)} كم', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
          Slider(
            min: 1,
            max: 50,
            divisions: 49,
            value: _localMaxDistanceKm,
            label: '${_localMaxDistanceKm.toStringAsFixed(0)} كم',
            onChanged: (v) {
              setState(() {
                _localMaxDistanceKm = v;
              });
            },
          ),
          const SizedBox(height: 16),

          // --- Sort Order Radio Buttons ---
          Text('ترتيب حسب', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
          Column(
            children:
                JobSortOrder.values.map((order) {
                  return RadioListTile<JobSortOrder>(
                    title: Text(_getSortOrderText(order), style: GoogleFonts.tajawal(fontSize: 14)),
                    value: order,
                    groupValue: _localSortOrder,
                    onChanged: (JobSortOrder? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _localSortOrder = newValue;
                        });
                      }
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),

          // --- Action Buttons (Apply & Reset) ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _jobController.resetAllFilters();
                    widget.onClearSearch?.call();

                    Get.back();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: cs.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('إعادة تعيين الكل', style: GoogleFonts.tajawal(fontSize: 16, color: cs.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _jobController.updateFilteredJobs(city: _localSelectedCity ?? '', jobType: _localSelectedJobType ?? '', query: _jobController.currentQuery, filterByDistance: true);
                    _jobController.changeSortOrder(_localSortOrder);
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
          const SizedBox(height: 16),
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
      default:
        return '';
    }
  }
}
