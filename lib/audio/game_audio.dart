import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_settings.dart';

enum GameSound { letter, wrongCheck, hintReveal, puzzleComplete }

abstract class AudioBackend {
  Future<void> resumeMusic();
  Future<void> pauseMusic();
  Future<void> play(GameSound sound);
  Future<void> stopEffects();
  Future<void> dispose();
}

/// One app-owned controller. Playback failures never affect gameplay or ads.
class GameAudio {
  GameAudio(this.settings, this.backend) {
    settings.addListener(_settingsChanged);
  }
  final AppSettings settings;
  final AudioBackend backend;
  bool _active = false, _playing = false, _disposed = false;
  int _gameplay = 0, _ads = 0;
  Future<void>? _commands;
  Future<void> get flush => _commands ?? Future<void>.value();
  bool get _musicAllowed =>
      !_disposed &&
      _active &&
      _gameplay == 0 &&
      _ads == 0 &&
      settings.musicEnabled;
  bool get _effectsAllowed =>
      !_disposed && _active && _ads == 0 && settings.sfxEnabled;
  void _queue(Future<void> Function() operation) {
    _commands = (_commands ?? Future<void>.value())
        .then((_) => operation())
        .catchError((Object _) {});
  }

  void _sync() => _queue(() async {
    if (_disposed) return;
    final wanted = _musicAllowed;
    if (wanted == _playing) return;
    if (wanted) {
      await backend.resumeMusic();
    } else {
      await backend.pauseMusic();
    }
    _playing = wanted;
  });
  void _settingsChanged() {
    _sync();
    if (!settings.sfxEnabled) _queue(backend.stopEffects);
  }

  void setActive(bool active) {
    if (_disposed || _active == active) return;
    _active = active;
    _sync();
    if (!active) _queue(backend.stopEffects);
  }

  /// Disposable leases keep nested/replaced gameplay routes from restarting music.
  VoidCallback enterGameplay() {
    if (_disposed) return () {};
    _gameplay++;
    _sync();
    var closed = false;
    return () {
      if (!closed) {
        closed = true;
        _gameplay--;
        _sync();
      }
    };
  }

  Future<VoidCallback> beginAd() async {
    if (_disposed) return () {};
    _ads++;
    _sync();
    _queue(backend.stopEffects);
    await flush;
    var closed = false;
    return () {
      if (!closed) {
        closed = true;
        _ads--;
        _sync();
      }
    };
  }

  void _play(GameSound sound) {
    if (!_effectsAllowed) return;
    _queue(() async {
      if (_effectsAllowed) await backend.play(sound);
    });
  }

  void playLetter() => _play(GameSound.letter);
  void playWrongCheck() => _play(GameSound.wrongCheck);
  void playHintReveal() => _play(GameSound.hintReveal);
  void playPuzzleComplete() => _play(GameSound.puzzleComplete);
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    settings.removeListener(_settingsChanged);
    _queue(backend.dispose);
    await flush;
  }
}

class GameAudioScope extends InheritedWidget {
  const GameAudioScope({required this.audio, required super.child, super.key});
  final GameAudio audio;
  static GameAudio? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameAudioScope>()?.audio;
  @override
  bool updateShouldNotify(GameAudioScope oldWidget) => audio != oldWidget.audio;
}

class GameAudioHost extends StatefulWidget {
  const GameAudioHost({required this.audio, required this.child, super.key});
  final GameAudio audio;
  final Widget child;
  @override
  State<GameAudioHost> createState() => _GameAudioHostState();
}

class _GameAudioHostState extends State<GameAudioHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.audio.setActive(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      widget.audio.setActive(state == AppLifecycleState.resumed);
  @override
  void didUpdateWidget(GameAudioHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio != widget.audio) {
      unawaited(oldWidget.audio.dispose());
      widget.audio.setActive(
        WidgetsBinding.instance.lifecycleState == null ||
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      GameAudioScope(audio: widget.audio, child: widget.child);
}
