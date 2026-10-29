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
    r'e429153b5ffc48f6799376632478279404b10681';

abstract class _$LocalMediaHousekeeper extends $AsyncNotifier<(int, int)> {
  FutureOr<(int, int)> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<(int, int)>, (int, int)>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<(int, int)>, (int, int)>,
              AsyncValue<(int, int)>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
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

String _$localDataNotifierHash() => r'f17b378424b412f3879f6543e74ce4c43da60ae3';

abstract class _$LocalDataNotifier extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
