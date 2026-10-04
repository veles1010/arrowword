import 'package:arrowword/app/app.dart';
import 'package:arrowword/features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fixtures extends PuzzleSequenceGenerator {
  _Fixtures(this.results) : super(prototypeCatalogue, prototypeSequenceConfig);
  final List<SequencePuzzleResult> results;
  final List<int> calls = [];
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls.add(puzzleIndex);
    return results[puzzleIndex - 1];
  }
}

void main() {
  late List<SequencePuzzleResult> results;
  setUpAll(
    () => results = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateRange(count: 2).puzzles,
  );
  Future<PuzzleSession> open(
    MemoryPuzzleProgressStore store, {
    int? dev,
    _Fixtures? generator,
  }) async {
    final s = await PuzzleSession.restore(
      store: store,
      generator: generator ?? _Fixtures(results),
      developmentIndex: dev,
    );
    addTearDown(s.dispose);
    return s;
  }

  PuzzleGame playing(PuzzleSession session) {
    final g = PuzzleGame(session.current.puzzle!)
      ..restoreLetters(session.letters, revealedCells: session.revealedCells);
    g.addListener(
      () => session.updateProgress(g.enteredLetters, g.revealedCells),
    );
    addTearDown(g.dispose);
    return g;
  }

  test(
    'hint coordinates/count survive restart without redundant solution letters',
    () async {
      final store = MemoryPuzzleProgressStore();
      final s = await open(store);
      final g = playing(s);
      final p = g.selectedPosition;
      g.revealSelectedLetter();
      await s.flush;
      final saved = PuzzleProgress.decode(store.record!);
      expect(saved.schemaVersion, 5);
      expect(saved.revealedCells, ['${p.row},${p.column}']);
      expect(saved.hintsUsed, 1);
      expect(saved.letters, isEmpty);
      final restored = await open(store);
      final restoredGame = playing(restored);
      restoredGame.enterLetter('Z');
      restoredGame.backspace();
      restoredGame.reset();
      await restored.flush;
      expect(restoredGame.letterAt(p), g.letterAt(p));
      expect(restored.hintsUsed, 1);
      expect(PuzzleProgress.decode(store.record!).hintsUsed, 1);
    },
  );
  test('schema 3 migration keeps letters, completion/history and does not replay prefix', () async {
    final r = results[1];
    final p = r.puzzle!.answers.first.start;
    final store = MemoryPuzzleProgressStore(
      PuzzleProgress(
        schemaVersion: 3,
        catalogVersion: 3,
        puzzleIndex: 2,
        puzzleId: r.puzzle!.id,
        signature: r.generation!.metrics!.structuralSignature,
        letters: {'${p.row},${p.column}': 'A'},
        completedThrough: 1,
        history: [
          ProgressHistoryEntry(
            puzzleIndex: 1,
            wordIds: results.first.toHistory().words.keys.toList(),
          ),
        ],
      ).encode(),
    );
    final generator = _Fixtures(results);
    final s = await open(store, generator: generator);
    expect(generator.calls, [2]);
    expect(s.letters[p], 'A');
    expect(s.completedThrough, 1);
    expect(s.hintsUsed, 0);
    expect(s.revealedCells, isEmpty);
    final saved = PuzzleProgress.decode(store.record!);
    expect(saved.schemaVersion, 5);
    expect(saved.history, hasLength(1));
    expect(saved.completedThrough, 1);
  });
  test('advancement resets per-puzzle hints and development cannot change player save', () async {
    final store = MemoryPuzzleProgressStore();
    final s = await open(store);
    playing(s).revealSelectedLetter();
    await s.flush;
    final saved = store.record;
    final dev = await open(store, dev: 1);
    playing(dev).revealSelectedLetter();
    dev.nextPuzzle();
    await dev.flush;
    expect(store.record, saved);
    s.nextPuzzle();
    await s.flush;
    expect(s.hintsUsed, 0);
    expect(s.revealedCells, isEmpty);
    final restored = await open(store);
    expect(restored.current.puzzleIndex, 2);
    expect(restored.hintsUsed, 0);
    expect(restored.revealedCells, isEmpty);
  });
  testWidgets('final-letter Harf Aç recognizes completion and persists hint', (
    tester,
  ) async {
    final store = MemoryPuzzleProgressStore();
    final s = await open(store);
    final p = s.current.puzzle!.answers.first.start;
    final solution = <GridPosition, String>{
      for (final a in s.current.puzzle!.answers)
        for (var i = 0; i < a.length; i++) a.positions[i]: a.solution[i],
    }..remove(p);
    s.updateLetters(solution);
    await tester.pumpWidget(
      ArrowwordApp(
        session: s,
        rewardedAdFactory: FakeRewardedHintAdService.new,
      ),
    );
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reklamla Harf Aç'));
    await tester.pumpAndSettle();
    await s.flush;
    expect(find.text('Bulmaca tamamlandı!'), findsOneWidget);
    expect(s.completedThrough, 1);
    expect(s.hintsUsed, 1);
    final saved = PuzzleProgress.decode(store.record!);
    expect(saved.completedThrough, 1);
    expect(saved.hintsUsed, 1);
    expect(s.currentScore!.hintsUsed, 1);
    expect(s.currentScore!.score, 1300);
    expect(saved.completedScores[1]!.score, 1300);
  });
}
