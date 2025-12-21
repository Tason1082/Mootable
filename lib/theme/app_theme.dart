// app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFF9800);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: primary,
      secondaryContainer: primary.withOpacity(0.15), // Tonal button
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

    // FILLED BUTTON (Katıl, Kaydet, vb.)
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return primary.withOpacity(0.4);
          return primary;
        }),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        )),
      ),
    ),

    // OUTLINED BUTTON
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(primary),
        side: MaterialStateProperty.all(BorderSide(color: primary)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        )),
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

    // CHIP (ChoiceChip, FilterChip, vb.)
    chipTheme: ChipThemeData(
      selectedColor: primary,
      backgroundColor: Colors.grey.shade200,
      disabledColor: Colors.grey.shade300,
      labelStyle: const TextStyle(color: Colors.black),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: primary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
  );
}
