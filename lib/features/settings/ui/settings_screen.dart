import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pill_tabs.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/logic/auth_state.dart';
import '../../backup/ui/backup_section.dart';
import 'profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(authControllerProvider.notifier).refreshBiometricAvailability();
    });
  }

  Future<void> _toggleFingerprint(bool enable) async {
    final AuthController controller = ref.read(authControllerProvider.notifier);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (!enable) {
      await controller.setFingerprint(enabled: false, password: '');
      messenger.showSnackBar(
        const SnackBar(content: Text('Fingerprint unlock turned off.')),
      );
      return;
    }

    final String? password = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _PasswordPrompt(),
    );
    if (password == null || password.isEmpty) {
      return;
    }
    final bool ok = await controller.setFingerprint(
      enabled: true,
      password: password,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Fingerprint unlock turned on.'
              : (ref.read(authControllerProvider).errorMessage ??
                    'Could not turn on fingerprint.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final AuthState auth = ref.watch(authControllerProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final String name = auth.name.trim();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space24,
          ),
          children: <Widget>[
            Text(
              'Settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Manage your wallet data and preferences.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            AppCard(
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const ProfileScreen(),
                  ),
                );
              },
              child: Row(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      name.isEmpty ? 'W' : name.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name.isEmpty ? 'My wallet' : name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'View and edit profile',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    PhosphorIconsRegular.caretRight,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            const SectionHeader(title: 'Appearance'),
            const SizedBox(height: AppSpacing.space8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        PhosphorIconsRegular.circleHalfTilt,
                        color: colors.textPrimary,
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Text(
                        'Theme',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    'Choose how Pocket looks.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  PillTabs(
                    index: themeMode == ThemeMode.light ? 0 : 1,
                    labels: const <String>['Light', 'Dark'],
                    onChanged: (int index) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setMode(
                            index == 0 ? ThemeMode.light : ThemeMode.dark,
                          );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            const SectionHeader(title: 'Security'),
            const SizedBox(height: AppSpacing.space8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(
                      PhosphorIconsRegular.lockSimple,
                      color: colors.textPrimary,
                    ),
                    title: const Text('Lock now'),
                    subtitle: Text(
                      'Also locks automatically after 30 seconds away.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(authControllerProvider.notifier).lock();
                    },
                  ),
                  Divider(height: 1, color: colors.outline),
                  SwitchListTile(
                    secondary: Icon(
                      PhosphorIconsRegular.fingerprint,
                      color: colors.textPrimary,
                    ),
                    title: const Text('Fingerprint unlock'),
                    subtitle: Text(
                      auth.biometricAvailable
                          ? 'Skip typing your password.'
                          : 'Not available on this device.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    activeTrackColor: colors.accent,
                    value: auth.fingerprintEnabled,
                    onChanged: auth.biometricAvailable
                        ? _toggleFingerprint
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            const SectionHeader(title: 'Data'),
            const SizedBox(height: AppSpacing.space12),
            const BackupSection(),
            const SizedBox(height: AppSpacing.space32),
            Center(
              child: Text(
                'Pocket · Your data never leaves this phone',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordPrompt extends StatefulWidget {
  const _PasswordPrompt();

  @override
  State<_PasswordPrompt> createState() => _PasswordPromptState();
}

class _PasswordPromptState extends State<_PasswordPrompt> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm your password'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: _obscure,
        onSubmitted: (String v) => Navigator.of(context).pop(v),
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? PhosphorIconsRegular.eye
                  : PhosphorIconsRegular.eyeSlash,
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Turn on'),
        ),
      ],
    );
  }
}
