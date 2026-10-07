import '../l10n/ui_strings.dart';

import 'package:flutter/material.dart';

import '../features/puzzle/domain/normal_puzzle_contract.dart';

import '../theme/arrowword_visuals.dart';

import 'player_statistics.dart';
import 'puzzle_session.dart';
import 'player_puzzle_tracks.dart';
import 'puzzle_difficulty_selector.dart';
import '../features/puzzle/domain/puzzle_difficulty.dart';
import 'daily_session.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    this.session,
    this.tracks,
    this.dailySession,
    this.inShell = false,
    super.key,
  });

  final PuzzleSession? session;
  final PlayerPuzzleTracks? tracks;
  final DailySession? dailySession;
  final bool inShell;
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late PuzzleDifficulty _difficulty =
      widget.tracks?.lastPlayed ?? PuzzleDifficulty.easy;
  PuzzleSession? get session => widget.session;
  PlayerPuzzleTracks? get tracks => widget.tracks;
  DailySession? get dailySession => widget.dailySession;
  bool get inShell => widget.inShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.statistics),
      automaticallyImplyLeading: !inShell,
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([?session, ?tracks, ?dailySession]),
        builder: (context, _) {
          final summary =
              tracks?.summary(_difficulty) ??
              PuzzleTrackSummary.fromSession(session!);
          final statistics = PlayerStatistics.fromScores(
            completedThrough: summary.completedCount,
            scores: summary.scores.values,
          );
          final best = statistics.bestScore;
          final accent = ArrowwordVisuals.of(context)
              .difficultyAccent(_difficulty, Theme.of(context).colorScheme);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 12.0;
                    final cardWidth = constraints.maxWidth >= 560
                        ? (constraints.maxWidth - gap) / 2
                        : constraints.maxWidth;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (tracks != null) ...[
                          PuzzleDifficultySelector(
                            selected: _difficulty,
                            onChanged: (value) =>
                                setState(() => _difficulty = value),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          context.l10n.statisticsIntro,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _StatisticCard(
                              key: const ValueKey('statistics-completed'),
                              iconColor: accent,
                              width: cardWidth,
                              icon: Icons.task_alt,
                              label: context.l10n.completedPuzzles,
                              value: '${statistics.completedPuzzleCount}',
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-scored'),
                              iconColor: accent,
                              width: cardWidth,
                              icon: Icons.scoreboard_outlined,
                              label: context.l10n.scoredPuzzles,
                              value: '${statistics.scoredPuzzleCount}',
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-total'),
                              iconColor: accent,
                              width: cardWidth,
                              icon: Icons.stars_outlined,
                              label: context.l10n.totalScore,
                              value: '${statistics.totalScore}',
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-average'),
                              iconColor: accent,
                              width: cardWidth,
                              icon: Icons.calculate_outlined,
                              label: context.l10n.averageScore,
                              value:
                                  statistics.averageScore?.toStringAsFixed(1) ??
                                  context.l10n.noScore,
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-best'),
                              iconColor: accent,
                              width: cardWidth,
                              icon: Icons.emoji_events_outlined,
                              label: context.l10n.bestScore,
                              value:
                                  statistics.maxScore?.toString() ??
                                  context.l10n.noScore,
                              detail: best == null
                                  ? null
                                  : isNormalPuzzleIndex(best.puzzleIndex)
                                  ? context.l10n.bestDetail(
                                      best.puzzleIndex,
                                      best.elapsedSeconds,
                                    )
                                  : context.l10n.legacyDetail(
                                      best.elapsedSeconds,
                                    ),
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-hint-free'),
                              iconColor: accent,
                              width: cardWidth,
                              icon: Icons.lightbulb_outline,
                              label: context.l10n.hintFree,
                              value: '${statistics.hintFreeBestScoreCount}',
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-error-free'),
                              iconColor: accent,
                              width: cardWidth,
                              icon: Icons.check_circle_outline,
                              label: context.l10n.errorFree,
                              value: '${statistics.errorFreeBestScoreCount}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.statisticsExplanation,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (tracks != null)
                          Text(
                            context.l10n.withinDifficulty,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (dailySession != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            context.l10n.dailyStatistics,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              _StatisticCard(
                                width: cardWidth,
                                icon: Icons.today,
                                label: context.l10n.dailyCount,
                                value:
                                    '${dailySession!.statistics.totalCompletedDaily}',
                              ),
                              _StatisticCard(
                                width: cardWidth,
                                icon: Icons.local_fire_department_outlined,
                                label: context.l10n.currentStreak,
                                value:
                                    '${dailySession!.statistics.currentStreak}',
                              ),
                              _StatisticCard(
                                width: cardWidth,
                                icon: Icons.calendar_month,
                                label: context.l10n.longestStreak,
                                value:
                                    '${dailySession!.statistics.longestStreak}',
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    this.iconColor,
    super.key,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(detail!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    ),
  );
}
