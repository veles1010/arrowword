import 'dart:convert';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/development_puzzle.dart';
import 'package:arrowword/app/player_puzzle_tracks.dart';
import 'package:arrowword/app/puzzle_difficulty_selector.dart';
import 'package:arrowword/app/puzzle_track.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_replay_attempt.dart';
import 'package:arrowword/app/puzzle_replay_screen.dart';
import 'package:arrowword/app/statistics_screen.dart';
import 'package:arrowword/features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'package:arrowword/features/puzzle/domain/normal_puzzle_contract.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_difficulty.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// State/UI fixtures only. Real 108-board validity and drift locks are independent
// in normal_36_generation_test; fake history here must not test word cooldown.
class _Generator extends PuzzleSequenceGenerator {
  _Generator(super.catalogue, super.config, this.fixture);
  final SequencePuzzleResult fixture;
  final calls = <int>[];
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls.add(puzzleIndex);
    return SequencePuzzleResult(
      puzzleIndex: puzzleIndex,
      seed: derivePuzzleSeed(config.baseSeed, puzzleIndex),
      catalogVersion: catalogue.version,
      pool: fixture.pool,
      generation: fixture.generation,
      puzzle: Puzzle(
        id: '${config.puzzleIdPrefix ?? 'generated-v${catalogue.version}'}-${puzzleIndex.toString().padLeft(6, '0')}',
        label: 'Bulmaca $puzzleIndex',
        rowCount: 10,
        columnCount: 10,
        answers: fixture.puzzle!.answers,
      ),
    );
  }
}

class _Store extends MemoryPuzzleProgressStore {
  _Store([super.record]);
  int clears = 0;
  @override
  Future<void> clear() async {
    clears++;
    await super.clear();
  }
}

Map<GridPosition, String> _solution(Puzzle puzzle) => {
  for (final a in puzzle.answers)
    for (var i = 0; i < a.length; i++) a.positions[i]: a.solution[i],
};

