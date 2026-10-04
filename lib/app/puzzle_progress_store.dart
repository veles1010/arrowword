import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/puzzle/domain/puzzle_score.dart';
import 'progress_json.dart';

abstract class PuzzleProgressStore {
  Future<String?> read();
  Future<void> write(String record);
  Future<void> clear();
}

class SharedPreferencesPuzzleProgressStore implements PuzzleProgressStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const _key = 'arrowword.puzzle_progress';
  @override
  Future<String?> read() => _preferences.getString(_key);
  @override
  Future<void> write(String record) => _preferences.setString(_key, record);
  @override
  Future<void> clear() => _preferences.remove(_key);
}

class MemoryPuzzleProgressStore implements PuzzleProgressStore {
  MemoryPuzzleProgressStore([this.record]);
  String? record;
  int writes = 0;
  @override
  Future<String?> read() async => record;
  @override
  Future<void> write(String record) async {
    this.record = record;
    writes++;
  }

  @override
  Future<void> clear() async {
    record = null;
  }
}

class PuzzleProgress {
  const PuzzleProgress({
    required this.catalogVersion,
    required this.puzzleIndex,
    required this.puzzleId,
    required this.signature,
    required this.letters,
    int? completedThrough,
    this.schemaVersion = 5,
    this.history = const [],
    this.revealedCells = const [],
    this.hintsUsed = 0,
    this.elapsedMilliseconds = 0,
    this.wrongChecks = 0,
    this.completedScores = const {},
    this.needsRewrite = false,
  }) : completedThrough = completedThrough ?? puzzleIndex - 1;
  final int catalogVersion, puzzleIndex;
  final int completedThrough, schemaVersion;
  final String puzzleId, signature;
  final Map<String, String> letters;
  final List<ProgressHistoryEntry> history;
  final List<String> revealedCells;
  final int hintsUsed;
  final int elapsedMilliseconds, wrongChecks;
  final Map<int, CompletedPuzzleScore> completedScores;
  // Recovery metadata only; never changes the persisted schema.
  final bool needsRewrite;
  String encode() => jsonEncode({
    'schemaVersion': schemaVersion,
    if (schemaVersion >= 3)
      'history': [
        for (final entry in history)
          {'puzzleIndex': entry.puzzleIndex, 'wordIds': entry.wordIds},
      ],
    if (schemaVersion >= 4) 'revealedCells': revealedCells,
    if (schemaVersion >= 4) 'hintsUsed': hintsUsed,
    if (schemaVersion >= 5) 'elapsedMilliseconds': elapsedMilliseconds,
    if (schemaVersion >= 5) 'wrongChecks': wrongChecks,
    if (schemaVersion >= 5)
      'completedScores': {
        for (final entry in completedScores.entries)
          '${entry.key}': entry.value.toJson(),
      },
    'completedThrough': completedThrough,
    'catalogVersion': catalogVersion,
    'puzzleIndex': puzzleIndex,
    'puzzleId': puzzleId,
    'signature': signature,
    'letters': letters,
  });
  static PuzzleProgress decode(String record) {
    final decoded = ProgressJson(record);
    final data = decoded.value;
    if (data is! Map ||
        data['schemaVersion'] is! int ||
        ![1, 2, 3, 4, 5].contains(data['schemaVersion']) ||
        data['catalogVersion'] is! int ||
        data['catalogVersion'] < 1 ||
        data['puzzleIndex'] is! int ||
        data['puzzleIndex'] < 1 ||
        data['puzzleIndex'] > 0xffffffff ||
        data['puzzleId'] is! String ||
        data['signature'] is! String ||
        data['letters'] is! Map) {
      throw const FormatException('Invalid puzzle progress');
    }
    if (decoded.duplicates.any((path) => path.first != 'completedScores')) {
      throw const FormatException('Ambiguous puzzle progress');
    }
    var repaired = decoded.duplicates.isNotEmpty;
    final completed = data['schemaVersion'] == 1
        ? data['puzzleIndex'] - 1
        : data['completedThrough'];
    if (completed is! int ||
        completed < 0 ||
        completed < data['puzzleIndex'] - 1 ||
        completed > data['puzzleIndex']) {
      throw const FormatException('Invalid completion progression');
    }
    final history = <ProgressHistoryEntry>[];
    if (data['schemaVersion'] >= 3) {
      final stored = data['history'];
      if (stored is! List || stored.length != data['puzzleIndex'] - 1) {
        throw const FormatException('Missing contiguous puzzle history');
      }
      for (var i = 0; i < stored.length; i++) {
        final entry = stored[i];
        if (entry is! Map ||
            entry['puzzleIndex'] is! int ||
            entry['puzzleIndex'] != i + 1 ||
            entry['wordIds'] is! List ||
            (entry['wordIds'] as List).any((id) => id is! String)) {
          throw const FormatException('Invalid puzzle history entry');
        }
        history.add(
          ProgressHistoryEntry(
            puzzleIndex: i + 1,
            wordIds: List<String>.from(entry['wordIds']),
          ),
        );
      }
    }
    final revealed = <String>[];
    if (data['schemaVersion'] >= 4) {
      if (data['revealedCells'] is! List ||
          (data['revealedCells'] as List).any((p) => p is! String) ||
          data['hintsUsed'] is! int) {
        throw const FormatException('Invalid hint progress');
      }
      revealed.addAll(List<String>.from(data['revealedCells']));
      if (revealed.toSet().length != revealed.length ||
          data['hintsUsed'] != revealed.length) {
        throw const FormatException('Invalid hint count');
      }
    }
    var elapsedMilliseconds = 0;
    var wrongChecks = 0;
    final completedScores = <int, CompletedPuzzleScore>{};
    if (data['schemaVersion'] >= 5) {
      final elapsed = data['elapsedMilliseconds'];
      final checks = data['wrongChecks'];
      final scores = data['completedScores'];
      if (elapsed is! int ||
          elapsed < 0 ||
          elapsed > maxPersistedElapsedMilliseconds ||
          checks is! int ||
          checks < 0) {
        throw const FormatException('Invalid attempt statistics');
      }
      elapsedMilliseconds = elapsed;
      wrongChecks = checks;
      final ambiguousScores = decoded.duplicates
          .where((path) => path.length > 1)
          .map((path) => path[1])
          .toSet();
      final scoreMapAmbiguous = decoded.duplicates.any(
        (path) => path.length == 1,
      );
      if (scores is! Map || scoreMapAmbiguous) repaired = true;
      for (final entry
          in scores is Map && !scoreMapAmbiguous
              ? scores.entries
              : const <MapEntry<Object?, Object?>>[]) {
        final key = entry.key;
        final index = key is String ? int.tryParse(key) : null;
        if (index == null ||
            index < 1 ||
            key != '$index' ||
            index > completed ||
            ambiguousScores.contains(key)) {
          repaired = true;
          continue;
        }
        try {
          final score = CompletedPuzzleScore.fromJson(entry.value);
          if (score.puzzleIndex != index) {
            throw const FormatException('Mismatched score index');
          }
          completedScores[index] = score;
        } on FormatException {
          repaired = true;
        }
      }
    }
    return PuzzleProgress(
      needsRewrite: repaired,
      elapsedMilliseconds: elapsedMilliseconds,
      wrongChecks: wrongChecks,
      completedScores: completedScores,
      revealedCells: revealed,
      hintsUsed: revealed.length,
      history: history,
      schemaVersion: data['schemaVersion'],
      completedThrough: completed,
      catalogVersion: data['catalogVersion'],
      puzzleIndex: data['puzzleIndex'],
      puzzleId: data['puzzleId'],
      signature: data['signature'],
      letters: {
        for (final entry in (data['letters'] as Map).entries)
          if (entry.key is String && entry.value is String)
            entry.key: entry.value,
      },
    );
  }
}

class ProgressHistoryEntry {
  const ProgressHistoryEntry({
    required this.puzzleIndex,
    required this.wordIds,
  });
  final int puzzleIndex;
  final List<String> wordIds;
}
