// lib/screens/edit_job_screen.dart
// lib/screens/edit_job_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


import '../core/models.dart'; // Ensure JobModel is here
import 'add_job_form_controller.dart'; // Import the updated controller

class EditJobScreen extends StatelessWidget {
  final JobModel job;

  const EditJobScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final AddJobFormController controller = Get.put(AddJobFormController(initialJob: job));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تعديل الإعلان',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
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
              // Job Title
              TextFormField(
                controller: controller.titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الوظيفة',
                  border: OutlineInputBorder(),
                ),
                validator: controller.validateRequired,
                style: GoogleFonts.tajawal(),
              ),
              const SizedBox(height: 12),

              // Job Description
              TextFormField(
                controller: controller.descController,
                decoration: const InputDecoration(
                  labelText: 'وصف الوظيفة',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: controller.validateRequired,
                style: GoogleFonts.tajawal(),
              ),
              const SizedBox(height: 12),

              // Job Type Dropdown
              Obx(() =>
                  DropdownButtonFormField<String>(
                    value: controller.selectedJobType.value,
                    decoration: const InputDecoration(
                      labelText: 'نوع الوظيفة',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.jobTypes
                        .map((type) =>
                        DropdownMenuItem(
                          value: type,
                          child: Text(type, style: GoogleFonts.tajawal()),
                        ))
                        .toList(),
                    onChanged: (value) => controller.selectedJobType.value = value!,
                    validator: controller.validateRequired,
                    style: GoogleFonts.tajawal(color: cs.onSurface),
                  )),
              const SizedBox(height: 12),

              // Remote Work Toggle
              Obx(() =>
                  SwitchListTile(
                    title: Text(
                      'وظيفة عن بعد؟',
                      style: GoogleFonts.tajawal(),
                    ),
                    value: controller.isRemote.value,
                    onChanged: controller.toggleRemote,
                    secondary: Icon(
                      controller.isRemote.value ? Icons.cloud : Icons.location_city,
                    ),
                  )),
              const SizedBox(height: 12),

              // Salary Range
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.minSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الحد الأدنى للراتب',
                        border: OutlineInputBorder(),
                      ),
                      validator: controller.validateNumber,
                      style: GoogleFonts.tajawal(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: controller.maxSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الحد الأقصى للراتب',
                        border: OutlineInputBorder(),
                      ),
                      validator: controller.validateNumber,
                      style: GoogleFonts.tajawal(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location Fields
              Obx(() {
                final isRemote = controller.isRemote.value;
                return Column(
                  children: [
                    // City Dropdown
                    DropdownButtonFormField<String>(
                      value: controller.cityController.text.isEmpty
                          ? null
                          : controller.cityController.text,
                      decoration: InputDecoration(
                        labelText: 'المدينة',
                        border: const OutlineInputBorder(),
                        enabled: !isRemote,
                      ),
                      items: AddJobFormController.cities
                          .map((city) =>
                          DropdownMenuItem(
                            value: city,
                            child: Text(city, style: GoogleFonts.tajawal()),
                          ))
                          .toList(),
                      onChanged: isRemote
                          ? null
                          : (value) => controller.cityController.text = value!,
                      validator: (value) {
                        if (!isRemote) {
                          return controller.validateRequired(value);
                        }
                        return null;
                      },
                      style: GoogleFonts.tajawal(color: cs.onSurface),
                    ),
                    const SizedBox(height: 12),

                    // Location Text
                    TextFormField(
                      controller: controller.locationTextController,
                      decoration: InputDecoration(
                        labelText: 'الموقع',
                        border: const OutlineInputBorder(),
                        enabled: !isRemote,
                      ),
                      validator: (value) {
                        if (!isRemote) {
                          return controller.validateRequired(value);
                        }
                        return null;
                      },
                      style: GoogleFonts.tajawal(),
                    ),
                    const SizedBox(height: 12),

                    // Map Picker Button
                    if (!isRemote)
                      ElevatedButton.icon(
                        onPressed: () => controller.pickLocation(context),
                        icon: const Icon(Icons.map),
                        label: Text(
                          'اختيار الموقع من الخريطة',
                          style: GoogleFonts.tajawal(),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Coordinates Display
                    Text(
                      'الإحداثيات: ${controller.latitude.value.toStringAsFixed(5)}, ${controller.longitude.value.toStringAsFixed(5)}',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),

              // Hashtags
              TextFormField(
                controller: controller.hashtagsController,
                decoration: const InputDecoration(
                  labelText: 'الكلمات المفتاحية (مثل: #مبرمج #جافا)',
                  border: OutlineInputBorder(),
                ),
                validator: controller.validateHashtags,
                style: GoogleFonts.tajawal(),
              ),
              const SizedBox(height: 12),

              // Add Contact Button
              ElevatedButton.icon(
                onPressed: () => controller.openAddContactDialog(context),
                icon: const Icon(Icons.add_link),
                label: Text(
                  'أضف طريقة تواصل',
                  style: GoogleFonts.tajawal(),
                ),
              ),
              const SizedBox(height: 12),

              // Contact Options Chips
              Obx(() =>
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: controller.contactOptions.map((opt) {
                      return Chip(
                        label: Text(
                          '${opt.type.displayName}: ${opt.value}',
                          style: GoogleFonts.tajawal(),
                        ),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => controller.removeContactOption(opt),
                        avatar: const Icon(Icons.link, size: 16),
                        backgroundColor: cs.secondaryContainer,
                        labelStyle: TextStyle(color: cs.onSecondaryContainer),
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 20),

              // Save Button
              Obx(() =>
                  ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.submitJob(),
                    icon: controller.isLoading.value
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.save),
                    label: Text(
                      controller.isLoading.value ? 'جاري الحفظ...' : 'حفظ التعديلات',
                      style: GoogleFonts.tajawal(),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}