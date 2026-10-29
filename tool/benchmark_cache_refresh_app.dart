// Run the same benchmark inside the selected iOS simulator, using its private
// temporary directory. No application settings, tokens or saved media are read.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilovlya/src/utils/provider_retry.dart';

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
  // This status-only widget does not read providers. The scope keeps the app root conventional.
  runApp(ProviderScope(retry: disableProviderRetry, child: MaterialApp(home: Scaffold(body: Center(child: Text(status))))));
}
