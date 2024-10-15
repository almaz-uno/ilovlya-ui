// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloads_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$downloadsNotifierHash() => r'be2a4b205b154590dd202908c2fbbd2cffb92665';

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

abstract class _$DownloadsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Download>> {
  late final String recordingId;

  FutureOr<List<Download>> build(
    String recordingId,
  );
}

/// See also [DownloadsNotifier].
@ProviderFor(DownloadsNotifier)
const downloadsNotifierProvider = DownloadsNotifierFamily();

/// See also [DownloadsNotifier].
class DownloadsNotifierFamily extends Family<AsyncValue<List<Download>>> {
  /// See also [DownloadsNotifier].
  const DownloadsNotifierFamily();

  /// See also [DownloadsNotifier].
  DownloadsNotifierProvider call(
    String recordingId,
  ) {
    return DownloadsNotifierProvider(
      recordingId,
    );
  }

  @override
  DownloadsNotifierProvider getProviderOverride(
    covariant DownloadsNotifierProvider provider,
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
  String? get name => r'downloadsNotifierProvider';
}

/// See also [DownloadsNotifier].
class DownloadsNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    DownloadsNotifier, List<Download>> {
  /// See also [DownloadsNotifier].
  DownloadsNotifierProvider(
    String recordingId,
  ) : this._internal(
          () => DownloadsNotifier()..recordingId = recordingId,
          from: downloadsNotifierProvider,
          name: r'downloadsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$downloadsNotifierHash,
          dependencies: DownloadsNotifierFamily._dependencies,
          allTransitiveDependencies:
              DownloadsNotifierFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  DownloadsNotifierProvider._internal(
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
  FutureOr<List<Download>> runNotifierBuild(
    covariant DownloadsNotifier notifier,
  ) {
    return notifier.build(
      recordingId,
    );
  }

  @override
  Override overrideWith(DownloadsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: DownloadsNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<DownloadsNotifier, List<Download>>
      createElement() {
    return _DownloadsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DownloadsNotifierProvider &&
        other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DownloadsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<Download>> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _DownloadsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<DownloadsNotifier,
        List<Download>> with DownloadsNotifierRef {
  _DownloadsNotifierProviderElement(super.provider);

  @override
  String get recordingId => (origin as DownloadsNotifierProvider).recordingId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
