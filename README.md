# Arrowword Flutter prototype

“Arrowword” is a working name. English answers use Turkish clues. The responsive
Material 3 board supports crossings, native keyboard input, validation, reset and
completion. The manual puzzle remains an unchanged regression fixture.

## Content and sequence

Catalogue **v2** has **300 curated local Dart entries**, 4–7 letters, stable
lowercase-solution IDs, difficulty metadata and internal tags. The original 60
word/clue pairs are preserved. Validation checks identity, characters, lengths,
clues and tags; health inspection measures crossing partners and letter frequency.

The app displays Puzzle 1, generated once through the sequence layer. Base seed
**20261003** and the unchanged v1 MurmurHash3-style 32-bit seed mixer derive each
index's seed. Locked seeds for indices 1/2/10 remain
3255270515 / 3017514609 / 3356167200.

The standard sequence uses a **strict five-puzzle cooldown** on both content IDs
and solutions, without automatic relaxation. Version 2 passed 30 consecutive
puzzles. IDs are now `generated-v2-000001`, etc. Catalogue changes intentionally
change deterministic boards; old-version history is rejected, not migrated.
There is no persistence or progression UI.

## Generator and verification

The offline pure-Dart best-of-budget generator, scoring and budgets are unchanged:
10,000 nodes/backtracks, 4,000,000 candidate checks, 200 nodes per anchor, 40
ranked branches. Strict visual-run integrity forbids phantom adjacencies and false
word extensions such as RAINCB. Failure never falls back to a manual board.

Normal tests cover catalogue validation, original-pair preservation, difficulty
filters, locked seeds, cooldown boundaries and seven deterministic v2 puzzles
including reversed-catalogue replay. Original six-seed performance regressions
use a test-only v1 fixture. The stress tool uses the **full v2 eligible pool** and
exits non-zero on generation, strict-validation or cooldown failure. Timing is
diagnostic, never a stopping rule.

- [All 240 additions and sense review](docs/catalogue_v2_review.md)
- [30-puzzle quality, usage and timing report](docs/catalogue_v2_stress.md)

No backend, downloaded dictionary, ads, payments, analytics or store infrastructure.

```bash
flutter pub get
flutter run
flutter analyze
flutter test
dart run tool/inspect_content.dart       # Full 30-puzzle v2 stress check, cooldown 5
dart run tool/inspect_content.dart 7     # Shorter diagnostic sequence, same policy
dart run tool/inspect_generator.dart 1 2 3 42 100 20261003 # Raw full-catalogue search
```
