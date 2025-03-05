// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mediaDirsHash() => r'2da7cdbc52239f2edb731277f5313df0c876bde6';

/// See also [mediaDirs].
@ProviderFor(mediaDirs)
final mediaDirsProvider = AutoDisposeFutureProvider<List<String>>.internal(
  mediaDirs,
  name: r'mediaDirsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mediaDirsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MediaDirsRef = AutoDisposeFutureProviderRef<List<String>>;
String _$settingsNotifierHash() => r'd3aae5c71667e3ec213b3c71c028694531dd6915';

/// See also [SettingsNotifier].
@ProviderFor(SettingsNotifier)
final settingsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SettingsNotifier, Settings>.internal(
  SettingsNotifier.new,
  name: r'settingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SettingsNotifier = AutoDisposeAsyncNotifier<Settings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
