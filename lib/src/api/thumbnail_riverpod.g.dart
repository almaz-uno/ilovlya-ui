// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thumbnail_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThumbnailDataNotifier)
final thumbnailDataProvider = ThumbnailDataNotifierFamily._();

final class ThumbnailDataNotifierProvider
    extends $AsyncNotifierProvider<ThumbnailDataNotifier, Uint8List> {
  ThumbnailDataNotifierProvider._({
    required ThumbnailDataNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'thumbnailDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$thumbnailDataNotifierHash();

  @override
  String toString() {
    return r'thumbnailDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ThumbnailDataNotifier create() => ThumbnailDataNotifier();

  @override
  bool operator ==(Object other) {
    return other is ThumbnailDataNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$thumbnailDataNotifierHash() =>
    r'd29bcf3ceb1bf8e7e13390c34b7f7f219eac8922';

final class ThumbnailDataNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ThumbnailDataNotifier,
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>,
          String
        > {
  ThumbnailDataNotifierFamily._()
    : super(
        retry: null,
        name: r'thumbnailDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ThumbnailDataNotifierProvider call(String thumbnailUrl) =>
      ThumbnailDataNotifierProvider._(argument: thumbnailUrl, from: this);

  @override
  String toString() => r'thumbnailDataProvider';
}

abstract class _$ThumbnailDataNotifier extends $AsyncNotifier<Uint8List> {
  late final _$args = ref.$arg as String;
  String get thumbnailUrl => _$args;

  FutureOr<Uint8List> build(String thumbnailUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Uint8List>, Uint8List>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Uint8List>, Uint8List>,
              AsyncValue<Uint8List>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
