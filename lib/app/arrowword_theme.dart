import 'package:flutter/material.dart';

import '../theme/arrowword_visuals.dart';

/// Blue identity with neutral surfaces; semantic roles also style puzzle cells.
abstract final class ArrowwordTheme {
  static const arrowBlue = Color(0xff3478f6);

  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: arrowBlue,
          brightness: brightness,
        ).copyWith(
          // Slightly deeper than the seed so white button/cell text stays readable.
          primary: dark ? const Color(0xff9bbcff) : const Color(0xff2864d7),
          onPrimary: dark ? const Color(0xff102d60) : const Color(0xffffffff),
          primaryContainer: dark
              ? const Color(0xff253956)
              : const Color(0xffe5eeff),
          onPrimaryContainer: dark
              ? const Color(0xffdbe7ff)
              : const Color(0xff173968),
          secondary: dark ? const Color(0xff8eaee2) : const Color(0xff416ca9),
          secondaryContainer: dark
              ? const Color(0xff222e40)
              : const Color(0xffeff4fc),
          onSecondaryContainer: dark
              ? const Color(0xffe0e8f6)
              : const Color(0xff263a56),
          // Clue cells use a neutral, not chromatic, tertiary container.
          tertiaryContainer: dark
              ? const Color(0xff303237)
              : const Color(0xffe9ebee),
          onTertiaryContainer: dark
              ? const Color(0xffeef0f3)
              : const Color(0xff292d34),
          surface: dark ? const Color(0xff18191c) : const Color(0xfffafbfc),
          surfaceDim: dark ? const Color(0xff18191c) : const Color(0xffd9dce1),
          surfaceBright: dark
              ? const Color(0xff393b40)
              : const Color(0xfffafbfc),
          surfaceContainerLowest: dark
              ? const Color(0xff121316)
              : const Color(0xffffffff),
          surfaceContainerLow: dark
              ? const Color(0xff202125)
              : const Color(0xfff4f5f7),
          surfaceContainer: dark
              ? const Color(0xff27282d)
              : const Color(0xffeff0f3),
          surfaceContainerHigh: dark
              ? const Color(0xff2e3035)
              : const Color(0xffe8eaee),
          surfaceContainerHighest: dark
              ? const Color(0xff36383e)
              : const Color(0xffe1e4e9),
          onSurface: dark ? const Color(0xfff0f1f4) : const Color(0xff20242c),
          onSurfaceVariant: dark
              ? const Color(0xffc1c5ce)
              : const Color(0xff505763),
          outline: dark ? const Color(0xff8b919c) : const Color(0xff747c89),
          outlineVariant: dark
              ? const Color(0xff4b5059)
              : const Color(0xffccd1da),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [ArrowwordVisuals.forScheme(scheme)],
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
    );
  }
}
