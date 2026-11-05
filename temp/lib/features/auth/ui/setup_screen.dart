import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../logic/auth_controller.dart';
import '../logic/auth_state.dart';

/// First-run screen: create the local account.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _balance = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _confirm.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    await ref.read(authControllerProvider.notifier).createAccount(
          name: _name.text,
          password: _password.text,
          startingBalance: double.parse(_balance.text.trim()),
        );
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? loadError =
        ref.watch(authControllerProvider.select((AuthState s) => s.errorMessage));

    return Scaffold(
      appBar: AppBar(title: const Text('Set up Smart Wallet')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Create your local account. Everything stays on this phone.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                if (loadError != null) ...[
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    loadError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.colors.expense,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space24),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Your name'),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (String? value) {
                    if (value == null ||
                        value.length < AuthController.minPasswordLength) {
                      return 'Password must be at least '
                          '${AuthController.minPasswordLength} characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space16),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                  validator: (String? value) {
                    if (value != _password.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space16),
                TextFormField(
                  controller: _balance,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Starting balance (total income so far)',
                  ),
                  validator: (String? value) {
                    final double? parsed = double.tryParse(
                      (value ?? '').trim(),
                    );
                    if (parsed == null) {
                      return 'Enter a number.';
                    }
                    if (parsed < 0) {
                      return 'Balance cannot be negative.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space24),
                AppCard(
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.info,
                        size: AppSpacing.iconMd,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Text(
                          'If you forget your password, your data cannot be '
                          'recovered.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                PrimaryButton(
                  label: _submitting ? 'Creating…' : 'Create account',
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
