// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'housekeeper_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localMediaHousekeeperHash() =>
    r'e7a8de294b3c83b3adcf22cdfc005234aa7caff5';

/// See also [LocalMediaHousekeeper].
@ProviderFor(LocalMediaHousekeeper)
final localMediaHousekeeperProvider = AutoDisposeAsyncNotifierProvider<
    LocalMediaHousekeeper, (int number, int size)>.internal(
  LocalMediaHousekeeper.new,
  name: r'localMediaHousekeeperProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localMediaHousekeeperHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LocalMediaHousekeeper
    = AutoDisposeAsyncNotifier<(int number, int size)>;
String _$localDataNotifierHash() => r'b4fc2336cc7f9e84a627619e627db4e6aa101587';

/// See also [LocalDataNotifier].
@ProviderFor(LocalDataNotifier)
final localDataNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LocalDataNotifier, int>.internal(
  LocalDataNotifier.new,
  name: r'localDataNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localDataNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LocalDataNotifier = AutoDisposeAsyncNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
