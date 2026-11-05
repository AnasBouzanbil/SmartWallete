import 'package:flutter/foundation.dart';

/// High-level status of the authentication flow.
enum AuthStatus {
  /// App is still checking whether an account exists.
  loading,

  /// No account yet — the setup screen must be shown.
  needsSetup,

  /// An account exists and the app is locked — login screen must be shown.
  locked,

  /// The user is authenticated — the home screen must be shown.
  unlocked,
}

/// Immutable state exposed by the auth controller.
@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.name = '',
    this.startingBalance = 0,
    this.fingerprintEnabled = false,
    this.biometricAvailable = false,
    this.errorMessage,
    this.lockedUntil,
    this.failedAttempts = 0,
  });

  const AuthState.loading()
      : status = AuthStatus.loading,
        name = '',
        startingBalance = 0,
        fingerprintEnabled = false,
        biometricAvailable = false,
        errorMessage = null,
        lockedUntil = null,
        failedAttempts = 0;

  final AuthStatus status;
  final String name;
  final double startingBalance;
  final bool fingerprintEnabled;

  /// Whether the device can offer fingerprint unlock right now.
  final bool biometricAvailable;

  /// Error message to show under the password field (or on setup).
  final String? errorMessage;

  /// When set, password input stays disabled until this moment passes.
  final DateTime? lockedUntil;

  /// Number of consecutive wrong password attempts.
  final int failedAttempts;

  /// True while the wrong-password lockout is active.
  bool isLockedOutAt(DateTime now) =>
      lockedUntil != null && now.isBefore(lockedUntil!);

  /// Seconds remaining in the lockout (0 when not locked out).
  int secondsRemainingAt(DateTime now) {
    if (lockedUntil == null) {
      return 0;
    }
    final int seconds = lockedUntil!.difference(now).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  AuthState copyWith({
    AuthStatus? status,
    String? name,
    double? startingBalance,
    bool? fingerprintEnabled,
    bool? biometricAvailable,
    String? errorMessage,
    DateTime? lockedUntil,
    int? failedAttempts,
    bool clearError = false,
    bool clearLockout = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      name: name ?? this.name,
      startingBalance: startingBalance ?? this.startingBalance,
      fingerprintEnabled: fingerprintEnabled ?? this.fingerprintEnabled,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lockedUntil: clearLockout ? null : (lockedUntil ?? this.lockedUntil),
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }
}
