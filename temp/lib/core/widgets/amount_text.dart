import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AmountType { income, expense, neutral }

/// Money amount with tabular figures so digits line up.
/// Colored by [type]: green for income, red for expense.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    super.key,
    required this.type,
    this.style,
    this.showSign = true,
  });

  final double amount;
  final AmountType type;
  final TextStyle? style;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;

    final Color color = switch (type) {
      AmountType.income => colors.income,
      AmountType.expense => colors.expense,
      AmountType.neutral => colors.textPrimary,
    };

    final TextStyle resolved =
        style ?? Theme.of(context).textTheme.titleLarge ?? const TextStyle();

    return Text(
      _format(amount, type, showSign),
      style: resolved.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  static String _format(double value, AmountType type, bool showSign) {
    final bool negative = value < 0;
    final List<String> parts = value.abs().toStringAsFixed(2).split('.');
    final String digits = parts[0];

    final StringBuffer grouped = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        grouped.write(',');
      }
      grouped.write(digits[i]);
    }

    String sign = '';
    if (negative) {
      sign = '-';
    } else if (showSign && type == AmountType.income) {
      sign = '+';
    } else if (showSign && type == AmountType.expense) {
      sign = '-';
    }

    return '$sign$grouped.${parts[1]}';
  }
}
