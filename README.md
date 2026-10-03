# Arrowword Flutter prototype

Early Arrowword-style mobile puzzle prototype: English answers and Turkish clues. “Arrowword” is a working project name, not a final consumer-facing name.

The responsive renderer and gameplay support shared crossings, Turkish clue cells,
native keyboard entry, validation, reset, and completion.

An experimental pure-Dart generator now creates one connected 10-answer puzzle in
a logical 10×10 grid, once at startup, using seed **20261003**. It uses 60 curated
local English words (4–7 letters) and Turkish clues; no dictionary is downloaded.
The manual puzzle remains unchanged as a gameplay/renderer regression fixture.

Generated boards satisfy a stricter contract than that historical fixture:
one unique clue immediately before each answer, matching opposite-direction
crossings, and no accidental letter adjacency. Every maximal horizontal/vertical
letter run of length 2+ must exactly match an answer. Thus a word cannot appear
extended by unrelated letters (for example, RAIN becoming RAINCB).

Search is deterministic bounded backtracking, with at least four answers per
direction and nine crossings. Limits: 10,000 nodes, 10,000 backtracks, 4,000,000
candidate checks, 200 nodes per anchor, and 40 ranked branches per node.
Search retains the best strictly valid complete board found within that budget,
skips repeated partial structures, and compares both orientations on square grids.
Final ranking uses integer scores for crossings, portrait width, compactness,
density (clues plus letters), graph leaves, and dangling arms. Equal scores use
crossings, area, columns, leaves, balance, then a canonical structural signature.
This is bounded quality search, not a guarantee of a global optimum.
Failure is explicit and shows a prototype error; there is no manual fallback.
The test suite covers seeds 1, 2, 3, 42, 100, and 20261003.
The inspection tool reports unique complete structures (including transposes),
first/best scores, graph degrees, search counters, and diagnostic elapsed time.
Wall-clock time never controls the search.

No backend, ads, payments, authentication, analytics, or store infrastructure is
included. “Arrowword” remains a working name.

```bash
flutter pub get
flutter run
flutter analyze
flutter test
dart run tool/inspect_generator.dart 20261003
```
