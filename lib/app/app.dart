import 'package:flutter/material.dart';

import '../features/puzzle/data/manual_puzzle.dart';
import '../features/puzzle/presentation/puzzle_screen.dart';

class ArrowwordApp extends StatelessWidget {
  const ArrowwordApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Arrowword Prototipi',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff426B5A)),
    ),
    home: PuzzleScreen(puzzle: manualPuzzle),
  );
}
