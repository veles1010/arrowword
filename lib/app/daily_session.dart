import 'package:flutter/foundation.dart';

import '../features/puzzle/daily/daily_puzzle.dart';
import '../features/puzzle/data/prototype_puzzle.dart';
import '../features/puzzle/domain/puzzle.dart';
import '../features/puzzle/generation/puzzle_metrics.dart';
import 'daily_progress_store.dart';
import 'daily_statistics.dart';

export 'daily_progress_store.dart' show DailyPuzzleScore;

/// Daily state is independent of the normal numbered puzzle progression.
class DailySession extends ChangeNotifier {
  DailySession._(
    this._generator, {
    required this.store,
    required DateTime Function() localNow,
  }) : _localNow = localNow,
       _dateKey = dailyDateKey(localNow());

  final DailyProgressStore store;
  final DateTime Function() _localNow;
  final DailyPuzzleGeneration Function(String) _generator;
  String _dateKey;
  DailyProgressAttempt? _savedAttempt;
  DailyPuzzleAttempt? _openedAttempt;
  final Map<String, DailyPuzzleScore> _results = {};
  Future<void> _writes = Future.value();

  String get dateKey => _dateKey;
  DailyPuzzleScore? get todayResult => _results[_dateKey];
  Map<String, DailyPuzzleScore> get results => Map.unmodifiable(_results);
  DailyStatistics get statistics =>
      DailyStatistics.fromDates(_results.keys, today: _dateKey);
  Future<void> get flush => _writes;
  bool get hasCurrentProgress =>
      todayResult == null && _savedAttempt?.dateKey == _dateKey;

  /// Restores metadata without generating either today's or a stale board.
  static Future<DailySession> restore({
    required DailyProgressStore store,
    DateTime Function()? localNow,
    DailyPuzzleGeneration Function(String)? generator,
  }) async {
    final session = DailySession._(
      generator ?? generateDailyPuzzle,
      store: store,
      localNow: localNow ?? DateTime.now,
    );
    try {
      final raw = await store.read();
      if (raw != null) {
        final saved = DailyProgress.decode(raw);
        session._results.addAll(saved.results);
        final attempt = saved.attempt;
        if (attempt != null &&
            attempt.dailySeedVersion == dailySeedVersion &&
            attempt.catalogueVersion == prototypeCatalogueVersion &&
            attempt.puzzleId == dailyPuzzleId(attempt.dateKey) &&
            !session._results.containsKey(attempt.dateKey)) {
          session._savedAttempt = attempt;
        }
        if (saved.needsRewrite ||
            (attempt != null && session._savedAttempt == null)) {
          session._save();
          await session.flush;
        }
      }
    } catch (error) {
      debugPrint('Ignoring daily progress: $error');
      session._results.clear();
      session._savedAttempt = null;
      try {
        await store.clear();
      } catch (error) {
        debugPrint('Daily progress clear failed: $error');
      }
    }
    return session;
  }

  void refreshDate() {
    final next = dailyDateKey(_localNow());
    if (next == _dateKey) return;
    _dateKey = next;
    notifyListeners();
  }

  /// Generates lazily and reuses a successful attempt on subsequent openings.
  /// The returned attempt keeps its original date across midnight.
  DailyPuzzleAttempt? openToday() {
    refreshDate();
    if (todayResult != null) return null;
    if (_openedAttempt?.dateKey == _dateKey &&
        _openedAttempt!.generation.isSuccess) {
      return _openedAttempt;
    }
    DailyPuzzleGeneration generation;
    try {
      generation = _generator(_dateKey);
      if (generation.isSuccess &&
          generation.puzzle!.id != dailyPuzzleId(_dateKey)) {
        generation = DailyPuzzleGeneration.failure(
          'Günlük bulmaca kimliği doğrulanamadı.',
        );
      }
    } catch (_) {
      generation = DailyPuzzleGeneration.failure(
        'Günlük bulmaca oluşturulamadı.',
      );
    }
    final attempt = DailyPuzzleAttempt._(
      _attemptChanged,
      _recordCompletion,
      dateKey: _dateKey,
      generation: generation,
    );
    final saved = _savedAttempt;
    if (generation.isSuccess &&
        saved?.dateKey == _dateKey &&
        saved!.puzzleId == generation.puzzle!.id &&
        saved.signature == puzzleStructuralSignature(generation.puzzle!)) {
      attempt._restore(saved);
    }
    _openedAttempt = attempt;
    if (generation.isSuccess) {
      _savedAttempt = attempt._snapshot();
      _save();
      notifyListeners();
    }
    return attempt;
  }

  void _attemptChanged(DailyPuzzleAttempt attempt) {
    if (!identical(attempt, _openedAttempt) ||
        _results.containsKey(attempt.dateKey)) {
      return;
    }
    _savedAttempt = attempt._snapshot();
    _save();
  }

  DailyPuzzleScore _recordCompletion(DailyPuzzleScore candidate) {
    final result = _results.putIfAbsent(candidate.dateKey, () => candidate);
    if (_savedAttempt?.dateKey == candidate.dateKey) _savedAttempt = null;
    _save();
    notifyListeners();
    return result;
  }

  void _save() {
    final record = DailyProgress(
      attempt: _savedAttempt,
      results: _results,
    ).encode();
    // Queue complete snapshots so an older slow write cannot win a race.
    _writes = _writes.then((_) => store.write(record)).catchError((
      Object error,
    ) {
      debugPrint('Daily progress save failed: $error');
    });
  }
}

