import 'package:flutter/material.dart';

/// The single source of truth for every color in the app.
/// Never use raw colors outside lib/core/theme.
class AppColors {
  const AppColors._();

  static const AppColorSet light = AppColorSet(
    background: Color(0xFFF4F6F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFECEFF1),
    accent: Color(0xFF0E7C86),
    onAccent: Color(0xFFFFFFFF),
    income: Color(0xFF17803D),
    expense: Color(0xFFB42318),
    textPrimary: Color(0xFF14181A),
    textSecondary: Color(0xFF5C6670),
    outline: Color(0xFFD7DDE1),
  );

  static const AppColorSet dark = AppColorSet(
    background: Color(0xFF101416),
    surface: Color(0xFF171C1F),
    surfaceAlt: Color(0xFF232A2E),
    accent: Color(0xFF3FB8C9),
    onAccent: Color(0xFF06272D),
    income: Color(0xFF46C176),
    expense: Color(0xFFE5736A),
    textPrimary: Color(0xFFECF1F3),
    textSecondary: Color(0xFF9AA5AD),
    outline: Color(0xFF2E363B),
  );
}

/// One set of color tokens, used for both light and dark mode.
class AppColorSet {
  const AppColorSet({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.accent,
    required this.onAccent,
    required this.income,
    required this.expense,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color accent;
  final Color onAccent;
  final Color income;
  final Color expense;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
}

/// Shortcut so widgets can read semantic colors of the current brightness:
/// `context.colors.income`, `context.colors.expense`, ...
extension AppColorsContext on BuildContext {
  AppColorSet get colors {
    final Brightness brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  }
}
