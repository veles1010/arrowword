import 'package:flutter/foundation.dart';

import '../features/puzzle/data/prototype_puzzle.dart';
import '../features/puzzle/sequence/puzzle_sequence.dart';
import '../features/puzzle/domain/puzzle.dart';
import '../features/puzzle/domain/puzzle_score.dart';
import '../features/puzzle/domain/puzzle_difficulty.dart';
import 'puzzle_progress_store.dart';

/// Progression with optional current-board storage and in-memory full history.
class PuzzleSession extends ChangeNotifier {
  PuzzleSession({
    PuzzleSequenceGenerator? generator,
    int startIndex = 1,
    this.store,
    this.difficulty = PuzzleDifficulty.easy,
  }) : _generator = _generatorForTrack(difficulty, generator, store) {
    if (startIndex < 1 || startIndex > 0xffffffff) {
      throw ArgumentError.value(startIndex, 'startIndex');
    }
    for (var index = 1; index <= startIndex; index++) {
      _generate(index);
      if (!current.isSuccess) break;
    }
    _completedThrough = current.puzzleIndex - 1;
  }
  final PuzzleSequenceGenerator _generator;
  final PuzzleDifficulty difficulty;
  PuzzleSession._fromHistory(
    this._generator,
    this.store,
    this.difficulty,
    int index,
    List<PuzzleHistoryEntry> prefix,
  ) {
    _history.addAll(prefix);
    _generate(index);
  }
  final PuzzleProgressStore? store;

  static PuzzleSequenceGenerator _generatorForTrack(
    PuzzleDifficulty difficulty,
    PuzzleSequenceGenerator? generator,
    PuzzleProgressStore? store,
  ) {
    if (store is TrackScopedProgressStore && store.difficulty != difficulty) {
      throw ArgumentError('Progress store belongs to a different track.');
    }
    if (generator == null && difficulty != PuzzleDifficulty.easy) {
      throw ArgumentError('No content provider for ${difficulty.id}.');
    }
    return generator ??
        PuzzleSequenceGenerator(prototypeCatalogue, prototypeSequenceConfig);
  }

  Map<GridPosition, String> _letters = {};
  Map<GridPosition, String> get letters => Map.unmodifiable(_letters);
  Set<GridPosition> _revealed = {};
  Set<GridPosition> get revealedCells => Set.unmodifiable(_revealed);
  int get hintsUsed => _revealed.length;
  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;
  int _wrongChecks = 0;
  int get wrongChecks => _wrongChecks;
  final Map<int, CompletedPuzzleScore> _completedScores = {};
  Map<int, CompletedPuzzleScore> get completedScores =>
      Map.unmodifiable(_completedScores);
  CompletedPuzzleScore? get currentScore =>
      _completedScores[current.puzzleIndex];
  int _completedThrough = 0;
  int get completedThrough => _completedThrough;
  Future<void> _writes = Future.value();
  Future<void> get flush => _writes;

