// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recordingNotifierHash() => r'2a68aa67fba10127667be307a2e65737eb03108f';

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

abstract class _$RecordingNotifier
    extends BuildlessAutoDisposeAsyncNotifier<RecordingInfo> {
  late final String recordingId;

  FutureOr<RecordingInfo> build(
    String recordingId,
  );
}

/// See also [RecordingNotifier].
@ProviderFor(RecordingNotifier)
const recordingNotifierProvider = RecordingNotifierFamily();

/// See also [RecordingNotifier].
class RecordingNotifierFamily extends Family<AsyncValue<RecordingInfo>> {
  /// See also [RecordingNotifier].
  const RecordingNotifierFamily();

  /// See also [RecordingNotifier].
  RecordingNotifierProvider call(
    String recordingId,
  ) {
    return RecordingNotifierProvider(
      recordingId,
    );
  }

  @override
  RecordingNotifierProvider getProviderOverride(
    covariant RecordingNotifierProvider provider,
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
  String? get name => r'recordingNotifierProvider';
}

/// See also [RecordingNotifier].
class RecordingNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    RecordingNotifier, RecordingInfo> {
  /// See also [RecordingNotifier].
  RecordingNotifierProvider(
    String recordingId,
  ) : this._internal(
          () => RecordingNotifier()..recordingId = recordingId,
          from: recordingNotifierProvider,
          name: r'recordingNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recordingNotifierHash,
          dependencies: RecordingNotifierFamily._dependencies,
          allTransitiveDependencies:
              RecordingNotifierFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  RecordingNotifierProvider._internal(
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
  FutureOr<RecordingInfo> runNotifierBuild(
    covariant RecordingNotifier notifier,
  ) {
    return notifier.build(
      recordingId,
    );
  }

  @override
  Override overrideWith(RecordingNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: RecordingNotifierProvider._internal(
        () => create()..recordingId = recordingId,
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
  AutoDisposeAsyncNotifierProviderElement<RecordingNotifier, RecordingInfo>
      createElement() {
    return _RecordingNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecordingNotifierProvider &&
        other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RecordingNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<RecordingInfo> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _RecordingNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RecordingNotifier,
        RecordingInfo> with RecordingNotifierRef {
  _RecordingNotifierProviderElement(super.provider);

  @override
  String get recordingId => (origin as RecordingNotifierProvider).recordingId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
