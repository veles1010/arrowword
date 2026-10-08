import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrowword/app/app_settings.dart';
import 'package:arrowword/app/settings_screen.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/puzzle_replay_screen.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:arrowword/audio/game_audio.dart';
import 'package:arrowword/l10n/generated/app_localizations.dart';
import 'package:arrowword/l10n/language_policy.dart';
import 'package:arrowword/features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_puzzle_screen.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';

class _Backend implements AudioBackend {
  final commands = <String>[];
  final sounds = <GameSound>[];
  int disposals = 0;
  @override
  Future<void> resumeMusic() async => commands.add('resume');
  @override
  Future<void> pauseMusic() async => commands.add('pause');
  @override
  Future<void> play(GameSound sound) async => sounds.add(sound);
  @override
  Future<void> stopEffects() async => commands.add('stopEffects');
  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class _BadAudioStore extends MemorySettingsStore {
  @override
  Future<bool?> readMusic() async => throw const FormatException('Bad type');
  @override
  Future<bool?> readSfx() async => throw StateError('Unavailable');
}

class _PendingAd extends FakeRewardedHintAdService {
  final resultFuture = Completer<HintAdResult>();
  @override
  Future<HintAdResult> show() {
    shows++;
    return resultFuture.future;
  }
}

class _ReplayFixtures extends PuzzleSequenceGenerator {
  _ReplayFixtures(this.fixture)
    : super(prototypeCatalogue, prototypeSequenceConfig);
  final SequencePuzzleResult fixture;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) => SequencePuzzleResult(
    puzzleIndex: puzzleIndex,
    seed: fixture.seed,
    catalogVersion: fixture.catalogVersion,
    pool: fixture.pool,
    puzzle: fixture.puzzle,
    generation: fixture.generation,
  );
}

