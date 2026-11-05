import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// A stored password verifier: a random salt (16 bytes) plus the PBKDF2 hash.
///
/// The plain password is never stored anywhere.
class PasswordHash {
  const PasswordHash({required this.salt, required this.hash});

  /// Random per-password salt (16 bytes).
  final Uint8List salt;

  /// PBKDF2-HMAC-SHA256 derived key.
  final Uint8List hash;

  /// Encodes salt and hash as a single base64 string for storage.
  String encode() => '${base64Encode(salt)}:${base64Encode(hash)}';

  /// Decodes the string produced by [encode]. Returns null when malformed.
  static PasswordHash? tryDecode(String encoded) {
    final int separator = encoded.indexOf(':');
    if (separator <= 0) {
      return null;
    }
    try {
      final Uint8List salt = base64Decode(encoded.substring(0, separator));
      final Uint8List hash = base64Decode(encoded.substring(separator + 1));
      return PasswordHash(salt: salt, hash: hash);
    } on FormatException {
      return null;
    }
  }
}

/// Hashes and verifies passwords with PBKDF2 (HMAC-SHA256).
///
/// Salt is 16 random bytes, iteration count is at least 100000, and the
/// derived key is 256 bits (32 bytes).
class PasswordHasher {
  const PasswordHasher({
    this.iterations = 100000,
    this.saltLength = 16,
    this.keyBits = 256,
  });

  /// PBKDF2 iteration count (spec requires at least 100000).
  final int iterations;

  /// Length of the random salt in bytes.
  final int saltLength;

  /// Length of the derived key in bits.
  final int keyBits;
  Pbkdf2 get _algorithm => Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: keyBits,
      );

  /// Creates a fresh hash for [password] using a new random salt.
  Future<PasswordHash> hash(String password) async {
    final Uint8List salt = _randomSalt();
    final SecretKey key = await _algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final List<int> bytes = await key.extractBytes();
    return PasswordHash(salt: salt, hash: Uint8List.fromList(bytes));
  }

  /// Returns true when [password] produces the same key as [stored].
  ///
  /// The comparison is constant-time to avoid leaking information through
  /// timing differences.
  Future<bool> verify(String password, PasswordHash stored) async {
    final SecretKey key = await _algorithm.deriveKeyFromPassword(
      password: password,
      nonce: stored.salt,
    );
    final List<int> bytes = await key.extractBytes();
    return _constantTimeEquals(bytes, stored.hash);
  }

  Uint8List _randomSalt() {
    final Random random = Random.secure();
    final Uint8List salt = Uint8List(saltLength);
    for (int i = 0; i < saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
