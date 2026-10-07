import 'package:flutter/material.dart';
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

/// The Settings route reads the same controller that drives the application.
class AppLanguageScope extends InheritedNotifier<AppLanguage> {
  const AppLanguageScope({
    required AppLanguage language,
    required super.child,
    super.key,
  }) : super(notifier: language);
  static AppLanguage? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageScope>()?.notifier;
}

/// System locale changes are presentation updates, never progression mutations.
class SystemLocaleListener extends StatefulWidget {
  const SystemLocaleListener({required this.builder, super.key});
  final WidgetBuilder builder;
  @override
  State<SystemLocaleListener> createState() => _SystemLocaleListenerState();
}

class _SystemLocaleListenerState extends State<SystemLocaleListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
