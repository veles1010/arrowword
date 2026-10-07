/// UI availability and complete gameplay availability are separate contracts.
enum AppLanguagePreference {
  system('system'),
  english('en'),
  turkish('tr'),
  spanish('es'),
  german('de'),
  french('fr'),
  brazilianPortuguese('pt-BR');

  const AppLanguagePreference(this.id);
  final String id;
  String get autonym => switch (this) {
    system => '',
    english => 'English',
    turkish => 'Türkçe',
    spanish => 'Español',
    german => 'Deutsch',
    french => 'Français',
    brazilianPortuguese => 'Português (Brasil)',
  };
  static AppLanguagePreference parse(String? value) =>
      values.firstWhere((entry) => entry.id == value, orElse: () => system);
}

class LocaleAvailability {
  const LocaleAvailability(
    this.tag, {
    required this.uiComplete,
    required this.cluesComplete,
  });
  final String tag;
  final bool uiComplete, cluesComplete;
  bool get productionComplete => uiComplete && cluesComplete;
}

class LanguagePolicy {
  const LanguagePolicy(this.locales);
  static const production = LanguagePolicy([
    LocaleAvailability('tr', uiComplete: true, cluesComplete: true),
    LocaleAvailability('en', uiComplete: true, cluesComplete: true),
    LocaleAvailability('es', uiComplete: true, cluesComplete: true),
    LocaleAvailability('de', uiComplete: true, cluesComplete: true),
    LocaleAvailability('fr', uiComplete: true, cluesComplete: true),
    LocaleAvailability('pt-BR', uiComplete: true, cluesComplete: true),
  ]);
  final List<LocaleAvailability> locales;
  Iterable<String> get enabled =>
      locales.where((l) => l.productionComplete).map((l) => l.tag);
  String resolve(
    AppLanguagePreference preference,
    Iterable<String> systemLocales,
  ) {
    final supported = enabled.toSet();
    String? match(String tag) {
      final canonical = tag.replaceAll('_', '-').toLowerCase();
      for (final candidate in supported) {
        if (candidate.toLowerCase() == canonical) return candidate;
      }
      final base = canonical.split('-').first;
      if (base == 'pt') {
        // Bare Portuguese defaults to Brazil; do not reinterpret Portugal.
        if (canonical == 'pt' && supported.contains('pt-BR')) return 'pt-BR';
        return supported.contains('en') ? 'en' : null;
      }
      return supported.contains(base) ? base : null;
    }

    if (preference != AppLanguagePreference.system) {
      final explicit = match(preference.id);
      if (explicit != null) return explicit;
    }
    for (final tag in systemLocales) {
      final resolved = match(tag);
      if (resolved != null) return resolved;
    }
    // English becomes the normal fallback atomically when its clue pack is complete.
    if (supported.contains('en')) return 'en';
    if (supported.contains('tr')) return 'tr';
    throw StateError('No complete gameplay locale is registered.');
  }
}

String? developmentUiLocale(String value, {required bool releaseMode}) =>
    !releaseMode && (value == 'en' || value == 'tr') ? value : null;
