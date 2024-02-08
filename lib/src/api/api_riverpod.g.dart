// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getUrlInfoHash() => r'b6d915662872c9fd28c05effa7104796b9ccc825';

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

/// See also [getUrlInfo].
@ProviderFor(getUrlInfo)
const getUrlInfoProvider = GetUrlInfoFamily();

/// See also [getUrlInfo].
class GetUrlInfoFamily extends Family<AsyncValue<URLInfo>> {
  /// See also [getUrlInfo].
  const GetUrlInfoFamily();

  /// See also [getUrlInfo].
  GetUrlInfoProvider call(
    String url,
  ) {
    return GetUrlInfoProvider(
      url,
    );
  }

  @override
  GetUrlInfoProvider getProviderOverride(
    covariant GetUrlInfoProvider provider,
  ) {
    return call(
      provider.url,
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
  String? get name => r'getUrlInfoProvider';
}

/// See also [getUrlInfo].
class GetUrlInfoProvider extends AutoDisposeFutureProvider<URLInfo> {
  /// See also [getUrlInfo].
  GetUrlInfoProvider(
    String url,
  ) : this._internal(
          (ref) => getUrlInfo(
            ref as GetUrlInfoRef,
            url,
          ),
          from: getUrlInfoProvider,
          name: r'getUrlInfoProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getUrlInfoHash,
          dependencies: GetUrlInfoFamily._dependencies,
          allTransitiveDependencies:
              GetUrlInfoFamily._allTransitiveDependencies,
          url: url,
        );

  GetUrlInfoProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.url,
  }) : super.internal();

  final String url;

