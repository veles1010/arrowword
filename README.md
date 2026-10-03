# Arrowword Flutter prototype

“Arrowword” is a working name, not a final brand. English answers use Turkish
clues. The responsive Material 3 board supports crossings, native keyboard entry,
validation, reset and completion. The historical manual puzzle remains a
regression fixture.

## Content and sequence

Catalogue **v1** contains 60 local Dart entries, lengths 4–7, with explicit stable
ids, clues, `easy/medium/hard` difficulty and optional internal tags. No words or
clues were changed during migration. Validation rejects duplicate ids/normalized
solutions, invalid A–Z answers, length violations, empty clues and invalid/duplicate
tags. Zero crossing partners is a warning, not automatic exclusion; health metrics
count partners sharing at least one letter and report letter occurrences.

The content pipeline validates and freezes entries, filters difficulty, excludes
recent ids/solutions, then passes a deterministically ordered pool to the existing
generator. History is in memory only. Missing cooldown history and generation
failures are explicit, with index, seed, eligible count and exclusions.

Puzzle indices start at **1**. Base seed **20261003** derives each puzzle seed via
the v1 32-bit MurmurHash3 avalanche of `baseSeed XOR index`: XOR-shift 16,
multiply `0x85ebca6b`, XOR-shift 13, multiply `0xc2b2ae35`, XOR-shift 16;
multiplications are modulo 2^32. Split 16-bit multiplication avoids platform
precision differences. Tests lock indices 1/2/10 to
3255270515 / 3017514609 / 3356167200.

Strict cooldown defaults to **5**. With this catalogue/base seed/budget, cooldowns
5 and 4 both fail at Puzzle 5 (20 eligible words); the explicit prototype setting
is **3**, which generates ten puzzles with minimum repeat distance 4. There is no
automatic relaxation. The app displays only Puzzle 1 through this pipeline,
generated synchronously once before `runApp`; no progression UI was added.
Range generation replays from index 1 to reconstruct required history.

Puzzle ids such as `generated-v1-000001` are scoped to the published sequence
configuration. Catalogue, seed-mixer, selection-policy or search changes may
change puzzles: version that compatibility contract deliberately. Puzzle indices
alone are not eternal identities. No migration/persistence is implemented.

## Grid generator

Pure-Dart best-of-budget search retains the best strictly valid complete board,
including both orientations on square grids. Every maximal letter run of length
2+ must match an answer: no phantom adjacency or false extensions such as RAINCB.
The default 10×10 board has ten answers, at least four per direction and nine
crossings. Failure never silently falls back to the manual puzzle.

The letter index, cached geometry, incremental reversible search state and
canonical placement keys remain intact. Budgets are unchanged: 10,000 nodes,
10,000 backtracks, 4,000,000 full candidate checks, 200 nodes per anchor, 40 ranked
branches per node. Candidate checks exclude indexed span/bounds filtering;
inspection reports those operations separately. Timing is diagnostic only.
Quality scoring and the six original generator regression seeds remain unchanged.

No backend, downloaded dictionary, ads, payments, analytics or store infrastructure.

```bash
flutter pub get
flutter run
flutter analyze
flutter test
dart run tool/inspect_content.dart       # Try strict cooldowns 5,4,3,2; stop on success
dart run tool/inspect_content.dart 3     # Inspect the configured prototype sequence
dart run tool/inspect_generator.dart 1 2 3 42 100 20261003 # Raw generator regression
```
