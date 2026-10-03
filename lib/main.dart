import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'app/development_puzzle.dart';
import 'app/puzzle_session.dart';
import 'app/puzzle_progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Generate outside widget builds; development replay happens once.
  final startIndex =
      kDebugMode && const bool.hasEnvironment('ARROWWORD_PUZZLE_INDEX')
      ? developmentPuzzleIndex(
          const String.fromEnvironment(
            'ARROWWORD_PUZZLE_INDEX',
            defaultValue: '1',
          ),
        )
      : null;
  final session = await PuzzleSession.restore(
    store: SharedPreferencesPuzzleProgressStore(),
    developmentIndex: startIndex,
  );
  runApp(
    ArrowwordApp(session: session, openPuzzleDirectly: startIndex != null),
  );
}
