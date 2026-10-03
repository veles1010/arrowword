import '../generation/puzzle_generator.dart';
import 'prototype_word_bank.dart';

const prototypeSeed = 20261003;
const prototypeGenerationConfig = PuzzleGenerationConfig();

PuzzleGenerationResult generatePrototypePuzzle() =>
    const PuzzleGenerator().generate(
      wordBank: prototypeWordBank,
      seed: prototypeSeed,
      config: prototypeGenerationConfig,
    );
