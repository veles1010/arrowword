import '../generation/puzzle_generator.dart';
import '../content/word_catalogue.dart';
import '../sequence/puzzle_sequence.dart';
import 'word_catalogue_data.dart';

const prototypeBaseSeed = 20261003;
const prototypeCatalogueVersion = 2;
// Catalogue v2 passes the 30-puzzle stress run without cooldown relaxation.
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
