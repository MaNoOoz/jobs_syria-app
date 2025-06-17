// lib/main_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../models.dart';
import '../routes/app_pages.dart';
import '../ui/home_view.dart';
import '../ui/map_screen.dart';
import '../ui/profile_screen.dart'; // Ensure this import is correct

import '../services/auth_service.dart'; // Changed from AuthController

import '../utils/theme_service.dart';

import 'FavoritesScreen.dart';
import 'map_controller.dart';
import 'settings_screen.dart'; // Assuming settings_screen is in the same directory as MainScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Get the AuthService instance
  final AuthService _authService = Get.find<AuthService>(); // Changed to AuthService
  final ThemeService _themeService = Get.find<ThemeService>();

  int _selectedIndex = 0; // Default to the first screen

  // Added ProfileScreen to the list of screens
  final List<Widget> _screens = const [
    HomePage(),
    MapScreen(),
    FavoritesScreen(),
    ProfileScreen(), // Added ProfileScreen
    SettingsScreen(),
  ];

  // Added title for ProfileScreen
  final List<String> _titles = [
    'الرئيسية',
    'الخريطة',
    'المفضلة',
    'الملف الشخصي', // Title for ProfileScreen
    'الإعدادات',
  ];

  @override
  void initState() {
    super.initState();
    // No explicit action needed here for user data, AuthService handles it.
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Use Obx to react to changes in AuthService.currentUser
    return Obx(() {
      // If currentUser is null, it means user is not logged in or logged out.
      // AuthService's listener should handle redirection, but this provides a visual cue.
      if (_authService.currentUser.value == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // If we reach here, _authService.currentUser.value is not null
      final currentUser = _authService.currentUser.value!; // Non-nullable now

      return Scaffold(
        appBar: AppBar(
          title: Text(
            _titles[_selectedIndex],
            style: TextStyle(fontWeight: FontWeight.w600, color: cs.onPrimaryContainer), // Consistent text color
          ),
          backgroundColor: cs.primaryContainer, // Consistent background color
          actions: [
            IconButton(
              icon: Icon(
                _themeService.isDarkMode.value ? FontAwesomeIcons.solidSun : FontAwesomeIcons.solidMoon,
                color: cs.onPrimaryContainer, // Consistent icon color
              ),
              onPressed: () => _themeService.toggleTheme(), // Use toggleTheme as defined in ThemeService
            ),
            // The profile icon button is now redundant since ProfileScreen is in the bottom nav.
            // You might remove it, or keep it if it serves a different purpose (e.g., quick access to a different profile view)
            // For now, I'll remove it as it's typically duplicate with bottom nav.
            // If you want to keep it, you need to import ProfileScreen if not already.
          ],
        ),
        body: _screens[_selectedIndex],
        // Floating Action Button visibility based on currentUser role
        floatingActionButton: _selectedIndex == 0 && currentUser.role == AppRoles.employer // Use AppRoles.employer
            ? FloatingActionButton.extended(
          onPressed: () {
            Get.toNamed(Routes.ADD_NEW); // Routes.ADD_NEW should map to AddJobScreen
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
          // Added a new BottomNavigationBarItem for ProfileScreen
          items: const [
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.mapLocationDot), label: 'الخريطة'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.solidHeart), label: 'المفضلة'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.solidUser), label: 'الملف الشخصي'), // New item for ProfileScreen
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.gear), label: 'الإعدادات'),
          ],
        ),
      );
    });
  }
}