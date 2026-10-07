import 'dart:io';

import 'package:arrowword/app/about_screen.dart';
import 'package:arrowword/features/puzzle/data/word_catalogue_data.dart';
import 'package:arrowword/features/puzzle/data/track_catalogue_data.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:arrowword/features/puzzle/localization/clue_pack.dart';
import 'package:arrowword/features/puzzle/localization/ru_id_clue_audit.dart';
import 'package:arrowword/l10n/clue_pack_cache.dart';
import 'package:arrowword/l10n/generated/app_localizations.dart';
import 'package:arrowword/l10n/language_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  final words = [...catalogueWords, ...mediumWords, ...hardWords];
  final tags = LanguagePolicy.production.enabled.toList();
  final sources = {
    for (final tag in tags)
      tag: File('assets/clues/$tag.json').readAsStringSync(),
  };
  final packs = sources.map((tag, text) => MapEntry(tag, decodeCluePack(text)));
  for (final tag in ['ru', 'id']) {
    final audit = RuIdClueAudit(tag, words, packs[tag]!, packs['en']!);
    test(
      '$tag complete canonical 900 clues, no editorial integrity failures',
      () {
        expect(packs[tag]!.keys.toList(), packs['en']!.keys.toList());
        expect(packs[tag], hasLength(900));
        expect(audit.errors, isEmpty);
        expect(audit.untranslatedWarnings, isEmpty);
        expect(audit.basic.rootWarnings, isEmpty);
        expect(audit.lengthWarnings, isEmpty);
        expect(audit.loanWarnings, hasLength(tag == 'ru' ? 13 : 15));
      },
    );
    for (final track in ['easy', 'medium', 'hard']) {
      test(
        '$tag $track word/character metrics keep compact editorial limits',
        () {
          final stats = audit.statistics(track);
          expect(stats['count'], 300);
          expect(stats['maxWords'], lessThanOrEqualTo(8));
          expect(stats['maxCharacters'], lessThanOrEqualTo(65));
        },
      );
    }
    test(
      '$tag is lazily decoded once and reused, without loading other packs',
      () async {
        final reads = <String>[];
        final cache = CluePackCache((locale) async {
          reads.add(locale);
          return sources[locale]!;
        }, locales: tags);
        expect(reads, isEmpty);
        final first = await cache.loadFor(tag);
        final again = await cache.loadFor(tag);
        expect(first, same(again));
        expect(reads, [tag]);
        for (final word in words) {
          expect(
            first.resolver.resolve(word.clueId!, tag),
            packs[tag]![word.clueId],
          );
        }
      },
    );
    test('$tag near-synonym definitions preserve canonical distinctions', () {
      String clue(String answer) =>
          packs[tag]![words
              .singleWhere((word) => word.solution == answer)
              .clueId]!;
      for (final pair in [
        ('COLUMN', 'PILLAR'),
        ('CHOICE', 'OPTION'),
        ('CITE', 'QUOTE'),
        ('HINDER', 'IMPEDE'),
        ('AMBLE', 'SAUNTER'),
        ('ENGINE', 'MOTOR'),
      ]) {
        expect(clue(pair.$1), isNot(clue(pair.$2)));
      }
      expect(clue('COLUMN'), contains(tag == 'ru' ? 'газете' : 'surat kabar'));
      expect(clue('ENGINE'), contains(tag == 'ru' ? 'топливо' : 'bahan bakar'));
      expect(clue('MOTOR'), contains(tag == 'ru' ? 'ток' : 'listrik'));
    });
  }
  test('Cyrillic ё й ы э ю я щ ж survive JSON, tokenization and resolver', () {
    final all = packs['ru']!.values.join();
    for (final character in 'ёйыэюящж'.split('')) {
      expect(all, contains(character));
    }
    final parsed = decodeCluePack('{"fixture":"ё й ы э ю я щ ж"}');
    expect(
      LocalizedClueResolver(
        {'ru': parsed},
        completeLocales: {'ru'},
      ).resolve('fixture', 'ru'),
      'ё й ы э ю я щ ж',
    );
  });
  for (final entry in {
    'ru': ['MOTOR', 'HOTEL', 'RADIO', 'SPORT'],
    'id': ['CAMERA', 'MOTOR', 'OPTION'],
  }.entries) {
    for (final answer in entry.value) {
      test('${entry.key} rejects own phonetic borrowing $answer', () {
        final aliases = RuIdClueAudit.ownForms[entry.key]![answer]!;
        final fixture = [WordEntry(answer, 'fixture', clueId: 'fixture')];
        final audit = RuIdClueAudit(
          entry.key,
          fixture,
          {
            'fixture':
                '${aliases.first}${entry.key == 'ru' && answer == 'MOTOR' ? 'ный' : ''}',
          },
          {'fixture': 'Independent English definition'},
        );
        expect(audit.errors, isNotEmpty);
      });
    }
  }
  test('Russian Latin fragments are reported, not silently accepted', () {
    final audit = RuIdClueAudit(
      'ru',
      [const WordEntry('APPLE', '', clueId: 'a')],
      {'a': 'Свежий orchard fruit'},
      {'a': 'Crisp orchard fruit'},
    );
    expect(audit.untranslatedWarnings, hasLength(1));
  });
  test(
    'Indonesian English fragments are reported, normal borrowings reviewed',
    () {
      final fixture = [const WordEntry('SUGAR', '', clueId: 'a')];
      final bad = RuIdClueAudit(
        'id',
        fixture,
        {'a': 'Sweet crystals for tea'},
        {'a': 'Sweet crystals added to tea'},
      );
      expect(bad.untranslatedWarnings, hasLength(1));
      final good = RuIdClueAudit('id', fixture, {
        'a': 'Kristal manis untuk teh',
      }, {});
      expect(good.errors, isEmpty);
      expect(good.loanWarnings, hasLength(1));
    },
  );
  test('future incomplete UI locale still cannot enable mixed gameplay', () {
    const policy = LanguagePolicy([
      LocaleAvailability('en', uiComplete: true, cluesComplete: true),
      LocaleAvailability('ru', uiComplete: true, cluesComplete: false),
    ]);
    expect(policy.enabled, ['en']);
    expect(policy.resolve(AppLanguagePreference.russian, ['ru-RU']), 'en');
  });
  for (final device in ['ru-RU', 'ru-KZ', 'id-ID']) {
    test(
      '$device production matching is complete and explicit override wins',
      () {
        expect(
          LanguagePolicy.production.resolve(AppLanguagePreference.system, [
            device,
          ]),
          device.split('-').first,
        );
        expect(
          LanguagePolicy.production.resolve(AppLanguagePreference.english, [
            device,
          ]),
          'en',
        );
      },
    );
  }
  for (final tag in tags) {
    testWidgets('$tag English-answer explanation appears only on About', (
      tester,
    ) async {
      final parts = tag.split('-');
      final locale = Locale.fromSubtags(
        languageCode: parts.first,
        countryCode: tag == 'pt-BR' ? 'BR' : null,
        scriptCode: tag == 'zh-Hans' ? 'Hans' : null,
      );
      final strings = await AppLocalizations.delegate.load(locale);
      expect(strings.answersAlwaysEnglish, isNotEmpty);
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: AboutScreen(
            loadInfo: () async => PackageInfo(
              appName: 'Arrowword',
              packageName: 'fixture',
              version: '1',
              buildNumber: '1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(strings.answersAlwaysEnglish), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