  /// Schema 3 generates only N; old schemas replay 1..N once to migrate.
  static Future<PuzzleSession> restore({
    required PuzzleProgressStore store,
    PuzzleSequenceGenerator? generator,
    int? developmentIndex,
    PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
  }) async {
    // Validate identity before recovery can clear a store. Never cross-track reset.
    generator = _generatorForTrack(difficulty, generator, store);
    if (developmentIndex != null) {
      if (difficulty != PuzzleDifficulty.easy) {
        throw ArgumentError('Development puzzle override is Easy-only.');
      }
      return PuzzleSession(generator: generator, startIndex: developmentIndex);
    }
    try {
      final raw = await store.read();
      if (raw != null) {
        final saved = PuzzleProgress.decode(raw);
        if (saved.catalogVersion != generator.catalogue.version) {
          throw const FormatException('Incompatible catalogue');
        }
        final prefix = <PuzzleHistoryEntry>[];
        if (saved.schemaVersion >= 3) {
          final byId = {
            for (final word in generator.catalogue.entries)
              word.id: word.solution,
          };
          for (final entry in saved.history) {
            if (entry.wordIds.length !=
                    generator.config.generation.targetAnswerCount ||
                entry.wordIds.toSet().length != entry.wordIds.length ||
                entry.wordIds.any((id) => !byId.containsKey(id))) {
              throw const FormatException('Invalid historical catalogue IDs');
            }
            prefix.add(
              PuzzleHistoryEntry(
                puzzleIndex: entry.puzzleIndex,
                catalogVersion: saved.catalogVersion,
                words: {for (final id in entry.wordIds) id: byId[id]!},
              ),
            );
          }
        }
        final session = saved.schemaVersion >= 3
            ? PuzzleSession._fromHistory(
                generator,
                store,
                difficulty,
                saved.puzzleIndex,
                prefix,
              )
            : PuzzleSession(
                generator: generator,
                startIndex: saved.puzzleIndex,
                store: store,
                difficulty: difficulty,
              );
        if (!session.current.isSuccess ||
            session.current.puzzle!.id != saved.puzzleId ||
            session.current.generation!.metrics!.structuralSignature !=
                saved.signature) {
          session.dispose();
          throw const FormatException('Puzzle identity mismatch');
        }
        final restored = <GridPosition, String>{};
        for (final entry in saved.letters.entries) {
          final match = RegExp(r'^(\d+),(\d+)$').firstMatch(entry.key);
          if (match == null || !RegExp(r'^[A-Z]$').hasMatch(entry.value)) {
            continue;
          }
          final row = int.tryParse(match[1]!), column = int.tryParse(match[2]!);
          if (row == null || column == null) continue;
          final position = GridPosition(row, column);
          if (session.current.puzzle!.answersAt(position).isNotEmpty) {
            restored[position] = entry.value;
          }
        }
        session._letters = restored;
        for (final coordinate in saved.revealedCells) {
          final match = RegExp(r'^(\d+),(\d+)$').firstMatch(coordinate);
          if (match == null) continue;
          final row = int.tryParse(match[1]!), column = int.tryParse(match[2]!);
          if (row == null || column == null) continue;
          final p = GridPosition(row, column);
          if (session.current.puzzle!.answersAt(p).isNotEmpty) {
            session._revealed.add(p);
          }
        }
        for (final p in session._revealed) {
          session._letters[p] = session._expected(p);
        }
        session._completedThrough = saved.completedThrough;
        session._elapsed = Duration(milliseconds: saved.elapsedMilliseconds);
        session._wrongChecks = saved.wrongChecks;
        session._completedScores.addAll(saved.completedScores);
        if (saved.schemaVersion < 5 || saved.needsRewrite) {
          session._save();
          await session.flush;
        }
        return session;
      }
    } catch (error) {
      debugPrint('Ignoring puzzle progress: $error');
      try {
        await store.clear();
      } catch (error) {
        debugPrint('Progress clear failed: $error');
      }
    }
    return PuzzleSession(
      generator: generator,
      store: store,
      difficulty: difficulty,
    );
  }

  void updateLetters(Map<GridPosition, String> letters) {
    updateProgress(letters, _revealed);
  }

  String _expected(GridPosition p) {
    final answer = current.puzzle!.answersAt(p).first;
    return answer.solution[answer.positions.indexOf(p)];
  }

  void updateProgress(
    Map<GridPosition, String> letters,
    Set<GridPosition> revealed,
  ) {
    if (_setProgress(letters, revealed)) _save();
  }

  /// One snapshot per letter/check mutation, including accumulated active time.
  void updateAttemptProgress(
    Map<GridPosition, String> letters,
    Set<GridPosition> revealed,
    Duration elapsed,
    int wrongChecks,
  ) {
    if (!current.isSuccess) return;
    final progressChanged = _setProgress(letters, revealed);
    final statsChanged = _setAttempt(elapsed, wrongChecks);
    if (progressChanged || statsChanged) _save();
  }

  bool _setAttempt(Duration elapsed, int wrongChecks) {
    if (completedThrough >= current.puzzleIndex) return false;
    if (elapsed.isNegative || wrongChecks < 0) {
      throw ArgumentError('Invalid attempt');
    }
    final nextElapsed = elapsed > _elapsed ? elapsed : _elapsed;
    final nextChecks = wrongChecks > _wrongChecks ? wrongChecks : _wrongChecks;
    if (nextElapsed == _elapsed && nextChecks == _wrongChecks) return false;
    _elapsed = nextElapsed;
    _wrongChecks = nextChecks;
    return true;
  }

  void checkpointElapsed(Duration elapsed) {
    if (current.isSuccess && _setAttempt(elapsed, _wrongChecks)) _save();
  }

  bool _setProgress(
    Map<GridPosition, String> letters,
    Set<GridPosition> revealed,
  ) {
    if (!current.isSuccess) return false;
    final valid = {
      for (final entry in letters.entries)
        if (current.puzzle!.answersAt(entry.key).isNotEmpty &&
            RegExp(r'^[A-Z]$').hasMatch(entry.value))
          entry.key: entry.value,
    };
    final locks = {
      for (final p in revealed)
        if (current.puzzle!.answersAt(p).isNotEmpty) p,
    };
    for (final p in locks) {
      valid[p] = _expected(p);
    }
    if (mapEquals(_letters, valid) && setEquals(_revealed, locks)) return false;
    _letters = valid;
    _revealed = locks;
    return true;
  }

