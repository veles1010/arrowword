"""Offline musical diagnostics/spectrogram; NumPy + Pillow, not app dependencies."""
import argparse
import json
import math
from pathlib import Path
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from generate_audio import MENU_CHORDS, menu_events


def load(path):
    with wave.open(str(path), "rb") as file:
        assert file.getnchannels() == 1 and file.getsampwidth() == 2
        return np.frombuffer(file.readframes(file.getnframes()), dtype="<i2").astype(float) / 32768, file.getframerate()


def spectrum(samples, rate):
    length, hop = 4096, 1024
    frames = np.lib.stride_tricks.sliding_window_view(samples, length)[::hop]
    power = abs(np.fft.rfft(frames * np.hanning(length), axis=1)) ** 2
    return power, np.fft.rfftfreq(length, 1 / rate), (np.arange(len(frames)) * hop + length / 2) / rate


def metrics(samples, rate):
    power, frequencies, _ = spectrum(samples, rate)
    summed = power.sum(axis=0)
    peak = float(abs(samples).max())
    steps = np.diff(samples)
    return {
        "durationSeconds": len(samples) / rate,
        "peak": peak, "peakDbFS": 20 * math.log10(peak),
        "headroomDb": -20 * math.log10(peak),
        "rms": float(np.sqrt(np.mean(samples ** 2))),
        "dc": float(samples.mean()),
        "energyBelow120HzPercent": float(summed[frequencies < 120].sum() / summed.sum() * 100),
        "largestFrequencyBinEnergyPercent": float(summed.max() / summed.sum() * 100),
        "spectralCentroidHz": float((frequencies * summed).sum() / summed.sum()),
        "wrapStepPcm": float((samples[0] - samples[-1]) * 32768),
        "wrapSlopeChangePcm": float((steps[0] - (samples[0] - samples[-1])) * 32768),
        "maxAdjacentStepPcm": float(abs(steps).max() * 32768),
    }


def plot(new, old, output):
    width, height = 1250, 770
    image = Image.new("RGB", (width, height), "#101923")
    draw = ImageDraw.Draw(image)
    try:
        regular = ImageFont.truetype("DejaVuSans.ttf", 15)
        title = ImageFont.truetype("DejaVuSans.ttf", 22)
    except OSError:
        regular = ImageFont.load_default(size=15)
        title = ImageFont.load_default(size=22)
    draw.text((25, 16), "Arrowword menu music - structural review (not artistic approval)", fill="white", font=title)
    for row, (label, source) in enumerate([("Replacement: 24 s / four harmonies / two instruments", new), ("Rejected: 16 s / static low drone", old)]):
        samples, rate = source
        power, freq, times = spectrum(samples, rate)
        # Uniform log-frequency raster, allowing low and upper musical bands to be seen.
        bins = np.geomspace(40, 4000, 260)
        db = 10 * np.log10(np.maximum(power, 1e-15))
        scaled = np.clip((db - db.max() + 65) / 65, 0, 1)
        indices = np.searchsorted(freq, bins).clip(0, len(freq)-1)
        values = scaled[:, indices].T[::-1]
        rgb = np.stack([255 * values ** 1.7, 220 * values ** .9, 180 * values ** .55], axis=2).astype("uint8")
        top = 89 + row * 340
        panel = Image.fromarray(rgb).resize((1080, 260), Image.Resampling.BILINEAR)
        image.paste(panel, (110, top))
        draw.text((110, top-27), label, fill="white", font=regular)
        for frequency in [60, 120, 250, 500, 1000, 2000, 4000]:
            y = top + round(259 * (1 - math.log(frequency/40) / math.log(4000/40)))
            draw.text((35, y-8), str(frequency), fill="#d9e6ef", font=regular)
        duration = len(samples) / rate
        for time in range(0, round(duration)+1, 3 if row == 0 else 4):
            x = 110 + round(1080 * time / duration)
            draw.text((x-7, top+266), str(time), fill="#d9e6ef", font=regular)
        if row == 0:
            for i, (chord, _) in enumerate(MENU_CHORDS):
                x = 110 + i*270
                draw.line((x, top, x, top+259), fill="#74818c", width=1)
                draw.text((x+8, top+294), chord, fill="#a6d9ff", font=regular)
    draw.text((25, 736), "Frequency: Hz (log axis). Time: seconds. Colour: relative spectral energy, -65...0 dB per panel.", fill="#c8d4df", font=regular)
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", required=True, type=Path)
    parser.add_argument("--output", type=Path, default=Path("docs/menu_music_spectrogram.png"))
    args = parser.parse_args()
    path = Path("assets/audio/menu_ambient.wav")
    new, old = load(path), load(args.baseline)
    report = {"replacement": metrics(*new), "rejected": metrics(*old),
              "noteEvents": len(menu_events()), "fileBytes": path.stat().st_size}
    print(json.dumps(report, indent=2))
    # Report evolving pitch-class energy independently for each six-second harmony.
    for index, (name, _) in enumerate(MENU_CHORDS):
        samples, rate = new
        segment = samples[round((index*6 + .7)*rate):round((index*6+5.7)*rate)]
        power, freq, _ = spectrum(segment, rate)
        strongest = np.argsort(power.sum(axis=0))[-6:][::-1]
        print(name, "dominant bands Hz:", [round(float(freq[i]), 1) for i in strongest])
    plot(new, old, args.output)
    print("Spectrogram:", args.output)


if __name__ == "__main__":
    main()
