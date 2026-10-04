# Arrowword Flutter prototype

“Arrowword” is a working name. English answers use Turkish clues. The responsive
Material 3 board supports crossings, native keyboard input, validation, reset and
completion. The manual puzzle remains an unchanged regression fixture.

## Content and sequence

Compatibility **v3** retains all **300 v2 local Dart records** unchanged: 4–7 letters, stable
lowercase-solution IDs, difficulty metadata and internal tags. The original 60
word/clue pairs are preserved. Validation checks identity, characters, lengths,
clues and tags; health inspection measures crossing partners and letter frequency.

The app displays Puzzle 1, generated once through the sequence layer. Base seed
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
schema-4 record saves current index/identity, letters, contiguous completion and
compact historical puzzle indices/content IDs (no old grids). Normal restore
resolves and validates that prefix, then generates only the current puzzle.
Schema-1/2 saves replay Puzzle 1..N once to migrate; later launches avoid replay.
Schema 3 migrates without prefix replay. Free “Harf Aç” reveals and locks one
selected cell; reset retains those cells. Only hint coordinates/count are saved,
not redundant solution letters. Each new puzzle starts with zero hints.
Corrupt/incompatible progress resets safely to empty Puzzle 1.
Debug ARROWWORD_PUZZLE_INDEX launches ignore and never overwrite player progress.
No statistics, archives, selection UI or cloud state are stored.

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

No backend, downloaded dictionary, ads, payments, analytics or store infrastructure.

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
