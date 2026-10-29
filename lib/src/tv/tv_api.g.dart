// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pairs the code shown on a television with this tenant. The server answers
/// 404 for an unknown, spent or expired code alike.

@ProviderFor(pairTv)
final pairTvProvider = PairTvFamily._();

/// Pairs the code shown on a television with this tenant. The server answers
/// 404 for an unknown, spent or expired code alike.

final class PairTvProvider
    extends
        $FunctionalProvider<
          AsyncValue<TvSession>,
          TvSession,
          FutureOr<TvSession>
        >
    with $FutureModifier<TvSession>, $FutureProvider<TvSession> {
  /// Pairs the code shown on a television with this tenant. The server answers
  /// 404 for an unknown, spent or expired code alike.
  PairTvProvider._({
    required PairTvFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pairTvProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pairTvHash();

  @override
  String toString() {
    return r'pairTvProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TvSession> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TvSession> create(Ref ref) {
    final argument = this.argument as String;
    return pairTv(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PairTvProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pairTvHash() => r'0026e325bdf737f0a5d3a5a7421c9673f3386df3';

/// Pairs the code shown on a television with this tenant. The server answers
/// 404 for an unknown, spent or expired code alike.

final class PairTvFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TvSession>, String> {
  PairTvFamily._()
    : super(
        retry: null,
        name: r'pairTvProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Pairs the code shown on a television with this tenant. The server answers
  /// 404 for an unknown, spent or expired code alike.

  PairTvProvider call(String code) =>
      PairTvProvider._(argument: code, from: this);

  @override
  String toString() => r'pairTvProvider';
}

/// Sessions of this tenant that have not ended.

@ProviderFor(tvSessions)
final tvSessionsProvider = TvSessionsProvider._();

/// Sessions of this tenant that have not ended.

final class TvSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TvSession>>,
          List<TvSession>,
          FutureOr<List<TvSession>>
        >
    with $FutureModifier<List<TvSession>>, $FutureProvider<List<TvSession>> {
  /// Sessions of this tenant that have not ended.
  TvSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvSessionsHash();

  @$internal
  @override
  $FutureProviderElement<List<TvSession>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TvSession>> create(Ref ref) {
    return tvSessions(ref);
  }
}

String _$tvSessionsHash() => r'7f396757c1865858a355ed557d81e14063db2d6b';

/// The state of one session, refreshed while somebody is looking at it. The
/// timer is cancelled with the provider, so a closed sheet stops polling.

@ProviderFor(TvSessionState)
final tvSessionStateProvider = TvSessionStateFamily._();

/// The state of one session, refreshed while somebody is looking at it. The
/// timer is cancelled with the provider, so a closed sheet stops polling.
final class TvSessionStateProvider
    extends $AsyncNotifierProvider<TvSessionState, TvSession> {
  /// The state of one session, refreshed while somebody is looking at it. The
  /// timer is cancelled with the provider, so a closed sheet stops polling.
  TvSessionStateProvider._({
    required TvSessionStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tvSessionStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tvSessionStateHash();

  @override
  String toString() {
    return r'tvSessionStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TvSessionState create() => TvSessionState();

  @override
  bool operator ==(Object other) {
    return other is TvSessionStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tvSessionStateHash() => r'70fe619c328480c3ef79ef49b389add65acc8146';

/// The state of one session, refreshed while somebody is looking at it. The
/// timer is cancelled with the provider, so a closed sheet stops polling.

final class TvSessionStateFamily extends $Family
    with
        $ClassFamilyOverride<
          TvSessionState,
          AsyncValue<TvSession>,
          TvSession,
          FutureOr<TvSession>,
          String
        > {
  TvSessionStateFamily._()
    : super(
        retry: null,
        name: r'tvSessionStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The state of one session, refreshed while somebody is looking at it. The
  /// timer is cancelled with the provider, so a closed sheet stops polling.

  TvSessionStateProvider call(String sessionId) =>
      TvSessionStateProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'tvSessionStateProvider';
}

/// The state of one session, refreshed while somebody is looking at it. The
/// timer is cancelled with the provider, so a closed sheet stops polling.

abstract class _$TvSessionState extends $AsyncNotifier<TvSession> {
  late final _$args = ref.$arg as String;
  String get sessionId => _$args;

  FutureOr<TvSession> build(String sessionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TvSession>, TvSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TvSession>, TvSession>,
              AsyncValue<TvSession>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
