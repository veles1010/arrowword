import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/puzzle/daily/daily_puzzle.dart';
import '../features/puzzle/data/prototype_puzzle.dart';
import '../features/puzzle/domain/puzzle_score.dart';
import 'progress_json.dart';

abstract class DailyProgressStore {
  Future<String?> read();
  Future<void> write(String record);
  Future<void> clear();
}

class SharedPreferencesDailyProgressStore implements DailyProgressStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const key = 'arrowword.daily_progress';

  @override
  Future<String?> read() => _preferences.getString(key);

  @override
  Future<void> write(String record) => _preferences.setString(key, record);

  @override
  Future<void> clear() => _preferences.remove(key);
}

class MemoryDailyProgressStore implements DailyProgressStore {
  MemoryDailyProgressStore([this.record]);

  String? record;
  int writes = 0;
  int clears = 0;

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
    clears++;
  }
}

/// The first recognized completion for a local calendar date.
class DailyPuzzleScore {
  factory DailyPuzzleScore({
    required String dateKey,
    required String dailyPuzzleId,
    required int score,
    required int elapsedSeconds,
    required int hintsUsed,
    required int wrongChecks,
    int scoringVersion = 1,
    int dailySeedVersion = 1,
    int catalogueVersion = prototypeCatalogueVersion,
  }) {
    if (!isValidDailyDateKey(dateKey)) {
      throw ArgumentError.value(dateKey, 'dateKey');
    }
    if (dailySeedVersion != 1 ||
        catalogueVersion < 1 ||
        catalogueVersion > prototypeCatalogueVersion) {
      throw ArgumentError('Invalid daily identity version');
    }
    final expectedId = 'daily-v$dailySeedVersion-c$catalogueVersion-$dateKey';
    if (dailyPuzzleId != expectedId) {
      throw ArgumentError.value(dailyPuzzleId, 'dailyPuzzleId');
    }
    if (scoringVersion != 1) {
      throw ArgumentError.value(scoringVersion, 'scoringVersion');
    }
    final expectedScore = calculatePuzzleScore(
      elapsedSeconds: elapsedSeconds,
      hintsUsed: hintsUsed,
      wrongChecks: wrongChecks,
    );
    if (score != expectedScore) {
      throw ArgumentError.value(score, 'score', 'Must equal $expectedScore');
    }
    return DailyPuzzleScore._(
      dateKey: dateKey,
      dailyPuzzleId: dailyPuzzleId,
      score: score,
      elapsedSeconds: elapsedSeconds,
      hintsUsed: hintsUsed,
      wrongChecks: wrongChecks,
      scoringVersion: scoringVersion,
      dailySeedVersion: dailySeedVersion,
      catalogueVersion: catalogueVersion,
    );
  }

  const DailyPuzzleScore._({
    required this.dateKey,
    required this.dailyPuzzleId,
    required this.score,
    required this.elapsedSeconds,
    required this.hintsUsed,
    required this.wrongChecks,
    required this.scoringVersion,
    required this.dailySeedVersion,
    required this.catalogueVersion,
  });

  factory DailyPuzzleScore.calculate({
    required String dateKey,
    required String dailyPuzzleId,
    required int elapsedSeconds,
    required int hintsUsed,
    required int wrongChecks,
  }) => DailyPuzzleScore(
    dateKey: dateKey,
    dailyPuzzleId: dailyPuzzleId,
    score: calculatePuzzleScore(
      elapsedSeconds: elapsedSeconds,
      hintsUsed: hintsUsed,
      wrongChecks: wrongChecks,
    ),
    elapsedSeconds: elapsedSeconds,
    hintsUsed: hintsUsed,
    wrongChecks: wrongChecks,
  );

  factory DailyPuzzleScore.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Daily score must be an object');
    }
    try {
      return DailyPuzzleScore(
        dateKey: _readString(json, 'dateKey'),
        dailyPuzzleId: _readString(json, 'dailyPuzzleId'),
        score: _readInt(json, 'score'),
        elapsedSeconds: _readInt(json, 'elapsedSeconds'),
        hintsUsed: _readInt(json, 'hintsUsed'),
        wrongChecks: _readInt(json, 'wrongChecks'),
        scoringVersion: _readInt(json, 'scoringVersion'),
        dailySeedVersion: _readInt(json, 'dailySeedVersion'),
        catalogueVersion: _readInt(json, 'catalogueVersion'),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid daily score: $error');
    }
  }

  final String dateKey, dailyPuzzleId;
  final int score, elapsedSeconds, hintsUsed, wrongChecks;
  final int scoringVersion, dailySeedVersion, catalogueVersion;

  Map<String, Object> toJson() => {
    'dateKey': dateKey,
    'dailyPuzzleId': dailyPuzzleId,
    'score': score,
    'elapsedSeconds': elapsedSeconds,
    'hintsUsed': hintsUsed,
    'wrongChecks': wrongChecks,
    'scoringVersion': scoringVersion,
    'dailySeedVersion': dailySeedVersion,
    'catalogueVersion': catalogueVersion,
  };
}

/// Compact storage: one recent unfinished attempt and completed daily results.
class DailyProgress {
  DailyProgress({
    this.attempt,
    Map<String, DailyPuzzleScore> results = const {},
    this.needsRewrite = false,
  }) : results = Map.unmodifiable(results);

