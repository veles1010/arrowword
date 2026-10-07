import 'dart:convert';
import 'dart:io';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/app_settings.dart';
import 'package:arrowword/app/daily_history_screen.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_puzzle_screen.dart';
import 'package:arrowword/app/daily_result_share_service.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/app/fluid_navigation_bar.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/settings_screen.dart';
import 'package:arrowword/features/puzzle/data/word_catalogue_data.dart';
import 'package:arrowword/features/puzzle/data/track_catalogue_data.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/data/difficulty_puzzles.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:arrowword/features/puzzle/localization/clue_pack.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:arrowword/l10n/app_language.dart';
import 'package:arrowword/l10n/clue_presentation.dart';
import 'package:arrowword/l10n/generated/app_localizations.dart';
import 'package:arrowword/l10n/generated/app_localizations_en.dart';
import 'package:arrowword/l10n/generated/app_localizations_tr.dart';
import 'package:arrowword/l10n/language_policy.dart';
import 'package:arrowword/l10n/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LanguageStore implements LanguagePreferenceStore {
  _LanguageStore([this.value]);
  String? value;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
    writes++;
  }
}

class _FixtureGenerator extends PuzzleSequenceGenerator {
  _FixtureGenerator(this.result)
    : super(prototypeCatalogue, prototypeSequenceConfig);
  final SequencePuzzleResult result;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) => result;
}

