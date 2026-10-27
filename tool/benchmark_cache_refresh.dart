// Host benchmark only; use benchmark_cache_refresh_app.dart on a simulator.
import 'package:flutter_test/flutter_test.dart';

import 'cache_refresh_benchmark.dart';

void main() {
  test('refresh 3000 cached recordings', runCacheRefreshBenchmark,
      timeout: const Timeout(Duration(minutes: 10)));
}
