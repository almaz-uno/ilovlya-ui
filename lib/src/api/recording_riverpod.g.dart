// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$updateRecordingHash() => r'e037967f697bb98cf75d828ce0417bfe38e81857';

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

/// See also [updateRecording].
@ProviderFor(updateRecording)
const updateRecordingProvider = UpdateRecordingFamily();

/// See also [updateRecording].
class UpdateRecordingFamily extends Family<AsyncValue<RecordingInfo>> {
  /// See also [updateRecording].
  const UpdateRecordingFamily();

  /// See also [updateRecording].
  UpdateRecordingProvider call(
    String recordingId,
  ) {
    return UpdateRecordingProvider(
      recordingId,
    );
  }

  @override
  UpdateRecordingProvider getProviderOverride(
    covariant UpdateRecordingProvider provider,
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
  String? get name => r'updateRecordingProvider';
}

/// See also [updateRecording].
class UpdateRecordingProvider extends AutoDisposeFutureProvider<RecordingInfo> {
  /// See also [updateRecording].
  UpdateRecordingProvider(
    String recordingId,
  ) : this._internal(
          (ref) => updateRecording(
            ref as UpdateRecordingRef,
            recordingId,
          ),
          from: updateRecordingProvider,
          name: r'updateRecordingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$updateRecordingHash,
          dependencies: UpdateRecordingFamily._dependencies,
          allTransitiveDependencies:
              UpdateRecordingFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  UpdateRecordingProvider._internal(
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
    FutureOr<RecordingInfo> Function(UpdateRecordingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpdateRecordingProvider._internal(
        (ref) => create(ref as UpdateRecordingRef),
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
  AutoDisposeFutureProviderElement<RecordingInfo> createElement() {
    return _UpdateRecordingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdateRecordingProvider && other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UpdateRecordingRef on AutoDisposeFutureProviderRef<RecordingInfo> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _UpdateRecordingProviderElement
    extends AutoDisposeFutureProviderElement<RecordingInfo>
    with UpdateRecordingRef {
  _UpdateRecordingProviderElement(super.provider);

  @override
  String get recordingId => (origin as UpdateRecordingProvider).recordingId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
