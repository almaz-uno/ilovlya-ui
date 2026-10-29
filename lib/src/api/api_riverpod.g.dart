// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getUrlInfo)
final getUrlInfoProvider = GetUrlInfoFamily._();

final class GetUrlInfoProvider
    extends $FunctionalProvider<AsyncValue<URLInfo>, URLInfo, FutureOr<URLInfo>>
    with $FutureModifier<URLInfo>, $FutureProvider<URLInfo> {
  GetUrlInfoProvider._({
    required GetUrlInfoFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getUrlInfoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getUrlInfoHash();

  @override
  String toString() {
    return r'getUrlInfoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<URLInfo> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<URLInfo> create(Ref ref) {
    final argument = this.argument as String;
    return getUrlInfo(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetUrlInfoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getUrlInfoHash() => r'd1c6901f5a6d21d0bdcffb0e14a004bde83641f9';

final class GetUrlInfoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<URLInfo>, String> {
  GetUrlInfoFamily._()
    : super(
        retry: null,
        name: r'getUrlInfoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetUrlInfoProvider call(String url) =>
      GetUrlInfoProvider._(argument: url, from: this);

  @override
  String toString() => r'getUrlInfoProvider';
}

@ProviderFor(addRecording)
final addRecordingProvider = AddRecordingFamily._();

final class AddRecordingProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecordingInfo>,
          RecordingInfo,
          FutureOr<RecordingInfo>
        >
    with $FutureModifier<RecordingInfo>, $FutureProvider<RecordingInfo> {
  AddRecordingProvider._({
    required AddRecordingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'addRecordingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$addRecordingHash();

  @override
  String toString() {
    return r'addRecordingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RecordingInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecordingInfo> create(Ref ref) {
    final argument = this.argument as String;
    return addRecording(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AddRecordingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$addRecordingHash() => r'1e6ef2f1981b7590492d1ddc6cf6308a0a47bc08';

final class AddRecordingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RecordingInfo>, String> {
  AddRecordingFamily._()
    : super(
        retry: null,
        name: r'addRecordingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AddRecordingProvider call(String url) =>
      AddRecordingProvider._(argument: url, from: this);

  @override
  String toString() => r'addRecordingProvider';
}

@ProviderFor(listRecordings)
final listRecordingsProvider = ListRecordingsFamily._();

final class ListRecordingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecordingInfo>>,
          List<RecordingInfo>,
          FutureOr<List<RecordingInfo>>
        >
    with
        $FutureModifier<List<RecordingInfo>>,
        $FutureProvider<List<RecordingInfo>> {
  ListRecordingsProvider._({
    required ListRecordingsFamily super.from,
    required (int, int, {String sortBy}) super.argument,
  }) : super(
         retry: null,
         name: r'listRecordingsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listRecordingsHash();

  @override
  String toString() {
    return r'listRecordingsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<RecordingInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RecordingInfo>> create(Ref ref) {
    final argument = this.argument as (int, int, {String sortBy});
    return listRecordings(
      ref,
      argument.$1,
      argument.$2,
      sortBy: argument.sortBy,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ListRecordingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listRecordingsHash() => r'cab404bf5bfcb1b81acf988d0fbf8a36ff944a4c';

final class ListRecordingsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<RecordingInfo>>,
          (int, int, {String sortBy})
        > {
  ListRecordingsFamily._()
    : super(
        retry: null,
        name: r'listRecordingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ListRecordingsProvider call(
    int offset,
    int limit, {
    String sortBy = 'created_at',
  }) => ListRecordingsProvider._(
    argument: (offset, limit, sortBy: sortBy),
    from: this,
  );

  @override
  String toString() => r'listRecordingsProvider';
}

@ProviderFor(getRecording)
final getRecordingProvider = GetRecordingFamily._();

final class GetRecordingProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecordingInfo>,
          RecordingInfo,
          FutureOr<RecordingInfo>
        >
    with $FutureModifier<RecordingInfo>, $FutureProvider<RecordingInfo> {
  GetRecordingProvider._({
    required GetRecordingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getRecordingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getRecordingHash();

  @override
  String toString() {
    return r'getRecordingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RecordingInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecordingInfo> create(Ref ref) {
    final argument = this.argument as String;
    return getRecording(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetRecordingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getRecordingHash() => r'791f3fbb21acca3e545ab4e75738a36304a35da6';

final class GetRecordingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RecordingInfo>, String> {
  GetRecordingFamily._()
    : super(
        retry: null,
        name: r'getRecordingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetRecordingProvider call(String id) =>
      GetRecordingProvider._(argument: id, from: this);

  @override
  String toString() => r'getRecordingProvider';
}

@ProviderFor(getDownload)
final getDownloadProvider = GetDownloadFamily._();

final class GetDownloadProvider
    extends
        $FunctionalProvider<AsyncValue<Download>, Download, FutureOr<Download>>
    with $FutureModifier<Download>, $FutureProvider<Download> {
  GetDownloadProvider._({
    required GetDownloadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getDownloadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getDownloadHash();

  @override
  String toString() {
    return r'getDownloadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Download> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Download> create(Ref ref) {
    final argument = this.argument as String;
    return getDownload(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetDownloadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getDownloadHash() => r'9199c7cd77cb15a76b066875c306d50a83fd72ee';

final class GetDownloadFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Download>, String> {
  GetDownloadFamily._()
    : super(
        retry: null,
        name: r'getDownloadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetDownloadProvider call(String id) =>
      GetDownloadProvider._(argument: id, from: this);

  @override
  String toString() => r'getDownloadProvider';
}

@ProviderFor(listDownloads)
final listDownloadsProvider = ListDownloadsFamily._();

final class ListDownloadsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Download>>,
          List<Download>,
          FutureOr<List<Download>>
        >
    with $FutureModifier<List<Download>>, $FutureProvider<List<Download>> {
  ListDownloadsProvider._({
    required ListDownloadsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listDownloadsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listDownloadsHash();

  @override
  String toString() {
    return r'listDownloadsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Download>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Download>> create(Ref ref) {
    final argument = this.argument as String;
    return listDownloads(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ListDownloadsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listDownloadsHash() => r'95164b5f10bb9bcf6d4509ecf5f35717887e93a5';

final class ListDownloadsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Download>>, String> {
  ListDownloadsFamily._()
    : super(
        retry: null,
        name: r'listDownloadsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ListDownloadsProvider call(String recordingId) =>
      ListDownloadsProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'listDownloadsProvider';
}

@ProviderFor(newDownload)
final newDownloadProvider = NewDownloadFamily._();

final class NewDownloadProvider
    extends
        $FunctionalProvider<AsyncValue<Download>, Download, FutureOr<Download>>
    with $FutureModifier<Download>, $FutureProvider<Download> {
  NewDownloadProvider._({
    required NewDownloadFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'newDownloadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$newDownloadHash();

  @override
  String toString() {
    return r'newDownloadProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Download> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Download> create(Ref ref) {
    final argument = this.argument as (String, String);
    return newDownload(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is NewDownloadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$newDownloadHash() => r'77f70995b8a09815d72fbe53ef69756020825a62';

final class NewDownloadFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Download>, (String, String)> {
  NewDownloadFamily._()
    : super(
        retry: null,
        name: r'newDownloadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NewDownloadProvider call(String recordingId, String format) =>
      NewDownloadProvider._(argument: (recordingId, format), from: this);

  @override
  String toString() => r'newDownloadProvider';
}

@ProviderFor(setHidden)
final setHiddenProvider = SetHiddenFamily._();

final class SetHiddenProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SetHiddenProvider._({
    required SetHiddenFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'setHiddenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$setHiddenHash();

  @override
  String toString() {
    return r'setHiddenProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return setHidden(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SetHiddenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$setHiddenHash() => r'0eb291e3fa19a3f6db26743a7a3f83038ae27d8c';

final class SetHiddenFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  SetHiddenFamily._()
    : super(
        retry: null,
        name: r'setHiddenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SetHiddenProvider call(String recordingId) =>
      SetHiddenProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'setHiddenProvider';
}

@ProviderFor(unsetHidden)
final unsetHiddenProvider = UnsetHiddenFamily._();

final class UnsetHiddenProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  UnsetHiddenProvider._({
    required UnsetHiddenFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'unsetHiddenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$unsetHiddenHash();

  @override
  String toString() {
    return r'unsetHiddenProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return unsetHidden(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UnsetHiddenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unsetHiddenHash() => r'33f4cf41b3c690552d6e48022d52f9f8e53ab69e';

final class UnsetHiddenFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  UnsetHiddenFamily._()
    : super(
        retry: null,
        name: r'unsetHiddenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UnsetHiddenProvider call(String recordingId) =>
      UnsetHiddenProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'unsetHiddenProvider';
}

@ProviderFor(setSeen)
final setSeenProvider = SetSeenFamily._();

final class SetSeenProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SetSeenProvider._({
    required SetSeenFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'setSeenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$setSeenHash();

  @override
  String toString() {
    return r'setSeenProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return setSeen(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SetSeenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$setSeenHash() => r'7722e4e3afbc89396d61c67f6955ce465d302e4c';

final class SetSeenFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  SetSeenFamily._()
    : super(
        retry: null,
        name: r'setSeenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SetSeenProvider call(String recordingId) =>
      SetSeenProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'setSeenProvider';
}

@ProviderFor(unsetSeen)
final unsetSeenProvider = UnsetSeenFamily._();

final class UnsetSeenProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  UnsetSeenProvider._({
    required UnsetSeenFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'unsetSeenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$unsetSeenHash();

  @override
  String toString() {
    return r'unsetSeenProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return unsetSeen(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UnsetSeenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unsetSeenHash() => r'4ffbb5eefb54895daa6828ac93d573f895035937';

final class UnsetSeenFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  UnsetSeenFamily._()
    : super(
        retry: null,
        name: r'unsetSeenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UnsetSeenProvider call(String recordingId) =>
      UnsetSeenProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'unsetSeenProvider';
}

@ProviderFor(putPosition)
final putPositionProvider = PutPositionFamily._();

final class PutPositionProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  PutPositionProvider._({
    required PutPositionFamily super.from,
    required (String, Duration, bool) super.argument,
  }) : super(
         retry: null,
         name: r'putPositionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$putPositionHash();

  @override
  String toString() {
    return r'putPositionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (String, Duration, bool);
    return putPosition(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is PutPositionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$putPositionHash() => r'93a3d8a18d15ed2a4e6cee179c92f6e93ff14970';

final class PutPositionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (String, Duration, bool)> {
  PutPositionFamily._()
    : super(
        retry: null,
        name: r'putPositionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PutPositionProvider call(
    String recordingId,
    Duration position,
    bool finished,
  ) => PutPositionProvider._(
    argument: (recordingId, position, finished),
    from: this,
  );

  @override
  String toString() => r'putPositionProvider';
}

@ProviderFor(getTenant)
final getTenantProvider = GetTenantProvider._();

final class GetTenantProvider
    extends $FunctionalProvider<AsyncValue<Tenant>, Tenant, FutureOr<Tenant>>
    with $FutureModifier<Tenant>, $FutureProvider<Tenant> {
  GetTenantProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getTenantProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getTenantHash();

  @$internal
  @override
  $FutureProviderElement<Tenant> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Tenant> create(Ref ref) {
    return getTenant(ref);
  }
}

String _$getTenantHash() => r'6f9949ff4dcd1860b81715b966bab7b4eaee40ac';

@ProviderFor(deleteDownloadContent)
final deleteDownloadContentProvider = DeleteDownloadContentFamily._();

final class DeleteDownloadContentProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  DeleteDownloadContentProvider._({
    required DeleteDownloadContentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deleteDownloadContentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deleteDownloadContentHash();

  @override
  String toString() {
    return r'deleteDownloadContentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return deleteDownloadContent(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteDownloadContentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deleteDownloadContentHash() =>
    r'8258ca27eb4bacb46385e8f74f65c47b4379714f';

final class DeleteDownloadContentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  DeleteDownloadContentFamily._()
    : super(
        retry: null,
        name: r'deleteDownloadContentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DeleteDownloadContentProvider call(String downloadId) =>
      DeleteDownloadContentProvider._(argument: downloadId, from: this);

  @override
  String toString() => r'deleteDownloadContentProvider';
}

@ProviderFor(deleteRecordingDownloadsContent)
final deleteRecordingDownloadsContentProvider =
    DeleteRecordingDownloadsContentFamily._();

final class DeleteRecordingDownloadsContentProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  DeleteRecordingDownloadsContentProvider._({
    required DeleteRecordingDownloadsContentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deleteRecordingDownloadsContentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deleteRecordingDownloadsContentHash();

  @override
  String toString() {
    return r'deleteRecordingDownloadsContentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return deleteRecordingDownloadsContent(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteRecordingDownloadsContentProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deleteRecordingDownloadsContentHash() =>
    r'a034e3aca50b120af162f547494977e93c4064d3';

final class DeleteRecordingDownloadsContentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  DeleteRecordingDownloadsContentFamily._()
    : super(
        retry: null,
        name: r'deleteRecordingDownloadsContentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DeleteRecordingDownloadsContentProvider call(String recordingId) =>
      DeleteRecordingDownloadsContentProvider._(
        argument: recordingId,
        from: this,
      );

  @override
  String toString() => r'deleteRecordingDownloadsContentProvider';
}
