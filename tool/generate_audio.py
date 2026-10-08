"""Original Arrowword synthesis, standard library only; deterministic PCM."""
import array
import math
from pathlib import Path
import sys
import wave

MENU_DURATION = 24.0
# Eight 4/4 bars at 80 BPM; each harmony spans two bars. Smooth, compact
# inversions keep three voices stationary or moving by at most a whole tone.
MENU_CHORDS = [
    ("Cmaj7", [60, 67, 71, 76]),
    ("Am7/C", [60, 67, 69, 76]),
    ("Fmaj7/C", [60, 65, 69, 76]),
    ("Gadd9/B", [59, 67, 69, 74]),
]


def menu_events():
    events = []
    # Softly rolled electric-piano voicings, followed by quieter, varied inner
    # voices. Not an eighth-note arpeggiator or copied two-second motif.
    for index, (_, pitches) in enumerate(MENU_CHORDS):
        start = index * 6.0
        for voice, pitch in enumerate(pitches):
            events.append((start + voice * .17, 5.35, pitch,
                           .085 - voice * .005, "warm_keys"))
        second_bar = [3.65, 3.95, 3.35, 3.70][index]
        for offset, voice in enumerate([[1, 2], [0, 2], [1, 3], [1, 2]][index]):
            events.append((start + second_bar + offset * .31, 3.35,
                           pitches[voice], .038, "warm_keys"))
    # Nine intentionally sparse details, including a common-tone E turnaround.
    for start, pitch, gain in [
        (1.35, 79, .082), (4.45, 76, .061),
        (7.55, 69, .075), (10.60, 79, .054),
        (13.65, 72, .072), (16.60, 69, .052),
        (19.50, 74, .066), (22.05, 67, .051), (23.25, 76, .046),
    ]:
        events.append((start, 3.1, pitch, gain, "soft_mallet"))
    return events


def render_menu():
    """Finite instrument notes rendered into a circular phrase, tails included."""
    count = round(MENU_DURATION * RATE)
    values = [0.0] * count
    for start, duration, pitch, gain, timbre in menu_events():
        frequency = 440 * 2 ** ((pitch - 69) / 12)
        length = round(duration * RATE)
        signal, envelopes = [], []
        for i in range(length):
            age = i / RATE
            attack = .085 if timbre == "warm_keys" else .045
            decay = 2.05 if timbre == "warm_keys" else .88
            envelope = (1 - math.exp(-age / attack)) ** 2 * math.exp(-age / decay)
            if age > duration - .6:
                envelope *= math.sin(math.pi * (duration - age) / 1.2) ** 2
            phase = TAU * frequency * age
            if timbre == "warm_keys":
                sound = (.72 * math.sin(phase)
                         + .14 * math.exp(-age / 1.2) * math.sin(2 * phase + .18)
                         + .05 * math.exp(-age / .7) * math.sin(3 * phase + .4)
                         + .10 * math.sin(phase * 1.0014 + .27)
                         + .08 * math.sin(phase * .9986 - .27))
            else:
                sound = (math.sin(phase)
                         + .18 * math.exp(-age / .35) * math.sin(2.01 * phase)
                         + .035 * math.exp(-age / .18) * math.sin(3.96 * phase))
            signal.append(gain * envelope * sound)
            envelopes.append(envelope)
        # Each finite note is zero-mean, without discontinuous endpoint shifts.
        correction = sum(signal) / sum(envelopes)
        onset = round(start * RATE)
        for i, (sample, envelope) in enumerate(zip(signal, envelopes)):
            values[(onset + i) % count] += sample - correction * envelope
    # Two very restrained early room reflections, also circular. No long fade
    # around the loop seam: the last note's natural tail belongs at bar one.
    dry = values[:]
    for seconds, gain in [(.067, .055), (.113, .025)]:
        delay = round(seconds * RATE)
        for i in range(count):
            values[i] += gain * dry[(i - delay) % count]
    return values

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
TAU = 2 * math.pi


def tone(t, frequency):
    return math.sin(TAU * frequency * t) + .12 * math.sin(TAU * 2 * frequency * t)


def note(t, start, duration, frequency):
    age = t - start
    if age < 0 or age >= duration:
        return 0
    envelope = math.sin(math.pi * age / duration) ** 2
    return envelope * math.exp(-3 * age / duration) * tone(age, frequency)


def write(name, duration, sample=None, *, values=None):
    count = round(duration * RATE)
    if values is None:
        values = [sample(i / RATE) for i in range(count)]
    # Remove any finite-window mean without adding a discontinuity at either end.
    if name != "menu_ambient":
        weights = [math.sin(math.pi * i / (count - 1)) ** 2 for i in range(count)]
        correction = sum(values) / sum(weights)
        values = [v - correction * w for v, w in zip(values, weights)]
    assert max(abs(v) for v in values) < .65
    assert abs(sum(values) / count) < 1e-6
    pcm = array.array("h", (round(v * 32767) for v in values))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(OUT / f"{name}.wav"), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(pcm.tobytes())
    print(f"{name}: {duration:.3f}s, {(OUT / (name + '.wav')).stat().st_size} bytes")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    if "--menu-only" in sys.argv:
        write("menu_ambient", MENU_DURATION, values=render_menu())
        return
    write("letter", .065, lambda t: .40 * note(t, 0, .065, 440))
    write("wrong_check", .190, lambda t: .35 * math.sin(math.pi * t / .190) ** 2
          * math.sin(TAU * (330 * t - 190 * t * t)))
    write("hint_reveal", .280, lambda t:
          .30 * note(t, 0, .24, 659.25) + .22 * note(t, .055, .225, 880))
    write("puzzle_complete", .900, lambda t: sum(
        .23 * note(t, start, .90 - start, freq)
        for start, freq in [(0, 392), (.14, 493.875), (.28, 587.375)]))
    write("menu_ambient", MENU_DURATION, values=render_menu())


if __name__ == "__main__":
    main()
