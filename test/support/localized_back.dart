import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WidgetTester.pageBack searches the English tooltip, not localized Material back.
Future<void> localizedPageBack(WidgetTester tester) async {
  final back = find.byType(BackButton);
  expect(
    back,
    findsOneWidget,
    reason: 'One visible Material back button expected',
  );
  await tester.tap(back);
}
