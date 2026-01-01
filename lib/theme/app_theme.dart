import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFF9800);

  // =========================
  // LIGHT THEME
  // =========================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: primary,
      secondaryContainer: primary.withOpacity(0.15),
      surface: Colors.white,
      background: Colors.white,
    ),

    // APP BAR
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    iconTheme: const IconThemeData(color: Colors.black87),

    // FILLED BUTTON
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return primary.withOpacity(0.4);
          }
          return primary;
        }),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ),

    // OUTLINED BUTTON
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(primary),
        side: MaterialStateProperty.all(BorderSide(color: primary)),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ),

    // INPUT
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary),
      ),
      prefixIconColor: primary,
    ),

    // BOTTOM NAV
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black87,
      unselectedItemColor: Colors.grey,
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),

    // CHIP
    chipTheme: ChipThemeData(
      selectedColor: primary,
      backgroundColor: Colors.grey.shade200,
      disabledColor: Colors.grey.shade300,
      labelStyle: const TextStyle(color: Colors.black),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: primary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
  );

  // =========================
  // DARK THEME
  // =========================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: primary,
      secondaryContainer: primary.withOpacity(0.25),
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
    ),

    // APP BAR
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    iconTheme: const IconThemeData(color: Colors.white70),

    // FILLED BUTTON
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return primary.withOpacity(0.4);
          }
          return primary;
        }),
        foregroundColor: MaterialStateProperty.all(Colors.black),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ),

    // OUTLINED BUTTON
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(primary),
        side: MaterialStateProperty.all(BorderSide(color: primary)),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ),

    // INPUT
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary),
      ),
      prefixIconColor: primary,
      labelStyle: const TextStyle(color: Colors.white70),
    ),

    // BOTTOM NAV
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF121212),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.black,
    ),

    // CHIP
    chipTheme: ChipThemeData(
      selectedColor: primary,
      backgroundColor: const Color(0xFF2A2A2A),
      disabledColor: const Color(0xFF333333),
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: primary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
  );
}
