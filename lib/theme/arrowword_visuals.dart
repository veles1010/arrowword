import 'package:flutter/material.dart';

import '../features/puzzle/domain/puzzle_difficulty.dart';

/// Local game surfaces and small content accents. Navigation ColorScheme roles
/// stay unchanged; square cells retain their existing geometry and state widths.
class ArrowwordVisuals extends ThemeExtension<ArrowwordVisuals> {
  const ArrowwordVisuals({
    required this.puzzlePage,
    required this.cell,
    required this.unused,
    required this.clue,
    required this.gridBorder,
    required this.active,
    required this.activeBorder,
    required this.hintActive,
    required this.mediumAccent,
    required this.hardAccent,
  });
  final Color puzzlePage, cell, unused, clue, gridBorder;
  final Color active, activeBorder, hintActive, mediumAccent, hardAccent;

  factory ArrowwordVisuals.forScheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return ArrowwordVisuals(
      puzzlePage: dark ? const Color(0xff18191c) : const Color(0xfff5f7fb),
      cell: dark ? const Color(0xff292d33) : const Color(0xffffffff),
      unused: dark ? const Color(0xff202226) : const Color(0xffeef1f5),
      clue: dark ? const Color(0xff34383f) : const Color(0xffe3e7ed),
      gridBorder: dark ? const Color(0xff626b79) : const Color(0xffa6b0be),
      active: dark ? const Color(0xff243b5b) : const Color(0xffe8f0ff),
      activeBorder: dark ? const Color(0xff7395cc) : const Color(0xff668aca),
      hintActive: dark ? const Color(0xff2d4668) : const Color(0xffddeaff),
      mediumAccent: dark ? const Color(0xfff0b85b) : const Color(0xff9a5b00),
      hardAccent: dark ? const Color(0xffc7aaee) : const Color(0xff7650b5),
    );
  }
  static ArrowwordVisuals of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ArrowwordVisuals>() ??
        ArrowwordVisuals.forScheme(theme.colorScheme);
  }

  Color difficultyAccent(PuzzleDifficulty difficulty, ColorScheme scheme) =>
      switch (difficulty) {
        PuzzleDifficulty.easy => scheme.primary,
        PuzzleDifficulty.medium => mediumAccent,
        PuzzleDifficulty.hard => hardAccent,
      };
  @override
  ArrowwordVisuals copyWith({
    Color? puzzlePage,
    Color? cell,
    Color? unused,
    Color? clue,
    Color? gridBorder,
    Color? active,
    Color? activeBorder,
    Color? hintActive,
    Color? mediumAccent,
    Color? hardAccent,
  }) => ArrowwordVisuals(
    puzzlePage: puzzlePage ?? this.puzzlePage,
    cell: cell ?? this.cell,
    unused: unused ?? this.unused,
    clue: clue ?? this.clue,
    gridBorder: gridBorder ?? this.gridBorder,
    active: active ?? this.active,
    activeBorder: activeBorder ?? this.activeBorder,
    hintActive: hintActive ?? this.hintActive,
    mediumAccent: mediumAccent ?? this.mediumAccent,
    hardAccent: hardAccent ?? this.hardAccent,
  );
  @override
  ArrowwordVisuals lerp(covariant ArrowwordVisuals? other, double t) {
    if (other == null) return this;
    return ArrowwordVisuals(
      puzzlePage: Color.lerp(puzzlePage, other.puzzlePage, t)!,
      cell: Color.lerp(cell, other.cell, t)!,
      unused: Color.lerp(unused, other.unused, t)!,
      clue: Color.lerp(clue, other.clue, t)!,
      gridBorder: Color.lerp(gridBorder, other.gridBorder, t)!,
      active: Color.lerp(active, other.active, t)!,
      activeBorder: Color.lerp(activeBorder, other.activeBorder, t)!,
      hintActive: Color.lerp(hintActive, other.hintActive, t)!,
      mediumAccent: Color.lerp(mediumAccent, other.mediumAccent, t)!,
      hardAccent: Color.lerp(hardAccent, other.hardAccent, t)!,
    );
  }
}
