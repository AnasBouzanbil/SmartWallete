import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

class ThemeSettingsRepository {
  ThemeSettingsRepository(this._db);

  final AppDatabase _db;

  Future<ThemeMode> read() async {
    final AppSetting? row =
        await (_db.select(_db.appSettings)
              ..where((table) => table.key.equals(SettingKeys.themeMode)))
            .getSingleOrNull();
    return switch (row?.value) {
      'light' => ThemeMode.light,
      _ => ThemeMode.dark,
    };
  }

  Future<void> write(ThemeMode mode) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: SettingKeys.themeMode,
            value: mode == ThemeMode.light ? 'light' : 'dark',
          ),
        );
  }
}

final Provider<ThemeSettingsRepository> themeSettingsRepositoryProvider =
    Provider<ThemeSettingsRepository>((ref) {
      return ThemeSettingsRepository(ref.watch(databaseProvider));
    });
