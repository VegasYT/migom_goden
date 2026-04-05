// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_item_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$catalogItemDetailHash() => r'catalog_item_detail_api_v1';

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

/// See also [catalogItemDetail].
@ProviderFor(catalogItemDetail)
const catalogItemDetailProvider = CatalogItemDetailFamily();

/// See also [catalogItemDetail].
class CatalogItemDetailFamily extends Family<AsyncValue<CatalogItemDetail?>> {
  /// See also [catalogItemDetail].
  const CatalogItemDetailFamily();

  /// See also [catalogItemDetail].
  CatalogItemDetailProvider call(int itemId) {
    return CatalogItemDetailProvider(itemId);
  }

  @override
  CatalogItemDetailProvider getProviderOverride(
    covariant CatalogItemDetailProvider provider,
  ) {
    return call(provider.itemId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'catalogItemDetailProvider';
}

/// See also [catalogItemDetail].
class CatalogItemDetailProvider
    extends AutoDisposeFutureProvider<CatalogItemDetail?> {
  /// See also [catalogItemDetail].
  CatalogItemDetailProvider(int itemId)
    : this._internal(
        (ref) => catalogItemDetail(ref as CatalogItemDetailRef, itemId),
        from: catalogItemDetailProvider,
        name: r'catalogItemDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$catalogItemDetailHash,
        dependencies: CatalogItemDetailFamily._dependencies,
        allTransitiveDependencies:
            CatalogItemDetailFamily._allTransitiveDependencies,
        itemId: itemId,
      );

  CatalogItemDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.itemId,
  }) : super.internal();

  final int itemId;

  @override
  Override overrideWith(
    FutureOr<CatalogItemDetail?> Function(CatalogItemDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CatalogItemDetailProvider._internal(
        (ref) => create(ref as CatalogItemDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        itemId: itemId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<CatalogItemDetail?> createElement() {
    return _CatalogItemDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CatalogItemDetailProvider && other.itemId == itemId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, itemId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CatalogItemDetailRef on AutoDisposeFutureProviderRef<CatalogItemDetail?> {
  /// The parameter `itemId` of this provider.
  int get itemId;
}

class _CatalogItemDetailProviderElement
    extends AutoDisposeFutureProviderElement<CatalogItemDetail?>
    with CatalogItemDetailRef {
  _CatalogItemDetailProviderElement(super.provider);

  @override
  int get itemId => (origin as CatalogItemDetailProvider).itemId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
