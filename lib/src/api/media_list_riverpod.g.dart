// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_list_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MediaListNotifier)
final mediaListProvider = MediaListNotifierProvider._();

final class MediaListNotifierProvider
    extends $AsyncNotifierProvider<MediaListNotifier, List<RecordingInfo>> {
  MediaListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaListNotifierHash();

  @$internal
  @override
  MediaListNotifier create() => MediaListNotifier();
}

String _$mediaListNotifierHash() => r'0ef4c512d760b612f73d35b1e34e2260b6f26e4e';

abstract class _$MediaListNotifier extends $AsyncNotifier<List<RecordingInfo>> {
  FutureOr<List<RecordingInfo>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<RecordingInfo>>, List<RecordingInfo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<RecordingInfo>>, List<RecordingInfo>>,
              AsyncValue<List<RecordingInfo>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SearchPhraseNotifier)
final searchPhraseProvider = SearchPhraseNotifierProvider._();

final class SearchPhraseNotifierProvider
    extends $NotifierProvider<SearchPhraseNotifier, String> {
  SearchPhraseNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchPhraseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchPhraseNotifierHash();

  @$internal
  @override
  SearchPhraseNotifier create() => SearchPhraseNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchPhraseNotifierHash() =>
    r'42b96e7dd059296b61c42cf26f1560b70989a910';

abstract class _$SearchPhraseNotifier extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
