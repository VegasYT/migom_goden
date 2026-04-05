import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/address_service.dart';
import '../../domain/address_model.dart';

final addressServiceProvider = Provider<AddressService>((ref) => AddressService());

class AddressNotifier extends AsyncNotifier<List<AddressModel>> {
  AddressService get _service => ref.read(addressServiceProvider);

  @override
  Future<List<AddressModel>> build() async {
    return _service.getAddresses();
  }

  Future<void> setDefault(String id) async {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((a) => a.copyWith(isDefault: a.id == id)).toList());
    // No dedicated API endpoint for default - handled locally until backend supports it
  }

  Future<void> add(AddressModel address) async {
    final created = await _service.createAddress(address);
    state = AsyncData([...(state.valueOrNull ?? []), created]);
  }

  Future<void> remove(String id) async {
    await _service.deleteAddress(id);
    final updated = (state.valueOrNull ?? []).where((a) => a.id != id).toList();
    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getAddresses());
  }
}

final addressProvider = AsyncNotifierProvider<AddressNotifier, List<AddressModel>>(
  AddressNotifier.new,
);

final defaultAddressProvider = Provider<AddressModel?>((ref) {
  final addresses = ref.watch(addressProvider).valueOrNull ?? [];
  try {
    return addresses.firstWhere((a) => a.isDefault);
  } catch (_) {
    return addresses.isNotEmpty ? addresses.first : null;
  }
});
