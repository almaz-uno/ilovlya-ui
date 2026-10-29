// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directories_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storePlaces)
final storePlacesProvider = StorePlacesProvider._();

final class StorePlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<StorePlaces>,
          StorePlaces,
          FutureOr<StorePlaces>
        >
    with $FutureModifier<StorePlaces>, $FutureProvider<StorePlaces> {
  StorePlacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storePlacesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storePlacesHash();

  @$internal
  @override
  $FutureProviderElement<StorePlaces> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StorePlaces> create(Ref ref) {
    return storePlaces(ref);
  }
}

String _$storePlacesHash() => r'1b987c7c48ead4187649965ebd1885cce5fa186f';
