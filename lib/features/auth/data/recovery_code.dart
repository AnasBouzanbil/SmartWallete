import 'dart:math';

class RecoveryCode {
  const RecoveryCode._();

  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generate({Random? random}) {
    final Random source = random ?? Random.secure();
    final StringBuffer buffer = StringBuffer();
    for (int group = 0; group < 4; group++) {
      if (group > 0) {
        buffer.write('-');
      }
      for (int i = 0; i < 4; i++) {
        buffer.write(_alphabet[source.nextInt(_alphabet.length)]);
      }
    }
    return buffer.toString();
  }

  static String normalize(String input) {
    return input.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  }
}
