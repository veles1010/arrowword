import '../features/puzzle/domain/puzzle.dart';
import '../features/puzzle/domain/puzzle_difficulty.dart';
import '../features/puzzle/domain/puzzle_score.dart';
import '../features/puzzle/sequence/puzzle_sequence.dart';
import 'puzzle_session.dart';

/// Ephemeral replay state. Only a recognized completion may update player scores.
class PuzzleReplayAttempt {
  PuzzleReplayAttempt({required this.session, required int puzzleIndex})
    : generation = session.buildReplayPuzzle(puzzleIndex);

  final PuzzleSession session;
  PuzzleDifficulty get difficulty => session.difficulty;
  final SequencePuzzleResult generation;
  Map<GridPosition, String> _letters = {};
  Set<GridPosition> _revealed = {};
  Duration _elapsed = Duration.zero;
  int _wrongChecks = 0;
  CompletedPuzzleScore? _result;
  bool _newBest = false;

  Map<GridPosition, String> get letters => Map.unmodifiable(_letters);
  Set<GridPosition> get revealedCells => Set.unmodifiable(_revealed);
  int get hintsUsed => _revealed.length;
  int get wrongChecks => _wrongChecks;
  Duration get elapsed => _elapsed;
  CompletedPuzzleScore? get result => _result;
  bool get isNewBest => _newBest;
  CompletedPuzzleScore? get bestScore =>
      session.completedScores[generation.puzzleIndex];

  void updateProgress(
    Map<GridPosition, String> letters,
    Set<GridPosition> revealed,
    Duration elapsed,
    int wrongChecks,
  ) {
    if (!generation.isSuccess || _result != null) return;
    final puzzle = generation.puzzle!;
    _letters = {
      for (final e in letters.entries)
        if (puzzle.answersAt(e.key).isNotEmpty &&
            RegExp(r'^[A-Z]$').hasMatch(e.value))
          e.key: e.value,
    };
    _revealed = {
      for (final p in revealed)
        if (puzzle.answersAt(p).isNotEmpty) p,
    };
    for (final p in _revealed) {
      final answer = puzzle.answersAt(p).first;
      _letters[p] = answer.solution[answer.positions.indexOf(p)];
    }
    checkpointElapsed(elapsed);
    if (wrongChecks < 0) throw ArgumentError.value(wrongChecks, 'wrongChecks');
    if (wrongChecks > _wrongChecks) _wrongChecks = wrongChecks;
  }

  void checkpointElapsed(Duration elapsed) {
    if (_result != null) return;
    if (elapsed.isNegative) throw ArgumentError.value(elapsed, 'elapsed');
    if (elapsed > _elapsed) _elapsed = elapsed;
  }

  void complete() {
    if (!generation.isSuccess || _result != null) return;
    for (final answer in generation.puzzle!.answers) {
      for (var i = 0; i < answer.length; i++) {
        if (_letters[answer.positions[i]] != answer.solution[i]) return;
      }
    }
    _result = CompletedPuzzleScore.calculate(
      puzzleIndex: generation.puzzleIndex,
      elapsedSeconds: _elapsed.inSeconds,
      hintsUsed: hintsUsed,
      wrongChecks: _wrongChecks,
    );
    _newBest = session.recordReplayScore(_result!);
  }
}
