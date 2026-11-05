import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/recovery_code.dart';
import '../logic/auth_controller.dart';
import '../logic/auth_state.dart';
import 'auth_brand.dart';
import 'recovery_code_dialog.dart';

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
  bool _obscure = true;

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

    final String recoveryCode = RecoveryCode.generate();
    final bool saved = await showRecoveryCodeDialog(
      context,
      code: recoveryCode,
    );
    if (!saved || !mounted) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).createAccount(
            name: _name.text,
            password: _password.text,
            startingBalance: double.parse(_balance.text.trim()),
            recoveryCode: recoveryCode,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the wallet.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final String? loadError = ref.watch(
      authControllerProvider.select((AuthState s) => s.errorMessage),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space16),
                const AuthBrand(subtitle: 'Your money, only on this phone'),
                const SizedBox(height: AppSpacing.space32),
                Text(
                  'Create your wallet',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Set a password to protect your data. It never leaves '
                  'this device.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (loadError != null) ...[
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    loadError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.expense,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space24),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(PhosphorIconsRegular.user),
                  ),
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
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(PhosphorIconsRegular.lock),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? PhosphorIconsRegular.eye
                            : PhosphorIconsRegular.eyeSlash,
                      ),
                    ),
                  ),
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
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(PhosphorIconsRegular.lockKey),
                  ),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.,]'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Starting balance (DH)',
                    hintText: '0.00',
                    prefixIcon: Icon(PhosphorIconsRegular.coins),
                  ),
                  validator: (String? value) {
                    final double? parsed = double.tryParse(
                      (value ?? '').trim().replaceAll(',', ''),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIconsRegular.shieldCheck,
                        size: AppSpacing.iconMd,
                        color: colors.accent,
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Text(
                          'You will get a recovery code next. Keep it safe — '
                          'it is the only way to recover your wallet if you '
                          'forget your password.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                PrimaryButton(
                  label: _submitting ? 'Creating…' : 'Create wallet',
                  icon: PhosphorIconsRegular.arrowRight,
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
