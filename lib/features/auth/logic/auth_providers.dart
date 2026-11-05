import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/biometric_service.dart';
import '../data/credentials_store.dart';
import '../data/password_hasher.dart';

/// The credentials store used by the auth feature.
///
/// Overridden in tests with an in-memory fake.
final Provider<CredentialsStore> credentialsStoreProvider =
    Provider<CredentialsStore>((ref) => SecureCredentialsStore());

/// The password hasher used by the auth feature.
final Provider<PasswordHasher> passwordHasherProvider =
    Provider<PasswordHasher>((ref) => const PasswordHasher());

/// The biometric service used by the auth feature.
///
/// Overridden in tests with a fake.
final Provider<BiometricService> biometricServiceProvider =
    Provider<BiometricService>((ref) => LocalAuthBiometricService());
