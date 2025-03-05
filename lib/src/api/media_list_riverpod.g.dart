// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_list_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mediaListNotifierHash() => r'07de1daa035230825abb9d3a42f19ecd59952280';

/// See also [MediaListNotifier].
@ProviderFor(MediaListNotifier)
final mediaListNotifierProvider = AutoDisposeAsyncNotifierProvider<
    MediaListNotifier, List<RecordingInfo>>.internal(
  MediaListNotifier.new,
  name: r'mediaListNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mediaListNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MediaListNotifier = AutoDisposeAsyncNotifier<List<RecordingInfo>>;
String _$searchPhraseNotifierHash() =>
    r'42b96e7dd059296b61c42cf26f1560b70989a910';

/// See also [SearchPhraseNotifier].
@ProviderFor(SearchPhraseNotifier)
final searchPhraseNotifierProvider =
    AutoDisposeNotifierProvider<SearchPhraseNotifier, String>.internal(
  SearchPhraseNotifier.new,
  name: r'searchPhraseNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchPhraseNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchPhraseNotifier = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
