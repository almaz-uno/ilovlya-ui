import 'dart:io';

import 'package:ilovlya/src/api/local_json.dart';

Future<void> main(List<String> args) async {
  await writeLocalJson(File(args.single), {'payload': 'x' * 65536},
      flush: false);
}
