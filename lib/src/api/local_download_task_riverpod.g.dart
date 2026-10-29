// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_download_task_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocalDTNotifier)
final localDTProvider = LocalDTNotifierProvider._();

final class LocalDTNotifierProvider
    extends $NotifierProvider<LocalDTNotifier, Map<String, LocalDownloadTask>> {
  LocalDTNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localDTProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localDTNotifierHash();

  @$internal
  @override
  LocalDTNotifier create() => LocalDTNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, LocalDownloadTask> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, LocalDownloadTask>>(
        value,
      ),
    );
  }
}

String _$localDTNotifierHash() => r'9c0335bf9a27030269f7c9b170eb127e0e2209ec';

abstract class _$LocalDTNotifier
    extends $Notifier<Map<String, LocalDownloadTask>> {
  Map<String, LocalDownloadTask> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, LocalDownloadTask>,
              Map<String, LocalDownloadTask>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, LocalDownloadTask>,
                Map<String, LocalDownloadTask>
              >,
              Map<String, LocalDownloadTask>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
