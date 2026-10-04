import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'app/development_puzzle.dart';
import 'app/puzzle_session.dart';
import 'app/puzzle_progress_store.dart';
import 'features/puzzle/ads/google_rewarded_hint_ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Test-ad initialization failure must not prevent normal gameplay startup.
  try {
    await initializeHintAds();
  } catch (_) {}
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
    ArrowwordApp(
      session: session,
      openPuzzleDirectly: startIndex != null,
      rewardedAdFactory: createHintAdService,
    ),
  );
}
