import 'package:flutter/material.dart';

import '../money/display.dart';

/// Money text that counts up / down smoothly when the value changes.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    super.key,
    required this.minor,
    this.style,
    this.masked = false,
    this.showSign = false,
  });

  final int minor;
  final TextStyle? style;
  final bool masked;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: minor.toDouble()),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Text(
          formatMinor(value.round(), masked: masked, showSign: showSign),
          style: style,
        );
      },
    );
  }
}
