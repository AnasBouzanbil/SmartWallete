import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../logic/auth_controller.dart';
import '../logic/auth_state.dart';
import 'auth_brand.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _password = TextEditingController();
  Timer? _ticker;
  bool _promptedBiometrics = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptBiometrics());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _password.dispose();
    super.dispose();
  }

  Future<void> _maybePromptBiometrics() async {
    final AuthState state = ref.read(authControllerProvider);
    if (_promptedBiometrics ||
        !state.fingerprintEnabled ||
        !state.biometricAvailable) {
      return;
    }
    _promptedBiometrics = true;
    await ref.read(authControllerProvider.notifier).unlockWithBiometrics();
  }

  Future<void> _submit() async {
    await ref
        .read(authControllerProvider.notifier)
        .unlockWithPassword(_password.text);
    _password.clear();
  }

  Future<void> _openForgotPassword() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final AuthState auth = ref.watch(authControllerProvider);
    final DateTime now = DateTime.now();
    final bool lockedOut = auth.isLockedOutAt(now);
    final int secondsLeft = auth.secondsRemainingAt(now);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.9, -1.0),
            radius: 1.1,
            colors: <Color>[
              colors.accent.withValues(alpha: 0.16),
              colors.background,
            ],
          ),
        ),
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space16),
                const AuthBrand(),
                const SizedBox(height: AppSpacing.space32),
                Text(
                  'Welcome back',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  auth.name.isEmpty
                      ? 'Enter your password to open your wallet.'
                      : 'Hi ${auth.name}, enter your password to continue.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space32),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  enabled: !lockedOut,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => lockedOut ? null : _submit(),
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
                    errorText: lockedOut
                        ? 'Too many attempts. Try again in ${secondsLeft}s.'
                        : auth.errorMessage,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                PrimaryButton(
                  label: lockedOut ? 'Locked (${secondsLeft}s)' : 'Unlock',
                  icon: PhosphorIconsRegular.arrowRight,
                  onPressed: lockedOut ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.space8),
                TextButton(
                  onPressed: lockedOut ? null : _openForgotPassword,
                  child: const Text('Forgot password?'),
                ),
                if (auth.fingerprintEnabled && auth.biometricAvailable) ...[
                  const SizedBox(height: AppSpacing.space16),
                  OutlinedButton.icon(
                    onPressed: lockedOut
                        ? null
                        : () => ref
                            .read(authControllerProvider.notifier)
                            .unlockWithBiometrics(),
                    icon: const Icon(PhosphorIconsRegular.fingerprint),
                    label: const Text('Use fingerprint'),
                  ),
                ],
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
