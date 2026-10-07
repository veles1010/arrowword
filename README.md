# Arrowword Flutter prototype

“Arrowword” is a working name. English answers use Turkish or English clues. The responsive
Material 3 board supports crossings, native keyboard input, validation, reset and
completion. The manual puzzle remains an unchanged regression fixture.

## Content and sequence

Compatibility **v3** retains all **300 v2 local Dart records** unchanged: 4–7 letters, stable
lowercase-solution IDs, difficulty metadata and internal tags. The original 60
word/clue pairs are preserved. Validation checks identity, characters, lengths,
clues and tags; health inspection measures crossing partners and letter frequency.

Normal progression begins at Puzzle 1 through the sequence layer. Base seed
**20261003** and the unchanged v1 MurmurHash3-style 32-bit seed mixer derive each
index's seed. Locked seeds for indices 1/2/10 remain
3255270515 / 3017514609 / 3356167200.

The standard sequence uses a **strict five-puzzle cooldown** on both content IDs
and solutions, without automatic relaxation. The sequence then offers only the
least-used eligible usage tier to the generator. An undersized or failed pool
widens with ranked construction supports: 2, 4, 16, then the full eligible support
pool only as a final stage. Usage count precedes compact letter-overlap utility,
recency and stable ID. Cooldown/difficulty exclusions never reappear. Each attempt
uses the same derived puzzle seed and unchanged budget. Up to three successful
stages are compared by a readability guard, generator quality and target novelty.

Balancing defaults on. Puzzle N requires complete verified history 1 through N−1;
missing lifetime history is an explicit failure. IDs are now
`generated-v3-000001`, etc. V3 changes selection policy, not catalogue records or
seed arithmetic. Old-version history is rejected, not migrated. Disabled balancing
is developer-only comparison mode and retains cooldown-window history semantics.
Completion advances to the next puzzle. A single versioned local shared_preferences
schema-5 record saves current index/identity, letters, contiguous completion and
compact historical puzzle indices/content IDs (no old grids). Normal restore
resolves and validates that prefix, then generates only the current puzzle.
Schema-1/2 saves replay Puzzle 1..N once to migrate; later launches avoid replay.
Schema 3/4 migrate without prefix replay. Rewarded “Reklamla Harf Aç” reveals and locks one
selected cell; reset retains those cells. Only hint coordinates/count are saved,
not redundant solution letters. Each new puzzle starts with zero hints.
Invalid core progression resets safely to empty Puzzle 1; invalid optional score
records are dropped without losing valid progression or other scores.
Debug ARROWWORD_PUZZLE_INDEX launches ignore and never overwrite player progress.

## Local play modes

Normal progression now offers **Kolay / Orta / Zor**, all available from the start
through Bulmacalar's difficulty selector.
Each difficulty has **36 puzzles**: **108 main puzzles** in total. All 36 tiles
are visible in the journey; future puzzles remain locked until reached. Completing
Puzzle 36 finishes that difficulty, keeps its solved save/replays, and offers no
Puzzle 37. Daily is separate and not limited by this main-game count.
Home resumes the last played track; browsing or replay does not change that
preference. Track progress, history and
best scores remain isolated; statistics are compared within each difficulty.
The **Easy** track retains its legacy preference
key, schema 5, generated-v3 IDs, seeds, content/history and scores are unchanged;
no migration is needed. Puzzle/progression difficulty is separate from word-level
difficulty metadata. Medium/Hard v1 each have 300 new answers, descriptive Turkish
clues, isolated stores/history and lazy providers. Startup, Home and difficulty
browsing read metadata only; a loading route opens the requested track's current
board on demand, with no eager preview generation. Replay uses its
owning track's history/scores; Daily remains independent.
Last-played preference uses `arrowword.last_puzzle_difficulty` (`easy/medium/hard`);
missing/invalid values default to Easy. Existing progression schema 5 and Daily
schema 1 are unchanged. Bounded generation stays synchronous after the loading
frame; unusually high-index legacy saves may still have a one-time migration cost.
Pre-contract saves beyond 36 are preserved, shown as 36/36 complete, and never
generate their out-of-range current board. Verified compact history allows replay
within 1..36; only an improved replay score writes that archive, preserving its
original current index/letters/stats/history. Unverifiable archives fail safely
without deletion. Historical score aggregates are retained; displayed completion
is capped at 36. No new persistence schema or destructive normalization.
Full validation: `dart run tool/inspect_tracks.dart --all-normal --repeat`;
see [36-puzzle validation](docs/normal_36_puzzle_validation.md).

