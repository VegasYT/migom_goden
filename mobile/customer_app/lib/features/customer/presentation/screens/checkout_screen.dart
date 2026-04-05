import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/address_model.dart';
import '../../domain/payment_method_model.dart';
import '../providers/address_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/payment_method_provider.dart';
import '../widgets/checkout/checkout_address_selector.dart';
import '../widgets/checkout/checkout_confirm_button.dart';
import '../widgets/checkout/checkout_payment_selector.dart';
import '../widgets/checkout/checkout_restaurant_card.dart';
import '../widgets/checkout/checkout_delivery_options.dart';
import '../widgets/checkout/checkout_sliver_header.dart';
import '../widgets/checkout/checkout_summary.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final int deliveryType;
  final String restaurantName;
  final int? outletId;

  const CheckoutScreen({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.deliveryType,
    required this.restaurantName,
    this.outletId,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  AddressModel? _selectedAddress;
  PaymentMethodModel? _selectedPayment;
  bool _leaveAtDoor = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final outletId = widget.outletId;
    final payment = _selectedPayment;

    if (outletId == null) return; // не должно случиться - кнопка заблокирована
    if (payment == null) {
      _showError('Выберите способ оплаты.');
      return;
    }
    final paymentId = int.tryParse(payment.id);
    if (paymentId == null || paymentId == 0) {
      _showError('Способ оплаты ещё не готов. Попробуйте через секунду.');
      return;
    }
    final isDelivery = widget.deliveryType == 0;
    if (isDelivery && _selectedAddress == null) {
      _showError('Выберите адрес доставки.');
      return;
    }

    HapticFeedback.mediumImpact();

    await ref.read(createOrderProvider.notifier).createOrder(
      outletId: outletId,
      deliveryType: isDelivery ? 'delivery' : 'pickup',
      paymentMethodId: paymentId,
      addressId: isDelivery ? int.tryParse(_selectedAddress?.id ?? '') : null,
      leaveAtDoor: _leaveAtDoor,
    );

    if (!mounted) return;
    final error = ref.read(createOrderProvider).error;
    if (error != null) {
      _showError(error.toString());
      return;
    }

    // Очищаем корзину и показываем успех
    await ref.read(cartProvider.notifier).refresh();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Заказ оформлен!',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Ваш заказ из ${widget.restaurantName} принят.\nОжидайте доставку.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // закрыть диалог
              Navigator.pop(context); // закрыть checkout
            },
            child: const Text('Отлично'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDelivery = widget.deliveryType == 0;
    final isOrdering = ref.watch(createOrderProvider).isLoading;
    final addressesAsync = ref.watch(addressProvider);
    final methodsAsync = ref.watch(paymentMethodProvider);

    final addresses = addressesAsync.valueOrNull ?? [];
    final methods = methodsAsync.valueOrNull ?? [];

    if (_selectedAddress == null && addresses.isNotEmpty) {
      _selectedAddress = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
    }
    if (_selectedPayment == null && methods.isNotEmpty) {
      _selectedPayment = methods.firstWhere(
        (m) => m.isDefault,
        orElse: () => methods.first,
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Оформление заказа',
            style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: CheckoutRestaurantCard(
                restaurantName: widget.restaurantName,
                isDelivery: isDelivery,
              ),
            ),

            if (isDelivery && _selectedAddress != null) ...[
              CheckoutSliverHeader(label: 'Адрес доставки'),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CheckoutAddressSelector(
                    selected: _selectedAddress!,
                    addresses: addresses,
                    onSelect: (a) => setState(() => _selectedAddress = a),
                  ),
                ),
              ),

              CheckoutSliverHeader(label: 'Параметры доставки'),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CheckoutDeliveryOptions(
                    leaveAtDoor: _leaveAtDoor,
                    onLeaveAtDoor: (v) => setState(() => _leaveAtDoor = v),
                  ),
                ),
              ),
            ],

            if (_selectedPayment != null) ...[
              CheckoutSliverHeader(label: 'Способ оплаты'),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CheckoutPaymentSelector(
                    selected: _selectedPayment!,
                    methods: methods,
                    onSelect: (m) => setState(() => _selectedPayment = m),
                  ),
                ),
              ),
            ],

            CheckoutSliverHeader(label: 'Состав заказа'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CheckoutSummary(
                  subtotal: widget.subtotal,
                  deliveryFee: widget.deliveryFee,
                  discount: widget.discount,
                  total: widget.total,
                  isDelivery: isDelivery,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: CheckoutConfirmButton(
                  total: widget.total,
                  onPressed: _placeOrder,
                  isLoading: isOrdering,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
