import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const AppColorSet light = AppColorSet(
    background: Color(0xFFF7F8F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF1E6),
    accent: Color(0xFF4F5F00),
    accentSoft: Color(0xFFD9F36A),
    onAccent: Color(0xFFFFFFFF),
    income: Color(0xFF2E7D32),
    expense: Color(0xFFB3261E),
    debtOwed: Color(0xFFF6DDD5),
    debtOwedSurface: Color(0xFF7A3E2F),
    debtLent: Color(0xFF2F5D7C),
    debtLentSurface: Color(0xFFDDEBF5),
    textPrimary: Color(0xFF171A12),
    textSecondary: Color(0xFF5D6654),
    outline: Color(0xFFD7DCCF),
    barTrack: Color(0xFFE4E8DB),
  );

  static const AppColorSet dark = AppColorSet(
    background: Color(0xFF0F100A),
    surface: Color(0xFF1D2517),
    surfaceAlt: Color(0xFF171E11),
    accent: Color(0xFFD9F36A),
    accentSoft: Color(0xFFEAF97A),
    onAccent: Color(0xFF11150B),
    income: Color(0xFF8FDF8A),
    expense: Color(0xFFF2A08C),
    debtOwed: Color(0xFFE2B5A5),
    debtOwedSurface: Color(0xFF2B1E1A),
    debtLent: Color(0xFF8FB4CF),
    debtLentSurface: Color(0xFF0A2335),
    textPrimary: Color(0xFFF1F4ED),
    textSecondary: Color(0xFF9AA38C),
    outline: Color(0xFF2B3324),
    barTrack: Color(0xFF242D1E),
  );
}

class AppColorSet {
  const AppColorSet({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.income,
    required this.expense,
    required this.debtOwed,
    required this.debtOwedSurface,
    required this.debtLent,
    required this.debtLentSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.barTrack,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color income;
  final Color expense;
  final Color debtOwed;
  final Color debtOwedSurface;
  final Color debtLent;
  final Color debtLentSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color barTrack;
}

extension AppColorsContext on BuildContext {
  AppColorSet get colors {
    final Brightness brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  }
}
