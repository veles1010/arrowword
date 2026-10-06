import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';

import 'puzzle_session.dart';
import 'player_puzzle_tracks.dart';
import 'puzzle_replay_screen.dart';
import '../features/puzzle/domain/puzzle_difficulty.dart';
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
    super.key,
  }) : assert(session != null || tracks != null);
  final PuzzleSession? session;
  final PlayerPuzzleTracks? tracks;
  final DailySession? dailySession;
  final AppSettings? settings;
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
    return ListenableBuilder(
      listenable: settings ?? tracks ?? session!,
      builder: (context, _) => MaterialApp(
        title: 'Arrowword',
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
                    : (difficulty) => _TrackPuzzleFlow(
                        tracks: tracks!,
                        difficulty: difficulty,
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
  });
  final PuzzleSession session;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final bool developmentOverride;
  final bool identifyTrack;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final generation = session.current;
      return generation.isSuccess
          ? PuzzleScreen(
              key: ValueKey(generation.puzzle!.id),
              puzzle: generation.puzzle!,
              rewardedAdFactory: rewardedAdFactory,
              title: developmentOverride || identifyTrack
                  ? '${session.difficulty.turkishLabel} · Bulmaca ${generation.puzzleIndex}'
                  : 'Bulmaca ${generation.puzzleIndex}',
              subtitle: developmentOverride
                  ? 'Geliştirme · İlerleme kaydedilmez'
                  : null,
              onNextPuzzle: developmentOverride ? null : session.nextPuzzle,
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
                      title: 'Bulmaca tamamlandı!',
                      contentBuilder: (_) {
                        final score = CompletedPuzzleScore.calculate(
                          puzzleIndex: generation.puzzleIndex,
                          elapsedSeconds: session.elapsed.inSeconds,
                          hintsUsed: session.hintsUsed,
                          wrongChecks: session.wrongChecks,
                        );
                        return Text(
                          puzzleResultDetails(
                            score: score.score,
                            elapsedSeconds: score.elapsedSeconds,
                            hintsUsed: score.hintsUsed,
                            wrongChecks: score.wrongChecks,
                          ),
                        );
                      },
                      actionLabel: 'Oturumu Kapat',
                      onFinished: () {
                        SystemNavigator.pop();
                      },
                    )
                  : null,
            )
          : Scaffold(
              appBar: AppBar(title: const Text('Bulmaca')),
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Bulmaca oluşturulamadı. Lütfen tekrar deneyin.',
                    ),
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
  });
  final PlayerPuzzleTracks tracks;
  final PuzzleDifficulty difficulty;
  final int? replayIndex;
  final RewardedHintAdService Function()? rewardedAdFactory;
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
          session = await widget.tracks.open(widget.difficulty);
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
              rewardedAdFactory: widget.rewardedAdFactory,
            );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.difficulty.turkishLabel)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Bulmaca hazırlanıyor…'),
                ] else ...[
                  const Text('Bulmaca şu anda hazırlanamadı. Tekrar deneyin.'),
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
                    child: const Text('Tekrar Dene'),
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
