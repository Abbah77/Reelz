import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color electricBlue = Color(0xFF0066FF);
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color glassBg = Color(0x30FFFFFF);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: electricBlue,
        surface: surfaceDark,
        background: darkBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black87,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      fontFamily: 'SFProDisplay',
    );
  }
  
  // Glass morphism decoration
  static BoxDecoration glassDecoration({double borderRadius = 16}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 5,
        ),
      ],
    );
  }
  
  // Glowing button style
  static ButtonStyle glowingButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: electricBlue,
    foregroundColor: Colors.white,
    elevation: 8,
    shadowColor: electricBlue.withOpacity(0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );
}
