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
  late double _localMaxDistanceKm; // Local state for the slider
  late JobSortOrder _localSortOrder;

  static const List<String> _jobTypes = ['الكل', 'دوام كامل', 'دوام جزئي', 'عن بعد', 'مؤقت'];

  @override
  void initState() {
    super.initState();
    _localSelectedCity = _jobController.currentCity.isEmpty ? null : _jobController.currentCity;
    _localSelectedJobType = _jobController.currentJobType.isEmpty ? null : _jobController.currentJobType;
    _localMaxDistanceKm = _jobController.maxDistanceKm.value; // Initialize from controller
    _localSortOrder = _jobController.currentSortOrder.value;

    _jobController.loadJobCities();
  }

  @override
  void dispose() {
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
          Obx(
                () => DropdownButtonFormField<String?>(
              decoration: InputDecoration(
                hintText: 'اختر المدينة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              value: _jobController.availableJobCities.contains(_localSelectedCity)
                  ? _localSelectedCity
                  : (_jobController.currentCity.isEmpty ? null : _jobController.currentCity),
              items: _jobController.availableJobCities.map((city) => DropdownMenuItem<String?>(
                value: city == 'الكل' ? null : city,
                child: Text(city),
              )).toList(),
              onChanged: (v) {
                setState(() {
                  _localSelectedCity = v;
                });
              },
            ),
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

          // --- Distance Slider ---
          Obx(() {
            // This Obx reacts to changes in _jobController.userLat and _jobController.userLng
            if (_jobController.userLat.value != null && _jobController.userLng.value != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              );
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'لم يتم تحديد موقعك. لا يمكن تصفية النتائج حسب المسافة.',
                  style: GoogleFonts.tajawal(fontSize: 12, color: cs.onSurface.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              );
            }
          }),

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
                    // Reset local state to reflect controller's reset
                    setState(() {
                      _localSelectedCity = null;
                      _localSelectedJobType = null;
                      _localMaxDistanceKm = _jobController.maxDistanceKm.value; // Reset to default
                      _localSortOrder = _jobController.currentSortOrder.value;
                    });
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
                    // Update the HomeController's maxDistanceKm with the slider's value
                    _jobController.maxDistanceKm.value = _localMaxDistanceKm;
                    _jobController.updateFilteredJobs(
                      city: _localSelectedCity ?? '',
                      jobType: _localSelectedJobType ?? '',
                      query: _jobController.currentQuery, // Preserve current search query
                      filterByDistance: true, // Always consider distance filter if applicable
                    );
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
    }
  }
}