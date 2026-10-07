import 'package:arrowword/l10n/language_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final complete = LanguagePolicy([
    ...LanguagePolicy.production.locales,
    for (final tag in ['ja', 'ko', 'zh-Hans', 'id', 'ru'])
      LocaleAvailability(tag, uiComplete: true, cluesComplete: true),
  ]);
  for (final entry in {
    'ja-JP': 'ja',
    'ko-KR': 'ko',
    'id-ID': 'id',
    'ru-RU': 'ru',
    'zh-Hans': 'zh-Hans',
    'zh-Hans-CN': 'zh-Hans',
    'zh-CN': 'zh-Hans',
    'zh-SG': 'zh-Hans',
    'zh-Hant': 'en',
    'zh-Hant-CN': 'en',
    'zh-TW': 'en',
    'zh-HK': 'en',
    'zh-MO': 'en',
    'zh': 'en',
    'pt-BR': 'pt-BR',
    'pt': 'pt-BR',
    'pt-PT': 'en',
  }.entries) {
    test('${entry.key} resolves safely when packs are complete', () {
      expect(
        complete.resolve(AppLanguagePreference.system, [entry.key]),
        entry.value,
      );
      expect(
        complete.resolve(AppLanguagePreference.simplifiedChinese, [entry.key]),
        'zh-Hans',
      );
    });
  }
  test(
    'new model IDs/autonyms are stable; incomplete packs stay unavailable',
    () {
      final choices = {
        'ja': '日本語',
        'ko': '한국어',
        'zh-Hans': '简体中文',
        'id': 'Bahasa Indonesia',
        'ru': 'Русский',
      };
      for (final entry in choices.entries) {
        final preference = AppLanguagePreference.parse(entry.key);
        expect(preference.id, entry.key);
        expect(preference.autonym, entry.value);
        expect(LanguagePolicy.production.enabled, isNot(contains(entry.key)));
        expect(LanguagePolicy.production.resolve(preference, ['en']), 'en');
      }
    },
  );
}
