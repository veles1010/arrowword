import 'package:arrowword/app/player_statistics.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/statistics_screen.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter/material.dart';
import 'package:arrowword/features/puzzle/domain/normal_puzzle_contract.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fixtures extends PuzzleSequenceGenerator {
  _Fixtures(this.results) : super(prototypeCatalogue, prototypeSequenceConfig);

  final List<SequencePuzzleResult> results;

  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) => results[puzzleIndex - 1];
}

class _LargeCountSession extends PuzzleSession {
  _LargeCountSession(List<SequencePuzzleResult> results)
    : super(generator: _Fixtures(results));

  @override
  int get completedThrough => 0xffffffff;

  @override
  Map<int, CompletedPuzzleScore> get completedScores => {
    0xffffffff: CompletedPuzzleScore.calculate(
      puzzleIndex: 0xffffffff,
      elapsedSeconds: 999999999,
      hintsUsed: 0,
      wrongChecks: 0,
    ),
  };
}

Widget _app(PuzzleSession session) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: StatisticsScreen(session: session),
);

Finder _value(String card, String value) => find.descendant(
  of: find.byKey(ValueKey('statistics-$card')),
  matching: find.text(value),
);

void main() {
  late List<SequencePuzzleResult> results;

  setUpAll(() {
    results = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateRange(count: 2).puzzles;
  });

  PuzzleSession session({int startIndex = 1, PuzzleProgressStore? store}) {
    final value = PuzzleSession(
      generator: _Fixtures(results),
      startIndex: startIndex,
      store: store,
    );
    addTearDown(value.dispose);
    return value;
  }

  testWidgets('new player sees zero counts and missing-score placeholders', (
    tester,
  ) async {
    final player = session();
    await tester.pumpWidget(_app(player));
    expect(find.text('İstatistikler'), findsOneWidget);
    for (final label in [
      'Tamamlanan bulmaca',
      'Puanlanan bulmaca',
      'Toplam puan',
      'Ortalama puan',
      'En iyi puan',
      'İpuçsuz tamamlanan',
      'Hatasız tamamlanan',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(_value('completed', '0'), findsOneWidget);
    expect(_value('scored', '0'), findsOneWidget);
    expect(_value('total', '0'), findsOneWidget);
    expect(_value('average', 'Henüz yok'), findsOneWidget);
    expect(_value('best', 'Henüz yok'), findsOneWidget);
    expect(_value('hint-free', '0'), findsOneWidget);
    expect(_value('error-free', '0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy completion displays no fabricated score', (tester) async {
    final player = session(startIndex: 2);
    await tester.pumpWidget(_app(player));
    expect(_value('completed', '1'), findsOneWidget);
    expect(_value('scored', '0'), findsOneWidget);
    expect(_value('average', 'Henüz yok'), findsOneWidget);
    expect(_value('best', 'Henüz yok'), findsOneWidget);
  });

  testWidgets('replay improvement refreshes visible derived values', (
    tester,
  ) async {
    final player = session(startIndex: 2);
    player.recordReplayScore(
      CompletedPuzzleScore.calculate(
        puzzleIndex: 1,
        elapsedSeconds: 110,
        hintsUsed: 2,
        wrongChecks: 1,
      ),
    );
    await tester.pumpWidget(_app(player));
    expect(_value('total', '1175'), findsOneWidget);
    expect(_value('average', '1175.0'), findsOneWidget);
    expect(_value('hint-free', '0'), findsOneWidget);
    expect(_value('error-free', '0'), findsOneWidget);

    expect(
      player.recordReplayScore(
        CompletedPuzzleScore.calculate(
          puzzleIndex: 1,
          elapsedSeconds: 90,
          hintsUsed: 0,
          wrongChecks: 0,
        ),
      ),
      isTrue,
    );
    await tester.pump();
    expect(_value('completed', '1'), findsOneWidget);
    expect(_value('scored', '1'), findsOneWidget);
    expect(_value('total', '1400'), findsOneWidget);
    expect(_value('average', '1400.0'), findsOneWidget);
    expect(_value('best', '1400'), findsOneWidget);
    expect(find.text('Bulmaca 1 · 90 sn'), findsOneWidget);
    expect(_value('hint-free', '1'), findsOneWidget);
    expect(_value('error-free', '1'), findsOneWidget);
  });

  test(
    'restart derives the same archive totals without extra persistence',
    () async {
      final store = MemoryPuzzleProgressStore();
      final player = session(startIndex: 2, store: store);
      player.recordReplayScore(
        CompletedPuzzleScore.calculate(
          puzzleIndex: 1,
          elapsedSeconds: 900,
          hintsUsed: 0,
          wrongChecks: 0,
        ),
      );
      final puzzle = player.current.puzzle!;
      player.updateAttemptProgress(
        {
          for (final answer in puzzle.answers)
            for (var i = 0; i < answer.length; i++)
              answer.positions[i]: answer.solution[i],
        },
        {puzzle.answers.first.start},
        const Duration(seconds: 10),
        0,
      );
      player.recognizeCompletion();
      await player.flush;
      final writes = store.writes;
      final restored = await PuzzleSession.restore(
        store: store,
        generator: _Fixtures(results),
      );
      addTearDown(restored.dispose);
      final statistics = PlayerStatistics.fromScores(
        completedThrough: restored.completedThrough,
        scores: restored.completedScores.values,
      );
      expect(statistics.completedPuzzleCount, 2);
      expect(statistics.scoredPuzzleCount, 2);
      expect(statistics.totalScore, 2300);
      expect(statistics.averageScore, 1150);
      expect(statistics.maxScore, 1300);
      expect(statistics.bestScore!.puzzleIndex, 2);
      expect(statistics.hintFreeBestScoreCount, 1);
      expect(statistics.errorFreeBestScoreCount, 2);
      await restored.flush;
      expect(store.writes, writes);
    },
  );

  testWidgets('high counts fit a compact scrollable layout with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final player = _LargeCountSession(results);
    addTearDown(player.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: StatisticsScreen(session: player),
        ),
      ),
    );
    expect(_value('completed', '$normalPuzzleCount'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('statistics-error-free')),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(_value('error-free', '1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
