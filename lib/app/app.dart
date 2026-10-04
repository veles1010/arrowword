import 'package:flutter/material.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';

import 'puzzle_session.dart';
import 'home_screen.dart';
import '../features/puzzle/presentation/puzzle_screen.dart';

class ArrowwordApp extends StatelessWidget {
  const ArrowwordApp({
    required this.session,
    this.openPuzzleDirectly = false,
    this.rewardedAdFactory,
    super.key,
  });
  final PuzzleSession session;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final bool openPuzzleDirectly;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Arrowword Prototipi',
    debugShowCheckedModeBanner: false,
    navigatorObservers: [puzzleRouteObserver],
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff426B5A)),
    ),
    home: openPuzzleDirectly || !session.current.isSuccess
        ? _PuzzleFlow(session: session, rewardedAdFactory: rewardedAdFactory)
        : HomeScreen(
            session: session,
            puzzleBuilder: (_) => _PuzzleFlow(
              session: session,
              rewardedAdFactory: rewardedAdFactory,
            ),
          ),
  );
}

class _PuzzleFlow extends StatelessWidget {
  const _PuzzleFlow({required this.session, this.rewardedAdFactory});
  final PuzzleSession session;
  final RewardedHintAdService Function()? rewardedAdFactory;
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
              title: 'Bulmaca ${generation.puzzleIndex}',
              onNextPuzzle: session.nextPuzzle,
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
              onCompleted: session.recognizeCompletion,
            )
          : Scaffold(
              appBar: AppBar(title: const Text('Bulmaca Prototipi')),
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Bulmaca oluşturulamadı.\nPrototip üretim hatası:\n${generation.failureReason}',
                    ),
                  ),
                ),
              ),
            );
    },
  );
}
