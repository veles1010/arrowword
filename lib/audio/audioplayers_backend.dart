import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'game_audio.dart';

/// Fixed players, no per-keystroke allocation or asset decoding in widgets.
class AudioplayersBackend implements AudioBackend {
  static const musicVolume = .20;
  static const effectVolume = .45;
  static bool get _lowLatency =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static AudioContext get _context => AudioContext(
    android: const AudioContextAndroid(
      audioFocus: AndroidAudioFocus.none,
      usageType: AndroidUsageType.game,
      stayAwake: false,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );
  final _music = AudioPlayer();
  final _effects = {for (final sound in GameSound.values) sound: AudioPlayer()};
  final _prepared = <GameSound>{};
  bool _musicPrepared = false;
  static const assets = {
    GameSound.letter: 'audio/letter.wav',
    GameSound.wrongCheck: 'audio/wrong_check.wav',
    GameSound.hintReveal: 'audio/hint_reveal.wav',
    GameSound.puzzleComplete: 'audio/puzzle_complete.wav',
  };
  @override
  Future<void> resumeMusic() async {
    if (!_musicPrepared) {
      await _music.setAudioContext(_context);
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(musicVolume);
      await _music.setSource(AssetSource('audio/menu_ambient.wav'));
      _musicPrepared = true;
    }
    await _music.resume();
  }

  @override
  Future<void> pauseMusic() => _music.pause();
  @override
  Future<void> play(GameSound sound) async {
    final player = _effects[sound]!;
    if (!_prepared.contains(sound)) {
      if (_lowLatency) await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setAudioContext(_context);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(effectVolume);
      await player.setSource(AssetSource(assets[sound]!));
      _prepared.add(sound);
    }
    if (_lowLatency) {
      await player.stop();
    } else {
      await player.seek(Duration.zero);
    }
    await player.resume();
  }

  @override
  Future<void> stopEffects() async {
    await Future.wait(_effects.values.map((p) => p.stop()));
  }

  @override
  Future<void> dispose() async {
    await Future.wait([
      _music.dispose(),
      ..._effects.values.map((p) => p.dispose()),
    ]);
  }
}
