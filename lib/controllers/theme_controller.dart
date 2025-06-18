// theme_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();
  final _key = 'isDarkMode';

  bool get isDarkMode => _loadThemeFromStorage();

  ThemeMode get themeMode =>
      isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme(bool isOn) {
    Get.changeThemeMode(isOn ? ThemeMode.dark : ThemeMode.light);
    _saveThemeToStorage(isOn);
  }

  bool _loadThemeFromStorage() => _storage.read(_key) ?? false;

  void _saveThemeToStorage(bool isDarkMode) =>
      _storage.write(_key, isDarkMode);
}
