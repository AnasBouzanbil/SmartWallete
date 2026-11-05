import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../database/app_database.dart';

IconData categoryIcon(String key) {
  return switch (key) {
    'food' => PhosphorIconsRegular.forkKnife,
    'transport' => PhosphorIconsRegular.car,
    'bills' => PhosphorIconsRegular.receipt,
    'fun' => PhosphorIconsRegular.gameController,
    'health' => PhosphorIconsRegular.firstAid,
    'salary' => PhosphorIconsRegular.money,
    _ => PhosphorIconsRegular.tag,
  };
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.category,
    this.size = 40,
  });

  final Category category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(category.colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(
        categoryIcon(category.iconKey),
        color: color,
        size: size * 0.5,
      ),
    );
  }
}
