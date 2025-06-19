import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/Constants.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: APP_MAIN_COLOR,
      // appBar: AppBar(
      //   centerTitle: true,
      //   backgroundColor: APP_MAIN_COLOR,
      //   title: const Text('الإعدادات', style: TextStyle(fontFamily: FONT_FAMILY, color: Colors.white, fontSize: 20)),
      // ),
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

  List<SettingItem> _getSettingItems() =>
      [
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
        // ... other items
      ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: _getSettingItems().length,
          itemBuilder: (context, index) => _buildSettingItem(_getSettingItems()[index]),
        ),
      ),
    );
  }

  Widget _buildSettingItem(SettingItem item) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          // color: item.color.withOpacity(0.1),
          child: ListTile(
            title: Text(item.title, ),
            trailing: const Icon(Icons.chevron_right,),
            leading: Icon(item.icon,  size: 30),
            onTap: () => item.onTap?.call(context),
          ),
        ),
      );
}

class SettingItem {
  final String title;
  final IconData icon;
  final bool isLoading;
  final Function(BuildContext)? onTap;

  SettingItem({
    required this.title,
    required this.icon,
    this.isLoading = false,
    this.onTap,
  });
}
