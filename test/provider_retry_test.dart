import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/provider_container.dart';

void main() {
  test('a failed provider remains in AsyncError without automatic retry', () async {
    var calls = 0;
    final provider = FutureProvider<int>((ref) {
      calls++;
      throw StateError('expected failure');
    });
    final container = createTestProviderContainer();
    addTearDown(container.dispose);

    await expectLater(container.read(provider.future), throwsA(isA<StateError>()));
    expect(container.read(provider).hasError, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(calls, 1);
  });
}
