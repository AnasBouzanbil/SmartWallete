import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../logic/auth_controller.dart';
import '../logic/auth_state.dart';

/// Temporary home screen shown after unlock.
///
/// Real features (transactions, debts, stats) come in later tasks.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  Future<void> _toggleFingerprint(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    if (!enable) {
      await ref
          .read(authControllerProvider.notifier)
          .setFingerprint(enabled: false, password: '');
      return;
    }

    final String? password = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _PasswordPromptDialog(),
    );
    if (password == null) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .setFingerprint(enabled: true, password: password);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AuthState auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Wallet'),
        actions: [
          IconButton(
            tooltip: 'Lock',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).lock(),
            icon: const Icon(PhosphorIconsRegular.lockSimple),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text('Hello, ${auth.name}', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Here is your starting point.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Starting balance',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                AmountText(auth.startingBalance, type: AmountType.income),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.space8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fingerprint login'),
                  subtitle: Text(
                    auth.biometricAvailable
                        ? 'Unlock with your fingerprint'
                        : 'Not available on this device',
                  ),
                  value: auth.fingerprintEnabled,
                  onChanged: !auth.biometricAvailable
                      ? null
                      : (bool value) =>
                          _toggleFingerprint(context, ref, value),
                ),
                if (auth.errorMessage != null)
                  Text(
                    auth.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.colors.expense,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog that asks for the current password before enabling fingerprint.
class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog();

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm password'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Password'),
        onSubmitted: (String value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
