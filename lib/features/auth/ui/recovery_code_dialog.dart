import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

Future<bool> showRecoveryCodeDialog(
  BuildContext context, {
  required String code,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => _RecoveryCodeDialog(code: code),
  );
  return result ?? false;
}

class _RecoveryCodeDialog extends StatelessWidget {
  const _RecoveryCodeDialog({required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery code copied.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return AlertDialog(
      icon: Icon(
        PhosphorIconsRegular.shieldCheck,
        color: colors.accent,
        size: AppSpacing.iconLg,
      ),
      title: const Text('Save your recovery code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This code is the only way to recover your wallet if you forget '
            'your password. It will not be shown again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radius16),
              border: Border.all(color: colors.outline),
            ),
            child: SelectableText(
              code,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          OutlinedButton.icon(
            onPressed: () => _copy(context),
            icon: const Icon(PhosphorIconsRegular.copy, size: AppSpacing.iconSm),
            label: const Text('Copy code'),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('I saved it'),
        ),
      ],
    );
  }
}
