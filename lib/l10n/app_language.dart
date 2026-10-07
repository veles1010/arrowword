import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language_policy.dart';

abstract class LanguagePreferenceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SharedPreferencesLanguageStore implements LanguagePreferenceStore {
  static const key = 'arrowword.settings.language';
  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get(key);
    return value is String ? value : null;
  }

  @override
  Future<void> write(String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);
}

class AppLanguage extends ChangeNotifier {
  AppLanguage(this.store, [this._preference = AppLanguagePreference.system]);
  final LanguagePreferenceStore store;
  AppLanguagePreference _preference;
  AppLanguagePreference get preference => _preference;
  Future<void> _pending = Future.value();
  static Future<AppLanguage> restore(LanguagePreferenceStore store) async {
    String? value;
    try {
      value = await store.read();
    } catch (_) {}
    return AppLanguage(store, AppLanguagePreference.parse(value));
  }

  Future<void> setPreference(AppLanguagePreference value) {
    if (value == _preference) return _pending;
    _preference = value;
    notifyListeners();
    return _pending = _pending.then((_) async {
      try {
        await store.write(value.id);
      } catch (_) {}
    });
  }
}
