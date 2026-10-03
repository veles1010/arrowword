import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
  });
  final int catalogVersion, puzzleIndex;
  final String puzzleId, signature;
  final Map<String, String> letters;
  String encode() => jsonEncode({
    'schemaVersion': 1,
    'catalogVersion': catalogVersion,
    'puzzleIndex': puzzleIndex,
    'puzzleId': puzzleId,
    'signature': signature,
    'letters': letters,
  });
  static PuzzleProgress decode(String record) {
    final data = jsonDecode(record);
    if (data is! Map ||
        data['schemaVersion'] != 1 ||
        data['catalogVersion'] is! int ||
        data['puzzleIndex'] is! int ||
        data['puzzleIndex'] < 1 ||
        data['puzzleIndex'] > 0xffffffff ||
        data['puzzleId'] is! String ||
        data['signature'] is! String ||
        data['letters'] is! Map) {
      throw const FormatException('Invalid puzzle progress');
    }
    return PuzzleProgress(
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
