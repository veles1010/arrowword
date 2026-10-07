import '../features/puzzle/localization/clue_pack.dart';

/// App-scoped and lazy: menus never parse packs; first gameplay loads both once.
/// Keeping complete packs together makes later language switches synchronous.
class CluePackCache {
  CluePackCache(this.read, {this.locales = const ['tr', 'en']});
  final Future<String> Function(String locale) read;
  final Iterable<String> locales;
  Future<LocalizedClueResolver>? _loading;
  LocalizedClueResolver? _ready;
  LocalizedClueResolver? get ready => _ready;
  Future<LocalizedClueResolver> load() => _loading ??= _load();
  Future<LocalizedClueResolver> _load() async {
    final entries = await Future.wait(
      locales.map(
        (locale) async => MapEntry(locale, decodeCluePack(await read(locale))),
      ),
    );
    return _ready = LocalizedClueResolver(
      Map.fromEntries(entries),
      completeLocales: locales.toSet(),
    );
  }
}
