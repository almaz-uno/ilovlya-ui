// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thumbnail_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$thumbnailDataNotifierHash() =>
    r'aca9c1e36c4c62ab60a261bfd098111012cece82';

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

abstract class _$ThumbnailDataNotifier
    extends BuildlessAutoDisposeAsyncNotifier<File> {
  late final String thumbnailUrl;

  FutureOr<File> build(
    String thumbnailUrl,
  );
}

/// See also [ThumbnailDataNotifier].
@ProviderFor(ThumbnailDataNotifier)
const thumbnailDataNotifierProvider = ThumbnailDataNotifierFamily();

/// See also [ThumbnailDataNotifier].
class ThumbnailDataNotifierFamily extends Family<AsyncValue<File>> {
  /// See also [ThumbnailDataNotifier].
  const ThumbnailDataNotifierFamily();

  /// See also [ThumbnailDataNotifier].
  ThumbnailDataNotifierProvider call(
    String thumbnailUrl,
  ) {
    return ThumbnailDataNotifierProvider(
      thumbnailUrl,
    );
  }

  @override
  ThumbnailDataNotifierProvider getProviderOverride(
    covariant ThumbnailDataNotifierProvider provider,
  ) {
    return call(
      provider.thumbnailUrl,
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
  String? get name => r'thumbnailDataNotifierProvider';
}

/// See also [ThumbnailDataNotifier].
class ThumbnailDataNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<ThumbnailDataNotifier, File> {
  /// See also [ThumbnailDataNotifier].
  ThumbnailDataNotifierProvider(
    String thumbnailUrl,
  ) : this._internal(
          () => ThumbnailDataNotifier()..thumbnailUrl = thumbnailUrl,
          from: thumbnailDataNotifierProvider,
          name: r'thumbnailDataNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$thumbnailDataNotifierHash,
          dependencies: ThumbnailDataNotifierFamily._dependencies,
          allTransitiveDependencies:
              ThumbnailDataNotifierFamily._allTransitiveDependencies,
          thumbnailUrl: thumbnailUrl,
        );

  ThumbnailDataNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.thumbnailUrl,
  }) : super.internal();

  final String thumbnailUrl;

  @override
  FutureOr<File> runNotifierBuild(
    covariant ThumbnailDataNotifier notifier,
  ) {
    return notifier.build(
      thumbnailUrl,
    );
  }

  @override
  Override overrideWith(ThumbnailDataNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ThumbnailDataNotifierProvider._internal(
        () => create()..thumbnailUrl = thumbnailUrl,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        thumbnailUrl: thumbnailUrl,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ThumbnailDataNotifier, File>
      createElement() {
    return _ThumbnailDataNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ThumbnailDataNotifierProvider &&
        other.thumbnailUrl == thumbnailUrl;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, thumbnailUrl.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ThumbnailDataNotifierRef on AutoDisposeAsyncNotifierProviderRef<File> {
  /// The parameter `thumbnailUrl` of this provider.
  String get thumbnailUrl;
}

class _ThumbnailDataNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ThumbnailDataNotifier, File>
    with ThumbnailDataNotifierRef {
  _ThumbnailDataNotifierProviderElement(super.provider);

  @override
  String get thumbnailUrl =>
      (origin as ThumbnailDataNotifierProvider).thumbnailUrl;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
