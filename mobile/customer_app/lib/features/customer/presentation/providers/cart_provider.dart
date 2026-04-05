import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cart_service.dart';
import '../../domain/cart_model.dart';

final cartServiceProvider = Provider<CartService>((ref) => CartService());

class CartNotifier extends AsyncNotifier<AllCartsResponse> {
  CartService get _service => ref.read(cartServiceProvider);

  @override
  Future<AllCartsResponse> build() async {
    return _service.getAllCarts();
  }

  Future<void> addItem({required int catalogItemId, int quantity = 1}) async {
    await _service.addItem(catalogItemId: catalogItemId, quantity: quantity);
    await _silentRefresh();
  }

  Future<void> updateItem({required int itemId, required int quantity}) async {
    await _service.updateItem(itemId: itemId, quantity: quantity);
    await _silentRefresh();
  }

  Future<void> removeItem(int itemId) async {
    await _service.removeItem(itemId);
    await _silentRefresh();
  }

  Future<void> clearCompanyCart(int companyId) async {
    await _service.clearCompanyCart(companyId);
    await _silentRefresh();
  }

  Future<void> clearAll() async {
    await _service.clearAllCarts();
    await _silentRefresh();
  }

  // Обновляет данные без перехода в AsyncLoading (без перестройки страницы)
  Future<void> _silentRefresh() async {
    final updated = await _service.getAllCarts();
    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getAllCarts());
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, AllCartsResponse>(
  CartNotifier.new,
);

final cartTotalItemsProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).valueOrNull?.totalItems ?? 0;
});

final cartGrandTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).valueOrNull?.grandTotal ?? 0;
});
