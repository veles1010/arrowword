import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsStore {
  Future<String?> readTheme();
  Future<void> writeTheme(String value);
}

abstract class AudioSettingsStore {
  Future<bool?> readMusic();
  Future<bool?> readSfx();
  Future<void> writeMusic(bool value);
  Future<void> writeSfx(bool value);
}

class SharedPreferencesSettingsStore
    implements SettingsStore, AudioSettingsStore {
  static const key = 'arrowword.settings.theme';
  static const musicKey = 'arrowword.settings.music_enabled';
  static const sfxKey = 'arrowword.settings.sfx_enabled';
  final _preferences = SharedPreferencesAsync();
  @override
  Future<String?> readTheme() => _preferences.getString(key);
  @override
  Future<void> writeTheme(String value) => _preferences.setString(key, value);
  @override
  Future<bool?> readMusic() => _preferences.getBool(musicKey);
  @override
  Future<bool?> readSfx() => _preferences.getBool(sfxKey);
  @override
  Future<void> writeMusic(bool value) => _preferences.setBool(musicKey, value);
  @override
  Future<void> writeSfx(bool value) => _preferences.setBool(sfxKey, value);
}

class MemorySettingsStore implements SettingsStore, AudioSettingsStore {
  MemorySettingsStore([this.value]);
  String? value;
  int writes = 0;
  bool? music, sfx;
  int audioWrites = 0;
  @override
  Future<bool?> readMusic() async => music;
  @override
  Future<bool?> readSfx() async => sfx;
  @override
  Future<void> writeMusic(bool value) async {
    music = value;
    audioWrites++;
  }

  @override
  Future<void> writeSfx(bool value) async {
    sfx = value;
    audioWrites++;
  }

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
  bool _musicEnabled = true, _sfxEnabled = true;
  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
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
    final settings = AppSettings(store, mode);
    if (store is AudioSettingsStore) {
      final audioStore = store as AudioSettingsStore;
      try {
        settings._musicEnabled = await audioStore.readMusic() ?? true;
      } catch (_) {}
      try {
        settings._sfxEnabled = await audioStore.readSfx() ?? true;
      } catch (_) {}
    }
    return settings;
  }

  void setMusicEnabled(bool value) => _setAudio(value, music: true);
  void setSfxEnabled(bool value) => _setAudio(value, music: false);
  void _setAudio(bool value, {required bool music}) {
    if (value == (music ? _musicEnabled : _sfxEnabled)) return;
    if (music) {
      _musicEnabled = value;
    } else {
      _sfxEnabled = value;
    }
    notifyListeners();
    final audioStore = store;
    if (audioStore is AudioSettingsStore) {
      final preferences = audioStore as AudioSettingsStore;
      _writes = _writes
          .then(
            (_) => music
                ? preferences.writeMusic(value)
                : preferences.writeSfx(value),
          )
          .catchError((Object error) {
            debugPrint('Audio preference save failed: $error');
          });
    }
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
