import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';

class JobDetailsScreen extends StatelessWidget {
  final JobModel job;

  const JobDetailsScreen({required this.job, super.key});

  void _launchContact(String value, ContactType type) async {
    try {
      String url = value.trim();

      // Format URL based on contact type
      switch (type) {
        case ContactType.email:
          if (!url.startsWith('mailto:')) url = 'mailto:$url';
          break;
        case ContactType.phone:
          if (!url.startsWith('tel:')) {
            url = 'tel:${url.replaceAll(RegExp(r'[^0-9+]'), '')}';
          }
          break;
        case ContactType.website:
          if (!url.startsWith(RegExp(r'https?://'))) url = 'https://$url';
          break;
        case ContactType.whatsapp:
          if (!url.startsWith('https://wa.me/') &&
              !url.startsWith('whatsapp://')) {
            url = 'https://wa.me/${url.replaceAll(RegExp(r'[^0-9+]'), '')}';
          }
          break;
        case ContactType.telegram:
          if (!url.startsWith('https://t.me/') &&
              !url.startsWith('tg://')) {
            url = 'https://t.me/${url.replaceFirst('@', '')}';
          }
          break;
        case ContactType.facebook:
          if (!url.startsWith('https://www.facebook.com/') &&
              !url.startsWith('fb://')) {
            url = 'https://www.facebook.com/${url.replaceFirst('@', '')}';
          }
          break;
        case ContactType.other:
          if (!url.startsWith(RegExp(r'https?://')) &&
              url.contains('.') &&
              !url.contains(' ')) {
            url = 'https://$url';
          }
          break;
      }

      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e, stack) {
      Logger().e('Error launching contact', error: e, stackTrace: stack);
      Get.snackbar(
        'خطأ',
        'لا يمكن فتح ${type.displayName}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm', 'ar');
    final postedAt = dateFormat.format(job.createdAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          job.title,
          overflow: TextOverflow.ellipsis,
        ),
        // backgroundColor: cs.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Title
            Text(
              job.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // City and Job Type Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (job.city.isNotEmpty)
                  Chip(
                    label: Text(job.city),
                    backgroundColor: cs.primaryContainer,
                  ),
                Chip(
                  label: Text(job.jobType),
                  backgroundColor: cs.secondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Posted Date
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'نشر في $postedAt',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const Divider(height: 32),

            // Job Description
            Text(
              'وصف الوظيفة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: 32),

            // Location (only for non-remote jobs)
            if (job.jobType != 'عن بعد' && job.location.isNotEmpty) ...[
              Text(
                'الموقع',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                job.location,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Divider(height: 32),
            ],

            // Hashtags
            if (job.hashtags.isNotEmpty) ...[
              Text(
                'الكلمات المفتاحية',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: job.hashtags.map((tag) => Chip(
                  label: Text('#$tag'),
                  backgroundColor: cs.surfaceVariant,
                )).toList(),
              ),
              const Divider(height: 32),
            ],

            // Contact Options
            if (job.contactOptions.isNotEmpty) ...[
              Text(
                'طرق التواصل',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: job.contactOptions.map((opt) {
                  final icon = _getContactIcon(opt.type);
                  final displayText = _getDisplayText(opt);

                  return ActionChip(
                    avatar: Icon(icon.icon, color: icon.color, size: 20),
                    label: Text(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _launchContact(opt.value, opt.type),
                    backgroundColor: cs.primaryContainer,
                    labelStyle: TextStyle(color: cs.onPrimaryContainer),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ContactIcon _getContactIcon(ContactType type) {
    switch (type) {
      case ContactType.whatsapp:
        return _ContactIcon(FontAwesomeIcons.whatsapp, Colors.green);
      case ContactType.telegram:
        return _ContactIcon(FontAwesomeIcons.telegram, Colors.blue);
      case ContactType.email:
        return _ContactIcon(Icons.email, Colors.red);
      case ContactType.website:
        return _ContactIcon(Icons.link, Colors.blue);
      case ContactType.phone:
        return _ContactIcon(Icons.phone, Colors.green);
      case ContactType.facebook:
        return _ContactIcon(FontAwesomeIcons.facebook, Colors.blue);
      case ContactType.other:
        return _ContactIcon(Icons.contact_support, Colors.grey);
    }
  }

  String _getDisplayText(ContactOption opt) {
    String text = opt.value;

    // Clean up display text
    text = text
        .replaceAll(RegExp(r'^(https?://|mailto:|tel:|@)'), '')
        .replaceAll('www.', '')
        .trim();

    // Shorten long texts
    if (text.length > 20) {
      text = '${text.substring(0, 20)}...';
    }

    return text;
  }
}

class _ContactIcon {
  final IconData icon;
  final Color color;

  _ContactIcon(this.icon, this.color);
}