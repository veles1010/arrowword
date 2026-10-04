import 'package:flutter/material.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'app_settings.dart';
import 'daily_session.dart';
import 'daily_landing_screen.dart';
import 'fluid_navigation_bar.dart';
import 'home_screen.dart';
import 'puzzle_session.dart';
import 'puzzle_progression_screen.dart';
import 'statistics_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.session,
    required this.puzzleBuilder,
    this.dailySession,
    this.settings,
    this.rewardedAdFactory,
    super.key,
  });
  final PuzzleSession session;
  final WidgetBuilder puzzleBuilder;
  final DailySession? dailySession;
  final AppSettings? settings;
  final RewardedHintAdService Function()? rewardedAdFactory;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  double _direction = 1;
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  void _select(int index) {
    if (index == _index) return;
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
              dailySession: widget.dailySession,
              settings: widget.settings,
              puzzleBuilder: widget.puzzleBuilder,
              rewardedAdFactory: widget.rewardedAdFactory,
              inShell: true,
            ),
            PuzzleProgressionScreen(
              session: widget.session,
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
              dailySession: widget.dailySession,
              inShell: true,
            ),
          ],
        ),
        builder: (context, child) {
          final value = Curves.easeOutCubic.transform(_transition.value);
          return FractionalTranslation(
            translation: Offset(_direction * .035 * (1 - value), 0),
            child: Opacity(opacity: .88 + .12 * value, child: child),
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
