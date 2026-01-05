// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$boardRepositoryHash() => r'05543fd712ad7a3c141410545d8ee32a6a530a35';

/// Repository provider
///
/// Copied from [boardRepository].
@ProviderFor(boardRepository)
final boardRepositoryProvider = AutoDisposeProvider<BoardRepository>.internal(
  boardRepository,
  name: r'boardRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$boardRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BoardRepositoryRef = AutoDisposeProviderRef<BoardRepository>;
String _$boardsHash() => r'6779bf7ae1ae2538daaf16b52a23a9a2082705a7';

/// Provider for fetching all boards
///
/// Copied from [boards].
@ProviderFor(boards)
final boardsProvider = AutoDisposeFutureProvider<List<Board>>.internal(
  boards,
  name: r'boardsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$boardsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BoardsRef = AutoDisposeFutureProviderRef<List<Board>>;
String _$boardHash() => r'e41780bb10a506b77758451c943207a5361f1b1d';

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

/// Provider for a single board
///
/// Copied from [board].
@ProviderFor(board)
const boardProvider = BoardFamily();

/// Provider for a single board
///
/// Copied from [board].
class BoardFamily extends Family<AsyncValue<Board?>> {
  /// Provider for a single board
  ///
  /// Copied from [board].
  const BoardFamily();

  /// Provider for a single board
  ///
  /// Copied from [board].
  BoardProvider call(
    String boardId,
  ) {
    return BoardProvider(
      boardId,
    );
  }

  @override
  BoardProvider getProviderOverride(
    covariant BoardProvider provider,
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
  String? get name => r'boardProvider';
}

/// Provider for a single board
///
/// Copied from [board].
class BoardProvider extends AutoDisposeFutureProvider<Board?> {
  /// Provider for a single board
  ///
  /// Copied from [board].
  BoardProvider(
    String boardId,
  ) : this._internal(
          (ref) => board(
            ref as BoardRef,
            boardId,
          ),
          from: boardProvider,
          name: r'boardProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$boardHash,
          dependencies: BoardFamily._dependencies,
          allTransitiveDependencies: BoardFamily._allTransitiveDependencies,
          boardId: boardId,
        );

  BoardProvider._internal(
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
    FutureOr<Board?> Function(BoardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BoardProvider._internal(
        (ref) => create(ref as BoardRef),
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
  AutoDisposeFutureProviderElement<Board?> createElement() {
    return _BoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BoardProvider && other.boardId == boardId;
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
mixin BoardRef on AutoDisposeFutureProviderRef<Board?> {
  /// The parameter `boardId` of this provider.
  String get boardId;
}

class _BoardProviderElement extends AutoDisposeFutureProviderElement<Board?>
    with BoardRef {
  _BoardProviderElement(super.provider);

  @override
  String get boardId => (origin as BoardProvider).boardId;
}

String _$boardControllerHash() => r'9a6f7adf607d56f23598c21fb1190cbbfc46c899';

/// Controller for board operations
///
/// Copied from [BoardController].
@ProviderFor(BoardController)
final boardControllerProvider =
    AutoDisposeAsyncNotifierProvider<BoardController, void>.internal(
  BoardController.new,
  name: r'boardControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$boardControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BoardController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