void main() {
  final fixtures = <PuzzleDifficulty, SequencePuzzleResult>{};
  setUpAll(() {
    for (final d in PuzzleDifficulty.values) {
      fixtures[d] = PuzzleTrackConfiguration.forDifficulty(d).createGenerator!()
          .generateNext(puzzleIndex: 1);
    }
  });
  _Generator generator(PuzzleDifficulty d) {
    final g = PuzzleTrackConfiguration.forDifficulty(d).createGenerator!();
    return _Generator(g.catalogue, g.config, fixtures[d]!);
  }

  String saved(PuzzleDifficulty d, int index, {bool solved = false}) {
    final g = generator(d), p = fixtures[d]!.puzzle!;
    final cells = _solution(p);
    return PuzzleProgress(
      catalogVersion: g.catalogue.version,
      puzzleIndex: index,
      puzzleId:
          '${g.config.puzzleIdPrefix ?? 'generated-v${g.catalogue.version}'}-${index.toString().padLeft(6, '0')}',
      signature: puzzleStructuralSignature(p),
      completedThrough: solved ? index : index - 1,
      letters: {
        for (final e
            in solved ? cells.entries : {cells.keys.first: 'Z'}.entries)
          '${e.key.row},${e.key.column}': e.value,
      },
      elapsedMilliseconds: 80000,
      wrongChecks: 1,
      completedScores: solved
          ? {
              index: CompletedPuzzleScore.calculate(
                puzzleIndex: index,
                elapsedSeconds: 80,
                hintsUsed: 0,
                wrongChecks: 1,
              ),
            }
          : {},
      history: [
        for (var i = 1; i < index; i++)
          ProgressHistoryEntry(
            puzzleIndex: i,
            wordIds: p.answers.map((a) => a.id).toList(),
          ),
      ],
    ).encode();
  }

  Future<
    ({
      PlayerPuzzleTracks tracks,
      Map<PuzzleDifficulty, _Generator> generators,
      Map<PuzzleDifficulty, _Store> stores,
      MemoryLastPuzzleDifficultyStore last,
    })
  >
  library({
    PuzzleDifficulty last = PuzzleDifficulty.easy,
    Map<PuzzleDifficulty, String> records = const {},
  }) async {
    final generators = {
      for (final d in PuzzleDifficulty.values) d: generator(d),
    };
    final stores = {
      for (final d in PuzzleDifficulty.values) d: _Store(records[d]),
    };
    final preference = MemoryLastPuzzleDifficultyStore(last.id);
    final tracks = await PlayerPuzzleTracks.restore(
      lastStore: preference,
      tracks: {
        for (final d in PuzzleDifficulty.values)
          d: PuzzleTrack(
            store: stores[d],
            configuration: PuzzleTrackConfiguration(
              difficulty: d,
              createGenerator: () => generators[d]!,
            ),
          ),
      },
    );
    addTearDown(tracks.dispose);
    return (
      tracks: tracks,
      generators: generators,
      stores: stores,
      last: preference,
    );
  }

  test('central finite contract is 36 per difficulty / 108 main puzzles', () {
    expect(normalPuzzleCount, 36);
    expect(totalNormalPuzzleCount, 108);
    for (final index in [1, 35, 36]) {
      expect(isNormalPuzzleIndex(index), isTrue);
    }
    for (final index in [0, -1, 37]) {
      expect(isNormalPuzzleIndex(index), isFalse);
    }
  });
  test('developer app range allows 36 but clearly rejects 37', () {
    expect(developmentPuzzleIndex('36'), normalPuzzleCount);
    expect(() => developmentPuzzleIndex('37'), throwsArgumentError);
    expect(() => generateDevelopmentPuzzle(37), throwsArgumentError);
  });
  for (final d in PuzzleDifficulty.values) {
    test(
      '${d.id} completes 35, advances to 36, then never creates 37; restart keeps completion',
      () async {
        final h = await library(records: {d: saved(d, 35, solved: true)});
        final s = await h.tracks.open(d);
        s.nextPuzzle();
        expect(s.current.puzzleIndex, normalPuzzleCount);
        s.updateAttemptProgress(
          _solution(s.current.puzzle!),
          {},
          const Duration(seconds: 85),
          1,
        );
        s.recognizeCompletion();
        await s.flush;
        expect(s.isTrackComplete, isTrue);
        expect(s.completedThrough, normalPuzzleCount);
        expect(s.currentScore!.score, 1375);
        final bytes = h.stores[d]!.record!;
        s.nextPuzzle();
        expect(h.generators[d]!.calls, [35, 36]);
        expect(s.current.puzzleIndex, normalPuzzleCount);
        final data = PuzzleProgress.decode(bytes);
        expect(data.schemaVersion, 5);
        expect(data.puzzleIndex, normalPuzzleCount);
        expect(data.history, hasLength(normalPuzzleCount - 1));
        final restart = await library(records: {d: bytes});
        expect(restart.tracks.summary(d).completedCount, normalPuzzleCount);
        expect(() => restart.tracks.open(d), throwsStateError);
        final restored = await restart.tracks.open(d, replay: true);
        expect(restored.letters, s.letters);
        expect(restored.currentScore!.toJson(), s.currentScore!.toJson());
        expect(restart.stores[d]!.writes, 0);
        expect(restart.stores[d]!.record, bytes);
        for (final other in PuzzleDifficulty.values.where((v) => v != d)) {
          expect(h.generators[other]!.calls, isEmpty);
          expect(h.stores[other]!.record, isNull);
        }
      },
    );
    test(
      '${d.id} Puzzle 36 replay updates only best and cannot reopen progression',
      () async {
        final h = await library(
          records: {d: saved(d, normalPuzzleCount, solved: true)},
        );
        final s = await h.tracks.open(d, replay: true);
        final replay = PuzzleReplayAttempt(
          session: s,
          puzzleIndex: normalPuzzleCount,
        );
        expect(replay.generation.isSuccess, isTrue);
        replay.updateProgress(
          _solution(replay.generation.puzzle!),
          {},
          const Duration(seconds: 60),
          0,
        );
        replay.complete();
        await s.flush;
        expect(s.completedScores[normalPuzzleCount]!.score, 1400);
        expect(s.isTrackComplete, isTrue);
        expect(s.current.puzzleIndex, normalPuzzleCount);
        s.nextPuzzle();
        expect(h.generators[d]!.calls, [36, 36]);
        expect(s.buildReplayPuzzle(37).isSuccess, isFalse);
        expect(h.last.writes, 0);
      },
    );
    testWidgets(
      '${d.id} fresh journey has 36 lazy tiles, 0/36 summary and no locked generation',
      (tester) async {
        final h = (await tester.runAsync(() => library(last: d)))!;
        await tester.pumpWidget(ArrowwordApp(tracks: h.tracks));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('navigation-1')));
        await tester.pumpAndSettle();
        expect(find.text('0 / 36 tamamlandı'), findsOneWidget);
        final grid = tester.widget<GridView>(find.byType(GridView));
        expect(grid.childrenDelegate.estimatedChildCount, normalPuzzleCount);
        expect(
          tester
              .widget<InkWell>(find.byKey(const ValueKey('puzzle-tile-1')))
              .onTap,
          isNotNull,
        );
        await tester.drag(find.byType(GridView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(find.text('Bulmaca 36'), findsOneWidget);
        expect(
          tester
              .widget<InkWell>(find.byKey(const ValueKey('puzzle-tile-36')))
              .onTap,
          isNull,
        );
        for (final g in h.generators.values) {
          expect(g.calls, isEmpty);
        }
        expect(h.last.writes, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      '${d.id} final dialog records score, has no Next and returns to completed replay journey',
      (tester) async {
        final h = (await tester.runAsync(
          () => library(last: d, records: {d: saved(d, normalPuzzleCount)}),
        ))!;
        await tester.pumpWidget(
          ArrowwordApp(
            tracks: h.tracks,
            rewardedAdFactory: () => FakeRewardedHintAdService(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Devam Et').hitTestable());
        await tester.pumpAndSettle();
        final screen = tester.widget<PuzzleScreen>(find.byType(PuzzleScreen));
        expect(screen.onNextPuzzle, isNull);
        for (final e in _solution(screen.puzzle).entries) {
          await tester.tap(
            find.byKey(ValueKey('cell-${e.key.row}-${e.key.column}')),
          );
          await tester.enterText(find.byType(TextField), e.value);
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(
          find.text('${d.turkishLabel} seviye tamamlandı!'),
          findsOneWidget,
        );
        expect(find.textContaining('Puan:'), findsOneWidget);
        expect(find.text('Sonraki Bulmaca'), findsNothing);
        expect(h.tracks.summary(d).completedCount, normalPuzzleCount);
        await tester.tap(find.text('Bulmacalara Dön'));
        await tester.pumpAndSettle();
        expect(find.text('36 / 36 tamamlandı'), findsOneWidget);
        expect(find.text('Bulmaca 37'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('puzzle-tile-36')));
        await tester.pumpAndSettle();
        expect(find.byType(PuzzleReplayScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Bulmacaları Gör'), findsOneWidget);
        expect(
          h.generators[d]!.calls.every((i) => i <= normalPuzzleCount),
          isTrue,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'finished track is focused even after another difficulty was browsed',
    (tester) async {
      const d = PuzzleDifficulty.easy;
      final data =
          jsonDecode(saved(d, normalPuzzleCount)) as Map<String, dynamic>;
      final answer = fixtures[d]!.puzzle!.answers.first;
      data['letters'] = {
        for (final e in _solution(fixtures[d]!.puzzle!).entries)
          '${e.key.row},${e.key.column}': e.value,
      };
      (data['letters'] as Map)['${answer.start.row},${answer.start.column}'] =
          'Z';
      final h = (await tester.runAsync(
        () => library(records: {d: jsonEncode(data)}),
      ))!;
      await tester.pumpWidget(
        ArrowwordApp(
          tracks: h.tracks,
          rewardedAdFactory: () => FakeRewardedHintAdService(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('navigation-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zor').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('navigation-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam Et').hitTestable());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), answer.solution[0]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bulmacalara Dön'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PuzzleDifficultySelector>(
              find.byType(PuzzleDifficultySelector).hitTestable(),
            )
            .selected,
        PuzzleDifficulty.easy,
      );
      expect(find.text('36 / 36 tamamlandı'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('pre-contract >36 payload is preserved; replay changes only scores and never generates out-of-range current', () async {
    const d = PuzzleDifficulty.easy;
    final bytes = saved(d, 40);
    final h = await library(records: {d: bytes});
    expect(h.tracks.summary(d).completedCount, normalPuzzleCount);
    expect(() => h.tracks.open(d, markPlayed: true), throwsStateError);
    expect(h.stores[d]!.record, bytes);
    expect(h.generators[d]!.calls, isEmpty);
    final s = await h.tracks.open(d, replay: true);
    expect(s.current.puzzleIndex, normalPuzzleCount);
    expect(s.letters, isEmpty);
    expect(h.generators[d]!.calls, [normalPuzzleCount]);
    expect(h.stores[d]!.record, bytes);
    expect(h.stores[d]!.writes, 0);
    final replay = PuzzleReplayAttempt(
      session: s,
      puzzleIndex: normalPuzzleCount,
    );
    replay.updateProgress(
      _solution(replay.generation.puzzle!),
      {},
      const Duration(seconds: 50),
      0,
    );
    replay.complete();
    await s.flush;
    final before = jsonDecode(bytes) as Map,
        after = jsonDecode(h.stores[d]!.record!) as Map;
    before.remove('completedScores');
    after.remove('completedScores');
    expect(after, before);
    expect(h.stores[d]!.clears, 0);
    expect(PuzzleProgress.decode(h.stores[d]!.record!).puzzleIndex, 40);
    expect(h.last.writes, 0);
  });
  testWidgets(
    'archived complete Home and statistics cap count without eager generation or fake current',
    (tester) async {
      final h = (await tester.runAsync(
        () => library(
          records: {
            PuzzleDifficulty.easy: saved(
              PuzzleDifficulty.easy,
              40,
              solved: true,
            ),
          },
        ),
      ))!;
      await tester.pumpWidget(ArrowwordApp(tracks: h.tracks));
      await tester.pumpAndSettle();
      expect(find.text('36 / 36 tamamlandı'), findsOneWidget);
      expect(find.text('Bulmacaları Gör'), findsOneWidget);
      expect(find.text('Bulmaca 40'), findsNothing);
      expect(find.text('Devam Et'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('navigation-3')));
      await tester.pumpAndSettle();
      final completed = find.byKey(const ValueKey('statistics-completed'));
      expect(
        find.descendant(of: completed, matching: find.text('36')),
        findsOneWidget,
      );
      final total = find.byKey(const ValueKey('statistics-total'));
      expect(
        find.descendant(of: total, matching: find.text('1375')),
        findsOneWidget,
      );
      expect(find.byType(StatisticsScreen), findsOneWidget);
      for (final g in h.generators.values) {
        expect(g.calls, isEmpty);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
