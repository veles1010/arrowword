import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'app/app_settings.dart';
import 'app/development_puzzle.dart';
import 'app/puzzle_track.dart';
import 'app/daily_session.dart';
import 'app/daily_progress_store.dart';
import 'features/puzzle/ads/google_rewarded_hint_ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DevelopmentPuzzleLaunch? launch;
  try {
    launch = resolveDevelopmentPuzzleLaunch(
      indexProvided: const bool.hasEnvironment('ARROWWORD_PUZZLE_INDEX'),
      releaseMode: kReleaseMode,
      index: const String.fromEnvironment(
        'ARROWWORD_PUZZLE_INDEX',
        defaultValue: '1',
      ),
      difficulty: const String.fromEnvironment(
        'ARROWWORD_PUZZLE_DIFFICULTY',
        defaultValue: 'easy',
      ),
    );
  } on ArgumentError {
    // Invalid inspection defines must never fall through to player persistence.
    runApp(
      const MaterialApp(
        title: 'Arrowword',
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Geliştirme bulmacası açılamadı.\n'
                  'ARROWWORD_PUZZLE_INDEX pozitif bir sayı olmalı.\n'
                  'ARROWWORD_PUZZLE_DIFFICULTY: easy, medium veya hard.',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  // Test-ad initialization failure must not prevent normal gameplay startup.
  try {
    await initializeHintAds();
  } catch (_) {}
  // Generate outside widget builds; development replay happens once.
  final startIndex = launch?.index;
  final session = await PuzzleTrack(
    configuration: developmentTrackConfiguration(
      startIndex,
      launch?.difficulty.id ?? 'easy',
    ),
  ).open(developmentIndex: startIndex);
  // Only metadata is read here. The Daily board is generated lazily on entry.
  final daily = startIndex == null
      ? await DailySession.restore(store: SharedPreferencesDailyProgressStore())
      : null;
  final settings = await AppSettings.restore(SharedPreferencesSettingsStore());
  runApp(
    ArrowwordApp(
      session: session,
      settings: settings,
      dailySession: daily,
      openPuzzleDirectly: startIndex != null,
      developmentOverride: launch != null,
      rewardedAdFactory: createHintAdService,
    ),
  );
}
