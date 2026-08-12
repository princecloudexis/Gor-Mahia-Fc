import 'package:gormahiafc/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';


class AppTheme {
  AppTheme._();

  // ─── Legacy aliases (keep for backward compat) ─────────────────────────────
  static const Color primaryGreen = AppColors.primaryGreen;
  static const Color primaryBlue = AppColors.primaryBlue;

  /// @deprecated Use AppColors.primaryGreen
  static const Color primaryPink = AppColors.primaryGreen;

  /// @deprecated Use AppColors.primaryBlue
  static const Color primaryPurple = AppColors.primaryBlue;

  static const LinearGradient primaryGradient = AppColors.primaryGradient;
  static const LinearGradient primaryGradientDiagonal =
      AppColors.primaryGradient;

  static const Color accentRed = AppColors.error;
  static const Color accentBlue = AppColors.blueMain;
  static const Color accentGreen = AppColors.greenLight;
  static const Color backgroundColor = AppColors.bgLight;
  static const Color cardColor = AppColors.bgCardLight;
  static const Color textDark = AppColors.textOnLight;
  static const Color textLight = AppColors.textMutedLight;
  static Color glassmorphismColor = AppColors.glassLight;

  static const Color backgroundColorDark = AppColors.bgDark;
  static const Color cardColorDark = AppColors.bgCardDark;
  static const Color textDarkInDarkMode = AppColors.textOnDark;
  static const Color textLightInDarkMode = AppColors.textSecondaryDark;
  static Color glassmorphismColorDark = AppColors.glassDark;

  // ─── Text Theme ────────────────────────────────────────────────────────────
  static final TextTheme _lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      color: AppColors.textOnLight,
    ),
    displayMedium: GoogleFonts.manrope(
      fontWeight: FontWeight.w700,
      color: AppColors.textOnLight,
    ),
    headlineLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w700,
      color: AppColors.textOnLight,
    ),
    headlineMedium: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: AppColors.textOnLight,
    ),
    titleLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: AppColors.textOnLight,
    ),
    bodyLarge: GoogleFonts.manrope(color: AppColors.textOnLight, fontSize: 16),
    bodyMedium: GoogleFonts.manrope(
      color: AppColors.textMutedLight,
      fontSize: 14,
    ),
    labelLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  static final TextTheme _darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      color: AppColors.textOnDark,
    ),
    displayMedium: GoogleFonts.manrope(
      fontWeight: FontWeight.w700,
      color: AppColors.textOnDark,
    ),
    headlineLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w700,
      color: AppColors.textOnDark,
    ),
    headlineMedium: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: AppColors.textOnDark,
    ),
    titleLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: AppColors.textOnDark,
    ),
    bodyLarge: GoogleFonts.manrope(color: AppColors.textOnDark, fontSize: 16),
    bodyMedium: GoogleFonts.manrope(
      color: AppColors.textSecondaryDark,
      fontSize: 14,
    ),
    labelLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  // ─── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: AppColors.bgLight,
    cardColor: AppColors.bgCardLight,
    shadowColor: Colors.black.withValues(alpha: 0.06),
    splashColor: AppColors.primaryGreen.withValues(alpha: 0.12),
    highlightColor: AppColors.primaryGreen.withValues(alpha: 0.08),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryGreen,
      secondary: AppColors.primaryBlue,
      tertiary: AppColors.gold,
      surface: AppColors.bgCardLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textOnLight,
      error: AppColors.error,
      onError: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.bgCardLight,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgInputLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textMutedLight),
      floatingLabelStyle: const TextStyle(color: AppColors.primaryBlue),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryGreen,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgInputLight,
      selectedColor: AppColors.primaryGreen,
      labelStyle: GoogleFonts.manrope(
        fontSize: 13,
        color: AppColors.textOnLight,
      ),
      secondaryLabelStyle: GoogleFonts.manrope(
        fontSize: 13,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.greenPale,
      thickness: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return AppColors.primaryGreen;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.greenLight.withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.3);
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryGreen,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.textOnLight,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    textTheme: _lightTextTheme,
  );

  // ─── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: AppColors.bgDark,
    cardColor: AppColors.bgCardDark,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    splashColor: AppColors.primaryGreen.withValues(alpha: 0.12),
    highlightColor: AppColors.primaryGreen.withValues(alpha: 0.08),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryGreen,
      secondary: AppColors.primaryBlue,
      tertiary: AppColors.gold,
      surface: AppColors.bgCardDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textOnDark,
      error: AppColors.error,
      onError: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.bgCardDark,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgSurfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.blueLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: TextStyle(
        color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
      ),
      floatingLabelStyle: const TextStyle(color: AppColors.blueLight),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.greenDark,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.greenLight,
        side: const BorderSide(color: AppColors.greenLight, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.blueLight),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgSurfaceDark,
      selectedColor: AppColors.primaryGreen,
      labelStyle: GoogleFonts.manrope(
        fontSize: 13,
        color: AppColors.textOnDark,
      ),
      secondaryLabelStyle: GoogleFonts.manrope(
        fontSize: 13,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.greenMain.withValues(alpha: 0.3),
      thickness: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.greenLight;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryGreen.withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.2);
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.greenLight,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.bgSurfaceDark,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    textTheme: _darkTextTheme,
  );
}
