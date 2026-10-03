import 'package:flutter/material.dart';

import '../features/puzzle/generation/puzzle_generator.dart';
import '../features/puzzle/presentation/puzzle_screen.dart';

class ArrowwordApp extends StatelessWidget {
  const ArrowwordApp({required this.generation, super.key});
  final PuzzleGenerationResult generation;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Arrowword Prototipi',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff426B5A)),
    ),
    home: generation.isSuccess
        ? PuzzleScreen(puzzle: generation.puzzle!)
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
          ),
  );
}
