import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../logic/auth_controller.dart';
import '../logic/auth_state.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submitRecovery() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    final bool ok = await ref
        .read(authControllerProvider.notifier)
        .resetPasswordWithRecoveryCode(
          code: _code.text,
          newPassword: _password.text,
        );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _useFingerprint() async {
    await ref.read(authControllerProvider.notifier).unlockWithBiometrics();
    if (!mounted) {
      return;
    }
    if (ref.read(authControllerProvider).status == AuthStatus.unlocked) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _resetWallet() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const _ResetWalletDialog(),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(authControllerProvider.notifier).resetWallet();
    if (mounted) {
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final AuthState auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
        ),
        title: const Text('Forgot password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Recover your wallet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Use the recovery code you saved when you created the wallet. '
                'Your data will stay intact.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (auth.fingerprintEnabled && auth.biometricAvailable) ...[
                const SizedBox(height: AppSpacing.space24),
                OutlinedButton.icon(
                  onPressed: _useFingerprint,
                  icon: const Icon(PhosphorIconsRegular.fingerprint),
                  label: const Text('Unlock with fingerprint'),
                ),
              ],
              const SizedBox(height: AppSpacing.space24),
              if (auth.hasRecoveryCode)
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _code,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Recovery code',
                          hintText: 'XXXX-XXXX-XXXX-XXXX',
                          prefixIcon: Icon(PhosphorIconsRegular.key),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          prefixIcon: const Icon(PhosphorIconsRegular.lock),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? PhosphorIconsRegular.eye
                                  : PhosphorIconsRegular.eyeSlash,
                            ),
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null ||
                              value.length <
                                  AuthController.minPasswordLength) {
                            return 'Password must be at least '
                                '${AuthController.minPasswordLength} '
                                'characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) =>
                            _submitting ? null : _submitRecovery(),
                        decoration: const InputDecoration(
                          labelText: 'Confirm new password',
                          prefixIcon: Icon(PhosphorIconsRegular.lockKey),
                        ),
                        validator: (String? value) {
                          if (value != _password.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.space12),
                        Text(
                          auth.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.expense,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.space24),
                      PrimaryButton(
                        label: _submitting
                            ? 'Resetting…'
                            : 'Reset password',
                        icon: PhosphorIconsRegular.arrowRight,
                        onPressed: _submitting ? null : _submitRecovery,
                      ),
                    ],
                  ),
                )
              else
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIconsRegular.warningCircle,
                        color: colors.debtOwed,
                        size: AppSpacing.iconMd,
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Text(
                          'This wallet has no recovery code. The only way to '
                          'start again is to reset the wallet, which erases '
                          'all data.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.space32),
              Divider(color: colors.outline),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'Reset wallet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Erase the account and all transactions from this phone.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _resetWallet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.expense,
                  side: BorderSide(color: colors.expense.withValues(alpha: 0.4)),
                ),
                icon: const Icon(PhosphorIconsRegular.warningCircle),
                label: const Text('Reset wallet and erase data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetWalletDialog extends StatefulWidget {
  const _ResetWalletDialog();

  @override
  State<_ResetWalletDialog> createState() => _ResetWalletDialogState();
}

class _ResetWalletDialogState extends State<_ResetWalletDialog> {
  final TextEditingController _confirmation = TextEditingController();

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final bool confirmed = _confirmation.text.trim().toUpperCase() == 'RESET';

    return AlertDialog(
      icon: Icon(
        PhosphorIconsRegular.warningCircle,
        color: colors.expense,
      ),
      title: const Text('Reset the wallet?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This permanently deletes your password, transactions, debts and '
            'receipts. It cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          TextField(
            controller: _confirmation,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Type RESET to confirm',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              confirmed ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: colors.expense,
            foregroundColor: colors.onAccent,
          ),
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
