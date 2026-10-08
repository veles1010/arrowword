# Arrowword original audio — V1

All five assets were synthesized specifically for Arrowword by
`tool/generate_audio.py`, using Python's standard-library sine waves and envelopes.
No external music, recording, copyrighted sample pack or attribution-dependent
source was downloaded or used. The script is deterministic; regeneration produces
byte-identical files. All files are mono, 22,050 Hz, signed 16-bit PCM WAV.

| File under assets/audio | Purpose | Duration | Bytes | Runtime gain |
| --- | --- | ---: | ---: | ---: |
| letter.wav | Soft tactile letter feedback | 65 ms | 2,910 | 0.45 |
| wrong_check.wav | Gentle descending incorrect-check cue | 190 ms | 8,424 | 0.45 |
| hint_reveal.wav | Two-note earned-letter reveal | 280 ms | 12,392 | 0.45 |
| puzzle_complete.wav | Restrained rising three-note completion | 900 ms | 39,734 | 0.45 |
| menu_ambient.wav | Eight-bar keys/mallet phrase | 24 s | 1,058,444 | 0.20 |

Total: **1,121,904 bytes (1.070 MiB)**, below the 2 MiB budget.

Short cues use smooth squared-sine envelopes and decay. Finite-window mean is
removed using a boundary-safe envelope. PCM checks enforce headroom, near-zero
DC and boundary quality. The rejected static low drone was discarded completely.
The replacement is an original eight-bar phrase in C major at approximately
80 BPM (4/4, three seconds per bar). Two bars each of Cmaj7 -> Am7/C -> Fmaj7/C ->
Gadd9/B use open inversions and common tones; each voice moves by at most a
whole tone between harmonies, including the turnaround. The F harmony separates
its E and F into different octaves rather than clustering adjacent semitones.
The final harmony returns to C.
Layer A contains 16 soft rolled chord tones and eight quieter inner-voice
rearticulations. Its electric-piano-like timbre uses decaying harmonic partials,
slow attacks and very restrained detuning. Layer B has nine sparse soft mallet
notes, with quickly decaying upper partials. There are 33 note events in total,
not a constant arpeggiator. Lowest fundamental: B3, approximately 247 Hz.
Two quiet early-room reflections are part of instrument shaping, not a third
musical layer. No vocals, drums, external samples or sustained bass drone.

Finite notes are rendered circularly so their natural release tails cross the
phrase boundary. There is no seam fade-out/fade-in; the initial sample is therefore
not required to be zero. The last E note is a common-tone turnaround into Cmaj7.
PCM wrap step is -178 counts (0.00543 full scale), less than normal internal
sample steps (maximum 1,105); start-versus-wrap slope difference is 3 counts.
New peak 0.17938 / -14.92 dBFS (14.92 dB headroom), RMS 0.03282, DC -1.50e-9.
Runtime gain remains 0.20: this is quieter, not louder, than the rejected source
(RMS 0.08718). Windowed FFT energy below 120 Hz fell from approximately 29.75%
to less than 0.000001%; spectral centroid rose from 141 Hz to 458 Hz. The largest
single spectral-bin share fell from 16.54% to 13.93%.

`tool/analyze_menu_audio.py` uses development-only NumPy/Pillow to print metrics
and generate `docs/menu_music_spectrogram.png`; it does not add an app dependency.
The inspected plot shows four changing midrange harmonic regions and sparse
upper-note envelopes, rather than static low bands. Per-panel colour scales are
relative; the image is not a loudness comparison or proof of pleasantness.
For a before/after comparison supply a preserved rejected WAV with `--baseline`.
`python tool/generate_audio.py --menu-only` replaces only menu music; default
generation retains the four SFX unchanged. Both paths remain deterministic.

Actual device decoding, loop continuity and artistic quality require audition.
**HUMAN LISTENING APPROVAL REQUIRED.**

One app-owned audioplayers backend retains one music player and one reusable
player per effect. Android short effects use the package's low-latency SoundPool
mode (no position seeking); other platforms reuse standard players. Music resumes
its paused loop position; tab changes do not
restart it. Gameplay and rewarded-ad leases suppress music. Backgrounding stops
effects and pauses music. Music/SFX settings are independent, default ON, with
separate local keys; media volume controls overall volume. Android uses game/media
playback without taking exclusive focus; iOS ambient respects silent mode and
mixes with other audio. No recording permission or background-audio mode is added.

Gains are conservative V1 starting values, not a claim of completed perceptual
mastering. Before release, listen on a physical phone and headphones at ordinary
media volume: repeated typing must not tire the ear, errors must not feel punitive,
the reveal must be distinct, completion brief, and the loop very quiet. Check all
four Music/SFX combinations, native ads, background/resume and loop wrap. Native
media-player startup latency and loop scheduling cannot be certified by fake tests.
