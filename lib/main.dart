import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'app/development_puzzle.dart';
import 'features/puzzle/data/prototype_puzzle.dart';

void main() {
  // One synchronous, bounded generation per app session, outside widget builds.
  final generation = kDebugMode
      ? generateDevelopmentPuzzle(
          developmentPuzzleIndex(
            const String.fromEnvironment(
              'ARROWWORD_PUZZLE_INDEX',
              defaultValue: '1',
            ),
          ),
        )
      : generatePrototypePuzzle();
  runApp(ArrowwordApp(generation: generation));
}
