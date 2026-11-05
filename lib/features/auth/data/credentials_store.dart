import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'user_credentials.dart';

abstract interface class CredentialsStore {
  Future<UserCredentials?> read();

  Future<void> write(UserCredentials credentials);

  Future<void> clear();
}

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
  static const String _recoveryKey = 'recovery_code_hash';

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
    final String recoveryRaw = await _storage.read(key: _recoveryKey) ?? '';

    return UserCredentials(
      name: name,
      startingBalance: double.tryParse(balanceRaw) ?? 0,
      passwordHash: hash,
      fingerprintEnabled: fingerprintRaw == 'true',
      recoveryCodeHash: recoveryRaw.isEmpty ? null : recoveryRaw,
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
    final String? recovery = credentials.recoveryCodeHash;
    if (recovery == null || recovery.isEmpty) {
      await _storage.delete(key: _recoveryKey);
    } else {
      await _storage.write(key: _recoveryKey, value: recovery);
    }
  }

  @override
  Future<void> clear() => _storage.deleteAll();
}
