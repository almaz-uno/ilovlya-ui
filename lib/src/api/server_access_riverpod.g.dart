// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_access_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the server of the settings accepts their token, as the requests that poll it have found (#211). A new token
/// or server URL starts afresh, not rejected: the user has changed it to be tried, and what another server answered
/// says nothing about this one.

@ProviderFor(ServerAccessNotifier)
final serverAccessProvider = ServerAccessNotifierProvider._();

/// Whether the server of the settings accepts their token, as the requests that poll it have found (#211). A new token
/// or server URL starts afresh, not rejected: the user has changed it to be tried, and what another server answered
/// says nothing about this one.
final class ServerAccessNotifierProvider
    extends $NotifierProvider<ServerAccessNotifier, ServerAccess> {
  /// Whether the server of the settings accepts their token, as the requests that poll it have found (#211). A new token
  /// or server URL starts afresh, not rejected: the user has changed it to be tried, and what another server answered
  /// says nothing about this one.
  ServerAccessNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverAccessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverAccessNotifierHash();

  @$internal
  @override
  ServerAccessNotifier create() => ServerAccessNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerAccess value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerAccess>(value),
    );
  }
}

String _$serverAccessNotifierHash() =>
    r'120d7511bd191736432b72e3a1df3086230009b5';

/// Whether the server of the settings accepts their token, as the requests that poll it have found (#211). A new token
/// or server URL starts afresh, not rejected: the user has changed it to be tried, and what another server answered
/// says nothing about this one.

abstract class _$ServerAccessNotifier extends $Notifier<ServerAccess> {
  ServerAccess build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ServerAccess, ServerAccess>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ServerAccess, ServerAccess>,
              ServerAccess,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
