// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get home => 'Inicio';

  @override
  String get puzzles => 'Puzles';

  @override
  String get daily => 'Diario';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get settings => 'Ajustes';

  @override
  String get about => 'Acerca de';

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get appInformation => 'Información de la app';

  @override
  String get easy => 'Fácil';

  @override
  String get medium => 'Medio';

  @override
  String get hard => 'Difícil';

  @override
  String get puzzle => 'Puzle';

  @override
  String get clear => 'Borrar';

  @override
  String get check => 'Comprobar';

  @override
  String get continueGame => 'Continuar';

  @override
  String get start => 'Empezar';

  @override
  String get replay => 'Volver a jugar';

  @override
  String get replayLower => 'repetición';

  @override
  String get play => 'Jugar';

  @override
  String get resume => 'Continuar';

  @override
  String get dailyTitle => 'Puzle diario';

  @override
  String get dailyHistory => 'Historial diario';

  @override
  String get seeResult => 'Ver resultado';

  @override
  String get share => 'Compartir';

  @override
  String get returnHome => 'Volver al inicio';

  @override
  String get returnPuzzles => 'Volver a los puzles';

  @override
  String get chooseDifficulty => 'Elegir dificultad';

  @override
  String get viewPuzzles => 'Ver puzles';

  @override
  String get nextPuzzle => 'Siguiente puzle';

  @override
  String get close => 'Cerrar';

  @override
  String get back => 'Volver';

  @override
  String get closeSession => 'Cerrar sesión de juego';

  @override
  String get restart => 'Empezar de nuevo';

  @override
  String get retry => 'Reintentar';

  @override
  String get locked => 'Bloqueado';

  @override
  String get completed => 'Completado';

  @override
  String get completedLower => 'completado';

  @override
  String get score => 'Puntuación';

  @override
  String get time => 'Tiempo';

  @override
  String get hints => 'Pistas';

  @override
  String get wrongChecks => 'Comprobaciones fallidas';

  @override
  String get best => 'Mejor';

  @override
  String get thisAttempt => 'Este intento';

  @override
  String get newRecord => '¡Nuevo récord!';

  @override
  String get puzzleCompleted => '¡Puzle completado!';

  @override
  String get dailyCompleted => '¡Puzle diario completado!';

  @override
  String get rewardHint => 'Revelar con anuncio';

  @override
  String get adLoading => 'Cargando anuncio';

  @override
  String get adUnavailable =>
      'No hay anuncios disponibles. Inténtalo de nuevo.';

  @override
  String get puzzleLoading => 'Preparando puzle…';

  @override
  String get puzzlePreparing => 'Preparando puzle';

  @override
  String get dailyPreparing => 'Preparando el puzle diario';

  @override
  String get generationError =>
      'No se pudo preparar el puzle. Inténtalo de nuevo.';

  @override
  String get shareError =>
      'No se pudo compartir el resultado. Inténtalo de nuevo.';

  @override
  String get dailyUnavailable =>
      'El puzle diario no está disponible en esta sesión.';

  @override
  String get emptyHistory => 'Aún no has completado ningún puzle diario.';

  @override
  String get noScore => 'Todavía no';

  @override
  String get completedPuzzles => 'Puzles completados';

  @override
  String get scoredPuzzles => 'Puzles con puntuación';

  @override
  String get totalScore => 'Puntuación total';

  @override
  String get averageScore => 'Puntuación media';

  @override
  String get bestScore => 'Mejor puntuación';

  @override
  String get hintFree => 'Sin pistas';

  @override
  String get errorFree => 'Sin errores';

  @override
  String get dailyStatistics => 'Puzles diarios';

  @override
  String get dailyCount => 'Diarios completados';

  @override
  String get currentStreak => 'Racha actual';

  @override
  String get longestStreak => 'Racha más larga';

  @override
  String get statisticsIntro =>
      'Puzles completados y mejores puntuaciones guardadas.';

  @override
  String get statisticsExplanation =>
      'Las estadísticas usan la mejor puntuación guardada de cada puzle. Los anteriores sin puntuación solo cuentan como completados.';

  @override
  String get withinDifficulty => 'Compara puntuaciones de la misma dificultad.';

  @override
  String get hintLocked => 'Revelada con pista, bloqueada';

  @override
  String get development => 'Desarrollo · El progreso no se guarda';

  @override
  String get allCorrect => 'Todas las letras son correctas.';

  @override
  String get legacyScore =>
      'Este puzle se completó antes de introducir las puntuaciones.';

  @override
  String get appDescription =>
      'Descubre palabras en inglés mediante pistas. Puzles de progresión, repeticiones y un puzle diario.';

  @override
  String get workingName =>
      'Arrowword es un nombre provisional; el nombre definitivo aún no está decidido.';

  @override
  String get versionLoading => 'Cargando información de versión…';

  @override
  String get versionUnavailable =>
      'La información de versión no está disponible ahora.';

  @override
  String puzzleNumber(int number) {
    return 'Puzle $number';
  }

  @override
  String trackPuzzle(String difficulty, int number) {
    return '$difficulty · Puzle $number';
  }

  @override
  String replayPuzzle(int number) {
    return 'Puzle $number · Repetición';
  }

  @override
  String trackFinished(String difficulty) {
    return '¡Nivel $difficulty completado!';
  }

  @override
  String progress(int completed, int total) {
    return '$completed / $total completados';
  }

  @override
  String scorePoints(int score) {
    return '$score puntos';
  }

  @override
  String todayCompleted(int score) {
    return 'Completado hoy · $score puntos';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Racha de $count días',
      one: 'Racha de 1 día',
    );
    return '$_temp0';
  }

  @override
  String completedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puzles completados',
      one: '1 puzle completado',
    );
    return '$_temp0';
  }

  @override
  String versionBuild(String version, String build) {
    return 'Versión $version · Compilación $build';
  }

  @override
  String bestDetail(int number, int seconds) {
    return 'Puzle $number · $seconds s';
  }

  @override
  String legacyDetail(int seconds) {
    return 'Registro anterior · $seconds s';
  }

  @override
  String dailyDetails(String duration, int hints, int checks) {
    String _temp0 = intl.Intl.pluralLogic(
      hints,
      locale: localeName,
      other: '$hints pistas',
      one: '1 pista',
    );
    String _temp1 = intl.Intl.pluralLogic(
      checks,
      locale: localeName,
      other: '$checks comprobaciones fallidas',
      one: '1 comprobación fallida',
    );
    return '$duration · $_temp0 · $_temp1';
  }

  @override
  String clueLength(String clue, int length) {
    return '$clue ($length)';
  }

  @override
  String clueSemantics(String clue, int length, String direction) {
    String _temp0 = intl.Intl.pluralLogic(
      length,
      locale: localeName,
      other: '$length letras',
      one: '1 letra',
    );
    return '$clue, $_temp0, $direction';
  }

  @override
  String get right => 'horizontal';

  @override
  String get down => 'vertical';

  @override
  String tileSemantics(
    int number,
    String status,
    String completed,
    String scored,
    int score,
    String replayable,
  ) {
    String _temp0 = intl.Intl.selectLogic(completed, {
      'yes': ', completado',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(scored, {
      'yes': ', $score puntos',
      'other': '',
    });
    String _temp2 = intl.Intl.selectLogic(replayable, {
      'yes': ', repetición',
      'other': '',
    });
    return 'Puzle $number, $status$_temp0$_temp1$_temp2';
  }

  @override
  String resultDetails(
    String label,
    int score,
    String hasBest,
    int best,
    String duration,
    int hints,
    int checks,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasBest, {
      'yes': 'Mejor: $best\n',
      'other': '',
    });
    return '$label: $score\n${_temp0}Tiempo: $duration\nPistas: $hints\nComprobaciones fallidas: $checks';
  }

  @override
  String dailyShare(
    String date,
    int score,
    String duration,
    int hints,
    int checks,
    String hasStreak,
    int streak,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      streak,
      locale: localeName,
      other: '$streak días',
      one: '1 día',
    );
    String _temp1 = intl.Intl.selectLogic(hasStreak, {
      'yes': '\nRacha: $_temp0',
      'other': '',
    });
    return 'Arrowword — Puzle diario\n$date\n\nPuntuación: $score\nTiempo: $duration\nPistas: $hints\nComprobaciones fallidas: $checks$_temp1';
  }

  @override
  String dateDisplay(int day, String month, int year) {
    return '$day de $month de $year';
  }

  @override
  String get clueUnavailable => 'Esta pista no está disponible ahora.';

  @override
  String get uiPreview =>
      'Desarrollo · Solo vista previa de la interfaz inglesa';

  @override
  String invalidDevConfig(int count) {
    return 'No se puede abrir el puzle de desarrollo.\nARROWWORD_PUZZLE_INDEX debe estar entre 1 y $count.\nARROWWORD_PUZZLE_DIFFICULTY: easy, medium o hard.';
  }

  @override
  String get month1 => 'enero';

  @override
  String get month2 => 'febrero';

  @override
  String get month3 => 'marzo';

  @override
  String get month4 => 'abril';

  @override
  String get month5 => 'mayo';

  @override
  String get month6 => 'junio';

  @override
  String get month7 => 'julio';

  @override
  String get month8 => 'agosto';

  @override
  String get month9 => 'septiembre';

  @override
  String get month10 => 'octubre';

  @override
  String get month11 => 'noviembre';

  @override
  String get month12 => 'diciembre';

  @override
  String get versionFailed => 'No se pudo cargar la información de versión.';

  @override
  String get puzzleGenerationFailed =>
      'No se pudo generar el puzle. Inténtalo de nuevo.';

  @override
  String get replayGenerationFailed =>
      'No se pudo reconstruir el puzle. Inténtalo de nuevo.';

  @override
  String get dailyGenerationFailed =>
      'No se pudo generar el puzle diario. Inténtalo de nuevo.';

  @override
  String get legacyScoringMessage =>
      'Este puzle se completó antes de introducir las puntuaciones.';

  @override
  String get restartGame => 'Reiniciar';

  @override
  String get emptyProgress => 'Aún no hay puzles completados';

  @override
  String get language => 'Idioma';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get englishName => 'English';

  @override
  String get turkishName => 'Türkçe';
}
