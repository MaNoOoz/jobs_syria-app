// lib/screens/edit_job_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models.dart'; // Ensure JobModel is here
import 'add_job_form_controller.dart'; // Import the updated controller

class EditJobScreen extends StatelessWidget {
  final JobModel job; // The job to be edited, passed to this screen

  const EditJobScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: Initialize the controller with the job data
    // Get.put ensures the controller is created/found and its onInit is called
    final AddJobFormController controller = Get.put(AddJobFormController(initialJob: job));

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل الإعلان', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: ListView(
            children: [
              // --- Reused Form Fields from AddJobScreen ---
              // Job Title
              TextFormField(
                controller: controller.titleController,
                decoration: InputDecoration(labelText: 'عنوان الوظيفة', border: OutlineInputBorder()),
                validator: controller.validateRequired,
                style: GoogleFonts.tajawal(),
              ),
              const SizedBox(height: 12),

              // Job Description
              TextFormField(
                controller: controller.descController,
                decoration: InputDecoration(labelText: 'وصف الوظيفة', border: OutlineInputBorder()),
                maxLines: 3,
                validator: controller.validateRequired,
                style: GoogleFonts.tajawal(),
              ),
              const SizedBox(height: 12),

              // Job Type Dropdown
              Obx(
                    () => DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'نوع الوظيفة', border: OutlineInputBorder()),
                  value: controller.selectedJobType.value.isEmpty ? null : controller.selectedJobType.value,
                  items: controller.jobTypes.map((type) => DropdownMenuItem(value: type, child: Text(type, style: GoogleFonts.tajawal()))).toList(),
                  onChanged: controller.onJobTypeChanged,
                  validator: controller.validateRequired,
                  style: GoogleFonts.tajawal(color: cs.onSurface),
                ),
              ),
              const SizedBox(height: 12),

              // Conditional Location Fields (City + Map Picker)
              Obx(() {
                final isRemote = controller.selectedJobType.value == 'عن بعد';
                return Column(
                  children: [
                    // City
                    TextFormField(
                      controller: controller.cityController,
                      decoration: InputDecoration(
                        labelText: 'المدينة',
                        border: OutlineInputBorder(),
                        enabled: !isRemote,
                        fillColor: isRemote ? cs.surfaceContainerHigh : null, // Use theme colors
                        filled: isRemote,
                      ),
                      validator: isRemote ? null : controller.validateRequired,
                      style: GoogleFonts.tajawal(),
                    ),
                    const SizedBox(height: 12),

                    // Location Text + Map Picker Button
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller.locationTextController,
                            decoration: InputDecoration(
                              labelText: 'الموقع (الإحداثيات)',
                              hintText: isRemote ? 'لا ينطبق على الوظائف عن بعد' : 'انقر على أيقونة الخريطة',
                              border: OutlineInputBorder(),
                              enabled: false, // User cannot type here directly, only via map
                              fillColor: isRemote ? cs.surfaceContainerHigh : null,
                              filled: isRemote,
                            ),
                            validator: isRemote ? null : controller.validateRequired,
                            style: GoogleFonts.tajawal(),
                          ),
                        ),
                        isRemote
                            ? const SizedBox.shrink()
                            : IconButton(
                          icon: const Icon(Icons.map),
                          onPressed: controller.pickLocationOnMap,
                          tooltip: 'اختر من الخريطة',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),

              // Hashtags
              TextFormField(
                controller: controller.hashtagsController,
                decoration: InputDecoration(labelText: 'الهاشتاغات (مفصولة بفواصل، تبدأ بـ #)', hintText: 'مثال: #برمجة,#تصميم,#هندسة', border: OutlineInputBorder()),
                style: GoogleFonts.tajawal(),
              ),
              const SizedBox(height: 12),

              // Add Contact Button
              ElevatedButton.icon(
                onPressed: () => controller.openAddContactDialog(context),
                icon: const Icon(Icons.add_link),
                label: Text('أضف طريقة تواصل', style: GoogleFonts.tajawal()),
              ),
              const SizedBox(height: 12),

              // Display Current Contact Options
              Obx(
                    () => Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: controller.contactOptions.map((opt) {
                    return Chip(
                      label: Text('${opt.type.name}: ${opt.value}', style: GoogleFonts.tajawal()),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => controller.removeContactOption(opt),
                      avatar: const Icon(Icons.link, size: 16),
                      backgroundColor: cs.secondaryContainer,
                      labelStyle: TextStyle(color: cs.onSecondaryContainer),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Save Job Button (Submit button)
              Obx(
                    () => ElevatedButton.icon(
                  onPressed: controller.isLoading.value ? null : controller.submitJob,
                  icon: controller.isLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                  label: Text(controller.isLoading.value ? 'جاري الحفظ...' : 'حفظ التعديلات', style: GoogleFonts.tajawal()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}