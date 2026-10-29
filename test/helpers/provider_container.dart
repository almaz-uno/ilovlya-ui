import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ilovlya/src/utils/provider_retry.dart';

ProviderContainer createTestProviderContainer({List<Override> overrides = const []}) => ProviderContainer(retry: disableProviderRetry, overrides: overrides);
