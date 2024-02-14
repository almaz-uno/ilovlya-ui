// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'housekeeper_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localMediaHousekeeperHash() =>
    r'acdd179141d8b3cc1545d7684ad8f4a7e4604330';

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
String _$localDataNotifierHash() => r'fb1a0c0cac57c92bacb71fb194fdb6081967ef86';

/// See also [LocalDataNotifier].
@ProviderFor(LocalDataNotifier)
final localDataNotifierProvider = AutoDisposeNotifierProvider<LocalDataNotifier,
    (int number, int size)>.internal(
  LocalDataNotifier.new,
  name: r'localDataNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localDataNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LocalDataNotifier = AutoDisposeNotifier<(int number, int size)>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
