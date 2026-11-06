import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/database/app_database.dart';
import 'package:smartwallete/core/database/database_provider.dart';
import 'package:smartwallete/core/theme/theme_mode_controller.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProviderContainer makeContainer() {
    return ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  }

  test('defaults to dark', () async {
    final ProviderContainer container = makeContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('setMode updates state and persists light', () async {
    final ProviderContainer container = makeContainer();
    addTearDown(container.dispose);
    container.read(themeModeProvider);

    await container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

    expect(container.read(themeModeProvider), ThemeMode.light);
    final AppSetting row = await (db.select(
      db.appSettings,
    )..where((table) => table.key.equals(SettingKeys.themeMode))).getSingle();
    expect(row.value, 'light');
  });

  test('reload reads the persisted value', () async {
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            key: SettingKeys.themeMode,
            value: 'light',
          ),
        );
    final ProviderContainer container = makeContainer();
    addTearDown(container.dispose);
    container.read(themeModeProvider);

    await container.read(themeModeProvider.notifier).reload();

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('unknown stored value falls back to dark', () async {
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            key: SettingKeys.themeMode,
            value: 'system',
          ),
        );
    final ProviderContainer container = makeContainer();
    addTearDown(container.dispose);
    container.read(themeModeProvider);

    await container.read(themeModeProvider.notifier).reload();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });
}
