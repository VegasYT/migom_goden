// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileHash() => r'profile_api_v1';

/// See also [profile].
@ProviderFor(profile)
final profileProvider = AutoDisposeFutureProvider<ProfileModel>.internal(
  profile,
  name: r'profileProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$profileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRef = AutoDisposeFutureProviderRef<ProfileModel>;

String _$profileOrdersHash() => r'profile_orders_v1';

/// See also [profileOrders].
@ProviderFor(profileOrders)
final profileOrdersProvider =
    AutoDisposeProvider<List<ProfileOrderItem>>.internal(
      profileOrders,
      name: r'profileOrdersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileOrdersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileOrdersRef = AutoDisposeProviderRef<List<ProfileOrderItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
