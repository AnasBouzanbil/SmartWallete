import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'user_credentials.dart';

/// Persistence for the account settings.
///
/// An interface so tests can inject an in-memory fake instead of touching
/// the platform keychain.
abstract interface class CredentialsStore {
  /// Reads the stored credentials, or null when no account exists yet.
  Future<UserCredentials?> read();

  /// Writes (or replaces) the stored credentials.
  Future<void> write(UserCredentials credentials);

  /// Removes everything (used to reset the app).
  Future<void> clear();
}

/// Real implementation backed by the platform secure storage.
///
/// Only non-secret settings and the salt+hash are stored — never the password.
class SecureCredentialsStore implements CredentialsStore {
  SecureCredentialsStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  final FlutterSecureStorage _storage;

  static const String _nameKey = 'user_name';
  static const String _balanceKey = 'starting_balance';
  static const String _hashKey = 'password_hash';
  static const String _fingerprintKey = 'fingerprint_enabled';

  @override
  Future<UserCredentials?> read() async {
    final String? hash = await _storage.read(key: _hashKey);
    if (hash == null) {
      return null;
    }

    final String name = await _storage.read(key: _nameKey) ?? '';
    final String balanceRaw = await _storage.read(key: _balanceKey) ?? '0';
    final String fingerprintRaw =
        await _storage.read(key: _fingerprintKey) ?? 'false';

    return UserCredentials(
      name: name,
      startingBalance: double.tryParse(balanceRaw) ?? 0,
      passwordHash: hash,
      fingerprintEnabled: fingerprintRaw == 'true',
    );
  }

  @override
  Future<void> write(UserCredentials credentials) async {
    await _storage.write(key: _nameKey, value: credentials.name);
    await _storage.write(
      key: _balanceKey,
      value: credentials.startingBalance.toString(),
    );
    await _storage.write(key: _hashKey, value: credentials.passwordHash);
    await _storage.write(
      key: _fingerprintKey,
      value: credentials.fingerprintEnabled.toString(),
    );
  }

  @override
  Future<void> clear() => _storage.deleteAll();
}
