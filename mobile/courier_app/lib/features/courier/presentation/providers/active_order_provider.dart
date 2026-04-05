import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../data/courier_api_service.dart';
import '../../domain/active_order_model.dart';
import '../../services/notification_service.dart';
import 'location_provider.dart';
import 'route_provider.dart';

class ActiveOrderNotifier extends StateNotifier<ActiveOrderState?> {
  final Ref _ref;
  final CourierApiService _api;

  ActiveOrderNotifier(this._ref, this._api) : super(null);

  Timer? _timer;

  void start(ActiveOrderModel order) {
    _timer?.cancel();
    state = ActiveOrderState(order: order);
    _startTimer();
    NotificationService.showActiveDelivery(
      destinationAddress: order.restaurantAddress,
      estimatedMinutes: order.estimatedToRestaurantMinutes,
      stage: 'Еду к ресторану',
      showPickedUpAction: true,
    );
  }

  /// Build ActiveOrderModel from API response data + outlet info.
  static ActiveOrderModel _fromApiData(
    Map<String, dynamic> data, {
    Map<String, dynamic>? outlet,
  }) {
    final address = data['delivery_address'] as Map<String, dynamic>?;
    final lat = address?['latitude'] as double?;
    final lng = address?['longitude'] as double?;
    final customerAddr = address?['address'] as String? ?? '';

    final items = (data['items'] as List? ?? []).map((item) {
      return ActiveOrderItem(
        name: item['name'] as String? ?? '',
        quantity: item['quantity'] as int? ?? 1,
      );
    }).toList();

    final totalPrice = data['total_price'] as String? ?? '0';

    final outletName = outlet?['name'] as String? ?? 'Ресторан';
    final outletAddress = outlet?['address'] as String? ?? '';
    final outletLat = double.tryParse('${outlet?['latitude'] ?? ''}') ?? 0;
    final outletLng = double.tryParse('${outlet?['longitude'] ?? ''}') ?? 0;

    return ActiveOrderModel(
      id: '#${data['id']}',
      restaurantName: outletName,
      restaurantAddress: outletAddress,
      restaurantPoint: Point(latitude: outletLat, longitude: outletLng),
      customerAddress: customerAddr,
      customerPoint: Point(
        latitude: lat ?? 0,
        longitude: lng ?? 0,
      ),
      distanceKm: 0,
      estimatedToRestaurantMinutes: 10,
      estimatedMinutes: data['delivery_time'] as int? ?? 30,
      payment: double.tryParse(totalPrice) ?? 0,
      items: items,
    );
  }

  /// Load active order from API on app start
  Future<void> loadFromApi() async {
    try {
      final data = await _api.getActiveOrder();
      if (data != null) {
        Map<String, dynamic>? outlet;
        final outletId = data['outlet_id'] as int?;
        if (outletId != null) {
          try {
            outlet = await _api.getOutlet(outletId);
          } catch (_) {}
        }
        final order = _fromApiData(data, outlet: outlet);
        final status = data['status'] as String?;
        start(order);
        // Sync stage with server status
        if (status == 'in_delivery') {
          _timer?.cancel();
          _ref.read(locationProvider.notifier).setPosition(order.restaurantPoint);
          state = state?.copyWith(
            stage: ActiveOrderStage.toCustomer,
            elapsedSeconds: 0,
          );
          _startTimer();
        }
      }
    } catch (_) {}
  }

  /// Courier picked up the order - call API then update stage.
  Future<void> pickedUp() async {
    final current = state;
    if (current == null) return;

    final orderId = int.tryParse(current.order.id.replaceAll('#', ''));
    if (orderId != null) {
      try {
        await _api.pickupOrder(orderId);
      } catch (_) {}
    }

    _timer?.cancel();
    _ref.read(locationProvider.notifier).setPosition(current.order.restaurantPoint);
    _ref.read(routeProvider.notifier).clear();
    state = current.copyWith(
      stage: ActiveOrderStage.toCustomer,
      elapsedSeconds: 0,
    );
    _startTimer();
    NotificationService.showActiveDelivery(
      destinationAddress: current.order.customerAddress,
      estimatedMinutes: current.order.estimatedMinutes,
      stage: 'Везу заказ клиенту',
      showDeliveredAction: true,
    );
  }

  /// Courier tapped "Delivered" - call API, then wait for customer confirmation.
  Future<void> delivered() async {
    _timer?.cancel();
    final current = state;
    if (current == null) return;

    final orderId = int.tryParse(current.order.id.replaceAll('#', ''));
    if (orderId != null) {
      try {
        await _api.deliverOrder(orderId);
      } catch (_) {}
    }

    _ref.read(routeProvider.notifier).clear();
    state = current.copyWith(stage: ActiveOrderStage.awaitingConfirmation);
    NotificationService.showActiveDelivery(
      destinationAddress: current.order.customerAddress,
      estimatedMinutes: 0,
      stage: 'Ожидаем подтверждения клиента...',
    );
  }

  /// Called when the WebSocket delivers customer confirmation (order.status_updated → received).
  void confirmDelivery() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(stage: ActiveOrderStage.delivered);
    NotificationService.cancelActiveDelivery();
  }

  void clear() {
    _timer?.cancel();
    state = null;
    NotificationService.cancelActiveDelivery();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current == null) return;
      state = current.copyWith(elapsedSeconds: current.elapsedSeconds + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final _activeOrderApiProvider = Provider<CourierApiService>((_) => CourierApiService());

final activeOrderProvider =
    StateNotifierProvider<ActiveOrderNotifier, ActiveOrderState?>(
  (ref) => ActiveOrderNotifier(ref, ref.read(_activeOrderApiProvider)),
);

@immutable
class TimerDisplay {
  final String text;
  final bool isOverdue;

  const TimerDisplay({required this.text, required this.isOverdue});
}

TimerDisplay formatCountdown(int secondsRemaining) {
  final isOverdue = secondsRemaining < 0;
  final abs = secondsRemaining.abs();
  final m = (abs ~/ 60).toString().padLeft(2, '0');
  final s = (abs % 60).toString().padLeft(2, '0');
  final text = '${isOverdue ? '−' : ''}$m:$s';
  return TimerDisplay(text: text, isOverdue: isOverdue);
}
