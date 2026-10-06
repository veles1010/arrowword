import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'app_settings.dart';
import 'daily_session.dart';
import 'daily_landing_screen.dart';
import 'fluid_navigation_bar.dart';
import 'home_screen.dart';
import 'puzzle_session.dart';
import 'player_puzzle_tracks.dart';
import '../features/puzzle/domain/puzzle_difficulty.dart';
import 'puzzle_progression_screen.dart';
import 'statistics_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    this.session,
    this.tracks,
    this.trackPuzzleBuilder,
    this.trackReplayBuilder,
    required this.puzzleBuilder,
    this.dailySession,
    this.settings,
    this.rewardedAdFactory,
    this.selectionHaptic,
    super.key,
  });
  final PuzzleSession? session;
  final PlayerPuzzleTracks? tracks;
  final Widget Function(PuzzleDifficulty)? trackPuzzleBuilder;
  final Widget Function(PuzzleDifficulty, int)? trackReplayBuilder;
  final WidgetBuilder puzzleBuilder;
  final DailySession? dailySession;
  final AppSettings? settings;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final Future<void> Function()? selectionHaptic;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  double _direction = 1;
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );
  void _select(int index) {
    if (index == _index) return;
    unawaited(_confirmSelection());
    widget.dailySession?.refreshDate();
    setState(() {
      _direction = index > _index ? 1 : -1;
      _index = index;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _transition.value = 1;
    } else {
      _transition.forward(from: 0);
    }
  }

  Future<void> _confirmSelection() async {
    try {
      await (widget.selectionHaptic ?? HapticFeedback.selectionClick)();
    } catch (_) {
      /* Haptics are optional on unsupported platforms. */
    }
  }

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _index == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _index != 0) _select(0);
    },
    child: Scaffold(
      body: AnimatedBuilder(
        animation: _transition,
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(
              session: widget.session,
              tracks: widget.tracks,
              onChooseDifficulty: () => _select(1),
              dailySession: widget.dailySession,
              settings: widget.settings,
              puzzleBuilder: widget.puzzleBuilder,
              rewardedAdFactory: widget.rewardedAdFactory,
              inShell: true,
            ),
            PuzzleProgressionScreen(
              session: widget.session,
              tracks: widget.tracks,
              trackPuzzleBuilder: widget.trackPuzzleBuilder,
              trackReplayBuilder: widget.trackReplayBuilder,
              puzzleBuilder: widget.puzzleBuilder,
              rewardedAdFactory: widget.rewardedAdFactory,
              inShell: true,
            ),
            DailyLandingScreen(
              session: widget.dailySession,
              rewardedAdFactory: widget.rewardedAdFactory,
            ),
            StatisticsScreen(
              session: widget.session,
              tracks: widget.tracks,
              dailySession: widget.dailySession,
              inShell: true,
            ),
          ],
        ),
        builder: (context, child) {
          final value = Curves.easeOutCubic.transform(_transition.value);
          return FractionalTranslation(
            translation: Offset(_direction * .025 * (1 - value), 0),
            child: Opacity(opacity: .94 + .06 * value, child: child),
          );
        },
      ),
      bottomNavigationBar: FluidNavigationBar(
        index: _index,
        onSelected: _select,
      ),
    ),
  );
}
