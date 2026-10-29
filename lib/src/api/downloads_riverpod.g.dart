// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloads_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DownloadsNotifier)
final downloadsProvider = DownloadsNotifierFamily._();

final class DownloadsNotifierProvider
    extends $AsyncNotifierProvider<DownloadsNotifier, List<Download>> {
  DownloadsNotifierProvider._({
    required DownloadsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'downloadsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$downloadsNotifierHash();

  @override
  String toString() {
    return r'downloadsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DownloadsNotifier create() => DownloadsNotifier();

  @override
  bool operator ==(Object other) {
    return other is DownloadsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$downloadsNotifierHash() => r'1203ff919d04ae09de5ae8700f4580ea2c4e3ab4';

final class DownloadsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DownloadsNotifier,
          AsyncValue<List<Download>>,
          List<Download>,
          FutureOr<List<Download>>,
          String
        > {
  DownloadsNotifierFamily._()
    : super(
        retry: null,
        name: r'downloadsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DownloadsNotifierProvider call(String recordingId) =>
      DownloadsNotifierProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'downloadsProvider';
}

abstract class _$DownloadsNotifier extends $AsyncNotifier<List<Download>> {
  late final _$args = ref.$arg as String;
  String get recordingId => _$args;

  FutureOr<List<Download>> build(String recordingId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Download>>, List<Download>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Download>>, List<Download>>,
              AsyncValue<List<Download>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
