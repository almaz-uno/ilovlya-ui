import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

ProviderContainer createTestProviderContainer({List<Override> overrides = const []}) => ProviderContainer(retry: (_, _) => null, overrides: overrides);
