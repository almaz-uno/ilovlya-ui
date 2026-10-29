// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecordingNotifier)
final recordingProvider = RecordingNotifierFamily._();

final class RecordingNotifierProvider
    extends $AsyncNotifierProvider<RecordingNotifier, RecordingInfo> {
  RecordingNotifierProvider._({
    required RecordingNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recordingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recordingNotifierHash();

  @override
  String toString() {
    return r'recordingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecordingNotifier create() => RecordingNotifier();

  @override
  bool operator ==(Object other) {
    return other is RecordingNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recordingNotifierHash() => r'289e18d3ba1e6eb561c523ecb1493ca164c0ef8f';

final class RecordingNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RecordingNotifier,
          AsyncValue<RecordingInfo>,
          RecordingInfo,
          FutureOr<RecordingInfo>,
          String
        > {
  RecordingNotifierFamily._()
    : super(
        retry: null,
        name: r'recordingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecordingNotifierProvider call(String recordingId) =>
      RecordingNotifierProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'recordingProvider';
}

abstract class _$RecordingNotifier extends $AsyncNotifier<RecordingInfo> {
  late final _$args = ref.$arg as String;
  String get recordingId => _$args;

  FutureOr<RecordingInfo> build(String recordingId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RecordingInfo>, RecordingInfo>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RecordingInfo>, RecordingInfo>,
              AsyncValue<RecordingInfo>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
