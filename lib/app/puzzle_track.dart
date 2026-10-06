import '../features/puzzle/data/prototype_puzzle.dart';
import '../features/puzzle/data/difficulty_puzzles.dart';
import '../features/puzzle/domain/puzzle_difficulty.dart';
import '../features/puzzle/sequence/puzzle_sequence.dart';
import 'puzzle_progress_store.dart';
import 'puzzle_session.dart';

PuzzleSequenceGenerator _legacyEasyGenerator() =>
    PuzzleSequenceGenerator(prototypeCatalogue, prototypeSequenceConfig);

/// Future content/sequence policy enters through this factory, not shared state.
/// Versioned Medium/Hard providers live in difficulty_puzzles; Easy is unchanged.
class PuzzleTrackConfiguration {
  const PuzzleTrackConfiguration({
    required this.difficulty,
    this.createGenerator,
  });
  final PuzzleDifficulty difficulty;
  final PuzzleSequenceGenerator Function()? createGenerator;

  static const easy = PuzzleTrackConfiguration(
    difficulty: PuzzleDifficulty.easy,
    createGenerator: _legacyEasyGenerator,
  );
  static const medium = PuzzleTrackConfiguration(
    difficulty: PuzzleDifficulty.medium,
    createGenerator: createMediumGenerator,
  );
  static const hard = PuzzleTrackConfiguration(
    difficulty: PuzzleDifficulty.hard,
    createGenerator: createHardGenerator,
  );
  static PuzzleTrackConfiguration forDifficulty(PuzzleDifficulty difficulty) =>
      switch (difficulty) {
        PuzzleDifficulty.easy => easy,
        PuzzleDifficulty.medium => medium,
        PuzzleDifficulty.hard => hard,
      };
}

/// One lazy session/store per track. Unconfigured tracks do not read, clear,
/// write, or generate anything; absence of content is not corrupt progression.
class PuzzleTrack {
  PuzzleTrack({required this.configuration, PuzzleProgressStore? store})
    : store = PuzzleTrackProgressStore(
        difficulty: configuration.difficulty,
        store:
            store ??
            SharedPreferencesPuzzleProgressStore(
              difficulty: configuration.difficulty,
            ),
      );
  final PuzzleTrackConfiguration configuration;
  final PuzzleTrackProgressStore store;
  PuzzleDifficulty get difficulty => configuration.difficulty;
  bool get isAvailable => configuration.createGenerator != null;
  Future<PuzzleSession>? _opening;
  int? _developmentIndex;

  Future<PuzzleSession> open({int? developmentIndex}) {
    if (!isAvailable) {
      return Future.error(
        UnsupportedError('No content provider for ${difficulty.id}.'),
      );
    }
    if (_opening != null && _developmentIndex != developmentIndex) {
      return Future.error(
        StateError('Track already opened in a different launch mode.'),
      );
    }
    _developmentIndex = developmentIndex;
    return _opening ??= PuzzleSession.restore(
      store: store,
      difficulty: difficulty,
      generator: configuration.createGenerator!(),
      developmentIndex: developmentIndex,
    );
  }
}
