import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models.dart';
import '../controllers/add_job_form_controller.dart';

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
              ),
              const SizedBox(height: 12),

              // Job Description
              TextFormField(
                controller: controller.descController,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                validator: controller.validateRequired,
              ),
              const SizedBox(height: 12),

              // Hashtags
              TextFormField(
                controller: controller.hashtagsController,
                decoration: const InputDecoration(
                  labelText: 'الهاشتاجات (مثال: عمل_عن_بعد, تسويق)',
                  border: OutlineInputBorder(),
                  hintText: 'افصل بين الهاشتاجات بفاصلة (,)',
                ),
                validator: controller.validateHashtags,
              ),
              const SizedBox(height: 12),

              // Job Type Dropdown
              Obx(() => DropdownButtonFormField<String>(
                value: controller.selectedJobType.value,
                decoration: const InputDecoration(
                  labelText: 'نوع الوظيفة',
                  border: OutlineInputBorder(),
                ),
                items: controller.jobTypes.map((String type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.selectedJobType.value = newValue;
                    controller.isRemote.value = (newValue == 'عن بعد'); // Sync isRemote with jobType
                  }
                },
              )),
              const SizedBox(height: 12),

              // Remote Job Switch (synced with job type)
              Obx(() => SwitchListTile(
                title: const Text('وظيفة عن بعد؟'),
                value: controller.isRemote.value,
                onChanged: controller.toggleRemote,
                secondary: Icon(controller.isRemote.value ? Icons.cloud_queue : Icons.apartment),
              )),
              const SizedBox(height: 12),

              // Location Text Field and Pick Location Button (Conditionally visible)
              Obx(() => Column(
                children: [
                  if (!controller.isRemote.value) ...[
                    TextFormField(
                      controller: controller.locationTextController,
                      decoration: const InputDecoration(
                        labelText: 'العنوان التفصيلي للوظيفة',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // Make it read-only
                      onTap: () => controller.pickLocation(context), // Open map picker on tap
                      validator: controller.validateRequired, // Only validate if not remote
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.cityController,
                      decoration: const InputDecoration(
                        labelText: 'المدينة',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // Make it read-only
                      onTap: () => controller.pickLocation(context), // Open map picker on tap
                      validator: controller.validateRequired, // Only validate if not remote
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => controller.pickLocation(context),
                      icon: const Icon(Icons.map),
                      label: const Text('اختر الموقع من الخريطة'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40), // Make button full width
                        backgroundColor: cs.secondary,
                        foregroundColor: cs.onSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              )),

              // Contact Options
              ListTile(
                title: const Text('طرق التواصل'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => controller.openAddContactDialog(context),
                ),
              ),
              Obx(() => Wrap(
                spacing: 8.0, // gap between adjacent chips
                runSpacing: 4.0, // gap between lines
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