void main() {
  final words = [...catalogueWords, ...mediumWords, ...hardWords];
  final tr = AppLocalizationsTr(), en = AppLocalizationsEn();
  final pack = decodeCluePack(File('assets/clues/tr.json').readAsStringSync());
  final resolver = LocalizedClueResolver({'tr': pack});
  final policy = LanguagePolicy.production;
  late SequencePuzzleResult fixture;
  setUpAll(() => fixture = generatePrototypePuzzle());

  test('900 clue IDs globally unique', () {
    expect(words, hasLength(900));
    expect(words.map((w) => w.clueId).toSet(), hasLength(900));
    expect(words.every((w) => w.clueId != null), isTrue);
  });
  for (final bank in {
    'easy_v3': catalogueWords,
    'medium_v1': mediumWords,
    'hard_v1': hardWords,
  }.entries) {
    test('${bank.key} frozen positional clue identities', () {
      expect(bank.value.first.clueId, '${bank.key}_000001');
      expect(bank.value.last.clueId, '${bank.key}_000300');
      for (final (index, word) in bank.value.indexed) {
        expect(
          word.clueId,
          '${bank.key}_${(index + 1).toString().padLeft(6, '0')}',
        );
        expect(word.normalized().clueId, word.clueId);
      }
    });
  }
  test('clue identity is independent of wording and legacy content ID', () {
    final original = words.first;
    final changed = WordEntry(
      original.solution,
      'A different presentation',
      id: original.id,
      clueId: original.clueId,
    );
    expect(changed.clueId, original.clueId);
    expect(changed.id, original.id);
  });
  test(
    'Turkish pack has exactly 900 known IDs, no blanks, exact approved text',
    () {
      expect(pack, hasLength(900));
      expect(pack.keys.toSet(), words.map((w) => w.clueId).toSet());
      for (final word in words) {
        expect(pack[word.clueId], word.turkishClue);
        expect(resolver.resolve(word.clueId!, 'tr-TR'), word.turkishClue);
        expect(pack[word.clueId]!.trim(), isNotEmpty);
      }
    },
  );
  for (final bad in [
    '{} nope',
    '[]',
    '{"id":""}',
    '{"id":7}',
    '{"id":"one","id":"two"}',
    r'{"id":"one","\u0069d":"two"}',
  ]) {
    test(
      'invalid/duplicate clue pack rejected: $bad',
      () => expect(() => decodeCluePack(bad), throwsFormatException),
    );
  }
  test('JSON quotes and colons inside clue text do not become IDs', () {
    final source = jsonEncode({
      'id': 'A "quoted": clue',
      'other': 'Another "quoted": clue',
    });
    expect(decodeCluePack(source), hasLength(2));
  });
  test('complete pack missing a clue is an integrity error, never wrong-language fallback', () {
    final missing = LocalizedClueResolver(
      {
        'tr': {},
        'en': {'id': 'English'},
      },
      completeLocales: {'tr', 'en'},
    );
    expect(
      () => missing.resolve('id', 'tr'),
      throwsA(isA<ClueIntegrityException>()),
    );
  });
  test('resolver exact locale, then base, then future English fallback', () {
    final future = LocalizedClueResolver(
      {
        'en-GB': {'id': 'British'},
        'en': {'id': 'English'},
        'tr': {'id': 'Turkish'},
      },
      completeLocales: {'tr', 'en'},
    );
    expect(future.resolve('id', 'en_GB'), 'British');
    expect(future.resolve('id', 'en-US'), 'English');
    expect(future.resolve('id', 'fi-FI'), 'English');
    expect(
      () => resolver.resolve('id', 'fi-FI'),
      throwsA(isA<ClueIntegrityException>()),
    );
  });
  test('clue packs defensively copy presentation data', () {
    final values = {'id': 'Original'};
    final local = LocalizedClueResolver(
      {'en': values},
      completeLocales: {'en'},
    );
    values['id'] = 'Changed';
    expect(local.resolve('id', 'en'), 'Original');
    expect(() => local.packs['en']!['id'] = 'Changed', throwsUnsupportedError);
  });
  test('both UI ARBs have complete matching keys', () {
    Map<String, dynamic> read(String locale) =>
        jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
            as Map<String, dynamic>;
    final turkish = read('tr'), english = read('en');
    expect(english.keys.toSet(), turkish.keys.toSet());
    for (final key in turkish.keys.where((k) => !k.startsWith('@'))) {
      expect(english[key], isA<String>());
      expect((english[key] as String).trim(), isNotEmpty);
    }
  });
  test(
    'critical production UI has no embedded Turkish presentation literals',
    () {
      final files = [
        ...Directory('lib/app')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('_screen.dart')),
        File('lib/app/app.dart'),
        File('lib/app/fluid_navigation_bar.dart'),
        File('lib/features/puzzle/presentation/puzzle_screen.dart'),
        File('lib/features/puzzle/presentation/puzzle_completion.dart'),
      ];
      final literal = RegExp(r"'[^'\n]*[çğıöşüÇĞİÖŞÜ][^'\n]*'");
      for (final file in files) {
        expect(
          literal.allMatches(file.readAsStringSync()),
          isEmpty,
          reason: 'Localize presentation text in ${file.path}',
        );
      }
    },
  );
  test('Turkish UI core labels and parameter text preserve copy', () {
    expect([tr.home, tr.puzzles, tr.daily, tr.statistics], shellLabels);
    expect(tr.trackPuzzle(tr.medium, 2), 'Orta · Bulmaca 2');
    expect(tr.progress(30, 36), '30 / 36 tamamlandı');
    expect(tr.completedCount(1), '1 bulmaca tamamlandı');
  });
  test('English UI core labels and plural messages', () {
    expect(
      [en.home, en.puzzles, en.daily, en.statistics],
      ['Home', 'Puzzles', 'Daily', 'Statistics'],
    );
    expect(en.completedCount(1), '1 puzzle completed');
    expect(en.completedCount(2), '2 puzzles completed');
    expect(en.streakDays(1), '1-day streak');
    expect(en.streakDays(3), '3-day streak');
    expect(
      en.dailyDetails('01:20', 1, 2),
      '01:20 · 1 hint · 2 incorrect checks',
    );
  });
  test('localized dates retain canonical storage identity', () {
    expect(localizedDailyDate('2026-10-04', tr), '4 Ekim 2026');
    expect(localizedDailyDate('2026-10-04', en), '4 October 2026');
    expect(dailyDateKey(DateTime(2026, 10, 4)), '2026-10-04');
  });
  test('English share is localized UI only, with no hidden content', () {
    final result = DailyPuzzleScore.calculate(
      dateKey: '2026-10-04',
      dailyPuzzleId: dailyPuzzleId('2026-10-04'),
      elapsedSeconds: 80,
      hintsUsed: 1,
      wrongChecks: 2,
    );
    final text = dailyResultShareText(result, streak: 1, strings: en);
    expect(
      text,
      'Arrowword — Daily Puzzle\n4 October 2026\n\nScore: 1250\nTime: 01:20\nHints: 1\nIncorrect checks: 2\nStreak: 1 day',
    );
    expect(text, isNot(contains(result.dailyPuzzleId)));
    expect(
      dailyResultShareText(result, streak: 0, strings: en),
      isNot(contains('Streak:')),
    );
  });
  test(
    'complete tr/en packs enable gameplay; UI-only locale remains gated',
    () {
      expect(policy.enabled, ['tr', 'en']);
      expect(
        policy.locales.singleWhere((l) => l.tag == 'en').uiComplete,
        isTrue,
      );
      expect(
        policy.locales.singleWhere((l) => l.tag == 'en').cluesComplete,
        isTrue,
      );
      const incomplete = LanguagePolicy([
        LocaleAvailability('tr', uiComplete: true, cluesComplete: true),
        LocaleAvailability('en', uiComplete: true, cluesComplete: false),
      ]);
      expect(incomplete.enabled, ['tr']);
      expect(
        incomplete.resolve(AppLanguagePreference.english, ['en-US']),
        'tr',
      );
    },
  );
  for (final tag in [
    'tr-TR',
    'tr',
    'en-US',
    'en-GB',
    'de-DE',
    'es-MX',
    'fi-FI',
  ]) {
    test('production locale $tag resolves coherently with global fallback', () {
      expect(
        policy.resolve(AppLanguagePreference.system, [tag]),
        tag.startsWith('tr') ? 'tr' : 'en',
      );
      expect(policy.resolve(AppLanguagePreference.english, [tag]), 'en');
      expect(policy.resolve(AppLanguagePreference.turkish, [tag]), 'tr');
    });
  }
  test(
    'future complete registry exact/base/device priority and English fallback',
    () {
      const future = LanguagePolicy([
        LocaleAvailability('tr', uiComplete: true, cluesComplete: true),
        LocaleAvailability('en', uiComplete: true, cluesComplete: true),
        LocaleAvailability('en-GB', uiComplete: true, cluesComplete: true),
        LocaleAvailability('de', uiComplete: true, cluesComplete: true),
      ]);
      expect(future.resolve(AppLanguagePreference.system, ['en-GB']), 'en-GB');
      expect(future.resolve(AppLanguagePreference.system, ['en-US']), 'en');
      expect(
        future.resolve(AppLanguagePreference.system, ['fi-FI', 'de-DE']),
        'de',
      );
      expect(future.resolve(AppLanguagePreference.system, ['fi-FI']), 'en');
      expect(future.resolve(AppLanguagePreference.turkish, ['en-US']), 'tr');
    },
  );
  for (final value in [null, 'system', 'tr', 'en', 'invalid']) {
    test('language preference restore $value with no writes', () async {
      final store = _LanguageStore(value);
      final controller = await AppLanguage.restore(store);
      addTearDown(controller.dispose);
      expect(controller.preference, AppLanguagePreference.parse(value));
      expect(store.writes, 0);
    });
  }
  test(
    'language preference updates once and restores enabled English',
    () async {
      final store = _LanguageStore();
      final controller = AppLanguage(store);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.setPreference(AppLanguagePreference.english);
      await controller.setPreference(AppLanguagePreference.english);
      expect(store.value, 'en');
      expect(store.writes, 1);
      expect(notifications, 1);
      final restored = await AppLanguage.restore(store);
      addTearDown(restored.dispose);
      expect(restored.preference, AppLanguagePreference.english);
      expect(policy.resolve(restored.preference, ['en-US']), 'en');
    },
  );
  test(
    'settings language key never changes puzzle or Daily payloads',
    () async {
      SharedPreferences.setMockInitialValues({
        'arrowword.puzzle_progress': 'easy',
        'arrowword.puzzle_progress.medium': 'medium',
        'arrowword.puzzle_progress.hard': 'hard',
        'arrowword.daily_progress': 'daily',
        'arrowword.settings.theme': 'dark',
      });
      final store = SharedPreferencesLanguageStore();
      await store.write('tr');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPreferencesLanguageStore.key), 'tr');
      expect(prefs.getString('arrowword.puzzle_progress'), 'easy');
      expect(prefs.getString('arrowword.puzzle_progress.medium'), 'medium');
      expect(prefs.getString('arrowword.puzzle_progress.hard'), 'hard');
      expect(prefs.getString('arrowword.daily_progress'), 'daily');
      expect(prefs.getString('arrowword.settings.theme'), 'dark');
      await prefs.setInt(SharedPreferencesLanguageStore.key, 7);
      expect(await store.read(), isNull);
    },
  );
  test('UI inspection define is ignored in release and validates supported UI locale', () {
    expect(developmentUiLocale('en', releaseMode: false), 'en');
    expect(developmentUiLocale('tr', releaseMode: false), 'tr');
    expect(developmentUiLocale('en', releaseMode: true), isNull);
    expect(developmentUiLocale('xx', releaseMode: false), isNull);
  });

  for (final track in {
    'easy': () =>
        PuzzleSequenceGenerator(prototypeCatalogue, prototypeSequenceConfig),
    'medium': createMediumGenerator,
    'hard': createHardGenerator,
  }.entries) {
    test(
      '${track.key} presentation locale cannot change generated board or identity',
      () {
        final generator = track.value();
        final result = generator.generateNext(puzzleIndex: 1);
        final puzzle = result.puzzle!;
        final signature = puzzleStructuralSignature(puzzle);
        final alternate = LocalizedClueResolver(
          {
            'en': {
              for (final a in puzzle.answers)
                a.clueId!: 'Fixture English ${a.id}',
            },
          },
          completeLocales: {'en'},
        );
        final turkish = puzzle.answers
            .map((a) => resolver.resolve(a.clueId!, 'tr'))
            .toList();
        final english = puzzle.answers
            .map((a) => alternate.resolve(a.clueId!, 'en'))
            .toList();
        expect(english, isNot(turkish));
        expect(puzzleStructuralSignature(puzzle), signature);
        final repeated = generator.generateNext(puzzleIndex: 1);
        expect(puzzleStructuralSignature(repeated.puzzle!), signature);
        expect(repeated.puzzle!.id, puzzle.id);
        expect(repeated.seed, result.seed);
        expect(
          repeated.puzzle!.answers
              .map(
                (a) => [
                  a.solution,
                  a.positions.map((p) => [p.row, p.column]).toList(),
                  a.cluePosition.row,
                  a.cluePosition.column,
                ],
              )
              .toList(),
          puzzle.answers
              .map(
                (a) => [
                  a.solution,
                  a.positions.map((p) => [p.row, p.column]).toList(),
                  a.cluePosition.row,
                  a.cluePosition.column,
                ],
              )
              .toList(),
        );
        expect(
          repeated.puzzle!.displayBounds.columnCount,
          puzzle.displayBounds.columnCount,
        );
      },
    );
  }
  test('Daily presentation uses stable Easy clue IDs without changing date identity/board', () {
    final daily = generateDailyPuzzle('2026-10-04').puzzle!;
    final signature = puzzleStructuralSignature(daily);
    for (final a in daily.answers) {
      expect(a.clueId, startsWith('easy_v3_'));
      expect(resolver.resolve(a.clueId!, 'tr'), a.turkishClue);
    }
    expect(daily.id, 'daily-v1-c3-2026-10-04');
    expect(dailyPuzzleSeed('2026-10-04'), 927491995);
    expect(puzzleStructuralSignature(daily), signature);
  });

  Future<void> localized(
    WidgetTester tester,
    Widget child,
    String locale, {
    bool compact = false,
  }) async {
    if (compact) {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in ['tr', 'en']) {
    testWidgets('$locale delegate loads and shell semantics stay localized', (
      tester,
    ) async {
      await localized(
        tester,
        Scaffold(
          bottomNavigationBar: FluidNavigationBar(index: 0, onSelected: (_) {}),
        ),
        locale,
        compact: true,
      );
      final copy = locale == 'tr' ? tr : en;
      expect(find.text(copy.home), findsOneWidget);
      expect(find.bySemanticsLabel(copy.home), findsOneWidget);
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byType(FluidNavigationBar));
      expect(AppLocalizations.of(context)!.localeName, locale);
    });
    testWidgets('$locale Settings and About compact accessible layout', (
      tester,
    ) async {
      final settings = AppSettings(MemorySettingsStore());
      addTearDown(settings.dispose);
      await localized(
        tester,
        SettingsScreen(settings: settings),
        locale,
        compact: true,
      );
      final copy = locale == 'tr' ? tr : en;
      expect(find.text(copy.settings), findsOneWidget);
      expect(
        find.text('English'),
        findsNothing,
      ); // Standalone screen without a language controller has no selector.
      await tester.tap(find.text(copy.appInformation));
      await tester.pumpAndSettle();
      expect(find.text(copy.about), findsOneWidget);
      expect(find.text('Arrowword'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'production enables persisted English on English device without rewriting preference',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale(
        'en',
        'US',
      );
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      final store = _LanguageStore('en');
      final language = await AppLanguage.restore(store);
      final session = PuzzleSession(generator: _FixtureGenerator(fixture));
      addTearDown(language.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ArrowwordApp(
          session: session,
          language: language,
          clueResolver: resolver,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Ana Sayfa'), findsNothing);
      expect(store.writes, 0);
      expect(language.preference, AppLanguagePreference.english);
    },
  );
  testWidgets(
    'English UI-only preview uses Turkish clues, never changes preference',
    (tester) async {
      final store = _LanguageStore('tr');
      final language = await AppLanguage.restore(store);
      final session = PuzzleSession(generator: _FixtureGenerator(fixture));
      addTearDown(language.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ArrowwordApp(
          session: session,
          language: language,
          uiLocalePreview: 'en',
          clueResolver: resolver,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('Puzzle 1'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);
      expect(find.text('Reveal with Ad'), findsOneWidget);
      expect(tr.rewardHint, 'Reklamla Harf Aç');
      final puzzle = tester
          .widget<PuzzleScreen>(find.byType(PuzzleScreen))
          .puzzle;
      for (final a in puzzle.answers) {
        expect(find.text(a.turkishClue), findsOneWidget);
      }
      expect(store.writes, 0);
      expect(store.value, 'tr');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'fake alternate clue presentation changes clues and semantics only',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final puzzle = fixture.puzzle!;
      final alternate = LocalizedClueResolver(
        {
          'en': {
            for (final a in puzzle.answers) a.clueId!: 'Translated ${a.id}',
          },
        },
        completeLocales: {'en'},
      );
      final first = puzzle.answers.first;
      await localized(
        tester,
        CluePresentation(
          resolver: alternate,
          locale: 'en',
          child: PuzzleScreen(
            puzzle: puzzle,
            initialLetters: {first.positions.first: first.solution[0]},
            initialRevealedCells: {first.positions.first},
          ),
        ),
        'en',
      );
      expect(find.text('Translated ${first.id}'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Revealed with a hint, locked')),
        findsOneWidget,
      );
      expect(
        tester.widget<PuzzleScreen>(find.byType(PuzzleScreen)).puzzle,
        same(puzzle),
      );
      semantics.dispose();
    },
  );
  testWidgets(
    'English Daily result and history UI are localized without a new attempt',
    (tester) async {
      final result = DailyPuzzleScore.calculate(
        dateKey: '2026-10-04',
        dailyPuzzleId: dailyPuzzleId('2026-10-04'),
        elapsedSeconds: 80,
        hintsUsed: 1,
        wrongChecks: 1,
      );
      final daily = await DailySession.restore(
        store: MemoryDailyProgressStore(
          DailyProgress(results: {result.dateKey: result}).encode(),
        ),
        localNow: () => DateTime(2026, 10, 4),
        generator: (_) => throw StateError('Must not generate'),
      );
      addTearDown(daily.dispose);
      await localized(
        tester,
        DailyResultScreen(result: result, session: daily),
        'en',
      );
      expect(find.text('Daily puzzle complete!'), findsOneWidget);
      expect(find.text('4 October 2026'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      await tester.tap(find.text('Daily History'));
      await tester.pumpAndSettle();
      expect(find.byType(DailyHistoryScreen), findsOneWidget);
      expect(find.text('01:20 · 1 hint · 1 incorrect check'), findsOneWidget);
      expect(daily.results, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