Medium catalogue/sequence v1 uses base seed `0x4D454431` (MED1), with IDs
`generated-medium-v1-000001`, etc. Hard v1 uses `0x48415231` (HAR1) and
`generated-hard-v1-000001`, etc. Both reuse the unchanged seed mixer, 10x10/10-answer
generator, budgets, quality comparator, strict cooldown 5 and bounded support.
No answer overlaps exist among the three catalogues. New content is local and
manually curated, not filtered from Easy or downloaded.

Developer inspection (debug/profile only; no player progress writes):

```bash
flutter run --profile --dart-define=ARROWWORD_PUZZLE_INDEX=27 --dart-define=ARROWWORD_PUZZLE_DIFFICULTY=medium
flutter run --profile --dart-define=ARROWWORD_PUZZLE_INDEX=1 --dart-define=ARROWWORD_PUZZLE_DIFFICULTY=medium
flutter run --profile --dart-define=ARROWWORD_PUZZLE_INDEX=11 --dart-define=ARROWWORD_PUZZLE_DIFFICULTY=medium
flutter run --profile --dart-define=ARROWWORD_PUZZLE_INDEX=1 --dart-define=ARROWWORD_PUZZLE_DIFFICULTY=hard
flutter run --profile --dart-define=ARROWWORD_PUZZLE_INDEX=27 --dart-define=ARROWWORD_PUZZLE_DIFFICULTY=hard
flutter run --profile --dart-define=ARROWWORD_PUZZLE_INDEX=19 --dart-define=ARROWWORD_PUZZLE_DIFFICULTY=hard
dart run tool/inspect_tracks.dart medium 30
dart run tool/inspect_tracks.dart hard 30
```

Difficulty defaults to Easy and is ignored unless the index override is present.
Release never enables it; debug and profile support direct, memory-only playtests.
Developer app indexes are restricted to 1..36; lower-level tooling is not.
The puzzle title identifies its track/index and development mode. Completion
shows an unsaved attempt score, with no progression/Next action. Invalid supplied
defines show a development error without opening player stores.
A developer index reconstructs only that track's
prefix once; a high index may take time before the board appears. Stop the previous
run and launch again when changing defines: hot reload cannot change them.
Track diagnostics gate counts, clue leakage/duplicates, crossability,
strict boards and cooldown; timings are observational. Semantic clue ambiguity
and learner-level appropriateness still require human playtesting.
See [v1 content and 30-puzzle validation report](docs/difficulty_v1_validation.md)
for seed locks, coverage, geometry, timing and playtest caveats.
The [pre-freeze semantic review](docs/difficulty_content_review.md) covers all 600
pairs, clue-only corrections, remaining synonym edges and recommended playtests.

Home's Ayarlar action offers persistent System/Light/Dark Material 3 themes and
installed version/build information. Settings use a separate preference key;
normal schema 5 and Daily schema 1 are unchanged.

Home opens normal play, the puzzle progression grid, local statistics or the Daily.
The four-destination shell preserves tab state, with tap/continuous drag navigation;
gameplay and Daily history remain nested routes. System Back from a secondary tab returns Home.
Scoring v1 records active-play time, hints and incorrect checks; background, covered
routes and rewarded-ad time do not count. Completed puzzle replays are fresh,
memory-only attempts. Only a higher score (or equal score with a faster time)
replaces that puzzle's saved best; replay never changes normal progression.
Statistics derive from those stored best records, not every attempt. Legacy
completions without scores remain unscored.

Daily Puzzle V1 uses the **device local calendar date**, not a server timezone.
The canonical `YYYY-MM-DD`, seed version 1 and catalogue version 3 form a stable
`daily-v1-c3-YYYY-MM-DD` identity and portable FNV-1a32 seed. The fixed catalogue
and unchanged bounded generator produce the same board independently of player
progress. At most two deterministic candidates prefer phone-readable geometry.
The board is generated lazily on Daily entry, never while building Home.
Günlük Geçmiş lists completed local Daily results without replay. Daily streaks
are derived from completed calendar dates (today or yesterday keeps a streak alive).
Completed Daily results can be shared as plain Turkish text without answers.

