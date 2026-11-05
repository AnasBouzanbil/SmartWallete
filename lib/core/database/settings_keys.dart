/// Keys used in the `app_settings` key/value table.
abstract final class SettingKeys {
  /// The user's display name.
  static const String displayName = 'display_name';

  /// ISO currency code, e.g. "USD". One currency for the whole app.
  static const String currencyCode = 'currency_code';

  /// 'system' | 'light' | 'dark'.
  static const String themeMode = 'theme_mode';

  /// 'true' | 'false' - mask balances and amounts by default.
  static const String hideAmounts = 'hide_amounts';
}
