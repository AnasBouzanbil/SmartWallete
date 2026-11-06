import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_settings_repository.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  int _loadToken = 0;
  bool _userSelected = false;

  @override
  ThemeMode build() {
    final ThemeSettingsRepository repository = ref.watch(
      themeSettingsRepositoryProvider,
    );
    final int token = ++_loadToken;
    _userSelected = false;
    Future.microtask(() => _load(repository, token));
    return ThemeMode.dark;
  }

  Future<void> _load(ThemeSettingsRepository repository, int token) async {
    try {
      final ThemeMode stored = await repository.read();
      if (!ref.mounted) {
        return;
      }
      if (token == _loadToken && !_userSelected) {
        state = stored;
      }
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      if (token == _loadToken && !_userSelected) {
        state = ThemeMode.dark;
      }
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _userSelected = true;
    _loadToken++;
    state = mode;
    try {
      await ref.read(themeSettingsRepositoryProvider).write(mode);
    } catch (_) {
      return;
    }
  }

  Future<void> reload() async {
    _userSelected = false;
    final int token = ++_loadToken;
    try {
      final ThemeMode stored = await ref
          .read(themeSettingsRepositoryProvider)
          .read();
      if (!ref.mounted) {
        return;
      }
      if (token == _loadToken) {
        state = stored;
      }
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      if (token == _loadToken) {
        state = ThemeMode.dark;
      }
    }
  }
}

final NotifierProvider<ThemeModeController, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
