import '../features/puzzle/localization/clue_pack.dart';

class LoadedCluePack {
  const LoadedCluePack(this.locale, this.resolver);
  final String locale;
  final LocalizedClueResolver resolver;
}

/// App-scoped and lazy. Retain the tr/en pair; new packs load only on demand.
class CluePackCache {
  CluePackCache(this.read, {this.locales = const ['tr', 'en']});
  final Future<String> Function(String locale) read;
  final Iterable<String> locales;
  final _packs = <String, Map<String, String>>{};
  final _reads = <String, Future<void>>{};
  final _loads = <String, Future<LoadedCluePack>>{};
  Future<LocalizedClueResolver>? _loading;
  LocalizedClueResolver? _ready;
  LocalizedClueResolver? get ready => _ready;
  Future<LocalizedClueResolver> load() => _loading ??= _load();
  LoadedCluePack? readyFor(String locale) =>
      _packs.containsKey(locale) ? LoadedCluePack(locale, _ready!) : null;

  Future<void> _read(String locale) => _reads.putIfAbsent(locale, () async {
    _packs[locale] = decodeCluePack(await read(locale));
    _ready = LocalizedClueResolver(
      _packs,
      completeLocales: _packs.keys.toSet(),
    );
  });

  Future<LocalizedClueResolver> _load() async {
    await Future.wait(['tr', 'en'].where(locales.contains).map(_read));
    return _ready!;
  }

  Future<LoadedCluePack> loadFor(String locale) =>
      _loads.putIfAbsent(locale, () async {
        if (!locales.contains(locale)) throw ClueIntegrityException('', locale);
        if (locale == 'tr' || locale == 'en') {
          await load();
        } else {
          await _read(locale);
        }
        return LoadedCluePack(locale, _ready!);
      });
}
