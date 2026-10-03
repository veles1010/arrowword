enum WordDifficulty { easy, medium, hard }

class WordEntry {
  const WordEntry(
    this.solution,
    this.turkishClue, {
    this._id,
    this.difficulty = WordDifficulty.easy,
    this.tags = const [],
  });

  final String? _id;
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
    difficulty: difficulty,
    tags: List.unmodifiable(tags),
  );
}
