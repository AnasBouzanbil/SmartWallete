import 'package:flutter/foundation.dart';

/// The user's locally stored account settings (never the plain password).
@immutable
class UserCredentials {
  const UserCredentials({
    required this.name,
    required this.startingBalance,
    required this.passwordHash,
    required this.fingerprintEnabled,
  });

  final String name;

  /// Total income the user had before they started tracking.
  final double startingBalance;

  /// Encoded salt:hash produced by [PasswordHasher].
  final String passwordHash;

  /// Whether fingerprint unlock is enabled.
  final bool fingerprintEnabled;

  UserCredentials copyWith({
    String? name,
    double? startingBalance,
    String? passwordHash,
    bool? fingerprintEnabled,
  }) {
    return UserCredentials(
      name: name ?? this.name,
      startingBalance: startingBalance ?? this.startingBalance,
      passwordHash: passwordHash ?? this.passwordHash,
      fingerprintEnabled: fingerprintEnabled ?? this.fingerprintEnabled,
    );
  }
}
