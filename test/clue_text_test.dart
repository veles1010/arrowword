import 'package:arrowword/features/puzzle/presentation/clue_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget sample(String clue, double width, double height) => MaterialApp(
  home: Center(
    child: SizedBox(width: width, height: height, child: ClueText(clue)),
  ),
);

void main() {
  testWidgets('single Turkish words stay intact with bounded type sizes', (
    tester,
  ) async {
    for (final clue in ['Testere', 'Yağmur', 'Üzümsü']) {
      await tester.pumpWidget(sample(clue, 50, 30));
      final text = tester.widget<Text>(find.text(clue));
      expect(text.softWrap, isFalse);
      expect(text.maxLines, 1);
      expect(text.style!.fontSize, inInclusiveRange(10, 14));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('multi-word clues use at most two whitespace-separated lines', (
    tester,
  ) async {
    await tester.pumpWidget(sample('Su Su', 30, 32));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, 'Su\nSu');
    expect(text.maxLines, 2);
    expect(text.style!.fontSize, inInclusiveRange(10, 14));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'narrow cells truncate instead of shrinking below readability floor',
    (tester) async {
      await tester.pumpWidget(sample('Testere', 18, 16));
      final text = tester.widget<Text>(find.text('Testere'));
      expect(text.style!.fontSize, 10);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.softWrap, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
