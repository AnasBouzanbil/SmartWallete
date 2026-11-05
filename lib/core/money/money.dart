/// Currency metadata. One currency is used app-wide (see SettingKeys).
class Currency {
  const Currency(this.code, this.symbol, {this.decimals = 2});

  final String code;
  final String symbol;

  /// Digits after the decimal point (minor-unit exponent).
  final int decimals;

  static const Currency usd = Currency('USD', '\$');
  static const Currency eur = Currency('EUR', '€');
  static const Currency gbp = Currency('GBP', '£');
  static const Currency mad = Currency('MAD', 'DH');
  static const Currency aed = Currency('AED', 'AED');
  static const Currency sar = Currency('SAR', 'SAR');

  static const List<Currency> all = <Currency>[usd, eur, gbp, mad, aed, sar];

  static Currency fromCode(String code) =>
      all.firstWhere((Currency c) => c.code == code, orElse: () => usd);
}

/// An amount of money stored as an integer count of minor units
/// (cents). Immutable; no floating point is ever involved.
class Money implements Comparable<Money> {
  const Money(this.minor);

  static const Money zero = Money(0);

  final int minor;

  Money operator +(Money o) => Money(minor + o.minor);
  Money operator -(Money o) => Money(minor - o.minor);
  Money operator -() => Money(-minor);

  bool get isNegative => minor < 0;
  bool get isZero => minor == 0;

  @override
  int compareTo(Money other) => minor.compareTo(other.minor);

  @override
  bool operator ==(Object other) => other is Money && other.minor == minor;

  @override
  int get hashCode => minor.hashCode;

  /// Parses user input such as "42", "42.5", "1,234.50" or "42,50".
  ///
  /// Returns null for empty input, letters, more than one decimal
  /// separator, or more fraction digits than [decimals].
  static Money? tryParse(String input, {int decimals = 2}) {
    String s = input.trim().replaceAll(' ', '');
    if (s.isEmpty) return null;

    // "1,234.50" -> thousands commas; "42,50" -> decimal comma.
    if (s.contains('.') && s.contains(',')) {
      s = s.replaceAll(',', '');
    } else if (s.contains(',')) {
      final List<String> parts = s.split(',');
      final bool decimalComma = parts.length == 2 && parts[1].length <= decimals;
      s = decimalComma ? s.replaceAll(',', '.') : s.replaceAll(',', '');
    }

    if (!RegExp(r'^\d*\.?\d*$').hasMatch(s) || s == '.') return null;
    final List<String> p = s.split('.');
    final String whole = p[0].isEmpty ? '0' : p[0];
    final String frac = p.length > 1 ? p[1] : '';
    if (frac.length > decimals) return null;

    final int w = int.parse(whole);
    final int f = frac.isEmpty ? 0 : int.parse(frac.padRight(decimals, '0'));
    int factor = 1;
    for (int i = 0; i < decimals; i++) {
      factor *= 10;
    }
    return Money(w * factor + f);
  }

  /// Formats e.g. 1248050 -> "$12,480.50".
  ///
  /// [showSign] adds "+" / "-" for non-zero values. [masked] returns
  /// bullets instead of the amount (hide-balance feature).
  String format(
    Currency currency, {
    bool showSign = false,
    bool masked = false,
  }) {
    if (masked) return '${currency.symbol} ••••';

    int factor = 1;
    for (int i = 0; i < currency.decimals; i++) {
      factor *= 10;
    }
    final int abs = minor.abs();
    final String whole = _group((abs ~/ factor).toString());
    final String frac = currency.decimals == 0
        ? ''
        : '.${(abs % factor).toString().padLeft(currency.decimals, '0')}';

    final String sign = minor < 0 ? '-' : (showSign && minor > 0 ? '+' : '');
    final String sym = currency.symbol;
    final String space = sym.length > 1 ? ' ' : '';
    return '$sign$sym$space$whole$frac';
  }

  static String _group(String digits) {
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}
