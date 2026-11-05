import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Result of a biometric unlock attempt.
enum BiometricResult {
  /// Authenticated successfully.
  success,

  /// The user cancelled or dismissed the prompt.
  cancelled,

  /// No biometric hardware, or none enrolled.
  unavailable,

  /// Temporarily locked out after too many attempts.
  lockedOut,

  /// Any other failure.
  failed,
}

/// Thin wrapper around [LocalAuthentication] so the rest of the app does not
/// depend on the plugin directly, and so it can be faked in tests.
abstract interface class BiometricService {
  /// True when the device has biometric hardware with an enrolled biometric.
  Future<bool> isAvailable();

  /// Prompts for a biometric unlock.
  Future<BiometricResult> authenticate();
}

/// Real implementation using the `local_auth` plugin.
///
/// All plugin failures are mapped to a [BiometricResult] so callers never
/// have to catch exceptions.
class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return false;
      }
      final List<BiometricType> enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<BiometricResult> authenticate() async {
    try {
      final bool ok = await _auth.authenticate(
        localizedReason: 'Unlock Smart Wallet',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricResult.success : BiometricResult.cancelled;
    } on LocalAuthException catch (e) {
      return _mapException(e.code);
    } on PlatformException {
      return BiometricResult.failed;
    }
  }

  BiometricResult _mapException(LocalAuthExceptionCode code) {
    return switch (code) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.userRequestedFallback =>
        BiometricResult.cancelled,
      LocalAuthExceptionCode.noCredentialsSet ||
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noBiometricHardware ||
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
        BiometricResult.unavailable,
      LocalAuthExceptionCode.temporaryLockout ||
      LocalAuthExceptionCode.biometricLockout =>
        BiometricResult.lockedOut,
      _ => BiometricResult.failed,
    };
  }
}
