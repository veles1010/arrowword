import 'support/localized_back.dart';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordedGenerator extends PuzzleSequenceGenerator {
  _RecordedGenerator(this.results, {this.failAt})
    : super(prototypeCatalogue, prototypeSequenceConfig);
  final List<SequencePuzzleResult> results;
  final int? failAt;
  final List<int> calls = [];
  final List<List<int>> histories = [];
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls.add(puzzleIndex);
    histories.add(history.map((h) => h.puzzleIndex).toList());
    if (puzzleIndex == failAt) {
      return SequencePuzzleResult(
        puzzleIndex: puzzleIndex,
        seed: derivePuzzleSeed(prototypeBaseSeed, puzzleIndex),
        catalogVersion: 3,
        pool: results.first.pool,
        failureReason: 'Test generation failure',
      );
    }
    return results[puzzleIndex - 1];
  }
}

void main() {
  late List<SequencePuzzleResult> results;
  setUpAll(() {
    results = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateRange(count: 3).puzzles;
  });
  test('initial Puzzle 1 advances deterministically with complete history', () {
    final recording = _RecordedGenerator(results);
    final session = PuzzleSession(generator: recording);
    addTearDown(session.dispose);
    expect(session.current.puzzleIndex, 1);
    session.nextPuzzle();
    expect(session.current.puzzleIndex, 2);
    expect(recording.calls, [1, 2]);
    expect(recording.histories, [
      [],
      [1],
    ]);
    expect(session.history.map((h) => h.puzzleIndex), [1, 2]);
    final expected = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateNext(puzzleIndex: 2, history: [results.first.toHistory()]);
    expect(
      session.current.generation!.metrics!.structuralSignature,
      expected.generation!.metrics!.structuralSignature,
    );
    expect(
      session.current.generation!.metrics!.structuralSignature,
      isNot(results.first.generation!.metrics!.structuralSignature),
    );
  });
  test('development index replays once and continues without replay', () {
    final recording = _RecordedGenerator(results);
    final session = PuzzleSession(generator: recording, startIndex: 2);
    addTearDown(session.dispose);
    expect(session.current.puzzleIndex, 2);
    session.nextPuzzle();
    expect(recording.calls, [1, 2, 3]);
    expect(recording.histories, [
      [],
      [1],
      [1, 2],
    ]);
    expect(session.current.puzzleIndex, 3);
  });
  test('failed next generation retains valid history and exposes failure', () {
    final recording = _RecordedGenerator(results, failAt: 2);
    final session = PuzzleSession(generator: recording);
    addTearDown(session.dispose);
    session.nextPuzzle();
    expect(session.current.isSuccess, isFalse);
    expect(session.current.failureReason, 'Test generation failure');
    expect(session.history.map((h) => h.puzzleIndex), [1]);
    session.nextPuzzle();
    expect(recording.calls, [1, 2]);
  });

  testWidgets('completion advances to a fresh PuzzleGame and numbered board', (
    tester,
  ) async {
    final session = PuzzleSession(generator: _RecordedGenerator(results));
    addTearDown(session.dispose);
    await tester.pumpWidget(ArrowwordApp(session: session));
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(find.text('Bulmaca 1'), findsOneWidget);
    final oldState = tester.state(find.byType(PuzzleScreen));
    for (final answer in session.current.puzzle!.answers) {
      await tester.tap(
        find.byKey(
          ValueKey(
            'cell-${answer.cluePosition.row}-${answer.cluePosition.column}',
          ),
        ),
      );
      for (final letter in answer.solution.split('')) {
        await tester.enterText(find.byType(TextField), letter);
      }
    }
    await tester.pumpAndSettle();
    expect(find.text('Bulmaca tamamlandı!'), findsOneWidget);
    await tester.tap(find.text('Sonraki Bulmaca'));
    await tester.pumpAndSettle();
    expect(find.text('Bulmaca 2'), findsOneWidget);
    expect(tester.state(find.byType(PuzzleScreen)), isNot(same(oldState)));
    for (final position
        in session.current.puzzle!.answers.expand((a) => a.positions).toSet()) {
      final cell = find.byKey(
        ValueKey('cell-${position.row}-${position.column}'),
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(of: cell, matching: find.byType(Text)),
            )
            .data,
        '',
      );
    }
    expect(find.text('Bulmaca tamamlandı!'), findsNothing);
    await localizedPageBack(tester);
    await tester.pumpAndSettle();
    expect(find.text('Bulmaca 2'), findsOneWidget);
    expect(find.text('Devam Et'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('next-generation failure shows safe Turkish error', (
    tester,
  ) async {
    final session = PuzzleSession(
      generator: _RecordedGenerator(results, failAt: 2),
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(ArrowwordApp(session: session));
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    session.nextPuzzle();
    await tester.pump();
    expect(find.byType(PuzzleScreen), findsNothing);
    expect(find.textContaining('Bulmaca oluşturulamadı.'), findsOneWidget);
    expect(find.textContaining('Test generation failure'), findsNothing);
    expect(find.textContaining('Lütfen tekrar deneyin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