A separate `arrowword.daily_progress` schema-1 payload resumes the most recent
unfinished Daily and retains immutable completed results by date. Yesterday's
unfinished letters are not today's attempt. Completing across midnight keeps the
attempt's original date (also shown while playing). Home rechecks the local date
on resume and route return; Daily rechecks on entry. A completed Daily opens its result, with no second scored
attempt or replay. Daily history is stored locally and shown in Günlük Geçmiş.
Invalid Daily entries are isolated where possible without touching normal saves.
Normal progression remains schema 5. No backend/global leaderboard or cloud sync
exists; a future online Daily may need a canonical server date/timezone.

## Generator and verification

The offline pure-Dart best-of-budget generator, scoring and budgets are unchanged:
10,000 nodes/backtracks, 4,000,000 candidate checks, 200 nodes per anchor, 40
ranked branches. Strict visual-run integrity forbids phantom adjacencies and false
word extensions such as RAINCB. Failure never falls back to a manual board.

Normal tests cover catalogue validation, original-pair preservation, difficulty
filters, locked seeds, lifetime history, tier widening, cooldown boundaries and
seven deterministic balanced puzzles including reversed-catalogue replay.
Original six-seed performance regressions use a test-only v1 fixture. The stress
tool exits non-zero on generation, strict-validation, history or cooldown failure.
Timing is diagnostic, never a stopping rule. No difficulty or length quotas were added.

The bounded-support 30-puzzle experiment reached 80.33% coverage and mean quality
3938.27 (naive v3: 76% / 3772.90). Ten-column boards fell from seven to three.
Tradeoffs: maximum use rose from two to three; mean attempts rose to 2.67, and
generation takes longer. The <=2 wide-board and <=2 mean-attempt goals remain unmet.

- [All 240 additions and sense review](docs/catalogue_v2_review.md)
- [30-puzzle quality, usage and timing report](docs/catalogue_v2_stress.md)
- [Balanced/unbalanced v3 comparison](docs/catalogue_v3_stress.md)
- [Three-way bounded-support comparison](docs/catalogue_v3_support_stress.md)

No backend, downloaded dictionary, production ads, payments, analytics or store infrastructure.

```bash
flutter pub get
flutter run
flutter analyze
flutter test
dart run tool/inspect_content.dart       # Full 30-puzzle balanced v3 stress check
dart run tool/inspect_content.dart --compare # Unbalanced, naive v3, bounded v3
dart run tool/inspect_content.dart --naive # Developer-only full-tier widening
dart run tool/inspect_content.dart --unbalanced # Developer-only v2-style selection
dart run tool/inspect_content.dart 7     # Shorter diagnostic sequence, same policy
dart run tool/inspect_generator.dart 1 2 3 42 100 20261003 # Raw full-catalogue search
```

## Rewarded hint development configuration

