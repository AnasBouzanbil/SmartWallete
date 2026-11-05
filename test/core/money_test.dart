import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/money/money.dart';

void main() {
  group('Money.tryParse', () {
    test('parses whole and decimal inputs', () {
      expect(Money.tryParse('42'), const Money(4200));
      expect(Money.tryParse('42.5'), const Money(4250));
      expect(Money.tryParse('42.05'), const Money(4205));
      expect(Money.tryParse('.5'), const Money(50));
    });

    test('handles thousands and decimal commas', () {
      expect(Money.tryParse('1,234.50'), const Money(123450));
      expect(Money.tryParse('42,50'), const Money(4250));
      expect(Money.tryParse('1,234'), const Money(123400));
    });

    test('rejects bad input', () {
      expect(Money.tryParse(''), isNull);
      expect(Money.tryParse('abc'), isNull);
      expect(Money.tryParse('1.2.3'), isNull);
      expect(Money.tryParse('1.234'), isNull);
      expect(Money.tryParse('.'), isNull);
    });

    test('has no floating point error', () {
      final Money sum = Money.tryParse('0.1')! + Money.tryParse('0.2')!;
      expect(sum, const Money(30));
    });
  });

  group('Money.format', () {
    test('groups thousands and pads decimals', () {
      expect(const Money(1248050).format(Currency.usd), '\$12,480.50');
      expect(const Money(5).format(Currency.usd), '\$0.05');
    });

    test('signs and masking', () {
      expect(const Money(-850).format(Currency.usd), '-\$8.50');
      expect(const Money(320000).format(Currency.usd, showSign: true), '+\$3,200.00');
      expect(const Money(320000).format(Currency.usd, masked: true), '\$ ••••');
    });

    test('word symbols get a space', () {
      expect(const Money(10000).format(Currency.mad), 'DH 100.00');
    });
  });
}
