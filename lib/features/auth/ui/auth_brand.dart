import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key, this.subtitle});

  final String? subtitle;

  static const String logoAsset = 'assets/brand/app_logo.png';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radius12),
          child: Image.asset(
            logoAsset,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Pocket',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
