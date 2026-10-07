import 'dart:convert';
import 'dart:io';

import 'package:arrowword/features/puzzle/data/word_catalogue_data.dart';
import 'package:arrowword/features/puzzle/data/track_catalogue_data.dart';
import 'package:arrowword/features/puzzle/localization/clue_pack.dart';
import 'package:arrowword/features/puzzle/localization/english_clue_audit.dart';
import 'package:arrowword/l10n/language_policy.dart';
import 'package:arrowword/features/puzzle/localization/localized_clue_audit.dart';
import 'package:arrowword/features/puzzle/localization/cjk_clue_audit.dart';
import 'package:arrowword/features/puzzle/localization/ru_id_clue_audit.dart';

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
  void validateCjk(String locale, Map<String, String> clues) {
    if (clues.keys.join('|') != english.keys.join('|')) {
      throw StateError('CJK clue coverage/order: $locale');
    }
    final cjk = CjkClueAudit(locale, words, clues, english);
    for (final track in ['easy', 'medium', 'hard']) {
      stdout.writeln('$locale/$track: ${jsonEncode(cjk.statistics(track))}');
    }
    stdout.writeln(
      '$locale: ${clues.length}/900; errors=${cjk.errors.length}; own-answer loan warnings=${cjk.loanWarnings.length}; borrowing/script usage review=${cjk.borrowingWarnings.length}; untranslated=${cjk.untranslatedWarnings.length}; length=${cjk.lengthWarnings.length}',
    );
    for (final warning in [
      ...cjk.errors,
      ...cjk.loanWarnings,
      ...cjk.borrowingWarnings,
      ...cjk.untranslatedWarnings,
      ...cjk.lengthWarnings,
    ]) {
      stdout.writeln(warning);
    }
    if (cjk.errors.isNotEmpty || cjk.untranslatedWarnings.isNotEmpty) {
      throw StateError('CJK editorial validation failed: $locale');
    }
  }

  void validateRuId(String locale, Map<String, String> clues) {
    if (clues.keys.join('|') != english.keys.join('|')) {
      throw StateError('Clue coverage/order: $locale');
    }
    final audit = RuIdClueAudit(locale, words, clues, english);
    for (final track in ['easy', 'medium', 'hard']) {
      stdout.writeln('$locale/$track: ${jsonEncode(audit.statistics(track))}');
    }
    stdout.writeln(
      '$locale: ${clues.length}/900; errors=${audit.errors.length}; loan review=${audit.loanWarnings.length}; untranslated=${audit.untranslatedWarnings.length}; length=${audit.lengthWarnings.length}; roots=${audit.basic.rootWarnings.length}',
    );
    for (final warning in [
      ...audit.errors,
      ...audit.loanWarnings,
      ...audit.untranslatedWarnings,
      ...audit.lengthWarnings,
      ...audit.basic.rootWarnings,
    ]) {
      stdout.writeln(warning);
    }
    if (audit.errors.isNotEmpty || audit.untranslatedWarnings.isNotEmpty) {
      throw StateError('Editorial validation failed: $locale');
    }
  }

  if (arguments.contains('--ru-id-drafts')) {
    for (final locale in ['ru', 'id']) {
      validateRuId(
        locale,
        decodeCluePack(File('assets/clues/$locale.json').readAsStringSync()),
      );
    }
  }
  if (arguments.contains('--cjk-drafts')) {
    for (final locale in ['ja', 'ko', 'zh-Hans']) {
      validateCjk(
        locale,
        decodeCluePack(File('assets/clues/$locale.json').readAsStringSync()),
      );
    }
  }
  for (final locale in [
    ...LanguagePolicy.production.locales,
    ...LanguagePolicy.prepared,
  ]) {
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
      if (['ja', 'ko', 'zh-Hans'].contains(locale.tag)) {
        validateCjk(locale.tag, clues);
      } else if (['ru', 'id'].contains(locale.tag)) {
        validateRuId(locale.tag, clues);
      } else if (locale.tag != 'tr' && locale.tag != 'en') {
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
