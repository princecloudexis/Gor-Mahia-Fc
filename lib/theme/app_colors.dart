import 'package:flutter/material.dart';

/// Gor Mahia FC — Official Brand Color Palette
/// Primary Green : #2B6535
/// Primary Blue  : #224194
class AppColors {
  AppColors._(); // prevent instantiation

  // ─────────────────────────────────────────
  // Brand / Logo Exact Colors
  // ─────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF2B6535);
  static const Color primaryBlue = Color(0xFF224194);
  static const Color logoWhite = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────
  // Green Shades
  // ─────────────────────────────────────────
  static const Color greenDarkest = Color(0xFF163520);
  static const Color greenDark = Color(0xFF1E4A2A);
  static const Color greenMain = Color(0xFF2B6535);
  static const Color greenMedium = Color(0xFF3D8B4A);
  static const Color greenLight = Color(0xFF5EAD6A);
  static const Color greenPale = Color(0xFFA8D5B2);
  static const Color greenSurface = Color(0xFF1E3D26);

  // ─────────────────────────────────────────
  // Blue Shades
  // ─────────────────────────────────────────
  static const Color blueDarkest = Color(0xFF0F1F4A);
  static const Color blueDark = Color(0xFF172D6B);
  static const Color blueMain = Color(0xFF224194); // Logo Primary
  static const Color blueMedium = Color(0xFF2E58C8);
  static const Color blueLight = Color(0xFF5A82D6);
  static const Color bluePale = Color(0xFFA3BAEA);

  // ─────────────────────────────────────────
  // Backgrounds — Dark Mode
  // ─────────────────────────────────────────
  static const Color bgDark = Color(0xFF0D1F14);
  static const Color bgSurfaceDark = Color(0xFF162B1C);
  static const Color bgCardDark = Color(0xFF1E3D26);

  // ─────────────────────────────────────────
  // Backgrounds — Light Mode
  // ─────────────────────────────────────────
  static const Color bgLight = Color(0xFFF4FBF5);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgInputLight = Color(0xFFEAF5EC);

  // ─────────────────────────────────────────
  // Text Colors
  // ─────────────────────────────────────────
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA8D5B2);
  static const Color textMutedDark = Color(0xFF6B9E77);
  static const Color textOnLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF3D5A44);
  static const Color textMutedLight = Color(0xFF6B8C72);

  // ─────────────────────────────────────────
  // Utility / Status Colors
  // ─────────────────────────────────────────
  static const Color gold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFF5C842);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ─────────────────────────────────────────
  // Gradients
  // ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenMain, blueMain],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenDark, greenMedium],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueDark, blueMedium],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldLight],
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDark, bgSurfaceDark],
  );

  // ─────────────────────────────────────────
  // Glassmorphism
  // ─────────────────────────────────────────
  static Color glassLight = Colors.white.withValues(alpha: 0.15);
  static Color glassDark = Colors.black.withValues(alpha: 0.3);
  static Color glassPrimaryGreen = greenMain.withValues(alpha: 0.2);
}
