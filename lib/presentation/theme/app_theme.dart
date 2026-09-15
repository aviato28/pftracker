import 'package:flutter/material.dart';

/// Dark, glass-cockpit-inspired palette and type scale — the whole app is
/// designed dark-first (matches the approved mockups); there is no light
/// theme variant.
class AppColors {
  AppColors._();

  static const background = Color(0xFF0A0E13);
  static const surface = Color(0xFF121820);
  static const surfaceLow = Color(0xFF0F151C);
  static const border = Color(0xFF212B36);
  static const borderLow = Color(0xFF1D2733);
  static const divider = Color(0xFF1B2530);

  static const textPrimary = Color(0xFFF2F5F7);
  static const textMuted = Color(0xFF8A97A3);
  static const textFaint = Color(0xFF54606B);
  static const textDisabled = Color(0xFF3E4952);

  static const accent = Color(0xFF2FE6D8);
  static const onAccent = Color(0xFF06181A);
  static const accentDim = Color(0x262FE6D8);

  static const toggleOffTrack = Color(0xFF232E3A);
  static const toggleOffKnob = Color(0xFF5C6975);

  static const error = Color(0xFFFF6B6B);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Manrope',
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        error: AppColors.error,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Manrope',
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w800,
          fontSize: 19,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textFaint),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accentDim,
        selectionHandleColor: AppColors.accent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textMuted,
          selectedBackgroundColor: AppColors.accent,
          selectedForegroundColor: AppColors.onAccent,
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: AppColors.textMuted),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Monospace text style for HUD-style numeric readouts.
TextStyle dataTextStyle({required double size, FontWeight weight = FontWeight.w700, Color? color}) {
  return TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.textPrimary,
    height: 1,
  );
}
