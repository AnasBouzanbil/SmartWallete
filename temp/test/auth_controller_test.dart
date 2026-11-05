import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/features/auth/data/biometric_service.dart';
import 'package:smartwallete/features/auth/data/password_hasher.dart';
import 'package:smartwallete/features/auth/data/user_credentials.dart';
import 'package:smartwallete/features/auth/logic/auth_controller.dart';
import 'package:smartwallete/features/auth/logic/auth_providers.dart';
import 'package:smartwallete/features/auth/logic/auth_state.dart';

import 'fakes.dart';

void main() {
  const PasswordHasher hasher = PasswordHasher(iterations: 1000);

  /// Builds a container with fakes and waits for the initial load to finish.
  Future<ProviderContainer> makeContainer({
    FakeCredentialsStore? store,
    FakeBiometricService? biometrics,
  }) async {
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        credentialsStoreProvider.overrideWithValue(
          store ?? FakeCredentialsStore(),
        ),
        passwordHasherProvider.overrideWithValue(hasher),
        biometricServiceProvider.overrideWithValue(
          biometrics ?? FakeBiometricService(),
        ),
      ],
    );
    // Let the controller's initial async load complete.
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  group('AuthController', () {
    test('starts in needsSetup when no account exists', () async {
      final ProviderContainer container = await makeContainer();

      expect(container.read(authControllerProvider).status,
          AuthStatus.needsSetup);
    });

    test('storage failure falls back to needsSetup instead of hanging',
        () async {
      final ProviderContainer container = await makeContainer(
        store: FakeCredentialsStore(null, true),
      );

      final AuthState state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.needsSetup);
      expect(state.errorMessage, isNotNull);
    });

    test('createAccount moves to unlocked with the entered values', () async {
      final ProviderContainer container = await makeContainer();
      final AuthController controller =
          container.read(authControllerProvider.notifier);

      await controller.createAccount(
        name: 'Sara',
        password: 'secret1',
        startingBalance: 1500,
      );

      final AuthState state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unlocked);
      expect(state.name, 'Sara');
      expect(state.startingBalance, 1500);
      expect(state.fingerprintEnabled, isFalse);
    });

    test('with an existing account it starts locked', () async {
      final store = FakeCredentialsStore();
      await store.write(await _credentials(hasher, 'secret1'));

      final ProviderContainer container = await makeContainer(store: store);

      expect(container.read(authControllerProvider).status, AuthStatus.locked);
    });

    test('correct password unlocks', () async {
      final store = FakeCredentialsStore();
      await store.write(await _credentials(hasher, 'secret1'));
      final ProviderContainer container = await makeContainer(store: store);

      await container
          .read(authControllerProvider.notifier)
          .unlockWithPassword('secret1');

      expect(container.read(authControllerProvider).status,
          AuthStatus.unlocked);
    });

    test('wrong password shows an error and stays locked', () async {
      final store = FakeCredentialsStore();
      await store.write(await _credentials(hasher, 'secret1'));
      final ProviderContainer container = await makeContainer(store: store);

      await container
          .read(authControllerProvider.notifier)
          .unlockWithPassword('nope');

      final AuthState state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.locked);
      expect(state.errorMessage, isNotNull);
      expect(state.failedAttempts, 1);
    });

    test('locks out after 5 wrong attempts with a countdown', () async {
      final store = FakeCredentialsStore();
      await store.write(await _credentials(hasher, 'secret1'));
      final ProviderContainer container = await makeContainer(store: store);
      final AuthController controller =
          container.read(authControllerProvider.notifier);

      for (int i = 0; i < AuthController.maxFailedAttempts; i++) {
        await controller.unlockWithPassword('wrong');
      }

      final AuthState state = container.read(authControllerProvider);
      expect(state.isLockedOutAt(DateTime.now()), isTrue);
      expect(state.secondsRemainingAt(DateTime.now()), greaterThan(0));

      // While locked out, even the correct password is ignored.
      await controller.unlockWithPassword('secret1');
      expect(container.read(authControllerProvider).status,
          AuthStatus.locked);
    });

    test('lock() moves from unlocked back to locked', () async {
      final store = FakeCredentialsStore();
      await store.write(await _credentials(hasher, 'secret1'));
      final ProviderContainer container = await makeContainer(store: store);
      final AuthController controller =
          container.read(authControllerProvider.notifier);

      await controller.unlockWithPassword('secret1');
      expect(container.read(authControllerProvider).status,
          AuthStatus.unlocked);

      controller.lock();
      expect(container.read(authControllerProvider).status, AuthStatus.locked);
    });

    test('enabling fingerprint requires the correct password', () async {
      final store = FakeCredentialsStore();
      await store.write(await _credentials(hasher, 'secret1'));
      final ProviderContainer container = await makeContainer(
        store: store,
        biometrics: FakeBiometricService(available: true),
      );
      final AuthController controller =
          container.read(authControllerProvider.notifier);
      await controller.unlockWithPassword('secret1');

      final bool wrong = await controller.setFingerprint(
        enabled: true,
        password: 'bad',
      );
      expect(wrong, isFalse);
      expect(container.read(authControllerProvider).fingerprintEnabled,
          isFalse);

      final bool ok = await controller.setFingerprint(
        enabled: true,
        password: 'secret1',
      );
      expect(ok, isTrue);
      expect(container.read(authControllerProvider).fingerprintEnabled, isTrue);
    });

    test('fingerprint success unlocks when enabled', () async {
      final store = FakeCredentialsStore();
      await store.write(
        (await _credentials(hasher, 'secret1'))
            .copyWith(fingerprintEnabled: true),
      );
      final ProviderContainer container = await makeContainer(
        store: store,
        biometrics: FakeBiometricService(
          available: true,
          result: BiometricResult.success,
        ),
      );

      await container
          .read(authControllerProvider.notifier)
          .unlockWithBiometrics();

      expect(container.read(authControllerProvider).status,
          AuthStatus.unlocked);
    });

    test('fingerprint cancelled keeps the app locked, no error', () async {
      final store = FakeCredentialsStore();
      await store.write(
        (await _credentials(hasher, 'secret1'))
            .copyWith(fingerprintEnabled: true),
      );
      final ProviderContainer container = await makeContainer(
        store: store,
        biometrics: FakeBiometricService(
          available: true,
          result: BiometricResult.cancelled,
        ),
      );

      await container
          .read(authControllerProvider.notifier)
          .unlockWithBiometrics();

      final AuthState state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.locked);
      expect(state.errorMessage, isNull);
    });
  });
}

/// Helper: builds stored credentials for [password].
Future<UserCredentials> _credentials(
  PasswordHasher hasher,
  String password,
) async {
  final PasswordHash hash = await hasher.hash(password);
  return UserCredentials(
    name: 'Sara',
    startingBalance: 1000,
    passwordHash: hash.encode(),
    fingerprintEnabled: false,
  );
}
