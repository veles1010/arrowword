import 'package:flutter/material.dart';

import 'puzzle_session.dart';
import 'puzzle_progression_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.session,
    required this.puzzleBuilder,
    super.key,
  });
  final PuzzleSession session;
  final WidgetBuilder puzzleBuilder;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openPuzzle() async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: widget.puzzleBuilder));
    // Letter changes do not notify the whole session. Refresh the CTA on return.
    if (mounted) setState(() {});
  }

  Future<void> _openProgression() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PuzzleProgressionScreen(
          session: widget.session,
          puzzleBuilder: widget.puzzleBuilder,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final session = widget.session;
      final fresh =
          session.current.puzzleIndex == 1 &&
          session.letters.isEmpty &&
          session.completedThrough == 0;
      return Scaffold(
        appBar: AppBar(title: const Text('Arrowword')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bulmaca ${session.current.puzzleIndex}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    session.completedThrough == 0
                        ? 'Henüz tamamlanan bulmaca yok'
                        : '${session.completedThrough} bulmaca tamamlandı',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: session.current.isSuccess ? _openPuzzle : null,
                    child: Text(fresh ? 'Başla' : 'Devam Et'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _openProgression,
                    child: const Text('Bulmacalar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
