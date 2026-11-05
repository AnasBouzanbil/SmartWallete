import 'package:smartwallete/features/auth/data/biometric_service.dart';
import 'package:smartwallete/features/auth/data/credentials_store.dart';
import 'package:smartwallete/features/auth/data/user_credentials.dart';
import 'package:smartwallete/features/auth/data/wallet_reset_service.dart';

/// In-memory [CredentialsStore] for tests. No platform keychain involved.
///
/// Set [throwOnRead] to simulate a storage failure (e.g. a missing plugin).
class FakeCredentialsStore implements CredentialsStore {
  FakeCredentialsStore([this._credentials, this.throwOnRead = false]);

  UserCredentials? _credentials;
  bool throwOnRead;

  @override
  Future<UserCredentials?> read() async {
    if (throwOnRead) {
      throw Exception('storage unavailable');
    }
    return _credentials;
  }

  @override
  Future<void> write(UserCredentials credentials) async {
    _credentials = credentials;
  }

  @override
  Future<void> clear() async {
    _credentials = null;
  }
}

/// In-memory [WalletResetService] for tests.
class FakeWalletResetService implements WalletResetService {
  bool resetCalled = false;

  @override
  Future<void> reset() async {
    resetCalled = true;
  }
}

/// Controllable [BiometricService] for tests.
class FakeBiometricService implements BiometricService {
  FakeBiometricService({
    this.available = false,
    this.result = BiometricResult.cancelled,
  });

  bool available;
  BiometricResult result;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticate() async => result;
}
