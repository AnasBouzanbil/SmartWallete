import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../shell/app_shell.dart';
import '../logic/auth_controller.dart';
import '../logic/auth_state.dart';
import 'login_screen.dart';
import 'setup_screen.dart';

/// Root widget for the auth flow.
///
/// Chooses the screen from the controller state and re-locks the app when it
/// returns from the background after more than [autoLockAfter].
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, this.autoLockAfter = const Duration(seconds: 30)});

  final Duration autoLockAfter;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _pausedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final DateTime? pausedAt = _pausedAt;
        _pausedAt = null;
        if (pausedAt != null &&
            DateTime.now().difference(pausedAt) >= widget.autoLockAfter) {
          ref.read(authControllerProvider.notifier).lock();
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthStatus status =
        ref.watch(authControllerProvider.select((AuthState s) => s.status));

    return switch (status) {
      AuthStatus.loading => const _LoadingView(),
      AuthStatus.needsSetup => const SetupScreen(),
      AuthStatus.locked => const LoginScreen(),
      AuthStatus.unlocked => const AppShell(),
    };
  }
}

/// Short branded loading state shown while the account is being read.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: AppSpacing.page,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
