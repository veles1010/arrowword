import 'dart:convert';

// Duration converts persisted milliseconds to signed 64-bit microseconds.
const maxPersistedElapsedMilliseconds = 0x7fffffffffffffff ~/ 1000;

/// JSON decoding loses repeated object keys. Record their paths before using
/// the decoded map so ambiguous optional entries can be dropped, not trusted.
class ProgressJson {
  ProgressJson(String record) : value = jsonDecode(record) {
    final stack = <_ObjectKeys>[];
    for (var i = 0; i < record.length; i++) {
      final c = record[i];
      if (c == '"') {
        final start = i++;
        while (i < record.length) {
          if (record[i] == '\\') {
            i += 2;
          } else if (record[i] == '"') {
            break;
          } else {
            i++;
          }
        }
        var next = i + 1;
        while (next < record.length && record[next].trim().isEmpty) {
          next++;
        }
        if (next < record.length && record[next] == ':') {
          final key = jsonDecode(record.substring(start, i + 1)) as String;
          final frame = stack.last;
          if (!frame.keys.add(key)) duplicates.add([...frame.path, key]);
          frame.pendingKey = key;
        } else if (stack.isNotEmpty) {
          stack.last.pendingKey = null;
        }
      } else if (c == '{' || c == '[') {
        final path = stack.isEmpty ? <String>[] : stack.last.takeValuePath();
        stack.add(_ObjectKeys(path, array: c == '['));
      } else if (c == '}' || c == ']') {
        stack.removeLast();
      } else if (c != ':' && c != ',' && c.trim().isNotEmpty) {
        // A primitive value ends at a structural token. JSON is already valid.
        if (stack.isNotEmpty) stack.last.pendingKey = null;
        while (i + 1 < record.length && !',}]'.contains(record[i + 1])) {
          i++;
        }
      }
    }
  }

  final Object? value;
  final List<List<String>> duplicates = [];
}

class _ObjectKeys {
  _ObjectKeys(this.path, {required this.array});
  final List<String> path;
  final bool array;
  final Set<String> keys = {};
  String? pendingKey;

  List<String> takeValuePath() {
    final path = [...this.path, array ? '*' : pendingKey!];
    pendingKey = null;
    return path;
  }
}