  static const schemaVersion = 1;
  final DailyProgressAttempt? attempt;
  final Map<String, DailyPuzzleScore> results;
  final bool needsRewrite;

  String encode() => jsonEncode({
    'schemaVersion': schemaVersion,
    'attempt': attempt?.toJson(),
    'results': {
      for (final entry in results.entries) entry.key: entry.value.toJson(),
    },
  });

  static DailyProgress decode(String record) {
    final decoded = ProgressJson(record);
    final json = decoded.value;
    if (json is! Map ||
        json['schemaVersion'] is! int ||
        json['schemaVersion'] != schemaVersion ||
        json['results'] is! Map) {
      throw const FormatException('Invalid daily progress');
    }
    if (decoded.duplicates.any(
      (p) => p.first != 'results' && p.first != 'attempt',
    )) {
      throw const FormatException('Ambiguous daily progress');
    }
    var repaired = decoded.duplicates.isNotEmpty;
    final ambiguousDates = decoded.duplicates
        .where((p) => p.first == 'results' && p.length > 1)
        .map((p) => p[1])
        .toSet();
    final allResultsAmbiguous = decoded.duplicates.any(
      (p) => p.first == 'results' && p.length == 1,
    );
    final results = <String, DailyPuzzleScore>{};
    for (final entry in (json['results'] as Map).entries) {
      if (allResultsAmbiguous || ambiguousDates.contains(entry.key)) continue;
      try {
        final result = DailyPuzzleScore.fromJson(entry.value);
        if (entry.key != result.dateKey) {
          throw const FormatException('Mismatched daily result date');
        }
        results[result.dateKey] = result;
      } on FormatException {
        repaired = true;
      }
    }
    DailyProgressAttempt? attempt;
    if (json['attempt'] != null &&
        !decoded.duplicates.any((p) => p.first == 'attempt')) {
      try {
        attempt = DailyProgressAttempt.fromJson(json['attempt']);
      } on FormatException {
        repaired = true;
      }
    }
    if (results.isEmpty &&
        attempt == null &&
        (json['results'] as Map).isNotEmpty) {
      throw const FormatException('No usable daily progress');
    }
    return DailyProgress(
      needsRewrite: repaired,
      attempt: attempt,
      results: results,
    );
  }
}

class DailyProgressAttempt {
  DailyProgressAttempt({
    required this.dateKey,
    required this.puzzleId,
    required this.signature,
    required Map<String, String> letters,
    required List<String> revealedCells,
    required this.hintsUsed,
    required this.elapsedMilliseconds,
    required this.wrongChecks,
    this.catalogueVersion = prototypeCatalogueVersion,
    this.dailySeedVersion = 1,
  }) : letters = Map.unmodifiable(letters),
       revealedCells = List.unmodifiable(revealedCells);

  factory DailyProgressAttempt.fromJson(Object? json) {
    if (json is! Map ||
        json['letters'] is! Map ||
        json['revealedCells'] is! List ||
        (json['revealedCells'] as List).any((value) => value is! String)) {
      throw const FormatException('Invalid daily attempt');
    }
    final dateKey = _readString(json, 'dateKey');
    final revealedCells = List<String>.from(json['revealedCells']);
    final hintsUsed = _readInt(json, 'hintsUsed');
    final elapsedMilliseconds = _readInt(json, 'elapsedMilliseconds');
    final wrongChecks = _readInt(json, 'wrongChecks');
    final catalogueVersion = _readInt(json, 'catalogueVersion');
    final seedVersion = _readInt(json, 'dailySeedVersion');
    if (!isValidDailyDateKey(dateKey) ||
        revealedCells.toSet().length != revealedCells.length ||
        hintsUsed != revealedCells.length ||
        elapsedMilliseconds < 0 ||
        elapsedMilliseconds > maxPersistedElapsedMilliseconds ||
        wrongChecks < 0 ||
        catalogueVersion < 1 ||
        seedVersion < 1) {
      throw const FormatException('Invalid daily attempt statistics');
    }
    return DailyProgressAttempt(
      dateKey: dateKey,
      puzzleId: _readString(json, 'puzzleId'),
      signature: _readString(json, 'signature'),
      catalogueVersion: catalogueVersion,
      dailySeedVersion: seedVersion,
      letters: {
        for (final entry in (json['letters'] as Map).entries)
          if (entry.key is String && entry.value is String)
            entry.key: entry.value,
      },
      revealedCells: revealedCells,
      hintsUsed: hintsUsed,
      elapsedMilliseconds: elapsedMilliseconds,
      wrongChecks: wrongChecks,
    );
  }

  final String dateKey, puzzleId, signature;
  final int catalogueVersion, dailySeedVersion;
  final Map<String, String> letters;
  final List<String> revealedCells;
  final int hintsUsed, elapsedMilliseconds, wrongChecks;

  Map<String, Object> toJson() => {
    'dateKey': dateKey,
    'puzzleId': puzzleId,
    'signature': signature,
    'catalogueVersion': catalogueVersion,
    'dailySeedVersion': dailySeedVersion,
    'letters': letters,
    'revealedCells': revealedCells,
    'hintsUsed': hintsUsed,
    'elapsedMilliseconds': elapsedMilliseconds,
    'wrongChecks': wrongChecks,
  };
}

int _readInt(Map json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer');
  return value;
}

String _readString(Map json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string');
  return value;
}
