import '../generation/puzzle_generator.dart';
import '../content/word_catalogue.dart';
import '../sequence/puzzle_sequence.dart';
import 'prototype_word_bank.dart';

const prototypeBaseSeed = 20261003;
const prototypeCatalogueVersion = 1;
// K=5 and K=4 fail at index 5 with 20 eligible words. K=3 completes 10.
// The general sequence default remains five; no automatic relaxation occurs.
const prototypeSequenceCooldown = 3;
const prototypeGenerationConfig = PuzzleGenerationConfig();
final prototypeCatalogue = WordCatalogue(
  version: prototypeCatalogueVersion,
  entries: prototypeWordBank,
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
