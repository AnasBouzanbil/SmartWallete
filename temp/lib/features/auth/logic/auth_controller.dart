import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/biometric_service.dart';
import '../data/credentials_store.dart';
import '../data/password_hasher.dart';
import '../data/user_credentials.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

/// Drives the whole login lifecycle: setup, unlock, lock and auto-lock.
///
/// States: loading -> needsSetup (first run) or locked (account exists),
/// and locked -> unlocked after a successful password or fingerprint unlock.
class AuthController extends Notifier<AuthState> {
  static const int minPasswordLength = 6;
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 30);

  CredentialsStore get _store => ref.read(credentialsStoreProvider);
  PasswordHasher get _hasher => ref.read(passwordHasherProvider);
  BiometricService get _biometrics => ref.read(biometricServiceProvider);

  @override
  AuthState build() {
    // Kick off the initial load; the UI shows the loading state until done.
    Future.microtask(_load);
    return const AuthState.loading();
  }

  /// Checks whether an account exists and moves to the right screen.
  ///
  /// Never leaves the app stuck on the loading state: if storage fails, it
  /// falls back to the setup screen and shows a message.
  Future<void> _load() async {
    try {
      final UserCredentials? stored = await _store.read();
      final bool biometricAvailable = await _safeBiometricAvailable();

      if (stored == null) {
        state = AuthState(
          status: AuthStatus.needsSetup,
          biometricAvailable: biometricAvailable,
        );
        return;
      }

      state = AuthState(
        status: AuthStatus.locked,
        name: stored.name,
        startingBalance: stored.startingBalance,
        fingerprintEnabled: stored.fingerprintEnabled,
        biometricAvailable: biometricAvailable,
      );
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.needsSetup,
        errorMessage: 'Could not read stored data. Please set up again.',
      );
    }
  }

  Future<bool> _safeBiometricAvailable() async {
    try {
      return await _biometrics.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Creates the account and unlocks the app.
  ///
  /// Validation errors are returned as field errors by the UI; this method
  /// assumes the input is already valid.
  Future<void> createAccount({
    required String name,
    required String password,
    required double startingBalance,
  }) async {
    final PasswordHash hashed = await _hasher.hash(password);
    final UserCredentials credentials = UserCredentials(
      name: name.trim(),
      startingBalance: startingBalance,
      passwordHash: hashed.encode(),
      fingerprintEnabled: false,
    );
    await _store.write(credentials);
    state = AuthState(
      status: AuthStatus.unlocked,
      name: credentials.name,
      startingBalance: credentials.startingBalance,
      fingerprintEnabled: false,
      biometricAvailable: state.biometricAvailable,
    );
  }

  /// Attempts to unlock with [password].
  Future<void> unlockWithPassword(String password) async {
    final DateTime now = DateTime.now();

    if (state.isLockedOutAt(now)) {
      return;
    }

    final UserCredentials? stored = await _store.read();
    if (stored == null) {
      await _load();
      return;
    }

    final PasswordHash? hash = PasswordHash.tryDecode(stored.passwordHash);
    final bool ok = hash != null && await _hasher.verify(password, hash);

    if (ok) {
      state = state.copyWith(
        status: AuthStatus.unlocked,
        clearError: true,
        clearLockout: true,
        failedAttempts: 0,
      );
      return;
    }

    final int attempts = state.failedAttempts + 1;
    if (attempts >= maxFailedAttempts) {
      state = state.copyWith(
        failedAttempts: 0,
        lockedUntil: now.add(lockoutDuration),
        errorMessage: 'Too many attempts. Try again in 30 seconds.',
      );
    } else {
      state = state.copyWith(
        failedAttempts: attempts,
        errorMessage: 'Wrong password. Please try again.',
      );
    }
  }

  /// Attempts to unlock with a fingerprint.
  Future<void> unlockWithBiometrics() async {
    final UserCredentials? stored = await _store.read();
    if (stored == null || !stored.fingerprintEnabled) {
      return;
    }

    final BiometricResult result = await _biometrics.authenticate();
    switch (result) {
      case BiometricResult.success:
        state = state.copyWith(
          status: AuthStatus.unlocked,
          clearError: true,
          clearLockout: true,
          failedAttempts: 0,
        );
      case BiometricResult.cancelled:
        // Silent — the user chose to fall back to the password.
        break;
      case BiometricResult.unavailable:
        state = state.copyWith(
          errorMessage: 'Fingerprint is not available. Use your password.',
          biometricAvailable: false,
        );
      case BiometricResult.lockedOut:
        state = state.copyWith(
          errorMessage:
              'Fingerprint is temporarily locked. Use your password.',
        );
      case BiometricResult.failed:
        state = state.copyWith(
          errorMessage: 'Fingerprint failed. Use your password.',
        );
    }
  }

  /// Enables or disables fingerprint login.
  ///
  /// Turning it on requires [password] to match the stored hash.
  Future<bool> setFingerprint({
    required bool enabled,
    required String password,
  }) async {
    final UserCredentials? stored = await _store.read();
    if (stored == null) {
      return false;
    }

    if (enabled) {
      final PasswordHash? hash = PasswordHash.tryDecode(stored.passwordHash);
      final bool ok = hash != null && await _hasher.verify(password, hash);
      if (!ok) {
        state = state.copyWith(errorMessage: 'Wrong password.');
        return false;
      }
      if (!await _safeBiometricAvailable()) {
        state = state.copyWith(
          errorMessage: 'Fingerprint is not available on this device.',
          biometricAvailable: false,
        );
        return false;
      }
    }

    await _store.write(stored.copyWith(fingerprintEnabled: enabled));
    state = state.copyWith(
      fingerprintEnabled: enabled,
      clearError: true,
    );
    return true;
  }

  /// Locks the app (used by the lock button and auto-lock).
  void lock() {
    if (state.status != AuthStatus.unlocked) {
      return;
    }
    state = state.copyWith(
      status: AuthStatus.locked,
      clearError: true,
      clearLockout: true,
      failedAttempts: 0,
    );
  }
}

/// The auth controller provider.
final NotifierProvider<AuthController, AuthState> authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
