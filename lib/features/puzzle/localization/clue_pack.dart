import 'dart:convert';

class ClueIntegrityException implements Exception {
  const ClueIntegrityException(this.clueId, this.locale);
  final String clueId, locale;
}

/// Packs are presentation data. Neither pack loading nor locale enters generation.
class LocalizedClueResolver {
  LocalizedClueResolver(
    Map<String, Map<String, String>> packs, {
    Set<String> completeLocales = const {'tr'},
  }) : packs = Map.unmodifiable(
         packs.map(
           (key, value) => MapEntry(
             _canonical(key),
             Map<String, String>.unmodifiable(value),
           ),
         ),
       ),
       completeLocales = Set.unmodifiable(completeLocales.map(_canonical));
  static String _canonical(String tag) =>
      tag.replaceAll('_', '-').toLowerCase();
  final Map<String, Map<String, String>> packs;
  final Set<String> completeLocales;
  String resolve(String clueId, String locale) {
    final tag = _canonical(locale);
    final base = tag.split('-').first;
    for (final candidate in {tag, base, 'en'}) {
      final pack = packs[candidate];
      final clue = pack?[clueId];
      if (clue != null && clue.trim().isNotEmpty) return clue;
      if (completeLocales.contains(candidate)) {
        throw ClueIntegrityException(clueId, candidate);
      }
    }
    throw ClueIntegrityException(clueId, tag);
  }
}

Map<String, String> decodeCluePack(String source) {
  // Reject duplicate JSON keys instead of accepting last-write-wins content.
  final keys = <String>[];
  // Scan complete JSON string tokens so escaped quotes/colons in clues are safe.
  for (var i = 0; i < source.length; i++) {
    if (source[i] != '"') continue;
    final start = i++;
    while (i < source.length) {
      if (source[i] == '\\') {
        i += 2;
      } else if (source[i] == '"') {
        break;
      } else {
        i++;
      }
    }
    if (i >= source.length) throw const FormatException('Invalid JSON string');
    var next = i + 1;
    while (next < source.length && source[next].trim().isEmpty) {
      next++;
    }
    if (next < source.length && source[next] == ':') {
      keys.add(jsonDecode(source.substring(start, i + 1)) as String);
    }
  }
  if (keys.toSet().length != keys.length) {
    throw const FormatException('Duplicate clue IDs');
  }
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Invalid clue pack');
  }
  return Map.unmodifiable(
    decoded.map((key, value) {
      if (value is! String || value.trim().isEmpty) {
        throw const FormatException('Invalid clue');
      }
      return MapEntry(key, value);
    }),
  );
}
