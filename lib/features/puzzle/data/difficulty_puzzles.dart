import '../content/word_catalogue.dart';
import '../sequence/puzzle_sequence.dart';
import 'track_catalogue_data.dart';

const mediumCatalogueVersion = 1, mediumSequenceVersion = 1;
const hardCatalogueVersion = 1, hardSequenceVersion = 1;
const mediumBaseSeed = 0x4D454431; // MED1
const hardBaseSeed = 0x48415231; // HAR1

// Lazy top-level initialization: Easy startup does not construct these banks.
final mediumCatalogue = WordCatalogue(
  version: mediumCatalogueVersion,
  entries: mediumWords,
);
final hardCatalogue = WordCatalogue(
  version: hardCatalogueVersion,
  entries: hardWords,
);
const mediumSequenceConfig = PuzzleSequenceConfig(
  baseSeed: mediumBaseSeed,
  puzzleIdPrefix: 'generated-medium-v1',
);
const hardSequenceConfig = PuzzleSequenceConfig(
  baseSeed: hardBaseSeed,
  puzzleIdPrefix: 'generated-hard-v1',
);
PuzzleSequenceGenerator createMediumGenerator() =>
    PuzzleSequenceGenerator(mediumCatalogue, mediumSequenceConfig);
PuzzleSequenceGenerator createHardGenerator() =>
    PuzzleSequenceGenerator(hardCatalogue, hardSequenceConfig);
