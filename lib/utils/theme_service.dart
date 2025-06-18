import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeService extends GetxService {
  // Reactive variable to hold the current dark mode state.
  // It will NOT be persisted without GetStorage. Default to false (light mode).
  final RxBool _isDarkMode = false.obs;

  // Getter to expose the reactive dark mode status
  RxBool get isDarkMode => _isDarkMode;

  // Get the current theme mode (light or dark)
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  // Toggle theme mode
  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value; // Toggle the reactive state
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // Get the current theme (light or dark ThemeData)
  ThemeData get lightTheme => _buildLightTheme();
  ThemeData get darkTheme => _buildDarkTheme();

  // --- Theme Data Definitions (Material 3) ---

  ThemeData _buildLightTheme() {
    const ColorSeed colorSeed = ColorSeed.purple;
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: colorSeed.color,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.primaryContainer, // Consistent with app
        foregroundColor: lightColorScheme.onPrimaryContainer, // Consistent with app
        elevation: 0,
        centerTitle: true, // Often centered in app bars
        // Use GoogleFonts with explicit text styles if needed, not for entire AppBarTheme
      ),
      // Set default text theme with Tajawal
      textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
      cardTheme: CardThemeData( // Corrected to CardTheme
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: lightColorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColorScheme.secondaryContainer,
        foregroundColor: lightColorScheme.onSecondaryContainer,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const ColorSeed colorSeed = ColorSeed.purple; // Consistent purple seed
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: colorSeed.color,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.primaryContainer, // Consistent with app
        foregroundColor: darkColorScheme.onPrimaryContainer, // Consistent with app
        elevation: 0,
        centerTitle: true,
        // Use GoogleFonts with explicit text styles if needed
      ),
      // Set default text theme with Tajawal
      textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData( // Corrected to CardTheme
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: darkColorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkColorScheme.secondaryContainer,
        foregroundColor: darkColorScheme.onSecondaryContainer,
      ),
    );
  }
}

// Helper enum for selecting seed colors more easily (unchanged)
enum ColorSeed {
  red(Color(0xFFE4442A)),
  purple(Color(0xFF6750A4)), // Material 3 standard purple
  deepPurple(Color(0xFF673AB7)), // A common darker purple
  indigo(Color(0xFF3F51B5)),
  blue(Color(0xFF2196F3)),

  black(Colors.black45), // Consider removing this if not used as a primary seed
  teal(Color(0xFF009688)),
  green(Color(0xFF4CAF50)),
  yellow(Color(0xFFFFEB3B)),
  orange(Color(0xFFFF9800)),
  deepOrange(Color(0xFFFF5722)),
  pink(Color(0xFFE91E63));

  const ColorSeed(this.color);
  final Color color;
}