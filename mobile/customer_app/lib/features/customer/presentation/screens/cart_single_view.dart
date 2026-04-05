import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_model.dart';
import '../providers/companies_provider.dart';
import '../providers/nearest_outlet_provider.dart';
import '../widgets/cart/cart_delivery_toggle.dart';
import '../widgets/cart/cart_item_tile.dart';
import '../widgets/cart/cart_order_summary.dart';
import '../widgets/cart/cart_promo_code_field.dart';

class CartSingleView extends ConsumerStatefulWidget {
  final CartModel cart;
  final Future<void> Function(CartItemModel item, int qty) onUpdateItem;
  final Future<void> Function(CartItemModel item) onRemove;
  final VoidCallback onClear;

  const CartSingleView({
    super.key,
    required this.cart,
    required this.onUpdateItem,
    required this.onRemove,
    required this.onClear,
  });

  @override
  ConsumerState<CartSingleView> createState() => _CartSingleViewState();
}

class _CartSingleViewState extends ConsumerState<CartSingleView> {
  final _promoController = TextEditingController();
  bool _promoApplied = false;
  bool _promoError = false;
  int _deliveryType = 0;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  CartModel get cart => widget.cart;

  double get _deliveryFee => _deliveryType == 1 ? 0 : 49;
  double get _discount => _promoApplied ? cart.total * 0.20 : 0;
  double get _total => cart.total + _deliveryFee - _discount;

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    setState(() {
      _promoApplied = code == 'MIGOM20';
      _promoError = !_promoApplied;
    });
  }

  void _showClearDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Очистить корзину?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Все товары из ${ref.watch(companyNameProvider(cart.companyId))} будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onClear();
            },
            child: Text('Удалить', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: CartDeliveryToggle(
              selected: _deliveryType,
              onChanged: (v) => setState(() => _deliveryType = v),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => CartItemTile(
                item: cart.items[i],
                onIncrement: () => widget.onUpdateItem(
                    cart.items[i], cart.items[i].quantity + 1),
                onDecrement: () => widget.onUpdateItem(
                    cart.items[i], cart.items[i].quantity - 1),
                onRemove: () => widget.onRemove(cart.items[i]),
              ),
              childCount: cart.items.length,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: TextButton.icon(
              onPressed: () => _showClearDialog(context),
              icon: Icon(Icons.delete_sweep_rounded,
                  size: 16, color: colorScheme.error),
              label: Text(
                'Очистить корзину',
                style: TextStyle(color: colorScheme.error, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: CartPromoCodeField(
              controller: _promoController,
              applied: _promoApplied,
              error: _promoError,
              onApply: _applyPromo,
              onRemove: () => setState(() {
                _promoApplied = false;
                _promoError = false;
                _promoController.clear();
              }),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: CartOrderSummary(
              subtotal: cart.total,
              deliveryFee: _deliveryFee,
              discount: _discount,
              total: _total,
              deliveryType: _deliveryType,
              freeDeliveryFrom: 800,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Builder(builder: (context) {
              final outletAsync =
                  ref.watch(nearestOutletProvider(cart.companyId));
              return CartCheckoutButton(
                total: _total,
                subtotal: cart.total,
                deliveryFee: _deliveryFee,
                discount: _discount,
                deliveryType: _deliveryType,
                restaurantName: ref.watch(companyNameProvider(cart.companyId)),
                outletId: outletAsync.valueOrNull,
                outletLoading: outletAsync.isLoading && !outletAsync.hasError,
              );
            }),
          ),
        ),
      ],
    );
  }
}
