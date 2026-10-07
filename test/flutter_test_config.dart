import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Existing Turkish-copy fixtures now explicitly use a Turkish test device.
  // Locale-policy/English tests override this inside their own test bodies.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => binding.platformDispatcher.localesTestValue = const [Locale('tr')],
  );
  tearDown(binding.platformDispatcher.clearLocalesTestValue);
  await testMain();
}