void main() {
  test('both preferences default ON without writes', () async {
    final store = MemorySettingsStore();
    final settings = await AppSettings.restore(store);
    expect(settings.musicEnabled, true);
    expect(settings.sfxEnabled, true);
    expect(store.audioWrites, 0);
    settings.dispose();
  });
  test('malformed audio reads fail independently to ON', () async {
    final settings = await AppSettings.restore(_BadAudioStore());
    expect(settings.musicEnabled, true);
    expect(settings.sfxEnabled, true);
    settings.dispose();
  });
  for (final music in [false, true]) {
    for (final sfx in [false, true]) {
      test(
        'music=$music / effects=$sfx survive restart independently',
        () async {
          final store = MemorySettingsStore('dark');
          final settings = await AppSettings.restore(store);
          settings.setMusicEnabled(music);
          settings.setSfxEnabled(sfx);
          settings.setMusicEnabled(music);
          settings.setSfxEnabled(sfx);
          await settings.flush;
          final restored = await AppSettings.restore(store);
          expect(restored.musicEnabled, music);
          expect(restored.sfxEnabled, sfx);
          expect(restored.themeMode, ThemeMode.dark);
          expect(store.writes, 0);
          expect(store.audioWrites, (music ? 0 : 1) + (sfx ? 0 : 1));
          settings.dispose();
          restored.dispose();
        },
      );
    }
  }
  late AppSettings settings;
  late _Backend backend;
  late GameAudio audio;
  setUp(() {
    settings = AppSettings(MemorySettingsStore());
    backend = _Backend();
    audio = GameAudio(settings, backend);
  });
  tearDown(() async {
    await audio.dispose();
    settings.dispose();
  });
  test(
    'menu starts once; repeated active/tab notifications never restart',
    () async {
      audio.setActive(true);
      await audio.flush;
      for (var i = 0; i < 10; i++) {
        audio.setActive(true);
      }
      settings.setTheme(ThemeMode.dark);
      await audio.flush;
      expect(backend.commands, ['resume']);
    },
  );
  test(
    'gameplay leases pause and restore once across overlapping routes',
    () async {
      audio.setActive(true);
      await audio.flush;
      final leave = audio.enterGameplay();
      await audio.flush;
      final leaveNext = audio.enterGameplay();
      leave();
      leave();
      await audio.flush;
      expect(backend.commands, ['resume', 'pause']);
      leaveNext();
      await audio.flush;
      expect(backend.commands, ['resume', 'pause', 'resume']);
    },
  );
  test('Music OFF stops now; ON while gameplay cannot start music', () async {
    audio.setActive(true);
    await audio.flush;
    settings.setMusicEnabled(false);
    await audio.flush;
    expect(backend.commands, ['resume', 'pause']);
    final leave = audio.enterGameplay();
    settings.setMusicEnabled(true);
    await audio.flush;
    expect(backend.commands, ['resume', 'pause']);
    leave();
    await audio.flush;
    expect(backend.commands.last, 'resume');
  });
  test('disabled music never starts on menu or resume', () async {
    settings.setMusicEnabled(false);
    audio.setActive(true);
    await audio.flush;
    audio.setActive(false);
    audio.setActive(true);
    await audio.flush;
    expect(backend.commands.where((c) => c == 'resume'), isEmpty);
  });
  test(
    'background stops all audio; menu resumes but gameplay stays silent',
    () async {
      audio.setActive(true);
      await audio.flush;
      audio.setActive(false);
      await audio.flush;
      expect(backend.commands, ['resume', 'pause', 'stopEffects']);
      audio.playLetter();
      await audio.flush;
      expect(backend.sounds, isEmpty);
      final leave = audio.enterGameplay();
      audio.setActive(true);
      await audio.flush;
      expect(backend.commands.where((c) => c == 'resume'), hasLength(1));
      leave();
      await audio.flush;
      expect(backend.commands.where((c) => c == 'resume'), hasLength(2));
    },
  );
  test(
    'ad lease silences music/effects before display and resumes correctly',
    () async {
      audio.setActive(true);
      await audio.flush;
      final finish = await audio.beginAd();
      expect(backend.commands, ['resume', 'pause', 'stopEffects']);
      audio.playHintReveal();
      await audio.flush;
      expect(backend.sounds, isEmpty);
      audio.setActive(false);
      finish();
      finish();
      await audio.flush;
      expect(backend.commands.where((c) => c == 'resume'), hasLength(1));
      audio.setActive(true);
      await audio.flush;
      expect(backend.commands.where((c) => c == 'resume'), hasLength(2));
    },
  );
  for (final sound in GameSound.values) {
    test(
      '$sound enabled independently of music, suppressed when SFX OFF',
      () async {
        audio.setActive(true);
        settings.setMusicEnabled(false);
        await audio.flush;
        void play() => switch (sound) {
          GameSound.letter => audio.playLetter(),
          GameSound.wrongCheck => audio.playWrongCheck(),
          GameSound.hintReveal => audio.playHintReveal(),
          GameSound.puzzleComplete => audio.playPuzzleComplete(),
        };
        play();
        await audio.flush;
        expect(backend.sounds, [sound]);
        settings.setSfxEnabled(false);
        play();
        await audio.flush;
        expect(backend.sounds, [sound]);
        settings.setSfxEnabled(true);
        play();
        await audio.flush;
        expect(backend.sounds, [sound, sound]);
        expect(settings.musicEnabled, false);
      },
    );
  }
  test('queued effects are suppressed if muted before playback', () async {
    audio.setActive(true);
    audio.playLetter();
    settings.setSfxEnabled(false);
    await audio.flush;
    expect(backend.sounds, isEmpty);
  });
  test(
    'dispose releases backend once, blocks future events/navigation',
    () async {
      audio.setActive(true);
      await audio.flush;
      await audio.dispose();
      await audio.dispose();
      audio.playLetter();
      audio.enterGameplay()();
      audio.setActive(true);
      await audio.flush;
      expect(backend.disposals, 1);
      expect(backend.sounds, isEmpty);
    },
  );
  Future<void> open(
    WidgetTester tester, {
    PuzzleScreen? screen,
    Widget? child,
  }) async {
    await tester.pumpWidget(
      GameAudioHost(
        audio: audio,
        child: MaterialApp(
          home: child ?? screen ?? PuzzleScreen(puzzle: manualPuzzle),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await audio.flush;
  }

  testWidgets(
    'valid changed ASCII cell sounds; repeated same letter/restore/backspace do not',
    (tester) async {
      final start = manualPuzzle.answers.first.start;
      await open(
        tester,
        screen: PuzzleScreen(
          puzzle: manualPuzzle,
          initialLetters: {start: 'A'},
        ),
      );
      expect(backend.sounds, isEmpty);
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      await tester.enterText(find.byType(TextField), 'b');
      await audio.flush;
      expect(backend.sounds, [GameSound.letter]);
      state.game.tapCell(start);
      await tester.enterText(find.byType(TextField), 'B');
      await audio.flush;
      expect(backend.sounds, hasLength(1));
      await tester.enterText(find.byType(TextField), '');
      await audio.flush;
      expect(backend.sounds, hasLength(1));
    },
  );
  for (final text in ['ё', '水', '한']) {
    testWidgets('$text input/composition/cancellation are silent', (
      tester,
    ) async {
      await open(tester);
      await tester.showKeyboard(find.byType(TextField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'a',
          composing: TextRange(start: 0, end: 1),
        ),
      );
      await tester.pump();
      await audio.flush;
      expect(backend.sounds, isEmpty);
      tester.testTextInput.updateEditingValue(TextEditingValue.empty);
      await tester.pump();
      await tester.enterText(find.byType(TextField), text);
      await audio.flush;
      expect(backend.sounds, isEmpty);
    });
  }
  testWidgets(
    'explicit incorrect Check sounds once; correct partial and rebuild silent',
    (tester) async {
      await open(tester);
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      final PuzzleGame game = state.game;
      game.enterLetter(manualPuzzle.answers.first.solution[0]);
      await tester.tap(find.text('Kontrol Et'));
      await tester.pump();
      await audio.flush;
      expect(backend.sounds, isEmpty);
      game.enterLetter('Z');
      await tester.tap(find.text('Kontrol Et'));
      await tester.pump();
      await audio.flush;
      expect(backend.sounds, [GameSound.wrongCheck]);
      await tester.pump();
      await audio.flush;
      expect(backend.sounds, hasLength(1));
    },
  );
  for (final result in HintAdResult.values) {
    testWidgets('$result ad outcome sounds only for actual earned reveal', (
      tester,
    ) async {
      final ad = FakeRewardedHintAdService(result: result);
      await open(
        tester,
        screen: PuzzleScreen(puzzle: manualPuzzle, rewardedAdFactory: () => ad),
      );
      await tester.tap(find.text('Reklamla Harf Aç'));
      await tester.pumpAndSettle();
      await audio.flush;
      expect(
        backend.sounds,
        result == HintAdResult.earned ? [GameSound.hintReveal] : isEmpty,
      );
      expect(backend.sounds, isNot(contains(GameSound.letter)));
    });
  }
  testWidgets(
    'pending ad alone silent; target already filled earns no hint sound',
    (tester) async {
      final ad = _PendingAd();
      await open(
        tester,
        screen: PuzzleScreen(puzzle: manualPuzzle, rewardedAdFactory: () => ad),
      );
      await tester.tap(find.text('Reklamla Harf Aç'));
      await tester.pump();
      await audio.flush;
      expect(backend.sounds, isEmpty);
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      state.game.enterLetter(manualPuzzle.answers.first.solution[0]);
      ad.resultFuture.complete(HintAdResult.earned);
      await tester.pumpAndSettle();
      await audio.flush;
      expect(backend.sounds, isEmpty);
    },
  );
  void solve(PuzzleGame game) {
    for (final answer in game.puzzle.answers) {
      game.tapClue(answer);
      for (final letter in answer.solution.split('')) {
        game.enterLetter(letter);
      }
    }
  }

  testWidgets(
    'new completion once; rebuild/resume/theme/locale do not repeat',
    (tester) async {
      await open(tester);
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      solve(state.game);
      await tester.pumpAndSettle();
      await audio.flush;
      expect(backend.sounds, [GameSound.puzzleComplete]);
      settings.setTheme(ThemeMode.dark);
      await tester.pumpWidget(
        GameAudioHost(
          audio: audio,
          child: MaterialApp(
            theme: ThemeData.dark(),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: PuzzleScreen(puzzle: manualPuzzle),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        (tester.state(find.byType(PuzzleScreen)) as dynamic).game,
        same(state.game),
      );
      for (final lifecycle in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(lifecycle);
      }
      await tester.pumpAndSettle();
      await audio.flush;
      expect(backend.sounds, hasLength(1));
    },
  );
  testWidgets('already solved restoration never sounds', (tester) async {
    final solved = PuzzleGame(manualPuzzle);
    solve(solved);
    await open(
      tester,
      screen: PuzzleScreen(
        puzzle: manualPuzzle,
        initialLetters: solved.enteredLetters,
        attemptFinalized: true,
      ),
    );
    expect(backend.sounds, isEmpty);
    solved.dispose();
  });
  testWidgets('fresh replay-style attempts each genuinely solve once', (
    tester,
  ) async {
    for (var n = 0; n < 2; n++) {
      await open(
        tester,
        screen: PuzzleScreen(
          key: ValueKey(n),
          puzzle: manualPuzzle,
          title: 'Replay',
        ),
      );
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      solve(state.game);
      await tester.pumpAndSettle();
      await audio.flush;
      expect(
        backend.sounds.where((s) => s == GameSound.puzzleComplete),
        hasLength(n + 1),
      );
    }
  });
  testWidgets('Daily actual completion shares single sound and persists once', (
    tester,
  ) async {
    final daily = await DailySession.restore(
      store: MemoryDailyProgressStore(),
      localNow: () => DateTime(2026, 10, 4),
      generator: (key) => DailyPuzzleGeneration.success(
        Puzzle(
          id: dailyPuzzleId(key),
          label: 'fixture',
          rowCount: manualPuzzle.rowCount,
          columnCount: manualPuzzle.columnCount,
          answers: manualPuzzle.answers,
        ),
      ),
    );
    addTearDown(daily.dispose);
    await open(tester, child: DailyPuzzleScreen(session: daily));
    final dynamic state = tester.state(find.byType(PuzzleScreen));
    solve(state.game);
    await tester.pumpAndSettle();
    await audio.flush;
    expect(backend.sounds, [GameSound.puzzleComplete]);
    expect(daily.results, hasLength(1));
  });
  testWidgets(
    'actual replay completion sounds once without advancing current progression',
    (tester) async {
      final fixture = PuzzleSequenceGenerator(
        prototypeCatalogue,
        prototypeSequenceConfig,
      ).generateNext(puzzleIndex: 1);
      final session = PuzzleSession(
        generator: _ReplayFixtures(fixture),
        startIndex: 2,
      );
      addTearDown(session.dispose);
      final currentId = session.current.puzzle!.id;
      await open(
        tester,
        child: PuzzleReplayScreen(session: session, puzzleIndex: 1),
      );
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      solve(state.game);
      await tester.pumpAndSettle();
      await audio.flush;
      expect(backend.sounds, [GameSound.puzzleComplete]);
      expect(session.current.puzzleIndex, 2);
      expect(session.completedThrough, 1);
      expect(session.current.puzzle!.id, currentId);
      expect(session.letters, isEmpty);
      expect(session.completedScores.keys, [1]);
    },
  );
  testWidgets('pushing gameplay pauses music, Back restores same menu player', (
    tester,
  ) async {
    await open(
      tester,
      child: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PuzzleScreen(puzzle: manualPuzzle),
              ),
            ),
            child: const Text('Play'),
          ),
        ),
      ),
    );
    expect(backend.commands, ['resume']);
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await audio.flush;
    expect(backend.commands, ['resume', 'pause']);
    Navigator.of(tester.element(find.byType(PuzzleScreen))).pop();
    await tester.pumpAndSettle();
    await audio.flush;
    expect(backend.commands, ['resume', 'pause', 'resume']);
  });
  for (final tag in LanguagePolicy.production.enabled) {
    testWidgets('$tag localized compact Audio settings toggles are live', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final locale = Locale.fromSubtags(
        languageCode: tag.split('-').first,
        countryCode: tag == 'pt-BR' ? 'BR' : null,
        scriptCode: tag == 'zh-Hans' ? 'Hans' : null,
      );
      final strings = await AppLocalizations.delegate.load(locale);
      expect(strings.audio, isNotEmpty);
      expect(strings.music, isNotEmpty);
      expect(strings.soundEffects, isNotEmpty);
      await tester.pumpWidget(
        GameAudioHost(
          audio: audio,
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SettingsScreen(settings: settings),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final music = find.byKey(const ValueKey('music-enabled'));
      final sfx = find.byKey(const ValueKey('sfx-enabled'));
      await tester.ensureVisible(music);
      await tester.tap(music);
      await tester.pump();
      expect(settings.musicEnabled, false);
      expect(settings.sfxEnabled, true);
      await tester.ensureVisible(sfx);
      await tester.tap(sfx);
      await tester.pump();
      expect(settings.sfxEnabled, false);
      expect(find.text(strings.soundEffects), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'original PCM assets are compact, unclipped, zero-DC, clean loop boundary',
    () {
      var total = 0;
      for (final name in [
        'letter',
        'wrong_check',
        'hint_reveal',
        'puzzle_complete',
        'menu_ambient',
      ]) {
        final bytes = File('assets/audio/$name.wav').readAsBytesSync();
        total += bytes.length;
        final data = ByteData.sublistView(bytes);
        expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
        expect(data.getUint16(22, Endian.little), 1);
        expect(data.getUint32(24, Endian.little), 22050);
        expect(data.getUint16(34, Endian.little), 16);
        var sum = 0, peak = 0;
        for (var i = 44; i < bytes.length; i += 2) {
          final sample = data.getInt16(i, Endian.little);
          sum += sample;
          if (sample.abs() > peak) peak = sample.abs();
        }
        expect(peak, lessThan(22000));
        expect((sum / ((bytes.length - 44) / 2)).abs(), lessThan(1));
        if (name == 'menu_ambient') {
          // A wrapped musical note tail need not begin at zero. Check actual
          // sample/slope continuity, not the rejected drone's zero-crossing.
          final first = data.getInt16(44, Endian.little);
          final wrapStep =
              first - data.getInt16(bytes.length - 2, Endian.little);
          final startStep = data.getInt16(46, Endian.little) - first;
          expect(data.getUint32(40, Endian.little), 24 * 22050 * 2);
          expect(wrapStep.abs(), lessThan(250));
          expect((startStep - wrapStep).abs(), lessThan(32));
        } else {
          expect(data.getInt16(44, Endian.little), 0);
        }
      }
      expect(total, lessThanOrEqualTo(2 * 1024 * 1024));
    },
  );
}
