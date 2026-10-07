enum WordDifficulty { easy, medium, hard }

class WordEntry {
  const WordEntry(
    this.solution,
    this.turkishClue, {
    this._id,
    this.difficulty = WordDifficulty.easy,
    this.tags = const [],
    this.clueId,
  });

  final String? _id;

  /// Presentation identity only; never used in deterministic search/ranking.
  final String? clueId;
  // Solution-derived default keeps small generator fixtures terse. Curated
  // content specifies ids explicitly, so future wording edits retain identity.
  String get id => _id ?? solution.trim().toLowerCase();
  final String solution;
  final String turkishClue;
  final WordDifficulty difficulty;
  final List<String> tags;

  WordEntry normalized() => WordEntry(
    solution.trim().toUpperCase(),
    turkishClue.trim(),
    id: id,
    clueId: clueId,
    difficulty: difficulty,
    tags: List.unmodifiable(tags),
  );
}
