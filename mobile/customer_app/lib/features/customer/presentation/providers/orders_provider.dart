import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/orders_service.dart';
import '../../domain/order_model.dart';
import 'companies_provider.dart';

final ordersServiceProvider = Provider<OrdersService>((ref) => OrdersService());

final ordersProvider = FutureProvider<List<ApiOrderModel>>((ref) async {
  return ref.watch(ordersServiceProvider).getOrders();
});

final activeOrdersProvider = FutureProvider<List<ApiOrderModel>>((ref) async {
  final orders = await ref.watch(ordersProvider.future);
  return orders.where((o) => o.isActive).toList();
});

final pastOrdersListProvider = FutureProvider<List<PastOrderModel>>((ref) async {
  final orders = await ref.watch(ordersProvider.future);
  final pastOrders = orders.where((o) => !o.isActive).toList();

  // Подгружаем имена компаний для каждого заказа
  final result = <PastOrderModel>[];
  for (final o in pastOrders) {
    final companyName = ref.watch(companyNameProvider(o.companyId));
    final outlets = ref.watch(companyOutletsProvider(o.companyId)).valueOrNull ?? [];
    final outlet = outlets.where((out) => out.id == o.outletId).firstOrNull;
    final name = outlet?.name ?? o.outletName ?? companyName;
    result.add(o.toPastOrderModel(restaurantName: name));
  }
  return result;
});

/// Первый активный заказ, сконвертированный в ActiveOrderModel для UI карты/деталей.
final activeOrderProvider = Provider<ActiveOrderModel?>((ref) {
  final activeOrders = ref.watch(activeOrdersProvider).valueOrNull ?? [];
  if (activeOrders.isEmpty) return null;

  final o = activeOrders.first;

  // Получаем данные outlet'а для адреса и координат
  final outlets = ref.watch(companyOutletsProvider(o.companyId)).valueOrNull ?? [];
  final outlet = outlets.where((out) => out.id == o.outletId).firstOrNull;

  final companyName = ref.watch(companyNameProvider(o.companyId));

  final subtotal = o.items.fold<double>(0, (sum, i) => sum + i.subtotal);

  return ActiveOrderModel(
    id: o.id.toString(),
    restaurantName: o.outletName ?? companyName,
    restaurantAddress: outlet?.address ?? o.outletAddress ?? '',
    deliveryAddress: o.deliveryAddressLabel,
    status: o.orderStatus,
    items: o.items
        .map((i) => OrderItem(name: i.name, quantity: i.quantity, price: i.price))
        .toList(),
    subtotal: subtotal,
    deliveryFee: o.deliveryFee,
    total: o.totalPrice,
    paymentMethod: PaymentMethod.cash,
    estimatedTime: '~30 мин',
    restaurantLocation: LatLng(
      outlet?.latitude ?? 0,
      outlet?.longitude ?? 0,
    ),
    deliveryLocation: LatLng(
      o.deliveryLatitude ?? 0,
      o.deliveryLongitude ?? 0,
    ),
  );
});

class CreateOrderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createOrder({
    required int outletId,
    required String deliveryType,
    required int paymentMethodId,
    int? addressId,
    bool leaveAtDoor = false,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(ordersServiceProvider).createOrder(
        outletId: outletId,
        deliveryType: deliveryType,
        customerPaymentMethodId: paymentMethodId,
        customerAddressId: addressId,
        leaveAtDoor: leaveAtDoor,
      );
      ref.invalidate(ordersProvider);
    });
  }
}

final createOrderProvider =
    AsyncNotifierProvider<CreateOrderNotifier, void>(CreateOrderNotifier.new);
