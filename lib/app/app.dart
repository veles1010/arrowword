import '../l10n/ui_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/language_policy.dart';
import '../l10n/app_language.dart';
import '../l10n/clue_presentation.dart';
import '../l10n/clue_pack_cache.dart';
import '../features/puzzle/localization/clue_pack.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';

import 'puzzle_session.dart';
import 'player_puzzle_tracks.dart';
import 'puzzle_replay_screen.dart';
import '../features/puzzle/domain/puzzle_difficulty.dart';
import '../features/puzzle/domain/normal_puzzle_contract.dart';
import 'app_shell.dart';
import 'daily_session.dart';
import 'app_settings.dart';
import 'arrowword_theme.dart';
import '../features/puzzle/presentation/puzzle_screen.dart';
import '../features/puzzle/presentation/puzzle_completion.dart';
import '../features/puzzle/domain/puzzle_score.dart';

class ArrowwordApp extends StatelessWidget {
  const ArrowwordApp({
    this.session,
    this.tracks,
    this.openPuzzleDirectly = false,
    this.developmentOverride = false,
    this.rewardedAdFactory,
    this.dailySession,
    this.settings,
    this.language,
    this.uiLocalePreview,
    this.clueResolver,
    this.clueCache,
    super.key,
  }) : assert(session != null || tracks != null);
  final PuzzleSession? session;
  final PlayerPuzzleTracks? tracks;
  final DailySession? dailySession;
  final AppSettings? settings;
  final AppLanguage? language;
  final String? uiLocalePreview;
  final LocalizedClueResolver? clueResolver;
  final CluePackCache? clueCache;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final bool openPuzzleDirectly;
  final bool developmentOverride;
  @override
  Widget build(BuildContext context) {
    if (developmentOverride && (session == null || session!.store != null)) {
      throw ArgumentError(
        'Development override requires a memory-only session.',
      );
    }
    return SystemLocaleListener(
      builder: (context) => ListenableBuilder(
        listenable: Listenable.merge([
          settings ?? tracks ?? session!,
          ?language,
        ]),
        builder: (context, _) {
          final productionLocale = LanguagePolicy.production.resolve(
            language?.preference ?? AppLanguagePreference.system,
            WidgetsBinding.instance.platformDispatcher.locales.map(
              (l) => l.toLanguageTag(),
            ),
          );
          final preview = developmentUiLocale(
            uiLocalePreview ?? '',
            releaseMode: kReleaseMode,
          );
          return MaterialApp(
            title: 'Arrowword',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale.fromSubtags(
              languageCode: (preview ?? productionLocale).split('-').first,
              countryCode: (preview ?? productionLocale).contains('-')
                  ? (preview ?? productionLocale).split('-').last
                  : null,
            ),
            builder: (context, child) {
              Widget result = child!;
              if (clueResolver != null || clueCache != null) {
                result = CluePresentation(
                  resolver: clueResolver,
                  cache: clueCache,
                  // Delegates may load asynchronously. Keep clues paired with
                  // the currently loaded UI until the new locale is ready.
                  // Only the explicit development UI-only preview may differ.
                  locale: preview == null
                      ? Localizations.localeOf(context).toLanguageTag()
                      : productionLocale,
                  child: result,
                );
              }
              if (language != null) {
                result = AppLanguageScope(language: language!, child: result);
              }
              return result;
            },
            debugShowCheckedModeBanner: false,
            navigatorObservers: [puzzleRouteObserver],
            theme: ArrowwordTheme.light(),
            darkTheme: ArrowwordTheme.dark(),
            themeMode: settings?.themeMode ?? ThemeMode.system,
            home:
                developmentOverride ||
                    openPuzzleDirectly ||
                    (session != null && !session!.current.isSuccess)
                ? _PuzzleFlow(
                    session: session!,
                    rewardedAdFactory: rewardedAdFactory,
                    developmentOverride: developmentOverride,
                  )
                : AppShell(
                    session: session,
                    tracks: tracks,
                    trackPuzzleBuilder: tracks == null
                        ? null
                        : (difficulty, onFinished) => _TrackPuzzleFlow(
                            tracks: tracks!,
                            difficulty: difficulty,
                            onTrackFinished: onFinished,
                            rewardedAdFactory: rewardedAdFactory,
                          ),
                    trackReplayBuilder: tracks == null
                        ? null
                        : (difficulty, index) => _TrackPuzzleFlow(
                            tracks: tracks!,
                            difficulty: difficulty,
                            replayIndex: index,
                            rewardedAdFactory: rewardedAdFactory,
                          ),
                    settings: settings,
                    dailySession: dailySession,
                    rewardedAdFactory: rewardedAdFactory,
                    puzzleBuilder: (_) => tracks != null
                        ? _TrackPuzzleFlow(
                            tracks: tracks!,
                            difficulty: tracks!.lastPlayed,
                            rewardedAdFactory: rewardedAdFactory,
                          )
                        : _PuzzleFlow(
                            session: session!,
                            rewardedAdFactory: rewardedAdFactory,
                          ),
                  ),
          );
        },
      ),
    );
  }
}

