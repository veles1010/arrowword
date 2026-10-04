import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsStore {
  Future<String?> readTheme();
  Future<void> writeTheme(String value);
}

class SharedPreferencesSettingsStore implements SettingsStore {
  static const key = 'arrowword.settings.theme';
  final _preferences = SharedPreferencesAsync();
  @override
  Future<String?> readTheme() => _preferences.getString(key);
  @override
  Future<void> writeTheme(String value) => _preferences.setString(key, value);
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this.value]);
  String? value;
  int writes = 0;
  @override
  Future<String?> readTheme() async => value;
  @override
  Future<void> writeTheme(String value) async {
    this.value = value;
    writes++;
  }
}

/// Separate preferences; never writes puzzle or Daily progress.
class AppSettings extends ChangeNotifier {
  AppSettings(this.store, [this._themeMode = ThemeMode.system]);
  final SettingsStore store;
  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;
  Future<void> _writes = Future.value();
  Future<void> get flush => _writes;
  static Future<AppSettings> restore(SettingsStore store) async {
    var mode = ThemeMode.system;
    try {
      final value = await store.readTheme();
      mode = ThemeMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      /* Invalid preference types/read failures use System. */
    }
    return AppSettings(store, mode);
  }

  void setTheme(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _writes = _writes.then((_) => store.writeTheme(mode.name)).catchError((
      Object error,
    ) {
      debugPrint('Theme preference save failed: $error');
    });
  }
}
