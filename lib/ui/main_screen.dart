// lib/main_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../models.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import '../ui/home_view.dart';
import '../ui/map_screen.dart';
import '../ui/profile_screen.dart';
import 'FavoritesScreen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = Get.find<AuthService>();

  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomePage(),
    MapScreen(),
    FavoritesScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = [
    'الرئيسية',
    'الخريطة',
    'المفضلة',
    'الملف الشخصي',
    'الإعدادات',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Obx(() {

      return Scaffold(
        appBar: AppBar(
          title: Text(
            _titles[_selectedIndex],
            style: TextStyle(fontWeight: FontWeight.w600, color: cs.onPrimaryContainer),
          ),
          backgroundColor: cs.primaryContainer,

        ),
        body: Column(
          children: [
            if (_authService.isGuest) // This uses the getter for UI display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                color: cs.tertiaryContainer,
                child: Text(
                  'أنت تستخدم التطبيق كزائر',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Directly check Firebase user's anonymous status for button press logic
            if (_authService.firebaseUser.value?.isAnonymous == true) {
              Get.snackbar(
                'غير مسموح',
                ' للإضافة وظائف جديدة.الرجاء تسجيل الدخول بالإيميل أنت تستخدم التطييق كزائر ',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.redAccent,
                colorText: Colors.white,
              );
            } else {
              Get.toNamed(Routes.ADD_NEW);
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة وظيفة'),
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: cs.primary,
          unselectedItemColor: cs.onSurfaceVariant,
          items: const [
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.mapLocationDot), label: 'الخريطة'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.solidHeart), label: 'المفضلة'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.solidUser), label: 'الملف الشخصي'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.gear), label: 'الإعدادات'),
          ],
        ),
      );
    });
  }
}