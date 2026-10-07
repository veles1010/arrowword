import 'dart:convert';
import 'dart:io';

import 'package:arrowword/features/puzzle/data/word_catalogue_data.dart';
import 'package:arrowword/features/puzzle/data/track_catalogue_data.dart';
import 'package:arrowword/features/puzzle/localization/clue_pack.dart';
import 'package:arrowword/features/puzzle/localization/english_clue_audit.dart';
import 'package:arrowword/l10n/language_policy.dart';
import 'package:arrowword/features/puzzle/localization/localized_clue_audit.dart';

void main(List<String> arguments) {
  final words = [...catalogueWords, ...mediumWords, ...hardWords];
  final expected = {for (final word in words) word.clueId!: word.turkishClue};
  if (expected.length != 900 || words.length != 900) {
    throw StateError('Clue identity coverage');
  }
  final file = File('assets/clues/tr.json');
  if (arguments.contains('--extract-tr')) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(expected)}\n',
    );
  }
  final actual = decodeCluePack(file.readAsStringSync());
  if (actual.length != expected.length ||
      expected.entries.any((e) => actual[e.key] != e.value)) {
    throw StateError('Turkish pack differs from frozen catalogue');
  }
  final english = decodeCluePack(
    File('assets/clues/en.json').readAsStringSync(),
  );
  if (english.keys.join('|') != actual.keys.join('|')) {
    throw StateError('English key order/coverage differs from Turkish');
  }
  final audit = EnglishClueAudit(words, english);
  for (final track in ['easy', 'medium', 'hard']) {
    stdout.writeln('$track: ${jsonEncode(audit.statistics(track))}');
  }
  stdout.writeln(
    'Errors: ${audit.errors.length}; root warnings: ${audit.rootWarnings.length}; length warnings: ${audit.lengthWarnings.length}; punctuation warnings: ${audit.punctuationWarnings.length}; generic warnings: ${audit.genericWarnings.length}; informational cross-references: ${audit.crossReferences.length}',
  );
  for (final message in [
    ...audit.errors,
    ...audit.rootWarnings,
    ...audit.lengthWarnings,
    ...audit.punctuationWarnings,
    ...audit.genericWarnings,
  ]) {
    stdout.writeln(message);
  }
  if (arguments.contains('--cross-references')) {
    for (final message in audit.crossReferences) {
      stdout.writeln(message);
    }
  }
  if (!audit.isValid) throw StateError('English clue validation failed');
  final referenceUi = jsonDecode(
    File('lib/l10n/app_tr.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  for (final locale in LanguagePolicy.production.locales) {
    if (locale.uiComplete) {
      final ui = jsonDecode(
        File('lib/l10n/app_${locale.tag.replaceAll('-', '_')}.arb')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      if (ui.length != referenceUi.length ||
          referenceUi.keys.any((k) => !ui.containsKey(k))) {
        throw StateError('UI resource coverage: ${locale.tag}');
      }
    }
    if (locale.productionComplete) {
      final clues = decodeCluePack(
        File('assets/clues/${locale.tag}.json').readAsStringSync(),
      );
      if (clues.length != expected.length ||
          expected.keys.any((k) => !clues.containsKey(k))) {
        throw StateError('Production clue coverage: ${locale.tag}');
      }
      if (clues.keys.join('|') != english.keys.join('|')) {
        throw StateError('Clue key ordering: ${locale.tag}');
      }
      if (locale.tag != 'tr' && locale.tag != 'en') {
        final localized = LocalizedClueAudit(words, clues, english);
        for (final track in ['easy', 'medium', 'hard']) {
          stdout.writeln(
            '${locale.tag}/$track: ${jsonEncode(localized.statistics(track))}',
          );
        }
        stdout.writeln(
          '${locale.tag}: errors=${localized.errors.length}; root warnings=${localized.rootWarnings.length}; length warnings=${localized.lengthWarnings.length}; punctuation warnings=${localized.punctuationWarnings.length}',
        );
        for (final warning in [
          ...localized.errors,
          ...localized.rootWarnings,
          ...localized.lengthWarnings,
          ...localized.punctuationWarnings,
        ]) {
          stdout.writeln(warning);
        }
        if (localized.errors.isNotEmpty) {
          throw StateError('Invalid ${locale.tag} clues');
        }
      }
    }
  }
  stdout.writeln(
    'Production-complete: ${LanguagePolicy.production.enabled.join(', ')}. Turkish: exact legacy match. Each pack: 900/900; total: ${LanguagePolicy.production.enabled.length * 900}.',
  );
}
