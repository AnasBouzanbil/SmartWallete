import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/storage/receipt_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Loads a relative receipt path and shows a simple placeholder if missing.
class ReceiptImage extends StatelessWidget {
  const ReceiptImage({
    super.key,
    required this.imagePath,
    this.height = 180,
    this.borderRadius = AppSpacing.radius16,
  });

  final String imagePath;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;

    return FutureBuilder<String>(
      future: ReceiptStore.absolutePath(imagePath),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (!snapshot.hasData) {
          return _Placeholder(
            height: height,
            borderRadius: borderRadius,
            colors: colors,
          );
        }

        final File file = File(snapshot.data!);
        if (!file.existsSync()) {
          return _Placeholder(
            height: height,
            borderRadius: borderRadius,
            colors: colors,
            label: 'Receipt photo missing',
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stack,
            ) {
              return _Placeholder(
                height: height,
                borderRadius: borderRadius,
                colors: colors,
                label: 'Receipt photo missing',
              );
            },
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.height,
    required this.borderRadius,
    required this.colors,
    this.label = 'No receipt photo',
  });

  final double height;
  final double borderRadius;
  final AppColorSet colors;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            PhosphorIconsRegular.receipt,
            size: AppSpacing.iconLg,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
