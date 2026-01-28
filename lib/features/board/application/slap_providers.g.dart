// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slap_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$slapRepositoryHash() => r'c2a97b9200ffb07b1c51ff66ef261790e3fea783';

/// Repository provider
///
/// Copied from [slapRepository].
@ProviderFor(slapRepository)
final slapRepositoryProvider = AutoDisposeProvider<SlapRepository>.internal(
  slapRepository,
  name: r'slapRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$slapRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SlapRepositoryRef = AutoDisposeProviderRef<SlapRepository>;
String _$aiMergeServiceHash() => r'11b3feb05b0f4531b3813b1d7f4bf7b149295c77';

/// AI merge service provider
///
/// Copied from [aiMergeService].
@ProviderFor(aiMergeService)
final aiMergeServiceProvider = AutoDisposeProvider<AiMergeService>.internal(
  aiMergeService,
  name: r'aiMergeServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiMergeServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AiMergeServiceRef = AutoDisposeProviderRef<AiMergeService>;
String _$slapsStreamHash() => r'6147d1e2323c9d104cf0553cdd630edf34141c35';

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

/// Stream provider for realtime slaps on a board
///
/// Copied from [slapsStream].
@ProviderFor(slapsStream)
const slapsStreamProvider = SlapsStreamFamily();

/// Stream provider for realtime slaps on a board
///
/// Copied from [slapsStream].
class SlapsStreamFamily extends Family<AsyncValue<List<Slap>>> {
  /// Stream provider for realtime slaps on a board
  ///
  /// Copied from [slapsStream].
  const SlapsStreamFamily();

  /// Stream provider for realtime slaps on a board
  ///
  /// Copied from [slapsStream].
  SlapsStreamProvider call(
    String boardId,
  ) {
    return SlapsStreamProvider(
      boardId,
    );
  }

  @override
  SlapsStreamProvider getProviderOverride(
    covariant SlapsStreamProvider provider,
  ) {
    return call(
      provider.boardId,
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
  String? get name => r'slapsStreamProvider';
}

/// Stream provider for realtime slaps on a board
///
/// Copied from [slapsStream].
class SlapsStreamProvider extends AutoDisposeStreamProvider<List<Slap>> {
  /// Stream provider for realtime slaps on a board
  ///
  /// Copied from [slapsStream].
  SlapsStreamProvider(
    String boardId,
  ) : this._internal(
          (ref) => slapsStream(
            ref as SlapsStreamRef,
            boardId,
          ),
          from: slapsStreamProvider,
          name: r'slapsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$slapsStreamHash,
          dependencies: SlapsStreamFamily._dependencies,
          allTransitiveDependencies:
              SlapsStreamFamily._allTransitiveDependencies,
          boardId: boardId,
        );

  SlapsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.boardId,
  }) : super.internal();

  final String boardId;

  @override
  Override overrideWith(
    Stream<List<Slap>> Function(SlapsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SlapsStreamProvider._internal(
        (ref) => create(ref as SlapsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        boardId: boardId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Slap>> createElement() {
    return _SlapsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SlapsStreamProvider && other.boardId == boardId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, boardId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SlapsStreamRef on AutoDisposeStreamProviderRef<List<Slap>> {
  /// The parameter `boardId` of this provider.
  String get boardId;
}

class _SlapsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<Slap>> with SlapsStreamRef {
  _SlapsStreamProviderElement(super.provider);

  @override
  String get boardId => (origin as SlapsStreamProvider).boardId;
}

String _$slapControllerHash() => r'adb0992a4e826d3f56000ad516ac7f620827a533';

/// Controller for slap operations
///
/// Copied from [SlapController].
@ProviderFor(SlapController)
final slapControllerProvider =
    AutoDisposeAsyncNotifierProvider<SlapController, void>.internal(
  SlapController.new,
  name: r'slapControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$slapControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SlapController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
