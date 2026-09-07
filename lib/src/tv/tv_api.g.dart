// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pairTvHash() => r'0026e325bdf737f0a5d3a5a7421c9673f3386df3';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Pairs the code shown on a television with this tenant. The server answers
/// 404 for an unknown, spent or expired code alike.
///
/// Copied from [pairTv].
@ProviderFor(pairTv)
const pairTvProvider = PairTvFamily();

/// Pairs the code shown on a television with this tenant. The server answers
/// 404 for an unknown, spent or expired code alike.
///
/// Copied from [pairTv].
class PairTvFamily extends Family<AsyncValue<TvSession>> {
  /// Pairs the code shown on a television with this tenant. The server answers
  /// 404 for an unknown, spent or expired code alike.
  ///
  /// Copied from [pairTv].
  const PairTvFamily();

  /// Pairs the code shown on a television with this tenant. The server answers
  /// 404 for an unknown, spent or expired code alike.
  ///
  /// Copied from [pairTv].
  PairTvProvider call(
    String code,
  ) {
    return PairTvProvider(
      code,
    );
  }

  @override
  PairTvProvider getProviderOverride(
    covariant PairTvProvider provider,
  ) {
    return call(
      provider.code,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'pairTvProvider';
}

/// Pairs the code shown on a television with this tenant. The server answers
/// 404 for an unknown, spent or expired code alike.
///
/// Copied from [pairTv].
class PairTvProvider extends AutoDisposeFutureProvider<TvSession> {
  /// Pairs the code shown on a television with this tenant. The server answers
  /// 404 for an unknown, spent or expired code alike.
  ///
  /// Copied from [pairTv].
  PairTvProvider(
    String code,
  ) : this._internal(
          (ref) => pairTv(
            ref as PairTvRef,
            code,
          ),
          from: pairTvProvider,
          name: r'pairTvProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pairTvHash,
          dependencies: PairTvFamily._dependencies,
          allTransitiveDependencies: PairTvFamily._allTransitiveDependencies,
          code: code,
        );

  PairTvProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.code,
  }) : super.internal();

  final String code;

  @override
  Override overrideWith(
    FutureOr<TvSession> Function(PairTvRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PairTvProvider._internal(
        (ref) => create(ref as PairTvRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        code: code,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TvSession> createElement() {
    return _PairTvProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PairTvProvider && other.code == code;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, code.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PairTvRef on AutoDisposeFutureProviderRef<TvSession> {
  /// The parameter `code` of this provider.
  String get code;
}

class _PairTvProviderElement extends AutoDisposeFutureProviderElement<TvSession>
    with PairTvRef {
  _PairTvProviderElement(super.provider);

  @override
  String get code => (origin as PairTvProvider).code;
}

String _$tvSessionsHash() => r'7f396757c1865858a355ed557d81e14063db2d6b';

/// Sessions of this tenant that have not ended.
///
/// Copied from [tvSessions].
@ProviderFor(tvSessions)
final tvSessionsProvider = AutoDisposeFutureProvider<List<TvSession>>.internal(
  tvSessions,
  name: r'tvSessionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tvSessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TvSessionsRef = AutoDisposeFutureProviderRef<List<TvSession>>;
String _$tvSessionStateHash() => r'2791a5ab319a72168e3e8ca7bd9c2dd0d741c949';

abstract class _$TvSessionState
    extends BuildlessAutoDisposeAsyncNotifier<TvSession> {
  late final String sessionId;

  FutureOr<TvSession> build(
    String sessionId,
  );
}

/// The state of one session, refreshed while somebody is looking at it. The
/// timer is cancelled with the provider, so a closed sheet stops polling.
///
/// Copied from [TvSessionState].
@ProviderFor(TvSessionState)
const tvSessionStateProvider = TvSessionStateFamily();

/// The state of one session, refreshed while somebody is looking at it. The
/// timer is cancelled with the provider, so a closed sheet stops polling.
///
/// Copied from [TvSessionState].
class TvSessionStateFamily extends Family<AsyncValue<TvSession>> {
  /// The state of one session, refreshed while somebody is looking at it. The
  /// timer is cancelled with the provider, so a closed sheet stops polling.
  ///
  /// Copied from [TvSessionState].
  const TvSessionStateFamily();

  /// The state of one session, refreshed while somebody is looking at it. The
  /// timer is cancelled with the provider, so a closed sheet stops polling.
  ///
  /// Copied from [TvSessionState].
  TvSessionStateProvider call(
    String sessionId,
  ) {
    return TvSessionStateProvider(
      sessionId,
    );
  }

  @override
  TvSessionStateProvider getProviderOverride(
    covariant TvSessionStateProvider provider,
  ) {
    return call(
      provider.sessionId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'tvSessionStateProvider';
}

/// The state of one session, refreshed while somebody is looking at it. The
/// timer is cancelled with the provider, so a closed sheet stops polling.
///
/// Copied from [TvSessionState].
class TvSessionStateProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TvSessionState, TvSession> {
  /// The state of one session, refreshed while somebody is looking at it. The
  /// timer is cancelled with the provider, so a closed sheet stops polling.
  ///
  /// Copied from [TvSessionState].
  TvSessionStateProvider(
    String sessionId,
  ) : this._internal(
          () => TvSessionState()..sessionId = sessionId,
          from: tvSessionStateProvider,
          name: r'tvSessionStateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tvSessionStateHash,
          dependencies: TvSessionStateFamily._dependencies,
          allTransitiveDependencies:
              TvSessionStateFamily._allTransitiveDependencies,
          sessionId: sessionId,
        );

  TvSessionStateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sessionId,
  }) : super.internal();

  final String sessionId;

  @override
  FutureOr<TvSession> runNotifierBuild(
    covariant TvSessionState notifier,
  ) {
    return notifier.build(
      sessionId,
    );
  }

  @override
  Override overrideWith(TvSessionState Function() create) {
    return ProviderOverride(
      origin: this,
      override: TvSessionStateProvider._internal(
        () => create()..sessionId = sessionId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sessionId: sessionId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<TvSessionState, TvSession>
      createElement() {
    return _TvSessionStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TvSessionStateProvider && other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TvSessionStateRef on AutoDisposeAsyncNotifierProviderRef<TvSession> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _TvSessionStateProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<TvSessionState, TvSession>
    with TvSessionStateRef {
  _TvSessionStateProviderElement(super.provider);

  @override
  String get sessionId => (origin as TvSessionStateProvider).sessionId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