  void _save() {
    if (store == null || !current.isSuccess) return;
    final record = PuzzleProgress(
      catalogVersion: current.catalogVersion,
      puzzleIndex: current.puzzleIndex,
      puzzleId: current.puzzle!.id,
      signature: current.generation!.metrics!.structuralSignature,
      letters: {
        for (final entry in _letters.entries)
          if (!_revealed.contains(entry.key))
            '${entry.key.row},${entry.key.column}': entry.value,
      },
      completedThrough: completedThrough,
      revealedCells: [for (final p in _revealed) '${p.row},${p.column}']
        ..sort(),
      hintsUsed: hintsUsed,
      elapsedMilliseconds: _elapsed.inMilliseconds,
      wrongChecks: _wrongChecks,
      completedScores: completedScores,
      history: [
        for (final entry in _history.where(
          (entry) => entry.puzzleIndex < current.puzzleIndex,
        ))
          ProgressHistoryEntry(
            puzzleIndex: entry.puzzleIndex,
            wordIds: entry.words.keys.toList()..sort(),
          ),
      ],
    ).encode();
    // Serialize snapshots so a slow older write cannot overwrite newer progress.
    _writes = _writes.then((_) => store!.write(record)).catchError((
      Object error,
    ) {
      debugPrint('Progress save failed: $error');
    });
  }

  final List<PuzzleHistoryEntry> _history = [];
  late SequencePuzzleResult current;
  List<PuzzleHistoryEntry> get history => List.unmodifiable(_history);

  /// Reconstruct one completed board without changing normal progression.
  SequencePuzzleResult buildReplayPuzzle(int index) {
    SequencePuzzleResult failure(String reason) => SequencePuzzleResult(
      puzzleIndex: index,
      seed: index >= 1 && index <= 0xffffffff
          ? derivePuzzleSeed(_generator.config.baseSeed, index)
          : current.seed,
      catalogVersion: current.catalogVersion,
      pool: current.pool,
      failureReason: reason,
    );
    if (!current.isSuccess ||
        index < 1 ||
        index > completedThrough ||
        index >= current.puzzleIndex) {
      return failure('Bu bulmaca tekrar oynamak için uygun değil.');
    }
    try {
      final prefix = _history
          .where((entry) => entry.puzzleIndex < index)
          .toList();
      if (prefix.length != index - 1 ||
          prefix.asMap().entries.any(
            (entry) =>
                entry.value.puzzleIndex != entry.key + 1 ||
                entry.value.catalogVersion != current.catalogVersion,
          )) {
        return failure('Bulmaca geçmişi doğrulanamadı.');
      }
      final historical = _history.where((entry) => entry.puzzleIndex == index);
      if (historical.length != 1) {
        return failure('Bulmaca geçmişi bulunamadı.');
      }
      final result = _generator.generateNext(
        puzzleIndex: index,
        history: List.unmodifiable(prefix),
      );
      if (!result.isSuccess) {
        return failure('Bulmaca tekrar oluşturulamadı.');
      }
      final reconstructed = result.toHistory();
      if (reconstructed.puzzleIndex != index ||
          reconstructed.catalogVersion != historical.single.catalogVersion ||
          !mapEquals(reconstructed.words, historical.single.words)) {
        return failure('Bulmaca geçmişi ile oluşturulan bulmaca eşleşmedi.');
      }
      return result;
    } catch (_) {
      return failure('Bulmaca tekrar oluşturulamadı.');
    }
  }

  /// Store only an improved completed replay; the current attempt is untouched.
  bool recordReplayScore(CompletedPuzzleScore result) {
    final index = result.puzzleIndex;
    if (!current.isSuccess ||
        index < 1 ||
        index > completedThrough ||
        index >= current.puzzleIndex ||
        result.scoringVersion != 1 ||
        !isBetterPuzzleScore(result, _completedScores[index])) {
      return false;
    }
    _completedScores[index] = result;
    _save();
    notifyListeners();
    return true;
  }

  void _generate(int index) {
    current = _generator.generateNext(puzzleIndex: index, history: history);
    if (current.isSuccess) _history.add(current.toHistory());
  }

  void nextPuzzle() {
    if (!current.isSuccess) return;
    final previousIndex = current.puzzleIndex;
    _generate(current.puzzleIndex + 1);
    if (current.isSuccess) {
      // Next is offered by gameplay only after recognized completion.
      _completedThrough = previousIndex;
      _letters = {};
      _revealed = {};
      _elapsed = Duration.zero;
      _wrongChecks = 0;
      _save();
    }
    notifyListeners();
  }

  /// Called by gameplay's completion recognition, never by ordinary letter saves.
  void recognizeCompletion() {
    if (!current.isSuccess || completedThrough >= current.puzzleIndex) return;
    for (final answer in current.puzzle!.answers) {
      for (var i = 0; i < answer.length; i++) {
        if (_letters[answer.positions[i]] != answer.solution[i]) return;
      }
    }
    _completedScores.putIfAbsent(
      current.puzzleIndex,
      () => CompletedPuzzleScore.calculate(
        puzzleIndex: current.puzzleIndex,
        elapsedSeconds: _elapsed.inSeconds,
        hintsUsed: hintsUsed,
        wrongChecks: _wrongChecks,
      ),
    );
    _completedThrough = current.puzzleIndex;
    _save();
    notifyListeners();
  }
}
