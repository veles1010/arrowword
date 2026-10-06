/// Player progression track, independent of vocabulary-level WordDifficulty.
enum PuzzleDifficulty {
  easy('easy', 'Kolay'),
  medium('medium', 'Orta'),
  hard('hard', 'Zor');

  const PuzzleDifficulty(this.id, this.turkishLabel);
  final String id;
  final String turkishLabel;
}