class _PuzzleFlow extends StatelessWidget {
  const _PuzzleFlow({
    required this.session,
    this.rewardedAdFactory,
    this.developmentOverride = false,
    this.identifyTrack = false,
    this.onTrackFinished,
  });
  final PuzzleSession session;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final bool developmentOverride;
  final bool identifyTrack;
  final VoidCallback? onTrackFinished;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final generation = session.current;
      return generation.isSuccess && isNormalPuzzleIndex(generation.puzzleIndex)
          ? CluePackGate(
              child: PuzzleScreen(
                key: ValueKey(generation.puzzle!.id),
                puzzle: generation.puzzle!,
                rewardedAdFactory: rewardedAdFactory,
                title: developmentOverride || identifyTrack
                    ? context.l10n.trackPuzzle(
                        context.difficultyLabel(session.difficulty),
                        generation.puzzleIndex,
                      )
                    : context.l10n.puzzleNumber(generation.puzzleIndex),
                subtitle: developmentOverride ? context.l10n.development : null,
                onNextPuzzle:
                    developmentOverride ||
                        generation.puzzleIndex >= normalPuzzleCount
                    ? null
                    : session.nextPuzzle,
                initialLetters: session.letters,
                initialRevealedCells: session.revealedCells,
                initialElapsed: session.elapsed,
                initialWrongChecks: session.wrongChecks,
                attemptFinalized:
                    session.completedThrough >= generation.puzzleIndex,
                onAttemptProgress: (letters, revealed, elapsed, checks) {
                  if (session.current.puzzleIndex == generation.puzzleIndex) {
                    session.updateAttemptProgress(
                      letters,
                      revealed,
                      elapsed,
                      checks,
                    );
                  }
                },
                onElapsedChanged: (elapsed) {
                  // Disposal of N happens after the session has already moved to N+1.
                  if (session.current.puzzleIndex == generation.puzzleIndex) {
                    session.checkpointElapsed(elapsed);
                  }
                },
                scoreResult: () => session.currentScore,
                onCompleted: developmentOverride
                    ? null
                    : session.recognizeCompletion,
                completion: developmentOverride
                    ? PuzzleCompletionPresentation(
                        title: context.l10n.puzzleCompleted,
                        contentBuilder: (dialogContext) {
                          final score = CompletedPuzzleScore.calculate(
                            puzzleIndex: generation.puzzleIndex,
                            elapsedSeconds: session.elapsed.inSeconds,
                            hintsUsed: session.hintsUsed,
                            wrongChecks: session.wrongChecks,
                          );
                          return Text(
                            puzzleResultDetails(
                              strings: dialogContext.l10n,
                              score: score.score,
                              elapsedSeconds: score.elapsedSeconds,
                              hintsUsed: score.hintsUsed,
                              wrongChecks: score.wrongChecks,
                            ),
                          );
                        },
                        actionLabel: context.l10n.closeSession,
                        onFinished: () {
                          SystemNavigator.pop();
                        },
                      )
                    : generation.puzzleIndex == normalPuzzleCount
                    ? PuzzleCompletionPresentation(
                        title: context.l10n.trackFinished(
                          context.difficultyLabel(session.difficulty),
                        ),
                        contentBuilder: (dialogContext) {
                          final score = session.currentScore;
                          return Text(
                            score == null
                                ? dialogContext.l10n.legacyScoringMessage
                                : puzzleResultDetails(
                                    strings: dialogContext.l10n,
                                    score: score.score,
                                    elapsedSeconds: score.elapsedSeconds,
                                    hintsUsed: score.hintsUsed,
                                    wrongChecks: score.wrongChecks,
                                  ),
                          );
                        },
                        actionLabel: onTrackFinished == null
                            ? context.l10n.back
                            : context.l10n.returnPuzzles,
                        onFinished: () {
                          Navigator.of(context).maybePop();
                          onTrackFinished?.call();
                        },
                      )
                    : null,
              ),
            )
          : Scaffold(
              appBar: AppBar(title: Text(context.l10n.puzzle)),
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.l10n.puzzleGenerationFailed),
                  ),
                ),
              ),
            );
    },
  );
}