“Reklamla Harf Aç” currently uses only Google's rewarded test ads. Sample app IDs
and ad units are TEST-ONLY and must be replaced before release. Release AdMob IDs
and consent/UMP are not configured; this app is not monetization-release-ready.
Hints are granted only for earned rewards, with no free fallback on ad failure.
Configuration follows [Google's Flutter rewarded-ad guide](https://developers.google.com/admob/flutter/rewarded).

## Release checklist

Implemented: core gameplay, persisted progression/scoring, replay best scores,
Daily/history/streaks/sharing, statistics, themes, Settings/About and fluid navigation.

Pending before store release:

- Final store metadata/screenshots.
- Publish/configure an Arrowword privacy-policy URL; none is currently configured.
- Supply Android release keystore/secrets locally. Debug signing is never used for release.
- Verify iOS signing/team, simulator/device build and archive on macOS/Xcode.
- Configure production AdMob App IDs/unit IDs and UMP/consent; decide required iOS privacy/ATT disclosures. Current ads remain TEST-only.

Android release signing reads ignored `android/key.properties`: `storePassword`,
`keyPassword`, `keyAlias`, `storeFile`. The file path may be absolute or relative
to `android/`; use forward slashes on Windows. Supply your own existing release
keystore, never commit credentials, and do not use the debug key. Missing/invalid
configuration deliberately fails release tasks with an actionable error; debug
builds need no release credentials. See [Android signing guidance](https://developer.android.com/studio/publish/app-signing).

Version is currently `1.0.0+1`; About reads installed metadata dynamically.
Every future store upload must use a monotonically increasing build number.

## Native branding

Approved originals remain unchanged in `assets/branding/source/`. The old opaque
icon is reference-only. `tool/generate_branding.py` (Python + Pillow, no runtime
dependency) builds `arrowword_icon_source_clean.png`: a square RGB 1024px master
using the transparent mark and the current theme's graphite surface. No baked
rounding, shadows or borders. Run `python tool/generate_branding.py` to regenerate.

Android legacy `ic_launcher.png` sizes are 48/72/96/144/192px (mdpi through
xxxhdpi). Adaptive foregrounds fit the guaranteed 66dp circle within 108dp layers;
background is solid theme graphite. Monochrome support is intentionally omitted
rather than simplifying the detailed approved artwork. iOS AppIcon slots are:
20pt (1x/2x/3x), 29pt (1x/2x/3x), 40pt (1x/2x/3x), 60pt (2x/3x),
76pt (1x/2x), 83.5pt (2x), and 1024px marketing icon. All icons derive directly
from the clean master. Native splash follows device appearance before Flutter
can read its saved theme setting. Android 12+ uses a 288dp canvas with artwork
inside the 192dp circle. No fake second Flutter splash is used.
Splash refinements use a splash-only cool neutral `#F5F7FB` in light appearance
and unchanged theme graphite `#18191C` in dark appearance. Neutral A surfaces are
mapped to graphite only in the light splash variant; blue arrow pixels and alpha
geometry are preserved. Dark variant keeps the approved source artwork.
Android 12+ remains mark-only inside its circular safe zone. Pre-12 Android and
iOS center a 256x272dp/pt transparent mark + Arrowword lockup, with 192dp/pt-wide
mark, 32dp/pt text gap and 30dp/pt wordmark. Bundled Bitstream Vera Sans Bold
(`assets/branding/fonts/`, license included) provides identical raster typography,
not a runtime font/dependency. iOS uses asset-catalog light/dark appearances.
Validate actual iOS launch/asset compilation later on macOS/Xcode.
Pixel/geometry checks: `python -m unittest discover -s tool -p test_branding.py`.

Android uses Flutter SDK defaults (currently min 24 / target 36), with INTERNET
and dependency-required network/ad permissions. iOS deployment target is 15.0.
Sample AdMob IDs remain TEST-only; no backend/global leaderboard is configured.

## Localization

Answers are always English; board geometry, seeds, IDs and progression are
language-independent. UI strings use Flutter `gen_l10n` (`app_tr.arb` / `app_en.arb`).
Clues are separate presentation packs: `assets/clues/tr.json` and
`assets/clues/en.json` each cover all 900 entries, keyed by frozen catalogue positions
(`easy_v3_000001`, `medium_v1_000001`, `hard_v1_000001`, etc.). Legacy content IDs
and Turkish catalogue fields remain intact; generation never loads locale assets.

Turkish and English are production-complete. Settings offers System Default,
English and Türkçe. Preferences are separate (`system` / `en` / `tr` under
`arrowword.settings.language`); invalid/missing values resolve to System. Turkish
devices use Turkish, English devices use English, and unsupported device languages
fall back to English. Explicit selection wins. UI and clues use the same production
locale, including Daily/share text; switching language never changes boards or saves.
Both compact packs are cached once at first gameplay entry, not decoded by menus
or cells. Future complete locale packs reuse these stable IDs and availability policy.

Developer UI-only review (debug/profile, ignored in release, never saves language):
`flutter run --profile --dart-define=ARROWWORD_UI_LOCALE=en`
This remains UI-only: it does not change preferences or the resolved clue locale.
On a Turkish device/preference it intentionally shows English chrome with Turkish
clues. Test complete English gameplay normally using Settings or device language.
Run `flutter gen-l10n` after UI edits and
`dart run tool/validate_localization.dart` to verify coverage/exact Turkish sync.
`--extract-tr` regenerates the pack from approved catalogue text; it does not translate.
English editorial decisions/statistics are recorded in `docs/english_clue_review.md`.
