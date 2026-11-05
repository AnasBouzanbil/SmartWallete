import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../logic/auth_controller.dart';
import '../logic/auth_state.dart';

/// Locked screen: unlock with password or fingerprint.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _password = TextEditingController();
  Timer? _ticker;
  bool _promptedBiometrics = false;

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

  /// Prompts for fingerprint once, automatically, when the screen opens.
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthState auth = ref.watch(authControllerProvider);
    final DateTime now = DateTime.now();
    final bool lockedOut = auth.isLockedOutAt(now);
    final int secondsLeft = auth.secondsRemainingAt(now);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  PhosphorIconsRegular.lock,
                  size: AppSpacing.iconXl,
                  color: context.colors.accent,
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  'Welcome back${auth.name.isEmpty ? '' : ', ${auth.name}'}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Enter your password to unlock.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                TextField(
                  controller: _password,
                  obscureText: true,
                  enabled: !lockedOut,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => lockedOut ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: lockedOut
                        ? 'Too many attempts. Try again in ${secondsLeft}s.'
                        : auth.errorMessage,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                PrimaryButton(
                  label: lockedOut ? 'Locked (${secondsLeft}s)' : 'Unlock',
                  onPressed: lockedOut ? null : _submit,
                ),
                if (auth.fingerprintEnabled && auth.biometricAvailable) ...[
                  const SizedBox(height: AppSpacing.space12),
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
    );
  }
}