/// Paint loading before opening only the requested track; no generator in build.
class _TrackPuzzleFlow extends StatefulWidget {
  const _TrackPuzzleFlow({
    required this.tracks,
    required this.difficulty,
    this.replayIndex,
    this.rewardedAdFactory,
    this.onTrackFinished,
  });
  final PlayerPuzzleTracks tracks;
  final PuzzleDifficulty difficulty;
  final int? replayIndex;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final VoidCallback? onTrackFinished;
  @override
  State<_TrackPuzzleFlow> createState() => _TrackPuzzleFlowState();
}

class _TrackPuzzleFlowState extends State<_TrackPuzzleFlow> {
  PuzzleSession? _session;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _open();
  }

  void _open() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() async {
        if (!mounted) return;
        PuzzleSession? session;
        try {
          session = await widget.tracks.open(
            widget.difficulty,
            replay: widget.replayIndex != null,
          );
        } catch (_) {
          /* Keep internals out of player errors. */
        }
        if (!mounted) {
          if (session != null && !widget.tracks.ownsSession(session)) {
            session.dispose();
          }
          return;
        }
        if (session != null &&
            session.current.isSuccess &&
            widget.replayIndex == null) {
          await widget.tracks.open(widget.difficulty, markPlayed: true);
        }
        if (!mounted) return;
        setState(() {
          _session = session;
          _loading = false;
        });
      });
    });
  }

  @override
  void dispose() {
    if (_session != null && !widget.tracks.ownsSession(_session!)) {
      _session!.dispose();
    }
    final tracks = widget.tracks, difficulty = widget.difficulty;
    Future.microtask(() => tracks.refresh(difficulty));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (!_loading && session != null && session.current.isSuccess) {
      return widget.replayIndex != null
          ? PuzzleReplayScreen(
              session: session,
              puzzleIndex: widget.replayIndex!,
              identifyTrack: true,
              rewardedAdFactory: widget.rewardedAdFactory,
            )
          : _PuzzleFlow(
              session: session,
              identifyTrack: true,
              onTrackFinished: widget.onTrackFinished,
              rewardedAdFactory: widget.rewardedAdFactory,
            );
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.difficultyLabel(widget.difficulty))),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading) ...[
                  CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(context.l10n.puzzleLoading),
                ] else ...[
                  Text(context.l10n.generationError),
                  TextButton(
                    onPressed: () {
                      if (_session != null &&
                          !widget.tracks.ownsSession(_session!)) {
                        _session!.dispose();
                      }
                      _session = null;
                      setState(() => _loading = true);
                      _open();
                    },
                    child: Text(context.l10n.retry),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
