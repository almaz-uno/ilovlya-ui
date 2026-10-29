// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'housekeeper_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocalMediaHousekeeper)
final localMediaHousekeeperProvider = LocalMediaHousekeeperProvider._();

final class LocalMediaHousekeeperProvider
    extends $AsyncNotifierProvider<LocalMediaHousekeeper, (int, int)> {
  LocalMediaHousekeeperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localMediaHousekeeperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localMediaHousekeeperHash();

  @$internal
  @override
  LocalMediaHousekeeper create() => LocalMediaHousekeeper();
}

String _$localMediaHousekeeperHash() =>
    r'271bbe153ff61fa26e6eb3e65ba56df972d50e92';

abstract class _$LocalMediaHousekeeper extends $AsyncNotifier<(int, int)> {
  FutureOr<(int, int)> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<(int, int)>, (int, int)>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<(int, int)>, (int, int)>,
              AsyncValue<(int, int)>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(LocalDataNotifier)
final localDataProvider = LocalDataNotifierProvider._();

final class LocalDataNotifierProvider
    extends $AsyncNotifierProvider<LocalDataNotifier, int> {
  LocalDataNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localDataNotifierHash();

  @$internal
  @override
  LocalDataNotifier create() => LocalDataNotifier();
}

String _$localDataNotifierHash() => r'66b2162347edee626dd32ab59c95bcc168bb2947';

abstract class _$LocalDataNotifier extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
