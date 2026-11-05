import 'money.dart';

const Currency appCurrency = Currency.mad;

String formatMinor(
  int minor, {
  bool showSign = false,
  bool masked = false,
}) {
  return Money(minor).format(
    appCurrency,
    showSign: showSign,
    masked: masked,
  );
}

int majorToMinor(double value) => (value * 100).round();
