import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/features/auth/data/password_hasher.dart';

void main() {
  // Lower iterations keep tests fast; production uses the default (100000).
  const PasswordHasher hasher = PasswordHasher(iterations: 1000);

  group('PasswordHasher', () {
    test('correct password passes verification', () async {
      final PasswordHash hash = await hasher.hash('correct horse');

      expect(await hasher.verify('correct horse', hash), isTrue);
    });

    test('wrong password fails verification', () async {
      final PasswordHash hash = await hasher.hash('correct horse');

      expect(await hasher.verify('wrong horse', hash), isFalse);
    });

    test('two hashes of the same password differ (random salt)', () async {
      final PasswordHash a = await hasher.hash('same password');
      final PasswordHash b = await hasher.hash('same password');

      expect(a.salt, isNot(equals(b.salt)));
      expect(a.hash, isNot(equals(b.hash)));
      // But both still verify the same password.
      expect(await hasher.verify('same password', a), isTrue);
      expect(await hasher.verify('same password', b), isTrue);
    });

    test('salt is 16 bytes and hash is 32 bytes', () async {
      final PasswordHash hash = await hasher.hash('secret');

      expect(hash.salt.length, 16);
      expect(hash.hash.length, 32);
    });

    test('encode / decode round-trips', () async {
      final PasswordHash hash = await hasher.hash('secret');

      final PasswordHash? decoded = PasswordHash.tryDecode(hash.encode());

      expect(decoded, isNotNull);
      expect(decoded!.salt, equals(hash.salt));
      expect(decoded.hash, equals(hash.hash));
      expect(await hasher.verify('secret', decoded), isTrue);
    });

    test('tryDecode returns null for malformed input', () {
      expect(PasswordHash.tryDecode('not-base64-at-all'), isNull);
      expect(PasswordHash.tryDecode('missing-colon'), isNull);
    });
  });
}
