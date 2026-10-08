import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'l10n/app_language.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/generated/app_localizations_tr.dart';
import 'l10n/clue_pack_cache.dart';
import 'l10n/language_policy.dart';

import 'app/app.dart';
import 'audio/game_audio.dart';
import 'audio/audioplayers_backend.dart';
import 'app/app_settings.dart';
import 'app/development_puzzle.dart';
import 'app/puzzle_track.dart';
import 'app/puzzle_session.dart';
import 'app/player_puzzle_tracks.dart';
import 'app/daily_session.dart';
import 'app/daily_progress_store.dart';
import 'features/puzzle/ads/google_rewarded_hint_ad_service.dart';
import 'features/puzzle/domain/normal_puzzle_contract.dart';

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
      MaterialApp(
        title: 'Arrowword',
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  AppLocalizationsTr().invalidDevConfig(normalPuzzleCount),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  // Generate outside widget builds; development replay happens once.
  final startIndex = launch?.index;
  final PuzzleSession? session = startIndex == null
      ? null
      : await PuzzleTrack(
          configuration: developmentTrackConfiguration(
            startIndex,
            launch?.difficulty.id ?? 'easy',
          ),
        ).open(developmentIndex: startIndex);
  final tracks = startIndex == null ? await PlayerPuzzleTracks.restore() : null;
  // Only metadata is read here. The Daily board is generated lazily on entry.
  final daily = startIndex == null
      ? await DailySession.restore(store: SharedPreferencesDailyProgressStore())
      : null;
  final settings = await AppSettings.restore(SharedPreferencesSettingsStore());
  final language = await AppLanguage.restore(SharedPreferencesLanguageStore());
  final clues = CluePackCache(
    (locale) => rootBundle.loadString('assets/clues/$locale.json'),
    locales: LanguagePolicy.production.enabled,
  );
  runApp(
    GameAudioHost(
      audio: GameAudio(settings, AudioplayersBackend()),
      child: ArrowwordApp(
        session: session,
        tracks: tracks,
        settings: settings,
        language: language,
        clueCache: clues,
        uiLocalePreview: const String.fromEnvironment('ARROWWORD_UI_LOCALE'),
        dailySession: daily,
        openPuzzleDirectly: startIndex != null,
        developmentOverride: launch != null,
        rewardedAdFactory: createHintAdService,
      ),
    ),
  );
  // Ads are optional: paint the app before beginning SDK initialization.
  scheduleHintAdsInitialization();
}
