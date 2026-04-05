import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_model.dart';
import '../providers/cart_provider.dart';
import '../providers/companies_provider.dart';
import '../widgets/cart/cart_empty.dart';
import 'cart_single_view.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _prevCartsCount = 0;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _ensureTabController(int count) {
    if (_tabController == null || _prevCartsCount != count) {
      final old = _tabController;
      _tabController = TabController(length: count, vsync: this);
      _prevCartsCount = count;
      // Dispose the old controller after the frame so widgets still holding
      // a reference to it don't throw "used after being disposed".
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
    }
  }

  Future<void> _removeItem(CartItemModel item) async {
    HapticFeedback.mediumImpact();
    await ref.read(cartProvider.notifier).removeItem(item.id);
  }

  Future<void> _updateItem(CartItemModel item, int qty) async {
    HapticFeedback.selectionClick();
    if (qty <= 0) {
      await ref.read(cartProvider.notifier).removeItem(item.id);
    } else {
      await ref.read(cartProvider.notifier).updateItem(
        itemId: item.id,
        quantity: qty,
      );
    }
  }

  Future<void> _clearCart(int companyId) async {
    HapticFeedback.mediumImpact();
    await ref.read(cartProvider.notifier).clearCompanyCart(companyId);
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return cartAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.toString()),
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).refresh(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      data: (allCarts) {
        final carts = allCarts.carts;
        if (carts.isEmpty) return const CartEmpty();

        _ensureTabController(carts.length);

        return Column(
          children: [
            Material(
              color: colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'Корзина',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  if (carts.length > 1)
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorColor: colorScheme.primary,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      labelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tabs: carts.map((cart) {
                        final name = ref.watch(companyNameProvider(cart.companyId));
                        return Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(name),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${cart.totalItems}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                ],
              ),
            ),
            Expanded(
              child: carts.length == 1
                  ? CartSingleView(
                      cart: carts[0],
                      onUpdateItem: _updateItem,
                      onRemove: _removeItem,
                      onClear: () => _clearCart(carts[0].companyId),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: carts.map((cart) {
                        return CartSingleView(
                          cart: cart,
                          onUpdateItem: _updateItem,
                          onRemove: _removeItem,
                          onClear: () => _clearCart(cart.companyId),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}
