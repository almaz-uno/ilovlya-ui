// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directories_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dbHash() => r'517fe9941ea314fa4c3f8c16e6c43b037bf0f28d';

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

/// See also [db].
@ProviderFor(db)
const dbProvider = DbFamily();

/// See also [db].
class DbFamily extends Family<AsyncValue<Database>> {
  /// See also [db].
  const DbFamily();

  /// See also [db].
  DbProvider call(
    String storeName,
  ) {
    return DbProvider(
      storeName,
    );
  }

  @override
  DbProvider getProviderOverride(
    covariant DbProvider provider,
  ) {
    return call(
      provider.storeName,
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
  String? get name => r'dbProvider';
}

/// See also [db].
class DbProvider extends AutoDisposeFutureProvider<Database> {
  /// See also [db].
  DbProvider(
    String storeName,
  ) : this._internal(
          (ref) => db(
            ref as DbRef,
            storeName,
          ),
          from: dbProvider,
          name: r'dbProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product') ? null : _$dbHash,
          dependencies: DbFamily._dependencies,
          allTransitiveDependencies: DbFamily._allTransitiveDependencies,
          storeName: storeName,
        );

  DbProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.storeName,
  }) : super.internal();

  final String storeName;

  @override
  Override overrideWith(
    FutureOr<Database> Function(DbRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DbProvider._internal(
        (ref) => create(ref as DbRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        storeName: storeName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Database> createElement() {
    return _DbProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DbProvider && other.storeName == storeName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, storeName.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DbRef on AutoDisposeFutureProviderRef<Database> {
  /// The parameter `storeName` of this provider.
  String get storeName;
}

class _DbProviderElement extends AutoDisposeFutureProviderElement<Database>
    with DbRef {
  _DbProviderElement(super.provider);

  @override
  String get storeName => (origin as DbProvider).storeName;
}

String _$storePlacesHash() => r'd13abc3525395439152295617862c59965bf4482';

/// See also [storePlaces].
@ProviderFor(storePlaces)
final storePlacesProvider = AutoDisposeFutureProvider<StorePlaces>.internal(
  storePlaces,
  name: r'storePlacesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$storePlacesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StorePlacesRef = AutoDisposeFutureProviderRef<StorePlaces>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
