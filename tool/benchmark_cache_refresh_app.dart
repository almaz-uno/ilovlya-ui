// Run the same benchmark inside the selected iOS simulator, using its private
// temporary directory. No application settings, tokens or saved media are read.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cache_refresh_benchmark.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  showStatus('CACHE_BENCH running; see the Flutter console');
  try {
    await runCacheRefreshBenchmark();
    debugPrintSynchronously('CACHE_BENCH complete');
    showStatus('CACHE_BENCH complete; results are in the Flutter console');
  } catch (error, stack) {
    debugPrintSynchronously('CACHE_BENCH failed: $error\n$stack');
    showStatus('CACHE_BENCH failed; see the Flutter console');
  }
}

void showStatus(String status) {
  runApp(MaterialApp(home: Scaffold(body: Center(child: Text(status)))));
}
