import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColorSet colors, Brightness brightness) {
    final ThemeData base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    );

    final TextTheme textTheme = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary);

    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: brightness,
        ).copyWith(
          primary: colors.accent,
          onPrimary: colors.onAccent,
          secondary: colors.accentSoft,
          onSecondary: brightness == Brightness.dark
              ? colors.onAccent
              : colors.textPrimary,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          onSurfaceVariant: colors.textSecondary,
          surfaceContainerHighest: colors.surfaceAlt,
          surfaceContainerLow: colors.background,
          outline: colors.outline,
          outlineVariant: colors.outline,
          error: colors.expense,
          onError: colors.onAccent,
        );

    final RoundedRectangleBorder rounded16 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius16),
    );
    final RoundedRectangleBorder rounded20 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius20),
    );
    const StadiumBorder pill = StadiumBorder();

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        elevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
      ),
      textTheme: textTheme,
      iconTheme: IconThemeData(color: colors.textSecondary),
      dividerTheme: DividerThemeData(color: colors.outline, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: rounded20,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceAlt,
        contentPadding: AppSpacing.field,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        prefixIconColor: colors.textSecondary,
        suffixIconColor: colors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius16),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius16),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius16),
          borderSide: BorderSide(color: colors.expense, width: 1.5),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.expense),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          disabledBackgroundColor: colors.surface,
          disabledForegroundColor: colors.textSecondary,
          minimumSize: const Size(0, AppSpacing.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
          shape: pill,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          disabledForegroundColor: colors.textSecondary,
          minimumSize: const Size(0, AppSpacing.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
          side: BorderSide(color: colors.outline),
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          disabledForegroundColor: colors.textSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          shape: rounded16,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.textPrimary,
          backgroundColor: colors.surface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        indicatorColor: colors.accent,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) => textTheme.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.onAccent
                : colors.textSecondary,
            size: AppSpacing.iconMd,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: rounded20,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radius28),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceAlt,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: rounded16,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: colors.surface,
        headerForegroundColor: colors.textPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? colors.onAccent
              : colors.textPrimary,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? colors.accent
              : Colors.transparent,
        ),
        todayBorder: BorderSide(color: colors.accent),
        shape: rounded20,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.surfaceAlt,
        selectedColor: colors.accent,
        disabledColor: colors.surface,
        labelStyle: textTheme.labelLarge?.copyWith(color: colors.textPrimary),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colors.onAccent,
        ),
        side: BorderSide.none,
        shape: pill,
      ),
    );
  }
}
