import 'dart:async';
import 'dart:io';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/app_settings.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_puzzle_screen.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/app/daily_result_share_service.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/settings_screen.dart';
import 'package:arrowword/l10n/app_language.dart';
import 'package:arrowword/l10n/clue_pack_cache.dart';
import 'package:arrowword/l10n/clue_presentation.dart';
import 'package:arrowword/l10n/generated/app_localizations.dart';
import 'package:arrowword/l10n/language_policy.dart';
import 'package:arrowword/features/puzzle/data/word_catalogue_data.dart';
import 'package:arrowword/features/puzzle/data/track_catalogue_data.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/data/difficulty_puzzles.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/localization/clue_pack.dart';
import 'package:arrowword/features/puzzle/localization/cjk_clue_audit.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements LanguagePreferenceStore {
  String value = 'en';
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
    writes++;
  }
}

class _Generator extends PuzzleSequenceGenerator {
  _Generator(this.fixture) : super(prototypeCatalogue, prototypeSequenceConfig);
  final SequencePuzzleResult fixture;
  int calls = 0;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls++;
    return fixture;
  }
}

class _Share implements DailyResultShareService {
  final texts = <String>[];
  @override
  Future<void> share(String text, {Rect? origin}) async => texts.add(text);
}

void main() {
  final tags = LanguagePolicy.production.enabled.toList();
  final sources = {
    for (final tag in tags)
      tag: File('assets/clues/$tag.json').readAsStringSync(),
  };
  final packs = sources.map(
    (tag, source) => MapEntry(tag, decodeCluePack(source)),
  );
  final words = [...catalogueWords, ...mediumWords, ...hardWords];
  final resolver = LocalizedClueResolver(packs, completeLocales: tags.toSet());
  late SequencePuzzleResult easy, medium, hard;
  setUpAll(() {
    easy = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateNext(puzzleIndex: 1);
    medium = createMediumGenerator().generateNext(puzzleIndex: 1);
    hard = createHardGenerator().generateNext(puzzleIndex: 1);
  });

  for (final tag in ['ja', 'ko', 'zh-Hans']) {
    final audit = CjkClueAudit(tag, words, packs[tag]!, packs['en']!);
    test(
      '$tag has exactly 900 canonical IDs, ordered, unique and non-empty',
      () {
        expect(packs[tag], hasLength(900));
        expect(packs[tag]!.keys.toList(), packs['en']!.keys.toList());
        expect(packs[tag]!.values.every((c) => c.trim().isNotEmpty), isTrue);
        expect(packs[tag]!.values.toSet(), hasLength(900));
        expect(audit.errors, isEmpty);
      },
    );
    for (final track in ['easy', 'medium', 'hard']) {
      test(
        '$tag/$track: 300 native-script clues, compact character metrics',
        () {
          final metrics = audit.statistics(track);
          expect(metrics['count'], 300);
          expect(metrics['averageCharacters'], greaterThan(0));
          expect(
            metrics['maxCharacters'],
            lessThanOrEqualTo(
              tag == 'ko'
                  ? 32
                  : tag == 'ja'
                  ? 28
                  : 22,
            ),
          );
          expect(metrics.containsKey('averageWords'), tag == 'ko');
          expect(audit.lengthWarnings, isEmpty);
        },
      );
    }
    test(
      '$tag has no direct/phonetic revelations or untranslated fragments',
      () {
        expect(audit.errors, isEmpty);
        expect(audit.loanWarnings, isEmpty);
        expect(audit.untranslatedWarnings, isEmpty);
        expect(
          audit.borrowingWarnings.length,
          {'ja': 31, 'ko': 5, 'zh-Hans': 2}[tag],
        );
        for (final word in words) {
          expect(resolver.resolve(word.clueId!, tag), packs[tag]![word.clueId]);
        }
      },
    );
    test('$tag rejects standalone and embedded phonetic own-answer clues', () {
      final (answer, phonetic, context) = switch (tag) {
        'ja' => ('HOTEL', 'ホテル', '泊まれるホテルの建物'),
        'ko' => ('MOTOR', '모터', '회전하는 모터 장치'),
        _ => ('MOTOR', '马达', '用于旋转的马达装置'),
      };
      final fixture = [WordEntry(answer, '', clueId: 'easy_v3_000001')];
      for (final clue in [phonetic, context]) {
        final bad = CjkClueAudit(tag, fixture, {'easy_v3_000001': clue}, {});
        expect(
          bad.errors.any((e) => e.contains('phonetic answer revelation')),
          isTrue,
        );
      }
    });
    test(
      '$tag flags Latin and full-width English leftovers without stripping Unicode',
      () {
        const fixture = [WordEntry('HOUSE', '', clueId: 'easy_v3_000001')];
        final native = packs[tag]!['easy_v3_000002']!;
        for (final leftover in [' the building', ' ＨＯＵＳＥ']) {
          final bad = CjkClueAudit(tag, fixture, {
            'easy_v3_000001': '$native$leftover',
          }, {});
          expect(bad.untranslatedWarnings, hasLength(1));
        }
        expect(decodeCluePack(sources[tag]!)['easy_v3_000002'], native);
      },
    );
  }
  test(
    'native katakana and ambiguous Hangul substrings warn rather than fail',
    () {
      final native = CjkClueAudit(
        'ja',
        [const WordEntry('TIGER', '', clueId: 'easy_v3_000001')],
        {'easy_v3_000001': 'しま模様のネコ科動物'},
        {},
      );
      expect(native.errors, isEmpty);
      expect(native.borrowingWarnings, hasLength(1));
      final ambiguous = CjkClueAudit(
        'ko',
        [const WordEntry('WOOL', '', clueId: 'easy_v3_000001')],
        {'easy_v3_000001': '겨울에 쓰는 섬유'},
        {},
      );
      expect(ambiguous.errors, isEmpty);
      expect(ambiguous.loanWarnings, hasLength(1));
    },
  );
  test('Traditional-only forms and neighbouring scripts are caught', () {
    const fixture = [WordEntry('HOUSE', '', clueId: 'easy_v3_000001')];
    expect(
      CjkClueAudit('zh-Hans', fixture, {
        'easy_v3_000001': '居住的建築學校',
      }, {}).errors,
      isNotEmpty,
    );
    expect(
      CjkClueAudit('ko', fixture, {'easy_v3_000001': '사는 곳あ'}, {}).errors,
      isNotEmpty,
    );
    expect(
      CjkClueAudit('ja', fixture, {'easy_v3_000001': '住まい한'}, {}).errors,
      isNotEmpty,
    );
  });
  test(
    'significant length outliers are counted by characters, not CJK word count',
    () {
      const fixture = [WordEntry('HOUSE', '', clueId: 'easy_v3_000001')];
      for (final (tag, character, length) in [
        ('ja', 'あ', 29),
        ('ko', '가', 33),
        ('zh-Hans', '字', 23),
      ]) {
        final bad = CjkClueAudit(tag, fixture, {
          'easy_v3_000001': character * length,
        }, {});
        expect(bad.lengthWarnings, hasLength(1));
      }
    },
  );
  test('all eleven complete production locales', () {
    expect(tags, [
      'tr',
      'en',
      'es',
      'de',
      'fr',
      'pt-BR',
      'ja',
      'ko',
      'zh-Hans',
      'id',
      'ru',
    ]);
    expect(tags, contains('ru'));
    expect(tags, contains('id'));
    expect(packs.values.fold<int>(0, (n, p) => n + p.length), 9900);
  });
  for (final entry in {
    'ja': 'ja',
    'ja-JP': 'ja',
    'ko': 'ko',
    'ko-KR': 'ko',
    'zh-Hans': 'zh-Hans',
    'zh-CN': 'zh-Hans',
    'zh-SG': 'zh-Hans',
    'zh-Hant': 'en',
    'zh-TW': 'en',
    'zh-HK': 'en',
    'zh-MO': 'en',
    'zh': 'en',
    'ru-RU': 'ru',
    'id-ID': 'id',
  }.entries) {
    test('production system mapping ${entry.key} -> ${entry.value}', () {
      expect(
        LanguagePolicy.production.resolve(AppLanguagePreference.system, [
          entry.key,
        ]),
        entry.value,
      );
    });
  }
  test('CJK cached on demand once, with no eager packs', () async {
    final reads = <String>[];
    final cache = CluePackCache((tag) async {
      reads.add(tag);
      return sources[tag]!;
    }, locales: tags);
    expect(reads, isEmpty);
    for (final tag in ['ja', 'ko', 'zh-Hans', 'ja']) {
      await cache.loadFor(tag);
    }
    expect(reads, ['ja', 'ko', 'zh-Hans']);
  });
  for (final track in ['easy', 'medium', 'hard']) {
    test(
      '$track puzzle identity is unaffected by all eleven presentations',
      () {
        final result = switch (track) {
          'easy' => easy,
          'medium' => medium,
          _ => hard,
        };
        final puzzle = result.puzzle!,
            signature = puzzleStructuralSignature(result.puzzle!);
        final before = puzzle.answers
            .map((a) => (a.solution, a.start, a.direction, a.cluePosition))
            .toList();
        for (final tag in tags) {
          for (final answer in puzzle.answers) {
            expect(
              resolver.resolve(answer.clueId!, tag),
              packs[tag]![answer.clueId],
            );
          }
        }
        expect(puzzleStructuralSignature(puzzle), signature);
        expect(
          puzzle.answers
              .map((a) => (a.solution, a.start, a.direction, a.cluePosition))
              .toList(),
          before,
        );
      },
    );
  }
  testWidgets(
    'en -> ru -> id -> ja -> ko -> zh-Hans is atomic, lazy and keeps attempt state',
    (tester) async {
      final pending = <String, Completer<void>>{
        for (final tag in ['ja', 'ko', 'zh-Hans', 'id', 'ru'])
          tag: Completer<void>(),
      };
      final reads = <String>[];
      final cache = CluePackCache((tag) async {
        reads.add(tag);
        await pending[tag]?.future;
        return sources[tag]!;
      }, locales: tags);
      final generator = _Generator(easy),
          language = AppLanguage(_Store(), AppLanguagePreference.english);
      final session = PuzzleSession(generator: generator);
      addTearDown(session.dispose);
      addTearDown(language.dispose);
      await tester.pumpWidget(
        ArrowwordApp(
          session: session,
          language: language,
          clueCache: cache,
          openPuzzleDirectly: true,
        ),
      );
      await tester.pumpAndSettle();
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      final PuzzleGame game = state.game;
      game.enterLetter('z');
      game.revealSelectedLetter();
      game.check();
      final letters = Map.of(game.enteredLetters),
          revealed = Set.of(game.revealedCells),
          checks = game.wrongChecks,
          selected = game.selectedPosition;
      final history = session.history.map((h) => h.words).toList();
      final answer = game.puzzle.answers.first;
      for (final preference in [
        AppLanguagePreference.russian,
        AppLanguagePreference.indonesian,
        AppLanguagePreference.japanese,
        AppLanguagePreference.korean,
        AppLanguagePreference.simplifiedChinese,
      ]) {
        await language.setPreference(preference);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(state.timer.isRunning, isFalse);
        pending[preference.id]!.complete();
        await tester.pumpAndSettle();
        expect(
          (tester.state(find.byType(PuzzleScreen)) as dynamic).game,
          same(game),
        );
        final context = tester.element(find.byType(PuzzleScreen));
        expect(
          AppLocalizations.of(context)!.localeName.replaceAll('_', '-'),
          preference.id,
        );
        expect(
          CluePresentation.text(context, answer),
          packs[preference.id]![answer.clueId],
        );
        expect(game.enteredLetters, letters);
        expect(game.revealedCells, revealed);
        expect(game.wrongChecks, checks);
        expect(game.selectedPosition, selected);
        expect(session.history.map((h) => h.words).toList(), history);
        expect(session.completedThrough, 0);
        expect(session.completedScores, isEmpty);
        expect(generator.calls, 1);
      }
      expect(reads, ['tr', 'en', 'ru', 'id', 'ja', 'ko', 'zh-Hans']);
    },
  );
  testWidgets(
    'Settings exposes all completed non-Latin and Indonesian autonyms',
    (tester) async {
      final language = AppLanguage(_Store(), AppLanguagePreference.english),
          session = PuzzleSession(generator: _Generator(easy));
      addTearDown(language.dispose);
      addTearDown(session.dispose);
      final settings = AppSettings(MemorySettingsStore());
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ArrowwordApp(session: session, language: language, settings: settings),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byType(DropdownButtonFormField<AppLanguagePreference>),
      );
      await tester.pumpAndSettle();
      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('한국어'), findsOneWidget);
      expect(find.text('简体中文'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Русский'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Русский'), findsOneWidget);
      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      expect(language.preference, AppLanguagePreference.russian);
      expect(
        AppLocalizations.of(tester.element(find.byType(SettingsScreen)))!
            .localeName,
        'ru',
      );
      expect(find.byType(SettingsScreen), findsOneWidget);
    },
  );
  for (final tag in ['ja', 'ko', 'zh-Hans', 'id', 'ru']) {
    for (final scale in [1.3, 1.5]) {
      testWidgets(
        '$tag Daily gameplay/completion/result/share compact at $scale',
        (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final locale = tag == 'zh-Hans'
              ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')
              : Locale(tag);
          final store = MemoryDailyProgressStore(), share = _Share();
          final daily = await DailySession.restore(
            store: store,
            localNow: () => DateTime(2026, 10, 4),
            generator: (key) => DailyPuzzleGeneration.success(
              Puzzle(
                id: dailyPuzzleId(key),
                label: 'fixture',
                rowCount: easy.puzzle!.rowCount,
                columnCount: easy.puzzle!.columnCount,
                answers: easy.puzzle!.answers,
              ),
            ),
          );
          addTearDown(daily.dispose);
          Future<void> pump(Widget child, String key) async {
            await tester.pumpWidget(
              MaterialApp(
                key: ValueKey(key),
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: CluePresentation(
                  resolver: resolver,
                  locale: tag,
                  child: child,
                ),
              ),
            );
            await tester.pumpAndSettle();
          }

          await pump(
            DailyPuzzleScreen(
              session: daily,
              monotonicNow: () => Duration.zero,
            ),
            'play',
          );
          final dynamic state = tester.state(find.byType(PuzzleScreen));
          final PuzzleGame game = state.game;
          final strings = AppLocalizations.of(
            tester.element(find.byType(PuzzleScreen)),
          )!;
          for (final answer in game.puzzle.answers) {
            expect(find.text(packs[tag]![answer.clueId]!), findsOneWidget);
            game.tapClue(answer);
            for (final letter in answer.solution.split('')) {
              game.enterLetter(letter);
            }
          }
          await tester.pumpAndSettle();
          await daily.flush;
          expect(find.text(strings.dailyCompleted), findsOneWidget);
          expect(find.text(strings.returnHome), findsOneWidget);
          expect(daily.results, hasLength(1));
          expect(tester.takeException(), isNull);
          final result = daily.todayResult!;
          final restored = await DailySession.restore(
            store: store,
            localNow: () => DateTime(2026, 10, 4),
          );
          addTearDown(restored.dispose);
          expect(
            restored.todayResult!.dailyPuzzleId,
            dailyPuzzleId('2026-10-04'),
          );
          expect(restored.todayResult!.score, result.score);
          await pump(
            DailyResultScreen(
              result: result,
              session: daily,
              shareService: share,
            ),
            'result',
          );
          await tester.ensureVisible(find.text(strings.share));
          await tester.tap(find.text(strings.share));
          await tester.pumpAndSettle();
          expect(share.texts, [
            dailyResultShareText(result, streak: 1, strings: strings),
          ]);
          expect(share.texts.single, isNot(contains('easy_v3_')));
          expect(share.texts.single, isNot(contains('Puan:')));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
