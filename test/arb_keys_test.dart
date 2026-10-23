import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// jsonDecode silently keeps the last duplicate, so inspect object keys before
// using the decoded map. Tokenizing strings keeps ICU braces out of the stack.
List<String> duplicateKeys(String source) {
  jsonDecode(source); // Reject invalid JSON before inspecting its tokens.
  final objects = <Set<String>>[];
  final duplicates = <String>[];
  final tokens = RegExp(r'"(?:[^"\\]|\\.)*"|[{}]');
  for (final token in tokens.allMatches(source)) {
    final value = token.group(0)!;
    if (value == '{') {
      objects.add(<String>{});
    } else if (value == '}') {
      objects.removeLast();
    } else if (RegExp(r'^\s*:').hasMatch(source.substring(token.end))) {
      final key = jsonDecode(value) as String;
      if (!objects.last.add(key)) duplicates.add(key);
    }
  }
  return duplicates;
}

void main() {
  test('duplicate detection handles nesting, escaped keys and ICU strings', () {
    expect(duplicateKeys(r'{"a": 1, "\u0061": 2, "meta": {"x": 1, "x": 2}}'), ['a', 'x']);
    expect(duplicateKeys(r'{"a": {"x": 1}, "b": {"x": 2}, "icu": "{count, plural, other{{count} files}}"}'), isEmpty);
  });

  final arbs = Directory('lib').listSync(recursive: true, followLinks: false).whereType<File>().where((file) {
    final name = p.basename(file.path);
    return name.startsWith('app_') && name.endsWith('.arb');
  }).toList()..sort((a, b) => a.path.compareTo(b.path));

  test('localization ARB files exist', () => expect(arbs, isNotEmpty));
  for (final file in arbs) {
    test('${file.path} has no duplicate JSON keys', () {
      expect(duplicateKeys(file.readAsStringSync()), isEmpty, reason: 'Repeated keys silently replace translations or placeholder metadata');
    });
  }
}
