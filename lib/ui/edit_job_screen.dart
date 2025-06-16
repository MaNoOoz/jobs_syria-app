import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import 'add_job_form_controller.dart';

class EditJobScreen extends StatelessWidget {
  final JobModel? job;

  const EditJobScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final AddJobFormController controller = Get.put(AddJobFormController(initialJob: job));
    final cs = Theme.of(context).colorScheme;


    if (job == null) {
      return const Center(child: Text('No job data available'));
    }
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

              // Remote Work Toggle
              Obx(() => SwitchListTile(
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

              // Job Type Dropdown
              Obx(() => DropdownButtonFormField<String>(
                value: controller.selectedJobType.value,
                decoration: const InputDecoration(
                  labelText: 'نوع الوظيفة',
                  border: OutlineInputBorder(),
                ),
                items: controller.jobTypes
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, style: GoogleFonts.tajawal()),
                ))
                    .toList(),
                onChanged: (value) => controller.selectedJobType.value = value!,
                validator: controller.validateRequired,
                style: GoogleFonts.tajawal(color: cs.onSurface),
              )),
              const SizedBox(height: 12),

              // Location Fields - Only show if not remote
              Obx(() {
                if (controller.isRemote.value) return const SizedBox();

                return Column(
                  children: [
                    // City Dropdown
                    DropdownButtonFormField<String>(
                      value: controller.selectedCity.value,
                      decoration: const InputDecoration(
                        labelText: 'المدينة',
                        border: OutlineInputBorder(),
                      ),
                      items: AddJobFormController.cities
                          .map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city, style: GoogleFonts.tajawal()),
                      ))
                          .toList(),
                      onChanged: controller.onCityChanged,
                      validator: controller.validateRequired,
                      style: GoogleFonts.tajawal(color: cs.onSurface),
                    ),
                    const SizedBox(height: 12),

                    // Location Text
                    TextFormField(
                      controller: controller.locationTextController,
                      decoration: const InputDecoration(
                        labelText: 'الموقع',
                        border: OutlineInputBorder(),
                      ),
                      validator: controller.validateRequired,
                      style: GoogleFonts.tajawal(),
                    ),
                    const SizedBox(height: 12),

                    // Map Picker Button
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
                    const SizedBox(height: 8),

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

              // Contact Options Section
              Text(
                'طرق التواصل:',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Add Contact Button
              ElevatedButton.icon(
                onPressed: () => controller.openAddContactDialog(context),
                icon: const Icon(Icons.add_link),
                label: Text(
                  'أضف طريقة تواصل',
                  style: GoogleFonts.tajawal(),
                ),
              ),
              const SizedBox(height: 8),

              // Contact Options Chips
              Obx(() => Wrap(
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
              const SizedBox(height: 24),

              // Save Button
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.submitJob,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
                child: controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : Text(
                  'حفظ التعديلات',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}