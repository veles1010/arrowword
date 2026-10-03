import '../generation/puzzle_generator.dart';
import '../content/word_catalogue.dart';
import '../sequence/puzzle_sequence.dart';
import 'word_catalogue_data.dart';

const prototypeBaseSeed = 20261003;
// Same 300 records as v2; v3 changes sequence selection, not vocabulary.
const prototypeCatalogueVersion = 3;
const prototypeSequenceCooldown = 5;
const prototypeGenerationConfig = PuzzleGenerationConfig();
final prototypeCatalogue = WordCatalogue(
  version: prototypeCatalogueVersion,
  entries: catalogueWords,
);
const prototypeSequenceConfig = PuzzleSequenceConfig(
  baseSeed: prototypeBaseSeed,
  cooldownPuzzles: prototypeSequenceCooldown,
  generation: prototypeGenerationConfig,
);

SequencePuzzleResult generatePrototypePuzzle() => PuzzleSequenceGenerator(
  prototypeCatalogue,
  prototypeSequenceConfig,
).generateNext(puzzleIndex: 1);
