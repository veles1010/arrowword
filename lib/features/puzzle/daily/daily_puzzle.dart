import '../data/prototype_puzzle.dart';
import '../domain/puzzle.dart';
import '../generation/puzzle_generator.dart';
import '../generation/puzzle_validator.dart';

/// Increment when the date-to-board contract changes.
const dailySeedVersion = 1;
const dailyMaxGenerationAttempts = 2;

/// Uses the supplied local calendar fields; the caller owns the clock/time zone.
String dailyDateKey(DateTime localDate) {
  if (localDate.year < 1 || localDate.year > 9999) {
    throw ArgumentError.value(localDate, 'localDate', 'Expected year 1–9999.');
  }
  return '${localDate.year.toString().padLeft(4, '0')}-'
      '${localDate.month.toString().padLeft(2, '0')}-'
      '${localDate.day.toString().padLeft(2, '0')}';
}

bool isValidDailyDateKey(String dateKey) {
  if (dateKey.length != 10 ||
      !RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$').hasMatch(dateKey)) {
    return false;
  }
  final year = int.parse(dateKey.substring(0, 4));
  final month = int.parse(dateKey.substring(5, 7));
  final day = int.parse(dateKey.substring(8, 10));
  if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) {
    return false;
  }
  // UTC avoids local daylight-saving transitions while checking the calendar.
  final parsed = DateTime.utc(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day;
}

String dailyPuzzleId(String dateKey) {
  if (!isValidDailyDateKey(dateKey)) {
    throw ArgumentError.value(dateKey, 'dateKey', 'Expected YYYY-MM-DD.');
  }
  return 'daily-v$dailySeedVersion-c$prototypeCatalogueVersion-$dateKey';
}

/// Seed v1 is FNV-1a uint32 over the ASCII versioned Daily puzzle id.
/// Split multiplication keeps every intermediate exact on Dart web as well.
int dailyPuzzleSeed(String dateKey) => _stableSeed(dailyPuzzleId(dateKey));

int _stableSeed(String identity) {
  var hash = 0x811c9dc5;
  for (final codeUnit in identity.codeUnits) {
    final value = hash ^ codeUnit;
    const multiplier = 0x01000193;
    final low = (value & 0xffff) * (multiplier & 0xffff);
    final high =
        ((value >>> 16) * (multiplier & 0xffff) +
            (value & 0xffff) * (multiplier >>> 16)) &
        0xffff;
    hash = (low + high * 65536) % 4294967296;
  }
  return hash;
}

class DailyPuzzleGeneration {
  DailyPuzzleGeneration.success(
    Puzzle this.puzzle, {
    List<PuzzleGenerationResult> attempts = const [],
  }) : failureReason = null,
       attempts = List.unmodifiable(attempts);

  DailyPuzzleGeneration.failure(
    String this.failureReason, {
    List<PuzzleGenerationResult> attempts = const [],
  }) : puzzle = null,
       attempts = List.unmodifiable(attempts);

  final Puzzle? puzzle;
  final String? failureReason;

  /// Search diagnostics; this list never exceeds [dailyMaxGenerationAttempts].
  final List<PuzzleGenerationResult> attempts;
  bool get isSuccess => puzzle != null && failureReason == null;
}

/// Lazy, bounded generation from the full fixed catalogue, without progression
/// indices or player history. A readable first candidate needs no second search.
DailyPuzzleGeneration generateDailyPuzzle(String dateKey) {
  if (!isValidDailyDateKey(dateKey)) {
    return DailyPuzzleGeneration.failure('Invalid Daily date: $dateKey.');
  }
  if (!prototypeCatalogue.isValid) {
    return DailyPuzzleGeneration.failure('Invalid Daily word catalogue.');
  }
  final id = dailyPuzzleId(dateKey);
  final attempts = <PuzzleGenerationResult>[];
  final failures = <String>[];
  PuzzleGenerationResult? best;
  for (var attempt = 0; attempt < dailyMaxGenerationAttempts; attempt++) {
    final generated = const PuzzleGenerator().generate(
      wordBank: prototypeCatalogue.entries,
      seed: attempt == 0
          ? dailyPuzzleSeed(dateKey)
          : _stableSeed('$id:candidate-${attempt + 1}'),
      config: prototypeGenerationConfig,
    );
    attempts.add(generated);
    if (!generated.isSuccess) {
      failures.add(generated.failureReason ?? 'No complete board found.');
      continue;
    }
    final validation = const PuzzleValidator().validate(
      generated.puzzle!,
      expectedAnswerCount: prototypeGenerationConfig.targetAnswerCount,
    );
    if (!validation.isValid) {
      failures.add('Invalid candidate: ${validation.errors.join('; ')}');
      continue;
    }
    final metrics = generated.metrics!;
    if (best == null ||
        (metrics.displayColumnCount <= 9 &&
            best.metrics!.displayColumnCount > 9) ||
        ((metrics.displayColumnCount <= 9) ==
                (best.metrics!.displayColumnCount <= 9) &&
            metrics.compareQuality(best.metrics!) > 0)) {
      best = generated;
    }
    if (best.metrics!.displayColumnCount <= 9) break;
  }
  if (best == null) {
    return DailyPuzzleGeneration.failure(
      'Daily $dateKey failed after ${attempts.length} bounded attempts: '
      '${failures.join('; ')}',
      attempts: attempts,
    );
  }
  final generated = best.puzzle!;
  final puzzle = Puzzle(
    id: id,
    label: 'Günlük Bulmaca',
    rowCount: generated.rowCount,
    columnCount: generated.columnCount,
    answers: generated.answers,
  );
  final validation = const PuzzleValidator().validate(
    puzzle,
    expectedAnswerCount: prototypeGenerationConfig.targetAnswerCount,
  );
  if (!validation.isValid) {
    return DailyPuzzleGeneration.failure(
      'Invalid Daily board: ${validation.errors.join('; ')}',
      attempts: attempts,
    );
  }
  return DailyPuzzleGeneration.success(puzzle, attempts: attempts);
}
