import 'dart:async';
import 'dart:io';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/app_settings.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_result_share_service.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/app/fluid_navigation_bar.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/settings_screen.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/data/track_catalogue_data.dart';
import 'package:arrowword/features/puzzle/data/word_catalogue_data.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:arrowword/features/puzzle/localization/clue_pack.dart';
import 'package:arrowword/features/puzzle/localization/localized_clue_audit.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:arrowword/l10n/app_language.dart';
import 'package:arrowword/l10n/clue_pack_cache.dart';
import 'package:arrowword/l10n/clue_presentation.dart';
import 'package:arrowword/l10n/generated/app_localizations.dart';
import 'package:arrowword/l10n/language_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements LanguagePreferenceStore {
  _Store([this.value]);
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

class _Generator extends PuzzleSequenceGenerator {
  _Generator(this.result) : super(prototypeCatalogue, prototypeSequenceConfig);
  final SequencePuzzleResult result;
  int calls = 0;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls++;
    return result;
  }
}

void main() {
  const tags = ['tr', 'en', 'es', 'de', 'fr', 'pt-BR'];
  final sources = {
    for (final tag in tags)
      tag: File('assets/clues/$tag.json').readAsStringSync(),
  };
  final packs = sources.map(
    (tag, source) => MapEntry(tag, decodeCluePack(source)),
  );
  final words = [...catalogueWords, ...mediumWords, ...hardWords];
  final resolver = LocalizedClueResolver(packs, completeLocales: tags.toSet());
  late SequencePuzzleResult fixture;
  setUpAll(
    () => fixture = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateNext(puzzleIndex: 1),
  );
  test('six complete production locales and 5400 clue strings', () {
    expect(LanguagePolicy.production.enabled, tags);
    expect(packs.values.fold<int>(0, (n, p) => n + p.length), 5400);
  });
  for (final tag in tags.skip(2)) {
    final audit = LocalizedClueAudit(words, packs[tag]!, packs['en']!);
    test('$tag has exact canonical 900 IDs in frozen order', () {
      expect(packs[tag], hasLength(900));
      expect(packs[tag]!.keys.toList(), packs['en']!.keys.toList());
      expect(audit.errors, isEmpty);
    });
    for (final track in ['easy', 'medium', 'hard']) {
      test('$tag/$track has 300 concise UTF-8 clues', () {
        final stats = audit.statistics(track);
        expect(stats['count'], 300);
        expect(stats['maxWords'], lessThanOrEqualTo(10));
        expect(stats['maxCharacters'], lessThanOrEqualTo(85));
        expect(audit.punctuationWarnings, isEmpty);
      });
    }
    test(
      '$tag complete pack resolves every approved entry without fallback',
      () {
        for (final word in words) {
          expect(resolver.resolve(word.clueId!, tag), packs[tag]![word.clueId]);
        }
      },
    );
    test('$tag preference restores and persists only its machine ID', () async {
      final store = _Store(tag);
      final language = await AppLanguage.restore(store);
      expect(language.preference.id, tag);
      expect(store.writes, 0);
      await language.setPreference(AppLanguagePreference.system);
      await language.setPreference(AppLanguagePreference.parse(tag));
      expect(store.value, tag);
      expect(store.writes, 2);
      language.dispose();
    });
  }
  for (final entry in {
    'tr-TR': 'tr',
    'en-GB': 'en',
    'es-MX': 'es',
    'es-ES': 'es',
    'de-DE': 'de',
    'de-AT': 'de',
    'fr-FR': 'fr',
    'fr-CA': 'fr',
    'pt-BR': 'pt-BR',
    'pt_BR': 'pt-BR',
    'pt': 'pt-BR',
    'pt-PT': 'en',
    'pt-AO': 'en',
    'fi-FI': 'en',
    'ja-JP': 'en',
  }.entries) {
    test(
      'device ${entry.key} resolves ${entry.value}, explicit override wins',
      () {
        expect(
          LanguagePolicy.production.resolve(AppLanguagePreference.system, [
            entry.key,
          ]),
          entry.value,
        );
        for (final preference
            in AppLanguagePreference.values
                .skip(1)
                .where(
                  (p) => LanguagePolicy.production.enabled.contains(p.id),
                )) {
          expect(
            LanguagePolicy.production.resolve(preference, [entry.key]),
            preference.id,
          );
        }
      },
    );
  }
  test('UTF-8 tokens retain accents, umlauts and non-Latin letters', () {
    expect(LocalizedClueAudit.tokenize('Élévation über ação 中文'), [
      'élévation',
      'über',
      'ação',
      '中文',
    ]);
  });
  test(
    'audit rejects duplicate, untranslated and exact own-answer leakage',
    () {
      const entries = [
        WordEntry('CLOUD', 'x', clueId: 'easy_v3_000001'),
        WordEntry('RAIN', 'y', clueId: 'easy_v3_000002'),
      ];
      final audit = LocalizedClueAudit(
        entries,
        {'easy_v3_000001': 'CLOUD', 'easy_v3_000002': 'CLOUD'},
        {'easy_v3_000001': 'CLOUD'},
      );
      expect(audit.errors.where((e) => e.contains('duplicate')), hasLength(1));
      expect(audit.errors.where((e) => e.contains('leakage')), hasLength(1));
      expect(
        audit.errors.where((e) => e.contains('untranslated')),
        hasLength(1),
      );
      final inflected = LocalizedClueAudit(entries, {
        'easy_v3_000001': 'Clouds overhead',
        'easy_v3_000002': 'Raining outside',
      }, {});
      expect(
        inflected.errors.where((e) => e.contains('inflection')),
        hasLength(2),
      );
    },
  );
  test('new packs load on demand once, not all six', () async {
    final reads = <String>[];
    final cache = CluePackCache((tag) async {
      reads.add(tag);
      return sources[tag]!;
    }, locales: tags);
    expect(reads, isEmpty);
    expect(cache.loadFor('es'), same(cache.loadFor('es')));
    await cache.loadFor('es');
    expect(reads, ['es']);
    await cache.loadFor('de');
    await cache.loadFor('es');
    expect(reads, ['es', 'de']);
    await cache.loadFor('tr');
    expect(reads, ['es', 'de', 'tr', 'en']);
  });
  test('missing clue in complete new locale fails instead of wrong-language fallback', () {
    final broken = LocalizedClueResolver(
      {'fr': {}, 'en': packs['en']!},
      completeLocales: {'fr', 'en'},
    );
    expect(
      () => broken.resolve(words.first.clueId!, 'fr'),
      throwsA(isA<ClueIntegrityException>()),
    );
  });

  Future<void> compact(
    WidgetTester tester,
    Widget child,
    String tag,
    double scale,
    bool dark,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final parts = tag.split('-');
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale.fromSubtags(
          languageCode: parts.first,
          countryCode: parts.length > 1 ? parts.last : null,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final tag in tags.skip(2)) {
    for (final scale in [1.3, 1.5]) {
      testWidgets('$tag compact Settings/About and autonyms scale $scale', (
        tester,
      ) async {
        final settings = AppSettings(MemorySettingsStore());
        final language = AppLanguage(_Store());
        addTearDown(settings.dispose);
        addTearDown(language.dispose);
        await compact(
          tester,
          SettingsScreen(settings: settings, language: language),
          tag,
          scale,
          true,
        );
        final context = tester.element(find.byType(SettingsScreen));
        final strings = AppLocalizations.of(context)!;
        expect(find.text(strings.language), findsOneWidget);
        await tester.tap(
          find.byType(DropdownButtonFormField<AppLanguagePreference>),
        );
        await tester.pumpAndSettle();
        expect(find.text('Português (Brasil)'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Português (Brasil)'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(strings.appInformation));
        await tester.tap(find.text(strings.appInformation));
        await tester.pumpAndSettle();
        expect(find.text('Arrowword'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
      testWidgets('$tag frozen navigation compact semantics scale $scale', (
        tester,
      ) async {
        await compact(
          tester,
          Scaffold(
            bottomNavigationBar: FluidNavigationBar(
              index: 2,
              onSelected: (_) {},
            ),
          ),
          tag,
          scale,
          false,
        );
        final strings = AppLocalizations.of(
          tester.element(find.byType(FluidNavigationBar)),
        )!;
        expect(find.text(strings.daily), findsOneWidget);
        expect(find.bySemanticsLabel(strings.daily), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
      testWidgets('$tag compact puzzle actions and clues scale $scale', (
        tester,
      ) async {
        await compact(
          tester,
          CluePresentation(
            resolver: resolver,
            locale: tag,
            child: PuzzleScreen(puzzle: fixture.puzzle!),
          ),
          tag,
          scale,
          true,
        );
        final strings = AppLocalizations.of(
          tester.element(find.byType(PuzzleScreen)),
        )!;
        expect(find.text(strings.rewardHint), findsOneWidget);
        if (tag == 'de') expect(strings.rewardHint, 'Tipp per Werbung');
        for (final answer in fixture.puzzle!.answers) {
          expect(find.text(packs[tag]![answer.clueId]!), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'late language pack is atomic and preserves game, selection and attempt',
    (tester) async {
      final release = Completer<void>(), reads = <String>[];
      final cache = CluePackCache((tag) async {
        reads.add(tag);
        if (tag == 'fr') await release.future;
        return sources[tag]!;
      }, locales: tags);
      final generator = _Generator(fixture);
      final session = PuzzleSession(generator: generator);
      final language = AppLanguage(_Store('tr'), AppLanguagePreference.turkish);
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
      final answer = fixture.puzzle!.answers.first;
      game.tapCell(answer.positions.first);
      game.enterLetter(answer.solution[0]);
      game.revealSelectedLetter();
      game.check();
      final letters = Map.of(game.enteredLetters), checks = game.wrongChecks;
      final hints = Set.of(game.revealedCells),
          selected = game.selectedPosition;
      await language.setPreference(AppLanguagePreference.french);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(state.timer.isRunning, isFalse);
      expect(find.text(packs['tr']![answer.clueId]!), findsNothing);
      release.complete();
      await tester.pumpAndSettle();
      expect(
        (tester.state(find.byType(PuzzleScreen)) as dynamic).game,
        same(game),
      );
      expect(state.timer.isRunning, isTrue);
      expect(game.enteredLetters, letters);
      expect(game.wrongChecks, checks);
      expect(game.revealedCells, hints);
      expect(game.selectedPosition, selected);
      expect(find.text(packs['fr']![answer.clueId]!), findsOneWidget);
      expect(reads, ['tr', 'en', 'fr']);
      expect(session.completedThrough, 0);
      expect(session.completedScores, isEmpty);
      expect(generator.calls, 1);
    },
  );
  test('same Daily identity and board resolve all six clue packs', () {
    const date = '2026-10-04';
    final puzzle = generateDailyPuzzle(date).puzzle!;
    final signature = puzzleStructuralSignature(puzzle);
    final seed = dailyPuzzleSeed(date), id = dailyPuzzleId(date);
    for (final tag in tags) {
      for (final answer in puzzle.answers) {
        expect(
          resolver.resolve(answer.clueId!, tag),
          packs[tag]![answer.clueId],
        );
      }
      expect(puzzleStructuralSignature(puzzle), signature);
      expect(dailyPuzzleSeed(date), seed);
      expect(puzzle.id, id);
    }
  });
  for (final tag in tags.skip(2)) {
    testWidgets('$tag production shell all tabs stay localized at scale 1.5', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final language = AppLanguage(
        _Store(tag),
        AppLanguagePreference.parse(tag),
      );
      final generator = _Generator(fixture);
      final session = PuzzleSession(generator: generator);
      addTearDown(language.dispose);
      addTearDown(session.dispose);
      var reads = 0;
      final cache = CluePackCache((tag) async {
        reads++;
        return sources[tag]!;
      }, locales: tags);
      await tester.pumpWidget(
        ArrowwordApp(session: session, language: language, clueCache: cache),
      );
      await tester.pumpAndSettle();
      for (final index in [1, 2, 3, 0]) {
        await tester.tap(find.byKey(ValueKey('navigation-$index')));
        await tester.pumpAndSettle();
        final strings = AppLocalizations.of(
          tester.element(find.byType(FluidNavigationBar)),
        )!;
        expect(strings.localeName.replaceAll('_', '-'), tag);
        expect(tester.takeException(), isNull);
      }
      expect(reads, 0);
      expect(generator.calls, 1);
    });
    test(
      '$tag Daily share has localized chrome, date and safe numerical values',
      () async {
        final parts = tag.split('-');
        final strings = await AppLocalizations.delegate.load(
          Locale.fromSubtags(
            languageCode: parts.first,
            countryCode: parts.length > 1 ? parts.last : null,
          ),
        );
        final result = DailyPuzzleScore(
          dateKey: '2026-10-04',
          dailyPuzzleId: dailyPuzzleId('2026-10-04'),
          score: 1250,
          elapsedSeconds: 80,
          hintsUsed: 1,
          wrongChecks: 2,
        );
        final text = dailyResultShareText(result, streak: 3, strings: strings);
        expect(text, contains(strings.dailyTitle));
        expect(text, contains('1250'));
        expect(text, contains('01:20'));
        expect(text, contains(strings.month10));
        expect(text, isNot(contains('Puan:')));
        expect(text, isNot(contains('easy_v3_')));
        expect(text, isNot(contains('APPLE')));
      },
    );
  }
}