class DailyPuzzleAttempt {
  DailyPuzzleAttempt._(
    this._onChanged,
    this._onCompleted, {
    required this.dateKey,
    required this.generation,
  });

  final String dateKey;
  final DailyPuzzleGeneration generation;
  final void Function(DailyPuzzleAttempt) _onChanged;
  final DailyPuzzleScore Function(DailyPuzzleScore) _onCompleted;
  Map<GridPosition, String> _letters = {};
  Set<GridPosition> _revealed = {};
  Duration _elapsed = Duration.zero;
  int _wrongChecks = 0;
  DailyPuzzleScore? _result;

  Map<GridPosition, String> get letters => Map.unmodifiable(_letters);
  Set<GridPosition> get revealedCells => Set.unmodifiable(_revealed);
  int get hintsUsed => _revealed.length;
  Duration get elapsed => _elapsed;
  int get wrongChecks => _wrongChecks;
  DailyPuzzleScore? get result => _result;

  void updateProgress(
    Map<GridPosition, String> letters,
    Set<GridPosition> revealed,
    Duration elapsed,
    int wrongChecks,
  ) {
    if (!generation.isSuccess || _result != null) return;
    if (elapsed.isNegative || wrongChecks < 0) {
      throw ArgumentError('Invalid daily attempt statistics');
    }
    final puzzle = generation.puzzle!;
    final nextLetters = {
      for (final entry in letters.entries)
        if (puzzle.answersAt(entry.key).isNotEmpty &&
            RegExp(r'^[A-Z]$').hasMatch(entry.value))
          entry.key: entry.value,
    };
    final nextRevealed = {
      ..._revealed,
      for (final position in revealed)
        if (puzzle.answersAt(position).isNotEmpty) position,
    };
    for (final position in nextRevealed) {
      nextLetters[position] = _expected(position);
    }
    final nextElapsed = elapsed > _elapsed ? elapsed : _elapsed;
    final nextWrongChecks = wrongChecks > _wrongChecks
        ? wrongChecks
        : _wrongChecks;
    if (mapEquals(_letters, nextLetters) &&
        setEquals(_revealed, nextRevealed) &&
        _elapsed == nextElapsed &&
        _wrongChecks == nextWrongChecks) {
      return;
    }
    _letters = nextLetters;
    _revealed = nextRevealed;
    _elapsed = nextElapsed;
    _wrongChecks = nextWrongChecks;
    _onChanged(this);
  }

  void checkpointElapsed(Duration elapsed) {
    if (!generation.isSuccess || _result != null) return;
    if (elapsed.isNegative) throw ArgumentError.value(elapsed, 'elapsed');
    if (elapsed <= _elapsed) return;
    _elapsed = elapsed;
    _onChanged(this);
  }

  /// Called only by gameplay's completion recognition, after its progress save.
  void complete() {
    if (!generation.isSuccess || _result != null) return;
    final puzzle = generation.puzzle!;
    if (puzzle.answers.isEmpty) return;
    for (final answer in puzzle.answers) {
      for (var index = 0; index < answer.length; index++) {
        if (_letters[answer.positions[index]] != answer.solution[index]) return;
      }
    }
    _result = DailyPuzzleScore.calculate(
      dateKey: dateKey,
      dailyPuzzleId: puzzle.id,
      elapsedSeconds: _elapsed.inSeconds,
      hintsUsed: hintsUsed,
      wrongChecks: _wrongChecks,
    );
    _result = _onCompleted(_result!);
  }

  String _expected(GridPosition position) {
    final answer = generation.puzzle!.answersAt(position).first;
    return answer.solution[answer.positions.indexOf(position)];
  }

  void _restore(DailyProgressAttempt saved) {
    final puzzle = generation.puzzle!;
    for (final entry in saved.letters.entries) {
      final position = _parsePosition(entry.key);
      if (position != null &&
          puzzle.answersAt(position).isNotEmpty &&
          RegExp(r'^[A-Z]$').hasMatch(entry.value)) {
        _letters[position] = entry.value;
      }
    }
    for (final coordinate in saved.revealedCells) {
      final position = _parsePosition(coordinate);
      if (position != null && puzzle.answersAt(position).isNotEmpty) {
        _revealed.add(position);
        _letters[position] = _expected(position);
      }
    }
    _elapsed = Duration(milliseconds: saved.elapsedMilliseconds);
    _wrongChecks = saved.wrongChecks;
  }

  DailyProgressAttempt _snapshot() => DailyProgressAttempt(
    dateKey: dateKey,
    puzzleId: generation.puzzle!.id,
    signature: puzzleStructuralSignature(generation.puzzle!),
    letters: {
      for (final entry in _letters.entries)
        if (!_revealed.contains(entry.key))
          '${entry.key.row},${entry.key.column}': entry.value,
    },
    revealedCells: [
      for (final position in _revealed) '${position.row},${position.column}',
    ]..sort(),
    hintsUsed: hintsUsed,
    elapsedMilliseconds: _elapsed.inMilliseconds,
    wrongChecks: _wrongChecks,
  );
}

GridPosition? _parsePosition(String coordinate) {
  final match = RegExp(r'^(\d+),(\d+)$').firstMatch(coordinate);
  if (match == null) return null;
  final row = int.tryParse(match[1]!);
  final column = int.tryParse(match[2]!);
  if (row == null || column == null) return null;
  return GridPosition(row, column);
}
