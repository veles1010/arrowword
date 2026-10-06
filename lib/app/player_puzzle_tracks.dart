import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/puzzle/domain/puzzle_difficulty.dart';
import '../features/puzzle/domain/puzzle_score.dart';
import '../features/puzzle/data/prototype_puzzle.dart'
    show prototypeCatalogueVersion;
import '../features/puzzle/data/difficulty_puzzles.dart'
    show mediumCatalogueVersion, hardCatalogueVersion;
import 'puzzle_progress_store.dart';
import 'puzzle_session.dart';
import 'puzzle_track.dart';

abstract class LastPuzzleDifficultyStore {
  Future<String?> read();
  Future<void> write(String id);
}

class SharedPreferencesLastPuzzleDifficultyStore
    implements LastPuzzleDifficultyStore {
  static const key = 'arrowword.last_puzzle_difficulty';
  final _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String id) => _preferences.setString(key, id);
}

class MemoryLastPuzzleDifficultyStore implements LastPuzzleDifficultyStore {
  MemoryLastPuzzleDifficultyStore([this.value]);
  String? value;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String id) async {
    value = id;
    writes++;
  }
}

/// Lightweight menu data. Reading it never opens a generator or rewrites a save.
class PuzzleTrackSummary {
  const PuzzleTrackSummary({
    this.index = 1,
    this.completedThrough = 0,
    this.hasLetters = false,
    this.scores = const {},
  });
  final int index, completedThrough;
  final bool hasLetters;
  final Map<int, CompletedPuzzleScore> scores;
  bool get isFresh => index == 1 && completedThrough == 0 && !hasLetters;
  factory PuzzleTrackSummary.fromSession(PuzzleSession session) =>
      PuzzleTrackSummary(
        index: session.current.puzzleIndex,
        completedThrough: session.completedThrough,
        hasLetters: session.letters.isNotEmpty,
        scores: session.completedScores,
      );
  factory PuzzleTrackSummary.fromProgress(PuzzleProgress progress) =>
      PuzzleTrackSummary(
        index: progress.puzzleIndex,
        completedThrough: progress.completedThrough,
        hasLetters:
            progress.letters.isNotEmpty || progress.revealedCells.isNotEmpty,
        scores: Map.unmodifiable(progress.completedScores),
      );
}

/// Player-only coordinator: independent lazy sessions, unchanged track stores.
/// Developer and Daily contexts never create or use this object.
class PlayerPuzzleTracks extends ChangeNotifier {
  PlayerPuzzleTracks._(this._tracks, this._lastStore);
  final Map<PuzzleDifficulty, PuzzleTrack> _tracks;
  final LastPuzzleDifficultyStore _lastStore;
  final _summaries = <PuzzleDifficulty, PuzzleTrackSummary>{};
  final _sessions = <PuzzleDifficulty, PuzzleSession>{};
  final _opening = <PuzzleDifficulty, Future<PuzzleSession>>{};
  PuzzleDifficulty _lastPlayed = PuzzleDifficulty.easy;
  PuzzleDifficulty get lastPlayed => _lastPlayed;
  Future<void> _writes = Future.value();
  Future<void> get flush => _writes;
  bool ownsSession(PuzzleSession session) =>
      _sessions.values.any((s) => identical(s, session));
  bool _disposed = false;
  PuzzleTrackSummary summary(PuzzleDifficulty difficulty) =>
      _summaries[difficulty]!;

  static Future<PlayerPuzzleTracks> restore({
    Map<PuzzleDifficulty, PuzzleTrack>? tracks,
    LastPuzzleDifficultyStore? lastStore,
  }) async {
    final result = PlayerPuzzleTracks._(
      tracks ??
          {
            for (final difficulty in PuzzleDifficulty.values)
              difficulty: PuzzleTrack(
                configuration: PuzzleTrackConfiguration.forDifficulty(
                  difficulty,
                ),
              ),
          },
      lastStore ?? SharedPreferencesLastPuzzleDifficultyStore(),
    );
    try {
      final id = await result._lastStore.read();
      result._lastPlayed = PuzzleDifficulty.values.firstWhere(
        (d) => d.id == id,
        orElse: () => PuzzleDifficulty.easy,
      );
    } catch (_) {
      /* An optional preference cannot invalidate progression. */
    }
    for (final difficulty in PuzzleDifficulty.values) {
      var summary = const PuzzleTrackSummary();
      try {
        final raw = await result._tracks[difficulty]!.store.read();
        if (raw != null) {
          final progress = PuzzleProgress.decode(raw);
          final version = switch (difficulty) {
            PuzzleDifficulty.easy => prototypeCatalogueVersion,
            PuzzleDifficulty.medium => mediumCatalogueVersion,
            PuzzleDifficulty.hard => hardCatalogueVersion,
          };
          if (progress.catalogVersion == version) {
            summary = PuzzleTrackSummary.fromProgress(progress);
          }
        }
      } catch (_) {
        /* Full recovery remains owned by the track session on open. */
      }
      result._summaries[difficulty] = summary;
    }
    return result;
  }

  Future<PuzzleSession> open(
    PuzzleDifficulty difficulty, {
    bool markPlayed = false,
  }) async {
    var cached = _sessions[difficulty];
    if (cached != null && !cached.current.isSuccess) {
      _sessions.remove(difficulty);
      cached.dispose();
      cached = null;
    }
    final session =
        cached ?? await (_opening[difficulty] ??= _load(difficulty));
    if (_disposed) throw StateError('Player tracks disposed.');
    if (session.current.isSuccess && markPlayed) {
      _lastPlayed = difficulty;
      _writes = _writes.then((_) => _lastStore.write(difficulty.id)).catchError(
        (Object _) {
          /* Play remains available if preferences fail. */
        },
      );
      refresh(difficulty);
    }
    return session;
  }

  Future<PuzzleSession> _load(PuzzleDifficulty difficulty) async {
    final track = _tracks[difficulty]!;
    try {
      final session = await PuzzleSession.restore(
        store: track.store,
        difficulty: difficulty,
        generator: track.configuration.createGenerator!(),
      );
      if (_disposed) {
        session.dispose();
        throw StateError('Player tracks disposed.');
      }
      if (session.current.isSuccess) {
        _sessions[difficulty] = session;
        session.addListener(() => refresh(difficulty));
        refresh(difficulty);
      }
      return session;
    } finally {
      _opening.remove(difficulty);
    }
  }

  void refresh(PuzzleDifficulty difficulty) {
    final session = _sessions[difficulty];
    if (_disposed || session == null || !session.current.isSuccess) return;
    _summaries[difficulty] = PuzzleTrackSummary.fromSession(session);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final session in _sessions.values) {
      session.dispose();
    }
    super.dispose();
  }
}
