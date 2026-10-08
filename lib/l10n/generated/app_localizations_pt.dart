// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get audio => 'Áudio';

  @override
  String get music => 'Música';

  @override
  String get soundEffects => 'Efeitos sonoros';

  @override
  String get answersAlwaysEnglish => 'As respostas são sempre em inglês.';

  @override
  String get home => 'Início';

  @override
  String get puzzles => 'Palavras cruzadas';

  @override
  String get daily => 'Diário';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get settings => 'Configurações';

  @override
  String get about => 'Sobre';

  @override
  String get appearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get appInformation => 'Informações do aplicativo';

  @override
  String get easy => 'Fácil';

  @override
  String get medium => 'Médio';

  @override
  String get hard => 'Difícil';

  @override
  String get puzzle => 'Palavras cruzadas';

  @override
  String get clear => 'Limpar';

  @override
  String get check => 'Conferir';

  @override
  String get continueGame => 'Continuar';

  @override
  String get start => 'Começar';

  @override
  String get replay => 'Jogar novamente';

  @override
  String get replayLower => 'nova tentativa';

  @override
  String get play => 'Jogar';

  @override
  String get resume => 'Continuar';

  @override
  String get dailyTitle => 'Desafio diário';

  @override
  String get dailyHistory => 'Histórico diário';

  @override
  String get seeResult => 'Ver resultado';

  @override
  String get share => 'Compartilhar';

  @override
  String get returnHome => 'Voltar ao início';

  @override
  String get returnPuzzles => 'Voltar às palavras cruzadas';

  @override
  String get chooseDifficulty => 'Escolher dificuldade';

  @override
  String get viewPuzzles => 'Ver palavras cruzadas';

  @override
  String get nextPuzzle => 'Próximo desafio';

  @override
  String get close => 'Fechar';

  @override
  String get back => 'Voltar';

  @override
  String get closeSession => 'Fechar partida';

  @override
  String get restart => 'Começar de novo';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get locked => 'Bloqueado';

  @override
  String get completed => 'Concluído';

  @override
  String get completedLower => 'concluído';

  @override
  String get score => 'Pontuação';

  @override
  String get time => 'Tempo';

  @override
  String get hints => 'Dicas';

  @override
  String get wrongChecks => 'Verificações incorretas';

  @override
  String get best => 'Melhor';

  @override
  String get thisAttempt => 'Esta tentativa';

  @override
  String get newRecord => 'Novo recorde!';

  @override
  String get puzzleCompleted => 'Desafio concluído!';

  @override
  String get dailyCompleted => 'Desafio diário concluído!';

  @override
  String get rewardHint => 'Revelar com anúncio';

  @override
  String get adLoading => 'Carregando anúncio';

  @override
  String get adUnavailable =>
      'Nenhum anúncio disponível agora. Tente novamente.';

  @override
  String get puzzleLoading => 'Preparando desafio…';

  @override
  String get puzzlePreparing => 'Preparando desafio';

  @override
  String get dailyPreparing => 'Preparando o desafio diário';

  @override
  String get generationError =>
      'Não foi possível preparar o desafio. Tente novamente.';

  @override
  String get shareError =>
      'Não foi possível compartilhar o resultado. Tente novamente.';

  @override
  String get dailyUnavailable =>
      'O desafio diário não está disponível nesta sessão.';

  @override
  String get emptyHistory => 'Nenhum desafio diário concluído ainda.';

  @override
  String get noScore => 'Ainda não';

  @override
  String get completedPuzzles => 'Desafios concluídos';

  @override
  String get scoredPuzzles => 'Desafios pontuados';

  @override
  String get totalScore => 'Pontuação total';

  @override
  String get averageScore => 'Pontuação média';

  @override
  String get bestScore => 'Melhor pontuação';

  @override
  String get hintFree => 'Conclusões sem dicas';

  @override
  String get errorFree => 'Conclusões sem erros';

  @override
  String get dailyStatistics => 'Desafios diários';

  @override
  String get dailyCount => 'Desafios diários concluídos';

  @override
  String get currentStreak => 'Sequência atual';

  @override
  String get longestStreak => 'Maior sequência';

  @override
  String get statisticsIntro =>
      'Desafios concluídos e melhores pontuações salvas.';

  @override
  String get statisticsExplanation =>
      'As estatísticas usam o melhor resultado salvo de cada desafio. Conclusões antigas sem pontuação contam apenas como desafios concluídos.';

  @override
  String get withinDifficulty => 'Compare pontuações da mesma dificuldade.';

  @override
  String get hintLocked => 'Revelada com dica, bloqueada';

  @override
  String get development => 'Desenvolvimento · O progresso não é salvo';

  @override
  String get allCorrect => 'Todas as letras estão corretas.';

  @override
  String get legacyScore =>
      'Este desafio foi concluído antes da introdução da pontuação.';

  @override
  String get appDescription =>
      'Descubra palavras em inglês pelas pistas. Desafios de progressão, novas tentativas e um desafio diário.';

  @override
  String get workingName =>
      'Arrowword é um nome provisório; o nome final ainda não foi decidido.';

  @override
  String get versionLoading => 'Carregando informações da versão…';

  @override
  String get versionUnavailable =>
      'As informações da versão estão indisponíveis.';

  @override
  String puzzleNumber(int number) {
    return 'Desafio $number';
  }

  @override
  String trackPuzzle(String difficulty, int number) {
    return '$difficulty · Desafio $number';
  }

  @override
  String replayPuzzle(int number) {
    return 'Desafio $number · Nova tentativa';
  }

  @override
  String trackFinished(String difficulty) {
    return 'Nível $difficulty concluído!';
  }

  @override
  String progress(int completed, int total) {
    return '$completed / $total concluídos';
  }

  @override
  String scorePoints(int score) {
    return '$score pontos';
  }

  @override
  String todayCompleted(int score) {
    return 'Concluído hoje · $score pontos';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequência de $count dias',
      one: 'Sequência de 1 dia',
    );
    return '$_temp0';
  }

  @override
  String completedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count desafios concluídos',
      one: '1 desafio concluído',
    );
    return '$_temp0';
  }

  @override
  String versionBuild(String version, String build) {
    return 'Versão $version · Compilação $build';
  }

  @override
  String bestDetail(int number, int seconds) {
    return 'Desafio $number · $seconds s';
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
      other: '$hints dicas',
      one: '1 dica',
    );
    String _temp1 = intl.Intl.pluralLogic(
      checks,
      locale: localeName,
      other: '$checks verificações incorretas',
      one: '1 verificação incorreta',
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
      'yes': ', concluído',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(scored, {
      'yes': ', $score pontos',
      'other': '',
    });
    String _temp2 = intl.Intl.selectLogic(replayable, {
      'yes': ', nova tentativa',
      'other': '',
    });
    return 'Desafio $number, $status$_temp0$_temp1$_temp2';
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
      'yes': 'Melhor: $best\n',
      'other': '',
    });
    return '$label: $score\n${_temp0}Tempo: $duration\nDicas: $hints\nVerificações incorretas: $checks';
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
      other: '$streak dias',
      one: '1 dia',
    );
    String _temp1 = intl.Intl.selectLogic(hasStreak, {
      'yes': '\nSequência: $_temp0',
      'other': '',
    });
    return 'Arrowword — Desafio diário\n$date\n\nPontuação: $score\nTempo: $duration\nDicas: $hints\nVerificações incorretas: $checks$_temp1';
  }

  @override
  String dateDisplay(int day, String month, int year) {
    return '$day de $month de $year';
  }

  @override
  String get clueUnavailable => 'Esta pista está indisponível agora.';

  @override
  String get uiPreview =>
      'Desenvolvimento · Apenas prévia da interface em inglês';

  @override
  String invalidDevConfig(int count) {
    return 'Não é possível abrir o desafio de desenvolvimento.\nARROWWORD_PUZZLE_INDEX deve estar entre 1 e $count.\nARROWWORD_PUZZLE_DIFFICULTY: easy, medium ou hard.';
  }

  @override
  String get month1 => 'janeiro';

  @override
  String get month2 => 'fevereiro';

  @override
  String get month3 => 'março';

  @override
  String get month4 => 'abril';

  @override
  String get month5 => 'maio';

  @override
  String get month6 => 'junho';

  @override
  String get month7 => 'julho';

  @override
  String get month8 => 'agosto';

  @override
  String get month9 => 'setembro';

  @override
  String get month10 => 'outubro';

  @override
  String get month11 => 'novembro';

  @override
  String get month12 => 'dezembro';

  @override
  String get versionFailed =>
      'Não foi possível carregar as informações da versão.';

  @override
  String get puzzleGenerationFailed =>
      'Não foi possível gerar o desafio. Tente novamente.';

  @override
  String get replayGenerationFailed =>
      'Não foi possível reconstruir o desafio. Tente novamente.';

  @override
  String get dailyGenerationFailed =>
      'Não foi possível gerar o desafio diário. Tente novamente.';

  @override
  String get legacyScoringMessage =>
      'Este desafio foi concluído antes da introdução da pontuação.';

  @override
  String get restartGame => 'Reiniciar';

  @override
  String get emptyProgress => 'Nenhum desafio concluído ainda';

  @override
  String get language => 'Idioma';

  @override
  String get systemDefault => 'Padrão do sistema';

  @override
  String get englishName => 'English';

  @override
  String get turkishName => 'Türkçe';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get audio => 'Áudio';

  @override
  String get music => 'Música';

  @override
  String get soundEffects => 'Efeitos sonoros';

  @override
  String get answersAlwaysEnglish => 'As respostas são sempre em inglês.';

  @override
  String get home => 'Início';

  @override
  String get puzzles => 'Palavras cruzadas';

  @override
  String get daily => 'Diário';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get settings => 'Configurações';

  @override
  String get about => 'Sobre';

  @override
  String get appearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get appInformation => 'Informações do aplicativo';

  @override
  String get easy => 'Fácil';

  @override
  String get medium => 'Médio';

  @override
  String get hard => 'Difícil';

  @override
  String get puzzle => 'Palavras cruzadas';

  @override
  String get clear => 'Limpar';

  @override
  String get check => 'Conferir';

  @override
  String get continueGame => 'Continuar';

  @override
  String get start => 'Começar';

  @override
  String get replay => 'Jogar novamente';

  @override
  String get replayLower => 'nova tentativa';

  @override
  String get play => 'Jogar';

  @override
  String get resume => 'Continuar';

  @override
  String get dailyTitle => 'Desafio diário';

  @override
  String get dailyHistory => 'Histórico diário';

  @override
  String get seeResult => 'Ver resultado';

  @override
  String get share => 'Compartilhar';

  @override
  String get returnHome => 'Voltar ao início';

  @override
  String get returnPuzzles => 'Voltar às palavras cruzadas';

  @override
  String get chooseDifficulty => 'Escolher dificuldade';

  @override
  String get viewPuzzles => 'Ver palavras cruzadas';

  @override
  String get nextPuzzle => 'Próximo desafio';

  @override
  String get close => 'Fechar';

  @override
  String get back => 'Voltar';

  @override
  String get closeSession => 'Fechar partida';

  @override
  String get restart => 'Começar de novo';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get locked => 'Bloqueado';

  @override
  String get completed => 'Concluído';

  @override
  String get completedLower => 'concluído';

  @override
  String get score => 'Pontuação';

  @override
  String get time => 'Tempo';

  @override
  String get hints => 'Dicas';

  @override
  String get wrongChecks => 'Verificações incorretas';

  @override
  String get best => 'Melhor';

  @override
  String get thisAttempt => 'Esta tentativa';

  @override
  String get newRecord => 'Novo recorde!';

  @override
  String get puzzleCompleted => 'Desafio concluído!';

  @override
  String get dailyCompleted => 'Desafio diário concluído!';

  @override
  String get rewardHint => 'Revelar com anúncio';

  @override
  String get adLoading => 'Carregando anúncio';

  @override
  String get adUnavailable =>
      'Nenhum anúncio disponível agora. Tente novamente.';

  @override
  String get puzzleLoading => 'Preparando desafio…';

  @override
  String get puzzlePreparing => 'Preparando desafio';

  @override
  String get dailyPreparing => 'Preparando o desafio diário';

  @override
  String get generationError =>
      'Não foi possível preparar o desafio. Tente novamente.';

  @override
  String get shareError =>
      'Não foi possível compartilhar o resultado. Tente novamente.';

  @override
  String get dailyUnavailable =>
      'O desafio diário não está disponível nesta sessão.';

  @override
  String get emptyHistory => 'Nenhum desafio diário concluído ainda.';

  @override
  String get noScore => 'Ainda não';

  @override
  String get completedPuzzles => 'Desafios concluídos';

  @override
  String get scoredPuzzles => 'Desafios pontuados';

  @override
  String get totalScore => 'Pontuação total';

  @override
  String get averageScore => 'Pontuação média';

  @override
  String get bestScore => 'Melhor pontuação';

  @override
  String get hintFree => 'Conclusões sem dicas';

  @override
  String get errorFree => 'Conclusões sem erros';

  @override
  String get dailyStatistics => 'Desafios diários';

  @override
  String get dailyCount => 'Desafios diários concluídos';

  @override
  String get currentStreak => 'Sequência atual';

  @override
  String get longestStreak => 'Maior sequência';

  @override
  String get statisticsIntro =>
      'Desafios concluídos e melhores pontuações salvas.';

  @override
  String get statisticsExplanation =>
      'As estatísticas usam o melhor resultado salvo de cada desafio. Conclusões antigas sem pontuação contam apenas como desafios concluídos.';

  @override
  String get withinDifficulty => 'Compare pontuações da mesma dificuldade.';

  @override
  String get hintLocked => 'Revelada com dica, bloqueada';

  @override
  String get development => 'Desenvolvimento · O progresso não é salvo';

  @override
  String get allCorrect => 'Todas as letras estão corretas.';

  @override
  String get legacyScore =>
      'Este desafio foi concluído antes da introdução da pontuação.';

  @override
  String get appDescription =>
      'Descubra palavras em inglês pelas pistas. Desafios de progressão, novas tentativas e um desafio diário.';

  @override
  String get workingName =>
      'Arrowword é um nome provisório; o nome final ainda não foi decidido.';

  @override
  String get versionLoading => 'Carregando informações da versão…';

  @override
  String get versionUnavailable =>
      'As informações da versão estão indisponíveis.';

  @override
  String puzzleNumber(int number) {
    return 'Desafio $number';
  }

  @override
  String trackPuzzle(String difficulty, int number) {
    return '$difficulty · Desafio $number';
  }

  @override
  String replayPuzzle(int number) {
    return 'Desafio $number · Nova tentativa';
  }

  @override
  String trackFinished(String difficulty) {
    return 'Nível $difficulty concluído!';
  }

  @override
  String progress(int completed, int total) {
    return '$completed / $total concluídos';
  }

  @override
  String scorePoints(int score) {
    return '$score pontos';
  }

  @override
  String todayCompleted(int score) {
    return 'Concluído hoje · $score pontos';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequência de $count dias',
      one: 'Sequência de 1 dia',
    );
    return '$_temp0';
  }

  @override
  String completedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count desafios concluídos',
      one: '1 desafio concluído',
    );
    return '$_temp0';
  }

  @override
  String versionBuild(String version, String build) {
    return 'Versão $version · Compilação $build';
  }

  @override
  String bestDetail(int number, int seconds) {
    return 'Desafio $number · $seconds s';
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
      other: '$hints dicas',
      one: '1 dica',
    );
    String _temp1 = intl.Intl.pluralLogic(
      checks,
      locale: localeName,
      other: '$checks verificações incorretas',
      one: '1 verificação incorreta',
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
      'yes': ', concluído',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(scored, {
      'yes': ', $score pontos',
      'other': '',
    });
    String _temp2 = intl.Intl.selectLogic(replayable, {
      'yes': ', nova tentativa',
      'other': '',
    });
    return 'Desafio $number, $status$_temp0$_temp1$_temp2';
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
      'yes': 'Melhor: $best\n',
      'other': '',
    });
    return '$label: $score\n${_temp0}Tempo: $duration\nDicas: $hints\nVerificações incorretas: $checks';
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
      other: '$streak dias',
      one: '1 dia',
    );
    String _temp1 = intl.Intl.selectLogic(hasStreak, {
      'yes': '\nSequência: $_temp0',
      'other': '',
    });
    return 'Arrowword — Desafio diário\n$date\n\nPontuação: $score\nTempo: $duration\nDicas: $hints\nVerificações incorretas: $checks$_temp1';
  }

  @override
  String dateDisplay(int day, String month, int year) {
    return '$day de $month de $year';
  }

  @override
  String get clueUnavailable => 'Esta pista está indisponível agora.';

  @override
  String get uiPreview =>
      'Desenvolvimento · Apenas prévia da interface em inglês';

  @override
  String invalidDevConfig(int count) {
    return 'Não é possível abrir o desafio de desenvolvimento.\nARROWWORD_PUZZLE_INDEX deve estar entre 1 e $count.\nARROWWORD_PUZZLE_DIFFICULTY: easy, medium ou hard.';
  }

  @override
  String get month1 => 'janeiro';

  @override
  String get month2 => 'fevereiro';

  @override
  String get month3 => 'março';

  @override
  String get month4 => 'abril';

  @override
  String get month5 => 'maio';

  @override
  String get month6 => 'junho';

  @override
  String get month7 => 'julho';

  @override
  String get month8 => 'agosto';

  @override
  String get month9 => 'setembro';

  @override
  String get month10 => 'outubro';

  @override
  String get month11 => 'novembro';

  @override
  String get month12 => 'dezembro';

  @override
  String get versionFailed =>
      'Não foi possível carregar as informações da versão.';

  @override
  String get puzzleGenerationFailed =>
      'Não foi possível gerar o desafio. Tente novamente.';

  @override
  String get replayGenerationFailed =>
      'Não foi possível reconstruir o desafio. Tente novamente.';

  @override
  String get dailyGenerationFailed =>
      'Não foi possível gerar o desafio diário. Tente novamente.';

  @override
  String get legacyScoringMessage =>
      'Este desafio foi concluído antes da introdução da pontuação.';

  @override
  String get restartGame => 'Reiniciar';

  @override
  String get emptyProgress => 'Nenhum desafio concluído ainda';

  @override
  String get language => 'Idioma';

  @override
  String get systemDefault => 'Padrão do sistema';

  @override
  String get englishName => 'English';

  @override
  String get turkishName => 'Türkçe';
}
