import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Tailwind Slate Colors
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Brand Accent Colors
  static const Color primaryBlue = Color(0xFF2563EB); // Tailwind blue-600
  static const Color primaryPurple = Color(0xFF9333EA); // Tailwind purple-600
  static const Color primaryEmerald = Color(0xFF059669); // Tailwind emerald-600
  static const Color primaryRose = Color(0xFFE11D48); // Tailwind rose-600
  static const Color primaryAmber = Color(0xFFD97706); // Tailwind amber-600

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: slate50,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      background: slate50,
      surface: Colors.white,
      onSurface: slate900,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: slate900,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: slate200, width: 1),
      ),
    ),
  );
}
