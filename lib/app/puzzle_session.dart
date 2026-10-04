import 'package:flutter/foundation.dart';

import '../features/puzzle/data/prototype_puzzle.dart';
import '../features/puzzle/sequence/puzzle_sequence.dart';
import '../features/puzzle/domain/puzzle.dart';
import 'puzzle_progress_store.dart';

/// Progression with optional current-board storage and in-memory full history.
class PuzzleSession extends ChangeNotifier {
  PuzzleSession({
    PuzzleSequenceGenerator? generator,
    int startIndex = 1,
    this.store,
  }) : _generator =
           generator ??
           PuzzleSequenceGenerator(
             prototypeCatalogue,
             prototypeSequenceConfig,
           ) {
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
  PuzzleSession._fromHistory(
    this._generator,
    this.store,
    int index,
    List<PuzzleHistoryEntry> prefix,
  ) {
    _history.addAll(prefix);
    _generate(index);
  }
  final PuzzleProgressStore? store;
  Map<GridPosition, String> _letters = {};
  Map<GridPosition, String> get letters => Map.unmodifiable(_letters);
  int _completedThrough = 0;
  int get completedThrough => _completedThrough;
  Future<void> _writes = Future.value();
  Future<void> get flush => _writes;

  /// Schema 3 generates only N; old schemas replay 1..N once to migrate.
  static Future<PuzzleSession> restore({
    required PuzzleProgressStore store,
    PuzzleSequenceGenerator? generator,
    int? developmentIndex,
  }) async {
    if (developmentIndex != null) {
      return PuzzleSession(generator: generator, startIndex: developmentIndex);
    }
    generator ??= PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    );
    try {
      final raw = await store.read();
      if (raw != null) {
        final saved = PuzzleProgress.decode(raw);
        if (saved.catalogVersion != generator.catalogue.version) {
          throw const FormatException('Incompatible catalogue');
        }
        final prefix = <PuzzleHistoryEntry>[];
        if (saved.schemaVersion == 3) {
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
        final session = saved.schemaVersion == 3
            ? PuzzleSession._fromHistory(
                generator,
                store,
                saved.puzzleIndex,
                prefix,
              )
            : PuzzleSession(
                generator: generator,
                startIndex: saved.puzzleIndex,
                store: store,
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
        session._completedThrough = saved.completedThrough;
        if (saved.schemaVersion < 3) {
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
    return PuzzleSession(generator: generator, store: store);
  }

  void updateLetters(Map<GridPosition, String> letters) {
    if (!current.isSuccess) return;
    final valid = {
      for (final entry in letters.entries)
        if (current.puzzle!.answersAt(entry.key).isNotEmpty &&
            RegExp(r'^[A-Z]$').hasMatch(entry.value))
          entry.key: entry.value,
    };
    if (mapEquals(_letters, valid)) return;
    _letters = valid;
    _save();
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
          '${entry.key.row},${entry.key.column}': entry.value,
      },
      completedThrough: completedThrough,
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
    _completedThrough = current.puzzleIndex;
    _save();
    notifyListeners();
  }
}
