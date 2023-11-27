// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getUrlInfoHash() => r'add44f790e785e7c49225c2337dd4dbd775044e3';

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
    String serverBaseURL,
    String url,
  ) {
    return GetUrlInfoProvider(
      serverBaseURL,
      url,
    );
  }

  @override
  GetUrlInfoProvider getProviderOverride(
    covariant GetUrlInfoProvider provider,
  ) {
    return call(
      provider.serverBaseURL,
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
    String serverBaseURL,
    String url,
  ) : this._internal(
          (ref) => getUrlInfo(
            ref as GetUrlInfoRef,
            serverBaseURL,
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
          serverBaseURL: serverBaseURL,
          url: url,
        );

  GetUrlInfoProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.serverBaseURL,
    required this.url,
  }) : super.internal();

  final String serverBaseURL;
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
        serverBaseURL: serverBaseURL,
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
    return other is GetUrlInfoProvider &&
        other.serverBaseURL == serverBaseURL &&
        other.url == url;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, serverBaseURL.hashCode);
    hash = _SystemHash.combine(hash, url.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetUrlInfoRef on AutoDisposeFutureProviderRef<URLInfo> {
  /// The parameter `serverBaseURL` of this provider.
  String get serverBaseURL;

  /// The parameter `url` of this provider.
  String get url;
}

class _GetUrlInfoProviderElement
    extends AutoDisposeFutureProviderElement<URLInfo> with GetUrlInfoRef {
  _GetUrlInfoProviderElement(super.provider);

  @override
  String get serverBaseURL => (origin as GetUrlInfoProvider).serverBaseURL;
  @override
  String get url => (origin as GetUrlInfoProvider).url;
}

String _$addRecordingHash() => r'16139fd27eac7c185740cf430a9e163a26dd59bb';

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

String _$listRecordingsHash() => r'a39766bfd2f6973fed2d60f63a4de4fa05208bf3';

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

String _$getRecordingHash() => r'de9eec516eb60d2de1b25d8d49202635b08e2ac6';

/// See also [getRecording].
@ProviderFor(getRecording)
const getRecordingProvider = GetRecordingFamily();

/// See also [getRecording].
class GetRecordingFamily extends Family<AsyncValue<RecordingInfo>> {
  /// See also [getRecording].
  const GetRecordingFamily();

  /// See also [getRecording].
  GetRecordingProvider call(
    String id, {
    bool updateFormats = true,
  }) {
    return GetRecordingProvider(
      id,
      updateFormats: updateFormats,
    );
  }

  @override
  GetRecordingProvider getProviderOverride(
    covariant GetRecordingProvider provider,
  ) {
    return call(
      provider.id,
      updateFormats: provider.updateFormats,
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
    String id, {
    bool updateFormats = true,
  }) : this._internal(
          (ref) => getRecording(
            ref as GetRecordingRef,
            id,
            updateFormats: updateFormats,
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
          updateFormats: updateFormats,
        );

  GetRecordingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
    required this.updateFormats,
  }) : super.internal();

  final String id;
  final bool updateFormats;

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
        updateFormats: updateFormats,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RecordingInfo> createElement() {
    return _GetRecordingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetRecordingProvider &&
        other.id == id &&
        other.updateFormats == updateFormats;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);
    hash = _SystemHash.combine(hash, updateFormats.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetRecordingRef on AutoDisposeFutureProviderRef<RecordingInfo> {
  /// The parameter `id` of this provider.
  String get id;

  /// The parameter `updateFormats` of this provider.
  bool get updateFormats;
}

class _GetRecordingProviderElement
    extends AutoDisposeFutureProviderElement<RecordingInfo>
    with GetRecordingRef {
  _GetRecordingProviderElement(super.provider);

  @override
  String get id => (origin as GetRecordingProvider).id;
  @override
  bool get updateFormats => (origin as GetRecordingProvider).updateFormats;
}

String _$listDownloadsHash() => r'47df7abb5bd4d5052cd1247e21902eb1011f25af';

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

String _$newDownloadHash() => r'16d4fd9ae9fd95c9bd1426a956834b8329fa2196';

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

String _$setHiddenHash() => r'332983d9cb66506602273d526d5344c62b44e73a';

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

String _$unsetHiddenHash() => r'b12d3cd574709f70ac1d073e506054e9253a2769';

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

String _$setSeenHash() => r'3256cafa032c5e0297abe0b1282d36eb84c0d089';

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

String _$unsetSeenHash() => r'd14715321abd9fe573fb384c0a78f5d484d472c7';

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

String _$putPositionHash() => r'b9a5bb13349fb43243ea4d099d99d9d3cae1e62e';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
