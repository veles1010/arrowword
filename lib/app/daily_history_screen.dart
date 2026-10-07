import '../l10n/ui_strings.dart';

import 'package:flutter/material.dart';

import 'daily_session.dart';
import 'daily_statistics.dart';

class DailyHistoryScreen extends StatelessWidget {
  const DailyHistoryScreen({required this.session, super.key});
  final DailySession session;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.dailyHistory)),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final results = session.results.values.toList()
            ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
          if (results.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.emptyHistory),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedDailyDate(result.dateKey, context.l10n),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(context.l10n.scorePoints(result.score)),
                      Text(
                        context.l10n.dailyDetails(
                          formatDailyDuration(result.elapsedSeconds),
                          result.hintsUsed,
                          result.wrongChecks,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
