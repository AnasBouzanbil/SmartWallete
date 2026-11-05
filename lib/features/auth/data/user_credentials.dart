import 'package:flutter/foundation.dart';

@immutable
class UserCredentials {
  const UserCredentials({
    required this.name,
    required this.startingBalance,
    required this.passwordHash,
    required this.fingerprintEnabled,
    this.recoveryCodeHash,
  });

  final String name;
  final double startingBalance;
  final String passwordHash;
  final bool fingerprintEnabled;
  final String? recoveryCodeHash;

  UserCredentials copyWith({
    String? name,
    double? startingBalance,
    String? passwordHash,
    bool? fingerprintEnabled,
    String? recoveryCodeHash,
  }) {
    return UserCredentials(
      name: name ?? this.name,
      startingBalance: startingBalance ?? this.startingBalance,
      passwordHash: passwordHash ?? this.passwordHash,
      fingerprintEnabled: fingerprintEnabled ?? this.fingerprintEnabled,
      recoveryCodeHash: recoveryCodeHash ?? this.recoveryCodeHash,
    );
  }
}