  @override
  Override overrideWith(
    FutureOr<URLInfo> Function(GetUrlInfoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetUrlInfoProvider._internal(
        (ref) => create(ref as GetUrlInfoRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        url: url,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<URLInfo> createElement() {
    return _GetUrlInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetUrlInfoProvider && other.url == url;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, url.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetUrlInfoRef on AutoDisposeFutureProviderRef<URLInfo> {
  /// The parameter `url` of this provider.
  String get url;
}

class _GetUrlInfoProviderElement
    extends AutoDisposeFutureProviderElement<URLInfo> with GetUrlInfoRef {
  _GetUrlInfoProviderElement(super.provider);

  @override
  String get url => (origin as GetUrlInfoProvider).url;
}

String _$addRecordingHash() => r'8abe30ed4bac5171045e2e4faad9cc2e57a22f73';

/// See also [addRecording].
@ProviderFor(addRecording)
const addRecordingProvider = AddRecordingFamily();

/// See also [addRecording].
class AddRecordingFamily extends Family<AsyncValue<RecordingInfo>> {
  /// See also [addRecording].
  const AddRecordingFamily();

  /// See also [addRecording].
  AddRecordingProvider call(
    String url,
  ) {
    return AddRecordingProvider(
      url,
    );
  }

  @override
  AddRecordingProvider getProviderOverride(
    covariant AddRecordingProvider provider,
  ) {
    return call(
      provider.url,
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
  String? get name => r'addRecordingProvider';
}

/// See also [addRecording].
class AddRecordingProvider extends AutoDisposeFutureProvider<RecordingInfo> {
  /// See also [addRecording].
  AddRecordingProvider(
    String url,
  ) : this._internal(
          (ref) => addRecording(
            ref as AddRecordingRef,
            url,
          ),
          from: addRecordingProvider,
          name: r'addRecordingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$addRecordingHash,
          dependencies: AddRecordingFamily._dependencies,
          allTransitiveDependencies:
              AddRecordingFamily._allTransitiveDependencies,
          url: url,
        );

  AddRecordingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.url,
  }) : super.internal();

  final String url;

  @override
  Override overrideWith(
    FutureOr<RecordingInfo> Function(AddRecordingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AddRecordingProvider._internal(
        (ref) => create(ref as AddRecordingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        url: url,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RecordingInfo> createElement() {
    return _AddRecordingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AddRecordingProvider && other.url == url;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, url.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AddRecordingRef on AutoDisposeFutureProviderRef<RecordingInfo> {
  /// The parameter `url` of this provider.
  String get url;
}

class _AddRecordingProviderElement
    extends AutoDisposeFutureProviderElement<RecordingInfo>
    with AddRecordingRef {
  _AddRecordingProviderElement(super.provider);

  @override
  String get url => (origin as AddRecordingProvider).url;
}

String _$listRecordingsHash() => r'a0db940b72cb2b6ae29bc73fe389f59e250524aa';

/// See also [listRecordings].
@ProviderFor(listRecordings)
const listRecordingsProvider = ListRecordingsFamily();

/// See also [listRecordings].
class ListRecordingsFamily extends Family<AsyncValue<List<RecordingInfo>>> {
  /// See also [listRecordings].
  const ListRecordingsFamily();

  /// See also [listRecordings].
  ListRecordingsProvider call(
    int offset,
    int limit, {
    String sortBy = "created_at",
  }) {
    return ListRecordingsProvider(
      offset,
      limit,
      sortBy: sortBy,
    );
  }

  @override
  ListRecordingsProvider getProviderOverride(
    covariant ListRecordingsProvider provider,
  ) {
    return call(
      provider.offset,
      provider.limit,
      sortBy: provider.sortBy,
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
  String? get name => r'listRecordingsProvider';
}

/// See also [listRecordings].
class ListRecordingsProvider
    extends AutoDisposeFutureProvider<List<RecordingInfo>> {
  /// See also [listRecordings].
  ListRecordingsProvider(
    int offset,
    int limit, {
    String sortBy = "created_at",
  }) : this._internal(
          (ref) => listRecordings(
            ref as ListRecordingsRef,
            offset,
            limit,
            sortBy: sortBy,
          ),
          from: listRecordingsProvider,
          name: r'listRecordingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$listRecordingsHash,
          dependencies: ListRecordingsFamily._dependencies,
          allTransitiveDependencies:
              ListRecordingsFamily._allTransitiveDependencies,
          offset: offset,
          limit: limit,
          sortBy: sortBy,
        );

  ListRecordingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.offset,
    required this.limit,
    required this.sortBy,
  }) : super.internal();

  final int offset;
  final int limit;
  final String sortBy;

  @override
  Override overrideWith(
    FutureOr<List<RecordingInfo>> Function(ListRecordingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ListRecordingsProvider._internal(
        (ref) => create(ref as ListRecordingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        offset: offset,
        limit: limit,
        sortBy: sortBy,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<RecordingInfo>> createElement() {
    return _ListRecordingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ListRecordingsProvider &&
        other.offset == offset &&
        other.limit == limit &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, sortBy.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ListRecordingsRef on AutoDisposeFutureProviderRef<List<RecordingInfo>> {
  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `sortBy` of this provider.
  String get sortBy;
}

class _ListRecordingsProviderElement
    extends AutoDisposeFutureProviderElement<List<RecordingInfo>>
    with ListRecordingsRef {
  _ListRecordingsProviderElement(super.provider);

  @override
  int get offset => (origin as ListRecordingsProvider).offset;
  @override
  int get limit => (origin as ListRecordingsProvider).limit;
  @override
  String get sortBy => (origin as ListRecordingsProvider).sortBy;
}

String _$getRecordingHash() => r'4583f11039ad747861fac52f14083615501bb45a';

/// See also [getRecording].
@ProviderFor(getRecording)
const getRecordingProvider = GetRecordingFamily();

/// See also [getRecording].
class GetRecordingFamily extends Family<AsyncValue<RecordingInfo>> {
  /// See also [getRecording].
  const GetRecordingFamily();

  /// See also [getRecording].
  GetRecordingProvider call(
    String id,
  ) {
    return GetRecordingProvider(
      id,
    );
  }

  @override
  GetRecordingProvider getProviderOverride(
    covariant GetRecordingProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'getRecordingProvider';
}

/// See also [getRecording].
class GetRecordingProvider extends AutoDisposeFutureProvider<RecordingInfo> {
  /// See also [getRecording].
  GetRecordingProvider(
    String id,
  ) : this._internal(
          (ref) => getRecording(
            ref as GetRecordingRef,
            id,
          ),
          from: getRecordingProvider,
          name: r'getRecordingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getRecordingHash,
          dependencies: GetRecordingFamily._dependencies,
          allTransitiveDependencies:
              GetRecordingFamily._allTransitiveDependencies,
          id: id,
        );

  GetRecordingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<RecordingInfo> Function(GetRecordingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetRecordingProvider._internal(
        (ref) => create(ref as GetRecordingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RecordingInfo> createElement() {
    return _GetRecordingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetRecordingProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetRecordingRef on AutoDisposeFutureProviderRef<RecordingInfo> {
  /// The parameter `id` of this provider.
  String get id;
}

class _GetRecordingProviderElement
    extends AutoDisposeFutureProviderElement<RecordingInfo>
    with GetRecordingRef {
  _GetRecordingProviderElement(super.provider);

  @override
  String get id => (origin as GetRecordingProvider).id;
}

String _$getDownloadHash() => r'406a352d6d31c916f257dcb847df7eecb5f8d3e6';

/// See also [getDownload].
@ProviderFor(getDownload)
const getDownloadProvider = GetDownloadFamily();

/// See also [getDownload].
class GetDownloadFamily extends Family<AsyncValue<Download>> {
  /// See also [getDownload].
  const GetDownloadFamily();

  /// See also [getDownload].
  GetDownloadProvider call(
    String id,
  ) {
    return GetDownloadProvider(
      id,
    );
  }

  @override
  GetDownloadProvider getProviderOverride(
    covariant GetDownloadProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'getDownloadProvider';
}

/// See also [getDownload].
class GetDownloadProvider extends AutoDisposeFutureProvider<Download> {
  /// See also [getDownload].
  GetDownloadProvider(
    String id,
  ) : this._internal(
          (ref) => getDownload(
            ref as GetDownloadRef,
            id,
          ),
          from: getDownloadProvider,
          name: r'getDownloadProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getDownloadHash,
          dependencies: GetDownloadFamily._dependencies,
          allTransitiveDependencies:
              GetDownloadFamily._allTransitiveDependencies,
          id: id,
        );

  GetDownloadProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Download> Function(GetDownloadRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetDownloadProvider._internal(
        (ref) => create(ref as GetDownloadRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Download> createElement() {
    return _GetDownloadProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetDownloadProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetDownloadRef on AutoDisposeFutureProviderRef<Download> {
  /// The parameter `id` of this provider.
  String get id;
}

class _GetDownloadProviderElement
    extends AutoDisposeFutureProviderElement<Download> with GetDownloadRef {
  _GetDownloadProviderElement(super.provider);

  @override
  String get id => (origin as GetDownloadProvider).id;
}

String _$listDownloadsHash() => r'3d8ac4ccfc026949e2b70495f8e4871a4907de57';

/// See also [listDownloads].
@ProviderFor(listDownloads)
const listDownloadsProvider = ListDownloadsFamily();

/// See also [listDownloads].
class ListDownloadsFamily extends Family<AsyncValue<List<Download>>> {
  /// See also [listDownloads].
  const ListDownloadsFamily();

  /// See also [listDownloads].
  ListDownloadsProvider call(
    String recordingId,
  ) {
    return ListDownloadsProvider(
      recordingId,
    );
  }

  @override
  ListDownloadsProvider getProviderOverride(
    covariant ListDownloadsProvider provider,
  ) {
    return call(
      provider.recordingId,
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
  String? get name => r'listDownloadsProvider';
}

/// See also [listDownloads].
class ListDownloadsProvider extends AutoDisposeFutureProvider<List<Download>> {
  /// See also [listDownloads].
  ListDownloadsProvider(
    String recordingId,
  ) : this._internal(
          (ref) => listDownloads(
            ref as ListDownloadsRef,
            recordingId,
          ),
          from: listDownloadsProvider,
          name: r'listDownloadsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$listDownloadsHash,
          dependencies: ListDownloadsFamily._dependencies,
          allTransitiveDependencies:
              ListDownloadsFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  ListDownloadsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recordingId,
  }) : super.internal();

  final String recordingId;

  @override
  Override overrideWith(
    FutureOr<List<Download>> Function(ListDownloadsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ListDownloadsProvider._internal(
        (ref) => create(ref as ListDownloadsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recordingId: recordingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Download>> createElement() {
    return _ListDownloadsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ListDownloadsProvider && other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ListDownloadsRef on AutoDisposeFutureProviderRef<List<Download>> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _ListDownloadsProviderElement
    extends AutoDisposeFutureProviderElement<List<Download>>
    with ListDownloadsRef {
  _ListDownloadsProviderElement(super.provider);

  @override
  String get recordingId => (origin as ListDownloadsProvider).recordingId;
}

String _$newDownloadHash() => r'a3fff48716e4aca74568da8737c82e477eba8c25';

/// See also [newDownload].
@ProviderFor(newDownload)
const newDownloadProvider = NewDownloadFamily();

/// See also [newDownload].
class NewDownloadFamily extends Family<AsyncValue<Download>> {
  /// See also [newDownload].
  const NewDownloadFamily();

  /// See also [newDownload].
  NewDownloadProvider call(
    String recordingId,
    String format,
  ) {
    return NewDownloadProvider(
      recordingId,
      format,
    );
  }

  @override
  NewDownloadProvider getProviderOverride(
    covariant NewDownloadProvider provider,
  ) {
    return call(
      provider.recordingId,
      provider.format,
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
  String? get name => r'newDownloadProvider';
}

/// See also [newDownload].
class NewDownloadProvider extends AutoDisposeFutureProvider<Download> {
  /// See also [newDownload].
  NewDownloadProvider(
    String recordingId,
    String format,
  ) : this._internal(
          (ref) => newDownload(
            ref as NewDownloadRef,
            recordingId,
            format,
          ),
          from: newDownloadProvider,
          name: r'newDownloadProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$newDownloadHash,
          dependencies: NewDownloadFamily._dependencies,
          allTransitiveDependencies:
              NewDownloadFamily._allTransitiveDependencies,
          recordingId: recordingId,
          format: format,
        );

  NewDownloadProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recordingId,
    required this.format,
  }) : super.internal();

  final String recordingId;
  final String format;

  @override
  Override overrideWith(
    FutureOr<Download> Function(NewDownloadRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NewDownloadProvider._internal(
        (ref) => create(ref as NewDownloadRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recordingId: recordingId,
        format: format,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Download> createElement() {
    return _NewDownloadProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NewDownloadProvider &&
        other.recordingId == recordingId &&
        other.format == format;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);
    hash = _SystemHash.combine(hash, format.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin NewDownloadRef on AutoDisposeFutureProviderRef<Download> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;

  /// The parameter `format` of this provider.
  String get format;
}

class _NewDownloadProviderElement
    extends AutoDisposeFutureProviderElement<Download> with NewDownloadRef {
  _NewDownloadProviderElement(super.provider);

  @override
  String get recordingId => (origin as NewDownloadProvider).recordingId;
  @override
  String get format => (origin as NewDownloadProvider).format;
}

String _$setHiddenHash() => r'754858ab0e1664eba3a82f1f6e9fbfdf6faa1fe4';

/// See also [setHidden].
@ProviderFor(setHidden)
const setHiddenProvider = SetHiddenFamily();

/// See also [setHidden].
class SetHiddenFamily extends Family<AsyncValue<void>> {
  /// See also [setHidden].
  const SetHiddenFamily();

  /// See also [setHidden].
  SetHiddenProvider call(
    String recordingId,
  ) {
    return SetHiddenProvider(
      recordingId,
    );
  }

  @override
  SetHiddenProvider getProviderOverride(
    covariant SetHiddenProvider provider,
  ) {
    return call(
      provider.recordingId,
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
  String? get name => r'setHiddenProvider';
}

/// See also [setHidden].
class SetHiddenProvider extends AutoDisposeFutureProvider<void> {
  /// See also [setHidden].
  SetHiddenProvider(
    String recordingId,
  ) : this._internal(
          (ref) => setHidden(
            ref as SetHiddenRef,
            recordingId,
          ),
          from: setHiddenProvider,
          name: r'setHiddenProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$setHiddenHash,
          dependencies: SetHiddenFamily._dependencies,
          allTransitiveDependencies: SetHiddenFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  SetHiddenProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recordingId,
  }) : super.internal();

  final String recordingId;

  @override
  Override overrideWith(
    FutureOr<void> Function(SetHiddenRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SetHiddenProvider._internal(
        (ref) => create(ref as SetHiddenRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recordingId: recordingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _SetHiddenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SetHiddenProvider && other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SetHiddenRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _SetHiddenProviderElement extends AutoDisposeFutureProviderElement<void>
    with SetHiddenRef {
  _SetHiddenProviderElement(super.provider);

  @override
  String get recordingId => (origin as SetHiddenProvider).recordingId;
}

String _$unsetHiddenHash() => r'4d2c3d73c2ab35a650613e56a8423929416889dc';

/// See also [unsetHidden].
@ProviderFor(unsetHidden)
const unsetHiddenProvider = UnsetHiddenFamily();

/// See also [unsetHidden].
class UnsetHiddenFamily extends Family<AsyncValue<void>> {
  /// See also [unsetHidden].
  const UnsetHiddenFamily();

  /// See also [unsetHidden].
  UnsetHiddenProvider call(
    String recordingId,
  ) {
    return UnsetHiddenProvider(
      recordingId,
    );
  }

  @override
  UnsetHiddenProvider getProviderOverride(
    covariant UnsetHiddenProvider provider,
  ) {
    return call(
      provider.recordingId,
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
  String? get name => r'unsetHiddenProvider';
}

/// See also [unsetHidden].
class UnsetHiddenProvider extends AutoDisposeFutureProvider<void> {
  /// See also [unsetHidden].
  UnsetHiddenProvider(
    String recordingId,
  ) : this._internal(
          (ref) => unsetHidden(
            ref as UnsetHiddenRef,
            recordingId,
          ),
          from: unsetHiddenProvider,
          name: r'unsetHiddenProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unsetHiddenHash,
          dependencies: UnsetHiddenFamily._dependencies,
          allTransitiveDependencies:
              UnsetHiddenFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  UnsetHiddenProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recordingId,
  }) : super.internal();

  final String recordingId;

  @override
  Override overrideWith(
    FutureOr<void> Function(UnsetHiddenRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnsetHiddenProvider._internal(
        (ref) => create(ref as UnsetHiddenRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recordingId: recordingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _UnsetHiddenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnsetHiddenProvider && other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UnsetHiddenRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _UnsetHiddenProviderElement extends AutoDisposeFutureProviderElement<void>
    with UnsetHiddenRef {
  _UnsetHiddenProviderElement(super.provider);

  @override
  String get recordingId => (origin as UnsetHiddenProvider).recordingId;
}

String _$setSeenHash() => r'f2a057ca7e608329dfb12198ba5e25977e0db437';

/// See also [setSeen].
@ProviderFor(setSeen)
const setSeenProvider = SetSeenFamily();

/// See also [setSeen].
class SetSeenFamily extends Family<AsyncValue<void>> {
  /// See also [setSeen].
  const SetSeenFamily();

  /// See also [setSeen].
  SetSeenProvider call(
    String recordingId,
  ) {
    return SetSeenProvider(
      recordingId,
    );
  }

  @override
  SetSeenProvider getProviderOverride(
    covariant SetSeenProvider provider,
  ) {
    return call(
      provider.recordingId,
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
  String? get name => r'setSeenProvider';
}

/// See also [setSeen].
class SetSeenProvider extends AutoDisposeFutureProvider<void> {
  /// See also [setSeen].
  SetSeenProvider(
    String recordingId,
  ) : this._internal(
          (ref) => setSeen(
            ref as SetSeenRef,
            recordingId,
          ),
          from: setSeenProvider,
          name: r'setSeenProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$setSeenHash,
          dependencies: SetSeenFamily._dependencies,
          allTransitiveDependencies: SetSeenFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  SetSeenProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recordingId,
  }) : super.internal();

  final String recordingId;

  @override
  Override overrideWith(
    FutureOr<void> Function(SetSeenRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SetSeenProvider._internal(
        (ref) => create(ref as SetSeenRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recordingId: recordingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _SetSeenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SetSeenProvider && other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SetSeenRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _SetSeenProviderElement extends AutoDisposeFutureProviderElement<void>
    with SetSeenRef {
  _SetSeenProviderElement(super.provider);

  @override
  String get recordingId => (origin as SetSeenProvider).recordingId;
}

String _$unsetSeenHash() => r'db231f2f7cd2fd34315a9cf1eda72bca8749306b';

/// See also [unsetSeen].
@ProviderFor(unsetSeen)
const unsetSeenProvider = UnsetSeenFamily();

/// See also [unsetSeen].
class UnsetSeenFamily extends Family<AsyncValue<void>> {
  /// See also [unsetSeen].
  const UnsetSeenFamily();

  /// See also [unsetSeen].
  UnsetSeenProvider call(
    String recordingId,
  ) {
    return UnsetSeenProvider(
      recordingId,
    );
  }

  @override
  UnsetSeenProvider getProviderOverride(
    covariant UnsetSeenProvider provider,
  ) {
    return call(
      provider.recordingId,
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
  String? get name => r'unsetSeenProvider';
}

/// See also [unsetSeen].
class UnsetSeenProvider extends AutoDisposeFutureProvider<void> {
  /// See also [unsetSeen].
  UnsetSeenProvider(
    String recordingId,
  ) : this._internal(
          (ref) => unsetSeen(
            ref as UnsetSeenRef,
            recordingId,
          ),
          from: unsetSeenProvider,
          name: r'unsetSeenProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unsetSeenHash,
          dependencies: UnsetSeenFamily._dependencies,
          allTransitiveDependencies: UnsetSeenFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  UnsetSeenProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recordingId,
  }) : super.internal();

  final String recordingId;

  @override
  Override overrideWith(
    FutureOr<void> Function(UnsetSeenRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnsetSeenProvider._internal(
        (ref) => create(ref as UnsetSeenRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recordingId: recordingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _UnsetSeenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnsetSeenProvider && other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UnsetSeenRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _UnsetSeenProviderElement extends AutoDisposeFutureProviderElement<void>
    with UnsetSeenRef {
  _UnsetSeenProviderElement(super.provider);

  @override
  String get recordingId => (origin as UnsetSeenProvider).recordingId;
}

String _$putPositionHash() => r'0eb640195347240dc48bff8fff96f9d59b52d6da';

/// See also [putPosition].
@ProviderFor(putPosition)
const putPositionProvider = PutPositionFamily();

/// See also [putPosition].
class PutPositionFamily extends Family<AsyncValue<void>> {
  /// See also [putPosition].
  const PutPositionFamily();

  /// See also [putPosition].
  PutPositionProvider call(
    String recordingId,
    Duration position,
    bool finished,
  ) {
    return PutPositionProvider(
      recordingId,
      position,
      finished,
    );
  }

  @override
  PutPositionProvider getProviderOverride(
    covariant PutPositionProvider provider,
  ) {
    return call(
      provider.recordingId,
      provider.position,
      provider.finished,
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
  String? get name => r'putPositionProvider';
}

/// See also [putPosition].
class PutPositionProvider extends AutoDisposeFutureProvider<void> {
  /// See also [putPosition].
  PutPositionProvider(
    String recordingId,
    Duration position,
    bool finished,
  ) : this._internal(
          (ref) => putPosition(
            ref as PutPositionRef,
            recordingId,
            position,
            finished,
          ),
          from: putPositionProvider,
          name: r'putPositionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$putPositionHash,
          dependencies: PutPositionFamily._dependencies,
          allTransitiveDependencies:
              PutPositionFamily._allTransitiveDependencies,
          recordingId: recordingId,
          position: position,
          finished: finished,
        );

  PutPositionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recordingId,
    required this.position,
    required this.finished,
  }) : super.internal();

  final String recordingId;
  final Duration position;
  final bool finished;

  @override
  Override overrideWith(
    FutureOr<void> Function(PutPositionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PutPositionProvider._internal(
        (ref) => create(ref as PutPositionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recordingId: recordingId,
        position: position,
        finished: finished,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _PutPositionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PutPositionProvider &&
        other.recordingId == recordingId &&
        other.position == position &&
        other.finished == finished;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);
    hash = _SystemHash.combine(hash, position.hashCode);
    hash = _SystemHash.combine(hash, finished.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PutPositionRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;

  /// The parameter `position` of this provider.
  Duration get position;

  /// The parameter `finished` of this provider.
  bool get finished;
}

class _PutPositionProviderElement extends AutoDisposeFutureProviderElement<void>
    with PutPositionRef {
  _PutPositionProviderElement(super.provider);

  @override
  String get recordingId => (origin as PutPositionProvider).recordingId;
  @override
  Duration get position => (origin as PutPositionProvider).position;
  @override
  bool get finished => (origin as PutPositionProvider).finished;
}

String _$getTenantHash() => r'ebbcaa7de7c89bcd2e1c5e1c20f441fec1c96447';

/// See also [getTenant].
@ProviderFor(getTenant)
final getTenantProvider = AutoDisposeFutureProvider<Tenant>.internal(
  getTenant,
  name: r'getTenantProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$getTenantHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GetTenantRef = AutoDisposeFutureProviderRef<Tenant>;
String _$deleteDownloadContentHash() =>
    r'4a512d40ae77d605158010748d48e95a0685665a';

/// See also [deleteDownloadContent].
@ProviderFor(deleteDownloadContent)
const deleteDownloadContentProvider = DeleteDownloadContentFamily();

/// See also [deleteDownloadContent].
class DeleteDownloadContentFamily extends Family<AsyncValue<void>> {
  /// See also [deleteDownloadContent].
  const DeleteDownloadContentFamily();

  /// See also [deleteDownloadContent].
  DeleteDownloadContentProvider call(
    String downloadId,
  ) {
    return DeleteDownloadContentProvider(
      downloadId,
    );
  }

  @override
  DeleteDownloadContentProvider getProviderOverride(
    covariant DeleteDownloadContentProvider provider,
  ) {
    return call(
      provider.downloadId,
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
  String? get name => r'deleteDownloadContentProvider';
}

/// See also [deleteDownloadContent].
class DeleteDownloadContentProvider extends AutoDisposeFutureProvider<void> {
  /// See also [deleteDownloadContent].
  DeleteDownloadContentProvider(
    String downloadId,
  ) : this._internal(
          (ref) => deleteDownloadContent(
            ref as DeleteDownloadContentRef,
            downloadId,
          ),
          from: deleteDownloadContentProvider,
          name: r'deleteDownloadContentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$deleteDownloadContentHash,
          dependencies: DeleteDownloadContentFamily._dependencies,
          allTransitiveDependencies:
              DeleteDownloadContentFamily._allTransitiveDependencies,
          downloadId: downloadId,
        );

  DeleteDownloadContentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.downloadId,
  }) : super.internal();

  final String downloadId;

  @override
  Override overrideWith(
    FutureOr<void> Function(DeleteDownloadContentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeleteDownloadContentProvider._internal(
        (ref) => create(ref as DeleteDownloadContentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        downloadId: downloadId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _DeleteDownloadContentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteDownloadContentProvider &&
        other.downloadId == downloadId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, downloadId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DeleteDownloadContentRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `downloadId` of this provider.
  String get downloadId;
}

class _DeleteDownloadContentProviderElement
    extends AutoDisposeFutureProviderElement<void>
    with DeleteDownloadContentRef {
  _DeleteDownloadContentProviderElement(super.provider);

  @override
  String get downloadId => (origin as DeleteDownloadContentProvider).downloadId;
}

String _$deleteRecordingDownloadsContentHash() =>
    r'05f7ac950a0fde295ec0f53a4763e3104253f6a6';

/// See also [deleteRecordingDownloadsContent].
@ProviderFor(deleteRecordingDownloadsContent)
const deleteRecordingDownloadsContentProvider =
    DeleteRecordingDownloadsContentFamily();

/// See also [deleteRecordingDownloadsContent].
class DeleteRecordingDownloadsContentFamily extends Family<AsyncValue<void>> {
  /// See also [deleteRecordingDownloadsContent].
  const DeleteRecordingDownloadsContentFamily();

  /// See also [deleteRecordingDownloadsContent].
  DeleteRecordingDownloadsContentProvider call(
    String recordingId,
  ) {
    return DeleteRecordingDownloadsContentProvider(
      recordingId,
    );
  }

  @override
  DeleteRecordingDownloadsContentProvider getProviderOverride(
    covariant DeleteRecordingDownloadsContentProvider provider,
  ) {
    return call(
      provider.recordingId,
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
  String? get name => r'deleteRecordingDownloadsContentProvider';
}

/// See also [deleteRecordingDownloadsContent].
class DeleteRecordingDownloadsContentProvider
    extends AutoDisposeFutureProvider<void> {
  /// See also [deleteRecordingDownloadsContent].
  DeleteRecordingDownloadsContentProvider(
    String recordingId,
  ) : this._internal(
          (ref) => deleteRecordingDownloadsContent(
            ref as DeleteRecordingDownloadsContentRef,
            recordingId,
          ),
          from: deleteRecordingDownloadsContentProvider,
          name: r'deleteRecordingDownloadsContentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$deleteRecordingDownloadsContentHash,
          dependencies: DeleteRecordingDownloadsContentFamily._dependencies,
          allTransitiveDependencies:
              DeleteRecordingDownloadsContentFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  DeleteRecordingDownloadsContentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recordingId,
  }) : super.internal();

  final String recordingId;

  @override
  Override overrideWith(
    FutureOr<void> Function(DeleteRecordingDownloadsContentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeleteRecordingDownloadsContentProvider._internal(
        (ref) => create(ref as DeleteRecordingDownloadsContentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recordingId: recordingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _DeleteRecordingDownloadsContentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteRecordingDownloadsContentProvider &&
        other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DeleteRecordingDownloadsContentRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _DeleteRecordingDownloadsContentProviderElement
    extends AutoDisposeFutureProviderElement<void>
    with DeleteRecordingDownloadsContentRef {
  _DeleteRecordingDownloadsContentProviderElement(super.provider);

  @override
  String get recordingId =>
      (origin as DeleteRecordingDownloadsContentProvider).recordingId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
