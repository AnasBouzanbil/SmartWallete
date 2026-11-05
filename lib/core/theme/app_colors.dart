import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

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
  AppColorSet get colors => AppColors.dark;
}
