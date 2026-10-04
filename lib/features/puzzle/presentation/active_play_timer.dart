/// Accumulates only running intervals from a monotonic time source.
class ActivePlayTimer {
  ActivePlayTimer({
    Duration initialElapsed = Duration.zero,
    Duration Function()? monotonicNow,
  }) : _accumulated = initialElapsed,
       _monotonicNow = monotonicNow ?? _stopwatchSource();

  final Duration Function() _monotonicNow;
  Duration _accumulated;
  Duration? _startedAt;

  static Duration Function() _stopwatchSource() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  bool get isRunning => _startedAt != null;

  Duration get elapsed {
    final startedAt = _startedAt;
    return startedAt == null
        ? _accumulated
        : _accumulated + (_monotonicNow() - startedAt);
  }

  void resume() {
    _startedAt ??= _monotonicNow();
  }

  void pause() {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    _accumulated += _monotonicNow() - startedAt;
    _startedAt = null;
  }
}
