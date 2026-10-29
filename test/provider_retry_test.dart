import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/utils/provider_retry.dart';

void main() {
  test('the production retry policy disables Riverpod automatic retries', () async {
    var defaultCalls = 0;
    final defaultProvider = FutureProvider<int>((ref) {
      defaultCalls++;
      throw Exception('expected failure');
    });
    final defaultContainer = ProviderContainer();
    addTearDown(defaultContainer.dispose);
    final defaultSubscription = defaultContainer.listen(defaultProvider, (_, _) {});
    addTearDown(defaultSubscription.close);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(defaultCalls, greaterThan(1));

    var testCalls = 0;
    final provider = FutureProvider<int>((ref) {
      testCalls++;
      throw Exception('expected failure');
    });
    final container = ProviderContainer(retry: disableProviderRetry);
    addTearDown(container.dispose);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(container.read(provider).hasError, isTrue);
    expect(testCalls, 1);
  });
}
