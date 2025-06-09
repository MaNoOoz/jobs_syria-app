// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: cs.primary),
              child: Center(
                child: Text(
                  'القائمة الرئيسية',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildTile(
              icon: FontAwesomeIcons.house,
              title: 'الرئيسية',
              onTap: () => Get.offAllNamed('/ui'),
            ),
            _buildTile(
              icon: FontAwesomeIcons.mapLocationDot,
              title: 'الخريطة',
              onTap: () => Get.offAllNamed('/map'),
            ),
            _buildTile(
              icon: FontAwesomeIcons.solidHeart,
              title: 'المفضلة',
              onTap: () => Get.toNamed('/favorites'),
            ),
            _buildTile(
              icon: FontAwesomeIcons.gear,
              title: 'الإعدادات',
              onTap: () => Get.toNamed('/settings'),
            ),
            const Spacer(),
            const Divider(),
            _buildTile(
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              onTap: () {
                final box = GetStorage();
                box.remove('user');
                Get.offAllNamed('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
