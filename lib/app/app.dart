import 'package:flutter/material.dart';

import 'puzzle_session.dart';
import '../features/puzzle/presentation/puzzle_screen.dart';

class ArrowwordApp extends StatelessWidget {
  const ArrowwordApp({required this.session, super.key});
  final PuzzleSession session;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Arrowword Prototipi',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff426B5A)),
    ),
    home: ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final generation = session.current;
        return generation.isSuccess
            ? PuzzleScreen(
                key: ValueKey(generation.puzzle!.id),
                puzzle: generation.puzzle!,
                title: 'Bulmaca ${generation.puzzleIndex}',
                onNextPuzzle: session.nextPuzzle,
                initialLetters: session.letters,
                onLettersChanged: session.updateLetters,
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
    ),
  );
}
