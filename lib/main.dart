import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'app/development_puzzle.dart';
import 'app/puzzle_session.dart';

void main() {
  // Generate outside widget builds; development replay happens once.
  final startIndex = kDebugMode
      ? developmentPuzzleIndex(
          const String.fromEnvironment(
            'ARROWWORD_PUZZLE_INDEX',
            defaultValue: '1',
          ),
        )
      : 1;
  runApp(ArrowwordApp(session: PuzzleSession(startIndex: startIndex)));
}
