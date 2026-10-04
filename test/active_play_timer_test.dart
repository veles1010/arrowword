import 'package:arrowword/features/puzzle/presentation/active_play_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Duration now;
  late ActivePlayTimer timer;

  setUp(() {
    now = Duration.zero;
    timer = ActivePlayTimer(monotonicNow: () => now);
  });

  test('paused background time is excluded and resumed time is added', () {
    expect(timer.isRunning, isFalse);
    timer.resume();
    now += const Duration(seconds: 7);
    timer.pause();
    expect(timer.isRunning, isFalse);
    now += const Duration(hours: 2);
    expect(timer.elapsed, const Duration(seconds: 7));
    timer.resume();
    expect(timer.isRunning, isTrue);
    now += const Duration(seconds: 3);
    expect(timer.elapsed, const Duration(seconds: 10));
  });

  test('duplicate resume and pause calls do not double count', () {
    timer.resume();
    now += const Duration(seconds: 2);
    timer.resume();
    now += const Duration(seconds: 3);
    timer.pause();
    now += const Duration(seconds: 20);
    timer.pause();
    expect(timer.elapsed, const Duration(seconds: 5));
    timer.resume();
    now += const Duration(seconds: 4);
    timer.pause();
    expect(timer.elapsed, const Duration(seconds: 9));
  });

  test('restored elapsed duration is retained', () {
    now = const Duration(hours: 1);
    timer = ActivePlayTimer(
      initialElapsed: const Duration(seconds: 42),
      monotonicNow: () => now,
    );
    expect(timer.elapsed, const Duration(seconds: 42));
    timer.resume();
    now += const Duration(seconds: 8);
    timer.pause();
    expect(timer.elapsed, const Duration(seconds: 50));
  });

  test('elapsed reads do not mutate accumulation or running state', () {
    timer.resume();
    now += const Duration(seconds: 3);
    expect(timer.elapsed, const Duration(seconds: 3));
    expect(timer.elapsed, const Duration(seconds: 3));
    expect(timer.isRunning, isTrue);
    now += const Duration(seconds: 2);
    timer.pause();
    expect(timer.elapsed, const Duration(seconds: 5));
    expect(timer.elapsed, const Duration(seconds: 5));
    expect(timer.isRunning, isFalse);
  });
}
