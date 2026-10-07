import 'dart:io';
import 'dart:async';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/app_settings.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_puzzle_screen.dart';
import 'package:arrowword/app/daily_result_share_service.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/app/player_statistics.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_replay_screen.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/data/word_catalogue_data.dart';
import 'package:arrowword/features/puzzle/data/track_catalogue_data.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:arrowword/features/puzzle/localization/clue_pack.dart';
import 'package:arrowword/features/puzzle/localization/english_clue_audit.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:arrowword/l10n/app_language.dart';
import 'package:arrowword/l10n/clue_pack_cache.dart';
import 'package:arrowword/l10n/clue_presentation.dart';
import 'package:arrowword/l10n/generated/app_localizations.dart';
import 'package:arrowword/l10n/language_policy.dart';
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
  _FixtureGenerator(this.puzzles)
    : super(prototypeCatalogue, prototypeSequenceConfig);
  final List<SequencePuzzleResult> puzzles;
  int calls = 0;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls++;
    return puzzles[puzzleIndex - 1];
  }
}

class _Share implements DailyResultShareService {
  final texts = <String>[];
  @override
  Future<void> share(String text, {Rect? origin}) async => texts.add(text);
}

void main() {
  final words = [...catalogueWords, ...mediumWords, ...hardWords];
  final enSource = File('assets/clues/en.json').readAsStringSync();
  final trSource = File('assets/clues/tr.json').readAsStringSync();
  final en = decodeCluePack(enSource), tr = decodeCluePack(trSource);
  final packs = {
    'tr': tr,
    'en': en,
    for (final locale in ['es', 'de', 'fr', 'pt-BR'])
      locale: decodeCluePack(
        File('assets/clues/$locale.json').readAsStringSync(),
      ),
  };
  final resolver = LocalizedClueResolver(
    packs,
    completeLocales: packs.keys.toSet(),
  );
  final audit = EnglishClueAudit(words, en);
  late List<SequencePuzzleResult> fixtures;
  setUpAll(
    () => fixtures = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateRange(count: 2).puzzles,
  );

  test('English pack exists and has exactly 900 entries', () {
    expect(File('assets/clues/en.json').existsSync(), isTrue);
    expect(en, hasLength(900));
  });
  test('English has precisely the Turkish ID set and order', () {
    expect(en.keys.toList(), tr.keys.toList());
    expect(en.keys.toSet(), words.map((w) => w.clueId).toSet());
  });
  test(
    'English has no blanks or duplicate definitions ignoring case/spacing',
    () {
      expect(en.values.every((v) => v.trim().isNotEmpty), isTrue);
      expect(
        en.values
            .map((v) => v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
            .toSet(),
        hasLength(900),
      );
    },
  );
  test('Turkish remains exactly the approved legacy catalogue text', () {
    for (final word in words) {
      expect(tr[word.clueId], word.turkishClue);
    }
    expect(tr, hasLength(900));
  });
  for (final track in ['easy', 'medium', 'hard']) {
    test('$track has 300 concise English clues and documented statistics', () {
      final stats = audit.statistics(track);
      expect(stats['count'], 300);
      expect(stats['averageWords'], inInclusiveRange(2, 7));
      expect(
        stats['maxWords'],
        lessThanOrEqualTo(
          track == 'easy'
              ? 6
              : track == 'medium'
              ? 7
              : 8,
        ),
      );
      expect(stats['maxCharacters'], lessThanOrEqualTo(56));
      expect(en.keys.where((k) => k.startsWith('${track}_')), hasLength(300));
    });
  }
  test('full English editorial audit has no direct leaks, derivatives or unreviewed root warnings', () {
    expect(audit.errors, isEmpty);
    expect(audit.rootWarnings, isEmpty);
    expect(audit.punctuationWarnings, isEmpty);
    expect(audit.genericWarnings, isEmpty);
    expect(audit.lengthWarnings.map((w) => w.split(' ').first).toSet(), {
      'easy_v3_000075',
      'easy_v3_000270',
    });
  });
  for (final example in <String, String>{
    'DRIFT|Drift from side to side': 'direct',
    'DRIFT|DRIFT moves': 'direct',
    'DRIFT|Drifts across water': 'derived',
    'DRIFT|Drifted movement': 'derived',
    'DRIFT|Drifting movement': 'derived',
    'CLOUD|Cloudy sky feature': 'derived',
    'FARM|Farmhouse property': 'derived',
    'RAIN|Rainfall from the sky': 'derived',
    "FARM|Farmer's property": 'derived',
    'CHOOSE|Make a choice': 'derived',
    'WRITE|Written marks': 'derived',
    'FOOT|Feet on the ground': 'derived',
    'FARM|A farm-house property': 'direct',
  }.entries) {
    test('leakage validator rejects ${example.key}', () {
      final parts = example.key.split('|');
      final single = EnglishClueAudit(
        [WordEntry(parts[0], 'Fixture', clueId: 'easy_v3_000001')],
        {'easy_v3_000001': parts[1]},
      );
      expect(single.errors, isNotEmpty);
    });
  }
  test('heuristic flags unknown compounds without pretending they are certain morphology', () {
    final sample = EnglishClueAudit(
      [const WordEntry('FARM', 'Fixture', clueId: 'easy_v3_000001')],
      {'easy_v3_000001': 'Green farmlandlike surroundings'},
    );
    expect(sample.rootWarnings, isNotEmpty);
  });
  test('validator detects duplicates, missing/unknown IDs, punctuation and generic filler', () {
    final sample = [
      const WordEntry('ACORN', 'Fixture', clueId: 'medium_v1_000001'),
      const WordEntry('MAPLE', 'Fixture', clueId: 'medium_v1_000002'),
    ];
    expect(
      EnglishClueAudit(sample, {
        'medium_v1_000001': 'Same description',
        'medium_v1_000002': 'Same description',
      }).errors,
      isNotEmpty,
    );
    expect(EnglishClueAudit(sample, {'wrong': 'Nope'}).errors, isNotEmpty);
    final noisy = EnglishClueAudit(sample, {
      'medium_v1_000001': 'A type of thing!',
      'medium_v1_000002':
          'A very very very very very very very very lengthy phrase.',
    });
    expect(noisy.punctuationWarnings, hasLength(2));
    expect(noisy.genericWarnings, hasLength(1));
    expect(noisy.lengthWarnings, isNotEmpty);
  });
  test(
    'editorial sense distinctions remain explicit across related answers',
    () {
      String clue(String answer) =>
          en[words.singleWhere((w) => w.solution == answer).clueId]!;
      expect(clue('BANK'), contains('money'));
      expect(clue('LIGHT'), contains('Illumination'));
      expect(clue('WATCH'), contains('wrist'));
      expect(clue('BARK'), contains('Tree'));
      expect(clue('COLUMN'), contains('newspaper'));
      expect(clue('PILLAR'), contains('support'));
      expect(clue('CHOICE'), startsWith('Act'));
      expect(clue('OPTION'), contains('alternative'));
      expect(clue('CITE'), contains('source'));
      expect(clue('QUOTE'), contains('words exactly'));
      expect(clue('HINDER'), contains('task'));
      expect(clue('IMPEDE'), contains('movement'));
      expect(clue('AMBLE'), contains('steps'));
      expect(clue('SAUNTER'), contains('pleasure'));
      expect(clue('NEST'), startsWith('Arrange'));
      expect(clue('STEM'), startsWith('Arise'));
    },
  );
  test(
    'production complete locale registry includes all six complete packs',
    () {
      expect(LanguagePolicy.production.enabled, [
        'tr',
        'en',
        'es',
        'de',
        'fr',
        'pt-BR',
      ]);
      expect(
        LanguagePolicy.production.locales.every(
          (l) => l.uiComplete && l.cluesComplete,
        ),
        isTrue,
      );
    },
  );
  for (final tag in [
    'tr',
    'tr-TR',
    'tr-CY',
    'en',
    'en-US',
    'en-GB',
    'de-DE',
    'fr-FR',
    'es-MX',
    'fi-FI',
    'ja-JP',
  ]) {
    test('System $tag resolves to its complete locale or English fallback', () {
      final policy = LanguagePolicy.production;
      expect(policy.resolve(AppLanguagePreference.system, [tag]), switch (tag
          .split('-')
          .first) {
        'tr' => 'tr',
        'de' => 'de',
        'fr' => 'fr',
        'es' => 'es',
        _ => 'en',
      });
      expect(policy.resolve(AppLanguagePreference.english, [tag]), 'en');
      expect(policy.resolve(AppLanguagePreference.turkish, [tag]), 'tr');
    });
  }
  test('missing/corrupt preference restores System without a write', () async {
    for (final value in [null, 'broken']) {
      final store = _LanguageStore(value);
      final language = await AppLanguage.restore(store);
      expect(language.preference, AppLanguagePreference.system);
      expect(store.writes, 0);
      expect(
        LanguagePolicy.production.resolve(language.preference, ['de-DE']),
        'de',
      );
      language.dispose();
    }
  });
  test(
    'pack cache is lazy, deduplicates concurrent loads and keeps O(1) maps',
    () async {
      final reads = <String>[];
      final cache = CluePackCache((locale) async {
        reads.add(locale);
        return locale == 'tr' ? trSource : enSource;
      });
      expect(reads, isEmpty);
      expect(cache.ready, isNull);
      final first = cache.load(), second = cache.load();
      expect(second, same(first));
      final loaded = await first;
      expect(reads, ['tr', 'en']);
      expect(cache.ready, same(loaded));
      expect(await cache.load(), same(loaded));
      for (final word in words) {
        expect(loaded.resolve(word.clueId!, 'en'), en[word.clueId]);
      }
      expect(reads, ['tr', 'en']);
    },
  );
  test(
    'language preference never writes progression, Daily or last-played keys',
    () async {
      final before = {
        'arrowword.puzzle_progress': 'easy',
        'arrowword.puzzle_progress.medium': 'medium',
        'arrowword.puzzle_progress.hard': 'hard',
        'arrowword.daily_progress': 'daily',
        'arrowword.last_puzzle_difficulty': 'hard',
      };
      SharedPreferences.setMockInitialValues(before);
      final language = await AppLanguage.restore(
        SharedPreferencesLanguageStore(),
      );
      await language.setPreference(AppLanguagePreference.english);
      final prefs = await SharedPreferences.getInstance();
      for (final entry in before.entries) {
        expect(prefs.getString(entry.key), entry.value);
      }
      expect(prefs.getString(SharedPreferencesLanguageStore.key), 'en');
      final restored = await AppLanguage.restore(
        SharedPreferencesLanguageStore(),
      );
      expect(restored.preference, AppLanguagePreference.english);
      language.dispose();
      restored.dispose();
    },
  );

  Future<(PuzzleSession, _FixtureGenerator, AppLanguage, _LanguageStore)> app(
    WidgetTester tester, {
    String? preference,
    String device = 'tr',
    CluePackCache? cache,
    bool directly = false,
    bool compact = false,
    bool dark = false,
  }) async {
    tester.binding.platformDispatcher.localesTestValue = [Locale(device)];
    final store = _LanguageStore(preference);
    final actual = await AppLanguage.restore(store);
    final generator = _FixtureGenerator(fixtures),
        session = PuzzleSession(generator: generator);
    addTearDown(actual.dispose);
    addTearDown(session.dispose);
    if (compact) {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    final settings = AppSettings(
      MemorySettingsStore(),
      dark ? ThemeMode.dark : ThemeMode.light,
    );
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      ArrowwordApp(
        session: session,
        language: actual,
        settings: settings,
        clueResolver: cache == null ? resolver : null,
        clueCache: cache,
        openPuzzleDirectly: directly,
      ),
    );
    await tester.pumpAndSettle();
    return (session, generator, actual, store);
  }

  for (final device in ['tr', 'en', 'de', 'fr', 'es', 'fi', 'ja']) {
    testWidgets(
      'production device $device has matching UI and actual clue pack',
      (tester) async {
        final (session, _, _, store) = await app(
          tester,
          device: device,
          directly: true,
        );
        final locale = ['tr', 'en', 'de', 'fr', 'es'].contains(device)
                ? device
                : 'en',
            puzzle = session.current.puzzle!;
        final context = tester.element(find.byType(PuzzleScreen));
        expect(AppLocalizations.of(context)!.localeName, locale);
        for (final answer in puzzle.answers) {
          expect(find.text(packs[locale]![answer.clueId]!), findsOneWidget);
        }
        expect(find.text(AppLocalizations.of(context)!.check), findsOneWidget);
        expect(store.writes, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Home and all 36 progression tiles never load clue assets', (
    tester,
  ) async {
    var reads = 0;
    final cache = CluePackCache((locale) async {
      reads++;
      return locale == 'tr' ? trSource : enSource;
    });
    final (_, generator, _, _) = await app(tester, cache: cache);
    expect(reads, 0);
    expect(generator.calls, 1);
    await tester.tap(find.byKey(const ValueKey('navigation-1')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(GridView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(reads, 0);
    expect(generator.calls, 1);
  });
  testWidgets(
    'first gameplay caches both packs and language changes do not recreate game',
    (tester) async {
      final reads = <String>[];
      final cache = CluePackCache((locale) async {
        reads.add(locale);
        return locale == 'tr' ? trSource : enSource;
      });
      final (session, generator, language, store) = await app(
        tester,
        preference: 'tr',
        cache: cache,
        directly: true,
      );
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      final PuzzleGame game = state.game;
      final answer = session.current.puzzle!.answers.first;
      game.tapCell(answer.positions.first);
      game.enterLetter(answer.solution[0]);
      game.check();
      final letters = Map.of(game.enteredLetters),
          hints = Set.of(game.revealedCells),
          checks = game.wrongChecks;
      final elapsed = state.timer.elapsed as Duration;
      final signature = puzzleStructuralSignature(game.puzzle);
      final history = session.history.map((h) => h.words).toList();
      await language.setPreference(AppLanguagePreference.english);
      await tester.pumpAndSettle();
      expect(
        (tester.state(find.byType(PuzzleScreen)) as dynamic).game,
        same(game),
      );
      expect(game.enteredLetters, letters);
      expect(game.revealedCells, hints);
      expect(game.wrongChecks, checks);
      expect(
        (state.timer.elapsed as Duration).compareTo(elapsed),
        greaterThanOrEqualTo(0),
      );
      expect(puzzleStructuralSignature(game.puzzle), signature);
      expect(generator.calls, 1);
      expect(reads, ['tr', 'en']);
      expect(session.current.puzzleIndex, 1);
      expect(session.completedThrough, 0);
      expect(session.history.map((h) => h.words).toList(), history);
      expect(session.completedScores, isEmpty);
      expect(find.text(en[answer.clueId]!), findsOneWidget);
      expect(store.value, 'en');
      await language.setPreference(AppLanguagePreference.turkish);
      await tester.pumpAndSettle();
      expect(find.text(tr[answer.clueId]!), findsOneWidget);
      expect(game.enteredLetters, letters);
      expect(generator.calls, 1);
      expect(reads, ['tr', 'en']);
      expect(store.value, 'tr');
    },
  );
  testWidgets(
    'Settings exposes autonyms and persists English then Turkish then System',
    (tester) async {
      final (session, generator, language, store) = await app(
        tester,
        preference: 'tr',
      );
      await tester.tap(find.byTooltip('Ayarlar'));
      await tester.pumpAndSettle();
      expect(find.text('Dil'), findsOneWidget);
      Future<void> choose(String label) async {
        await tester.tap(
          find.byType(DropdownButtonFormField<AppLanguagePreference>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      await choose('English');
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(store.value, 'en');
      expect(language.preference, AppLanguagePreference.english);
      await choose('Türkçe');
      expect(find.text('Dil'), findsOneWidget);
      expect(store.value, 'tr');
      await choose('Sistem Varsayılanı');
      expect(store.value, 'system');
      expect(language.preference, AppLanguagePreference.system);
      final restored = await AppLanguage.restore(store);
      expect(restored.preference, AppLanguagePreference.system);
      restored.dispose();
      expect(generator.calls, 1);
      expect(session.current.puzzleIndex, 1);
      expect(store.writes, 3);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'language switch preserves saved letters, hints, time, checks, history and nonzero best scores',
    (tester) async {
      final generator = _FixtureGenerator(fixtures),
          store = MemoryPuzzleProgressStore();
      final session = PuzzleSession(
        generator: generator,
        startIndex: 2,
        store: store,
      );
      final score = CompletedPuzzleScore.calculate(
        puzzleIndex: 1,
        elapsedSeconds: 110,
        hintsUsed: 1,
        wrongChecks: 3,
      );
      expect(session.recordReplayScore(score), isTrue);
      final answer = session.current.puzzle!.answers.first;
      session.updateAttemptProgress(
        {answer.positions.first: answer.solution[0]},
        {answer.positions.first},
        const Duration(seconds: 17),
        2,
      );
      await session.flush;
      final saved = store.record,
          history = session.history.map((h) => h.words).toList();
      final language = AppLanguage(
        _LanguageStore('tr'),
        AppLanguagePreference.turkish,
      );
      addTearDown(language.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ArrowwordApp(
          session: session,
          language: language,
          clueResolver: resolver,
          openPuzzleDirectly: true,
        ),
      );
      await tester.pumpAndSettle();
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      final PuzzleGame game = state.game;
      final letters = game.enteredLetters;
      await language.setPreference(AppLanguagePreference.english);
      await tester.pumpAndSettle();
      expect(
        (tester.state(find.byType(PuzzleScreen)) as dynamic).game,
        same(game),
      );
      expect(game.enteredLetters, letters);
      expect(game.hintsUsed, 1);
      expect(game.wrongChecks, 2);
      expect(session.elapsed, const Duration(seconds: 17));
      expect(session.hintsUsed, 1);
      expect(session.wrongChecks, 2);
      expect(session.current.puzzleIndex, 2);
      expect(session.completedThrough, 1);
      expect(session.completedScores[1], same(score));
      expect(session.history.map((h) => h.words).toList(), history);
      expect(store.record, saved);
      expect(generator.calls, 2);
      final stats = PlayerStatistics.fromScores(
        completedThrough: session.completedThrough,
        scores: session.completedScores.values,
      );
      expect(stats.totalScore, score.score);
      expect(stats.scoredPuzzleCount, 1);
      expect(stats.averageScore, score.score.toDouble());
    },
  );
  testWidgets(
    'clue loading paints feedback and does not construct a gameplay timer early',
    (tester) async {
      final pending = {'tr': Completer<String>(), 'en': Completer<String>()};
      final cache = CluePackCache((locale) => pending[locale]!.future);
      final session = PuzzleSession(generator: _FixtureGenerator(fixtures));
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ArrowwordApp(
          session: session,
          clueCache: cache,
          openPuzzleDirectly: true,
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(PuzzleScreen), findsNothing);
      pending['tr']!.complete(trSource);
      await tester.pump();
      expect(find.byType(PuzzleScreen), findsNothing);
      pending['en']!.complete(enSource);
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleScreen), findsOneWidget);
      expect(cache.ready, isNotNull);
    },
  );
  testWidgets(
    'system language changes in an open app update presentation only',
    (tester) async {
      final (session, generator, _, store) = await app(tester, directly: true);
      final context = tester.element(find.byType(PuzzleScreen));
      final puzzle = session.current.puzzle!, id = puzzle.id;
      tester.binding.platformDispatcher.localesTestValue = [
        const Locale('en', 'GB'),
      ];
      await tester.pumpAndSettle();
      expect(AppLocalizations.of(context)!.localeName, 'en');
      expect(session.current.puzzle!.id, id);
      expect(generator.calls, 1);
      expect(store.writes, 0);
      tester.binding.platformDispatcher.localesTestValue = [
        const Locale('tr', 'TR'),
      ];
      await tester.pumpAndSettle();
      expect(AppLocalizations.of(context)!.localeName, 'tr');
      expect(generator.calls, 1);
    },
  );
  testWidgets(
    'every rendered language-switch frame pairs UI and clues atomically',
    (tester) async {
      final (session, _, language, _) = await app(
        tester,
        preference: 'tr',
        directly: true,
      );
      final answer = session.current.puzzle!.answers.first;
      for (final preference in [
        AppLanguagePreference.english,
        AppLanguagePreference.turkish,
      ]) {
        await language.setPreference(preference);
        for (var frame = 0; frame < 3; frame++) {
          await tester.pump();
          final context = tester.element(find.byType(PuzzleScreen));
          final ui = AppLocalizations.of(context)!;
          final clue = CluePresentation.text(context, answer);
          expect(clue, (ui.localeName == 'tr' ? tr : en)[answer.clueId]);
          expect(find.text(ui.check), findsOneWidget);
        }
        await tester.pumpAndSettle();
      }
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'English compact ${dark ? 'dark' : 'light'} UI and Settings at 1.5 scale fit',
      (tester) async {
        await app(tester, preference: 'en', compact: true, dark: dark);
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        // The new language control is tested at real accessibility scale.
        final view = tester.view;
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.5;
        await tester.pumpAndSettle();
        expect(find.text('Language'), findsOneWidget);
        expect(view.physicalSize, const Size(360, 640));
        expect(tester.takeException(), isNull);
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
      },
    );
  }
  testWidgets(
    'English compact puzzle actions and localized hint semantics fit',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final puzzle = fixtures.first.puzzle!, first = puzzle.answers.first;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: CluePresentation(
            resolver: resolver,
            locale: 'en',
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: PuzzleScreen(
                puzzle: puzzle,
                monotonicNow: () => Duration.zero,
                initialRevealedCells: {first.positions.first},
                initialLetters: {first.positions.first: first.solution[0]},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reveal with Ad'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Revealed with a hint, locked')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
  testWidgets(
    'failed clue assets show a safe localized error without constructing gameplay',
    (tester) async {
      final cache = CluePackCache(
        (_) async => throw const FormatException('INTERNAL_ASSET_ERROR'),
      );
      await app(tester, preference: 'en', cache: cache, directly: true);
      expect(find.text('This clue is currently unavailable.'), findsOneWidget);
      expect(find.byType(PuzzleScreen), findsNothing);
      expect(find.textContaining('INTERNAL'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'replay uses English presentation without changing board or score history',
    (tester) async {
      final session = PuzzleSession(
        generator: _FixtureGenerator(fixtures),
        startIndex: 2,
      );
      addTearDown(session.dispose);
      final before = session.buildReplayPuzzle(1),
          stats = PlayerStatistics.fromScores(
            completedThrough: session.completedThrough,
            scores: session.completedScores.values,
          );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: CluePresentation(
            resolver: resolver,
            locale: 'en',
            child: PuzzleReplayScreen(
              session: session,
              puzzleIndex: 1,
              monotonicNow: () => Duration.zero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final puzzle = tester
          .widget<PuzzleScreen>(find.byType(PuzzleScreen))
          .puzzle;
      expect(
        puzzleStructuralSignature(puzzle),
        puzzleStructuralSignature(before.puzzle!),
      );
      for (final answer in puzzle.answers) {
        expect(find.text(en[answer.clueId]!), findsOneWidget);
      }
      expect(session.current.puzzleIndex, 2);
      expect(session.completedThrough, 1);
      expect(session.completedScores, isEmpty);
      expect(
        PlayerStatistics.fromScores(
          completedThrough: session.completedThrough,
          scores: session.completedScores.values,
        ).totalScore,
        stats.totalScore,
      );
    },
  );
  testWidgets(
    'Daily English clues and share retain original identity, progress and result',
    (tester) async {
      final store = MemoryDailyProgressStore();
      final daily = await DailySession.restore(
        store: store,
        localNow: () => DateTime(2026, 10, 4),
        generator: (key) => DailyPuzzleGeneration.success(
          Puzzle(
            id: dailyPuzzleId(key),
            label: 'fixture',
            rowCount: fixtures.first.puzzle!.rowCount,
            columnCount: fixtures.first.puzzle!.columnCount,
            answers: fixtures.first.puzzle!.answers,
          ),
        ),
      );
      addTearDown(daily.dispose);
      final share = _Share();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: CluePresentation(
            resolver: resolver,
            locale: 'en',
            child: DailyPuzzleScreen(
              session: daily,
              monotonicNow: () => Duration.zero,
              shareService: share,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final puzzle = tester
          .widget<PuzzleScreen>(find.byType(PuzzleScreen))
          .puzzle;
      expect(puzzle.id, 'daily-v1-c3-2026-10-04');
      expect(dailyPuzzleSeed(daily.dateKey), 927491995);
      expect(
        puzzleStructuralSignature(puzzle),
        puzzleStructuralSignature(fixtures.first.puzzle!),
      );
      for (final answer in puzzle.answers) {
        expect(find.text(en[answer.clueId]!), findsOneWidget);
      }
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      final PuzzleGame game = state.game;
      for (final answer in puzzle.answers) {
        game.tapClue(answer);
        for (final letter in answer.solution.split('')) {
          game.enterLetter(letter);
        }
      }
      await tester.pumpAndSettle();
      await daily.flush;
      expect(find.text('Daily puzzle complete!'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
      expect(daily.results, hasLength(1));
      final result = daily.results.values.single;
      final restored = await DailySession.restore(
        store: store,
        localNow: () => DateTime(2026, 10, 4),
      );
      addTearDown(restored.dispose);
      expect(restored.todayResult!.score, result.score);
      expect(restored.todayResult!.dailyPuzzleId, result.dailyPuzzleId);
      final english = dailyResultShareText(
        result,
        streak: 1,
        strings: lookupAppLocalizations(const Locale('en')),
      );
      expect(english, contains('Score:'));
      expect(english, isNot(contains('Puan:')));
      expect(english, isNot(contains(result.dailyPuzzleId)));
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('completed-daily'),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: DailyResultScreen(
            result: result,
            session: daily,
            shareService: share,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(share.texts, hasLength(1));
      expect(share.texts.single, english);
    },
  );
  test('normal and Daily score records retain their separate unchanged scoring formula', () {
    final normal = CompletedPuzzleScore.calculate(
      puzzleIndex: 1,
      elapsedSeconds: 80,
      hintsUsed: 1,
      wrongChecks: 2,
    );
    final daily = DailyPuzzleScore.calculate(
      dateKey: '2026-10-04',
      dailyPuzzleId: dailyPuzzleId('2026-10-04'),
      elapsedSeconds: 80,
      hintsUsed: 1,
      wrongChecks: 2,
    );
    expect(normal.score, 1250);
    expect(daily.score, 1250);
    expect(normal.scoringVersion, 1);
    expect(daily.scoringVersion, 1);
  });
}
