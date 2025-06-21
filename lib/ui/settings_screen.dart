// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart'; // Import Get for Get.find and Obx

import '../utils/Constants.dart';
import '../services/auth_service.dart'; // Ensure AuthService is imported
import '../utils/theme_service.dart'; // Import ThemeService

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody({Key? key}) : super(key: key);

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  bool _isLoading = false;
  final AuthService _authService = Get.find<AuthService>(); // Get AuthService instance
  final ThemeService _themeService = Get.find<ThemeService>(); // Get ThemeService instance

  final Map<Uri, String> _appUris = {
    Uri.parse(OtherApps): 'Other Apps',
    Uri.parse(BASE_URL_flutter): 'Main App',
  };

  Future<void> _launchAppUri(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $uri');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في فتح: ${_appUris[uri]}')),
      );
    }
  }

  List<SettingItem> _getSettingItems(ColorScheme cs) =>
      [
        // SettingItem(
        //   title: "وضع السمة الداكنة",
        //   icon: Icons.dark_mode,
        //   isToggle: true,
        //   toggleValue: _themeService.isDarkMode.value,
        //   onToggle: (value) {
        //     _themeService.toggleTheme();
        //   },
        // ),
        SettingItem(
          title: "سياسة الخصوصية",
          icon: Icons.privacy_tip,
          isLoading: _isLoading,
          onTap: (context) => _launchAppUri(Uri.parse(PP)),
        ),
        SettingItem(
          title: "مشاركة التطبيق",
          icon: Icons.share,
          onTap: (context) {
            return Share.share(
              'Check out this app: $BASE_URL_flutter',
              subject: APP_NAME,
            );
          },
        ),
        SettingItem(
          title: "تطبيقاتنا الأخرى",
          icon: Icons.apps,
          onTap: (context) => _launchAppUri(Uri.parse(OtherApps)),
        ),
        SettingItem(
          title: "تحديث التطبيق",
          icon: Icons.update_outlined,
          onTap: (context) => _launchAppUri(Uri.parse(BASE_URL_flutter)),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: _getSettingItems(cs).length,
          itemBuilder: (context, index) => _buildSettingItem(_getSettingItems(cs)[index], cs),
        ),
      ),
    );
  }

  Widget _buildSettingItem(SettingItem item, ColorScheme cs) {
    if (item.isToggle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          child: Obx(() => SwitchListTile(
            title: Text(item.title),
            value: _themeService.isDarkMode.value, // Directly observe the RxBool
            onChanged: item.onToggle,
            secondary: Icon(item.icon, size: 30),
            activeColor: cs.primary,
          )),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        child: ListTile(
          title: Text(item.title),
          trailing: const Icon(Icons.chevron_right),
          leading: Icon(item.icon, size: 30),
          onTap: () => item.onTap?.call(context),
        ),
      ),
    );
  }
}

class SettingItem {
  final String title;
  final IconData icon;
  final bool isLoading;
  final Function(BuildContext)? onTap;
  final bool isToggle;
  final bool? toggleValue;
  final Function(bool)? onToggle;

  SettingItem({
    required this.title,
    required this.icon,
    this.isLoading = false,
    this.onTap,
    this.isToggle = false,
    this.toggleValue,
    this.onToggle,
  });
}