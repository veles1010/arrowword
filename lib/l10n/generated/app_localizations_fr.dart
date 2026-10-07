// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get home => 'Accueil';

  @override
  String get puzzles => 'Grilles';

  @override
  String get daily => 'Quotidien';

  @override
  String get statistics => 'Statistiques';

  @override
  String get settings => 'Réglages';

  @override
  String get about => 'À propos';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get system => 'Système';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get appInformation => 'Informations sur l\'application';

  @override
  String get easy => 'Facile';

  @override
  String get medium => 'Moyen';

  @override
  String get hard => 'Difficile';

  @override
  String get puzzle => 'Grille';

  @override
  String get clear => 'Effacer';

  @override
  String get check => 'Vérifier';

  @override
  String get continueGame => 'Continuer';

  @override
  String get start => 'Commencer';

  @override
  String get replay => 'Rejouer';

  @override
  String get replayLower => 'rejeu';

  @override
  String get play => 'Jouer';

  @override
  String get resume => 'Continuer';

  @override
  String get dailyTitle => 'Grille du jour';

  @override
  String get dailyHistory => 'Historique quotidien';

  @override
  String get seeResult => 'Voir le résultat';

  @override
  String get share => 'Partager';

  @override
  String get returnHome => 'Retour à l\'accueil';

  @override
  String get returnPuzzles => 'Retour aux grilles';

  @override
  String get chooseDifficulty => 'Choisir la difficulté';

  @override
  String get viewPuzzles => 'Voir les grilles';

  @override
  String get nextPuzzle => 'Grille suivante';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get closeSession => 'Fermer la partie';

  @override
  String get restart => 'Recommencer';

  @override
  String get retry => 'Réessayer';

  @override
  String get locked => 'Verrouillé';

  @override
  String get completed => 'Terminé';

  @override
  String get completedLower => 'terminé';

  @override
  String get score => 'Score';

  @override
  String get time => 'Temps';

  @override
  String get hints => 'Indices';

  @override
  String get wrongChecks => 'Vérifications incorrectes';

  @override
  String get best => 'Meilleur';

  @override
  String get thisAttempt => 'Cette tentative';

  @override
  String get newRecord => 'Nouveau record !';

  @override
  String get puzzleCompleted => 'Grille terminée !';

  @override
  String get dailyCompleted => 'Grille du jour terminée !';

  @override
  String get rewardHint => 'Révéler avec pub';

  @override
  String get adLoading => 'Chargement de la pub';

  @override
  String get adUnavailable =>
      'Aucune publicité disponible. Réessayez plus tard.';

  @override
  String get puzzleLoading => 'Préparation de la grille…';

  @override
  String get puzzlePreparing => 'Préparation de la grille';

  @override
  String get dailyPreparing => 'Préparation de la grille du jour';

  @override
  String get generationError => 'Impossible de préparer la grille. Réessayez.';

  @override
  String get shareError => 'Impossible de partager le résultat. Réessayez.';

  @override
  String get dailyUnavailable =>
      'La grille du jour est indisponible dans cette session.';

  @override
  String get emptyHistory => 'Aucune grille du jour terminée pour le moment.';

  @override
  String get noScore => 'Pas encore';

  @override
  String get completedPuzzles => 'Grilles terminées';

  @override
  String get scoredPuzzles => 'Grilles avec score';

  @override
  String get totalScore => 'Score total';

  @override
  String get averageScore => 'Score moyen';

  @override
  String get bestScore => 'Meilleur score';

  @override
  String get hintFree => 'Terminées sans indice';

  @override
  String get errorFree => 'Terminées sans erreur';

  @override
  String get dailyStatistics => 'Grilles du jour';

  @override
  String get dailyCount => 'Grilles du jour terminées';

  @override
  String get currentStreak => 'Série actuelle';

  @override
  String get longestStreak => 'Plus longue série';

  @override
  String get statisticsIntro =>
      'Grilles terminées et meilleurs scores enregistrés.';

  @override
  String get statisticsExplanation =>
      'Les statistiques utilisent le meilleur score enregistré de chaque grille. Les anciennes réussites sans score comptent seulement parmi les grilles terminées.';

  @override
  String get withinDifficulty => 'Comparez les scores d\'une même difficulté.';

  @override
  String get hintLocked => 'Révélée par un indice, verrouillée';

  @override
  String get development => 'Développement · Progression non enregistrée';

  @override
  String get allCorrect => 'Toutes les lettres sont correctes.';

  @override
  String get legacyScore =>
      'Cette grille a été terminée avant l\'introduction des scores.';

  @override
  String get appDescription =>
      'Découvrez des mots anglais grâce aux indices. Grilles de progression, rejeu et grille du jour.';

  @override
  String get workingName =>
      'Arrowword est un nom provisoire ; le nom définitif n\'est pas encore choisi.';

  @override
  String get versionLoading => 'Chargement de la version…';

  @override
  String get versionUnavailable =>
      'Les informations de version sont indisponibles.';

  @override
  String puzzleNumber(int number) {
    return 'Grille $number';
  }

  @override
  String trackPuzzle(String difficulty, int number) {
    return '$difficulty · Grille $number';
  }

  @override
  String replayPuzzle(int number) {
    return 'Grille $number · Rejeu';
  }

  @override
  String trackFinished(String difficulty) {
    return 'Parcours $difficulty terminé !';
  }

  @override
  String progress(int completed, int total) {
    return '$completed / $total terminées';
  }

  @override
  String scorePoints(int score) {
    return '$score points';
  }

  @override
  String todayCompleted(int score) {
    return 'Terminé aujourd\'hui · $score points';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série de $count jours',
      one: 'Série de 1 jour',
    );
    return '$_temp0';
  }

  @override
  String completedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grilles terminées',
      one: '1 grille terminée',
    );
    return '$_temp0';
  }

  @override
  String versionBuild(String version, String build) {
    return 'Version $version · Build $build';
  }

  @override
  String bestDetail(int number, int seconds) {
    return 'Grille $number · $seconds s';
  }

  @override
  String legacyDetail(int seconds) {
    return 'Ancien résultat · $seconds s';
  }

  @override
  String dailyDetails(String duration, int hints, int checks) {
    String _temp0 = intl.Intl.pluralLogic(
      hints,
      locale: localeName,
      other: '$hints indices',
      one: '1 indice',
    );
    String _temp1 = intl.Intl.pluralLogic(
      checks,
      locale: localeName,
      other: '$checks vérifications incorrectes',
      one: '1 vérification incorrecte',
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
      other: '$length lettres',
      one: '1 lettre',
    );
    return '$clue, $_temp0, $direction';
  }

  @override
  String get right => 'horizontalement';

  @override
  String get down => 'verticalement';

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
      'yes': ', terminée',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(scored, {
      'yes': ', $score points',
      'other': '',
    });
    String _temp2 = intl.Intl.selectLogic(replayable, {
      'yes': ', rejouable',
      'other': '',
    });
    return 'Grille $number, $status$_temp0$_temp1$_temp2';
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
      'yes': 'Meilleur : $best\n',
      'other': '',
    });
    return '$label : $score\n${_temp0}Temps : $duration\nIndices : $hints\nVérifications incorrectes : $checks';
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
      other: '$streak jours',
      one: '1 jour',
    );
    String _temp1 = intl.Intl.selectLogic(hasStreak, {
      'yes': '\nSérie : $_temp0',
      'other': '',
    });
    return 'Arrowword — Grille du jour\n$date\n\nScore : $score\nTemps : $duration\nIndices : $hints\nVérifications incorrectes : $checks$_temp1';
  }

  @override
  String dateDisplay(int day, String month, int year) {
    return '$day $month $year';
  }

  @override
  String get clueUnavailable => 'Cet indice est actuellement indisponible.';

  @override
  String get uiPreview =>
      'Développement · Aperçu de l\'interface anglaise uniquement';

  @override
  String invalidDevConfig(int count) {
    return 'Impossible d\'ouvrir la grille de développement.\nARROWWORD_PUZZLE_INDEX doit être compris entre 1 et $count.\nARROWWORD_PUZZLE_DIFFICULTY : easy, medium ou hard.';
  }

  @override
  String get month1 => 'janvier';

  @override
  String get month2 => 'février';

  @override
  String get month3 => 'mars';

  @override
  String get month4 => 'avril';

  @override
  String get month5 => 'mai';

  @override
  String get month6 => 'juin';

  @override
  String get month7 => 'juillet';

  @override
  String get month8 => 'août';

  @override
  String get month9 => 'septembre';

  @override
  String get month10 => 'octobre';

  @override
  String get month11 => 'novembre';

  @override
  String get month12 => 'décembre';

  @override
  String get versionFailed =>
      'Impossible de charger les informations de version.';

  @override
  String get puzzleGenerationFailed =>
      'Impossible de générer la grille. Réessayez.';

  @override
  String get replayGenerationFailed =>
      'Impossible de reconstruire la grille. Réessayez.';

  @override
  String get dailyGenerationFailed =>
      'Impossible de générer la grille du jour. Réessayez.';

  @override
  String get legacyScoringMessage =>
      'Cette grille a été terminée avant l\'introduction des scores.';

  @override
  String get restartGame => 'Recommencer';

  @override
  String get emptyProgress => 'Aucune grille terminée pour le moment';

  @override
  String get language => 'Langue';

  @override
  String get systemDefault => 'Langue du système';

  @override
  String get englishName => 'English';

  @override
  String get turkishName => 'Türkçe';
}
