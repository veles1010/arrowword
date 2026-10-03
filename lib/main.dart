import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'features/puzzle/data/prototype_puzzle.dart';

void main() {
  // One synchronous, bounded generation per app session, outside widget builds.
  final generation = generatePrototypePuzzle();
  runApp(ArrowwordApp(generation: generation));
}
