// lib/main_screen.dart (or where your MainScreen is located)

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:quiz_project/home/profile_screen.dart';

// Remove GetStorage import if not used for other purposes in this widget
// import 'package:get_storage/get_storage.dart';
// import 'package:quiz_project/home/storage_keys.dart'; // No longer directly needed

import '../controllers/AuthController.dart';
import '../home/home_view.dart';
import '../home/map_screen.dart';
import '../home/settings_screen.dart';
import '../home/theme_service.dart';
import 'FavoritesScreen.dart';
import 'add_job_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Get the AuthController instance
  final AuthController _authController = Get.find<AuthController>();
  final ThemeService _themeService = Get.find<ThemeService>();

  int _selectedIndex = 0;

  final List<Widget> _screens = const [HomePage(), MapScreen(), FavoritesScreen(), SettingsScreen()];

  final List<String> _titles = ['الرئيسية', 'الخريطة', 'المفضلة', 'الإعدادات'];

  @override
  void initState() {
    super.initState();
    // No need to load current user or listen to box here.
    // AuthController already loads it and handles redirection.
    // The UI will react via Obx.
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Use Obx to react to changes in AuthController.currentUser
    return Obx(() {
      // If currentUser is null, it means user is not logged in or logged out.
      // AuthController should handle redirection, but as a fallback/initial state:
      if (_authController.currentUser.value == null) {
        // You can show a loading indicator or just an empty scaffold
        // The AuthController's listener should navigate away quickly.
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // If we reach here, _authController.currentUser.value is not null
      final currentUser = _authController.currentUser.value!; // Non-nullable now

      return Scaffold(
        appBar: AppBar(
          title: Text(_titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: cs.primary,
          actions: [
            IconButton(icon: Icon(Get.isDarkMode ? FontAwesomeIcons.solidSun : FontAwesomeIcons.solidMoon), onPressed: () => _themeService.switchTheme()),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Get.to(() => const ProfileScreen());
              },
            ),
          ],
        ),
        body: _screens[_selectedIndex],
        // Floating Action Button visibility based on currentUser role
        floatingActionButton:
            _selectedIndex == 0 && currentUser.role == 'employer'
                ? FloatingActionButton.extended(
                  onPressed: () {
                    Get.to(() => const AddJobScreen());
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة وظيفة'),
                  backgroundColor: cs.secondaryContainer,
                  foregroundColor: cs.onSecondaryContainer,
                )
                : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: cs.primary,
          unselectedItemColor: cs.onSurfaceVariant,
          items: const [
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.mapLocationDot), label: 'الخريطة'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.solidHeart), label: 'المفضلة'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.gear), label: 'الإعدادات'),
          ],
        ),
      );
    });
  }
}
