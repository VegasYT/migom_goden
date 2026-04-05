import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/courier_api_service.dart';
import '../../data/courier_mock_data.dart';
import '../../services/notification_service.dart';
import '../../services/order_sound_service.dart';

// Seconds the courier has to accept before the order is auto-declined
const kOrderTimeoutSeconds = 30;

enum IncomingOrderStatus { none, pending, accepted, declined }

@immutable
class IncomingOrderState {
  final IncomingOrderStatus status;
  final IncomingOrder? order;
  // Seconds remaining to accept (counts down from kOrderTimeoutSeconds)
  final int secondsLeft;

  const IncomingOrderState({
    this.status = IncomingOrderStatus.none,
    this.order,
    this.secondsLeft = kOrderTimeoutSeconds,
  });

  bool get hasPending => status == IncomingOrderStatus.pending;

  IncomingOrderState copyWith({
    IncomingOrderStatus? status,
    IncomingOrder? order,
    int? secondsLeft,
  }) =>
      IncomingOrderState(
        status: status ?? this.status,
        order: order ?? this.order,
        secondsLeft: secondsLeft ?? this.secondsLeft,
      );
}

class IncomingOrderNotifier extends StateNotifier<IncomingOrderState> {
  IncomingOrderNotifier(this._api) : super(const IncomingOrderState());

  final CourierApiService _api;
  Timer? _countdownTimer;

  /// Called from WS listener when courier.order_offer arrives.
  void receiveFromWs(Map<String, dynamic> payload) {
    final orderId = payload['order_id'] as int?;
    final expiresIn = payload['expires_in'] as int? ?? kOrderTimeoutSeconds;
    if (orderId == null) return;

    // Parse items from payload
    final itemsList = (payload['items'] as List? ?? []).map((item) {
      return IncomingOrderItem(
        name: item['name'] as String? ?? '',
        quantity: item['quantity'] as int? ?? 1,
      );
    }).toList();

    final customerAddress = payload['delivery_address'] as String? ?? '';
    final totalPrice = payload['total_price'] as String? ?? '0';
    final restaurantName = payload['outlet_name'] as String? ?? 'Ресторан';
    final restaurantAddress = payload['outlet_address'] as String? ?? '';
    final distanceKm = (payload['distance_km'] as num?)?.toDouble() ?? 0;
    final estimatedMinutes = payload['estimated_minutes'] as int? ?? 0;

    final order = IncomingOrder(
      id: '#$orderId',
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      customerAddress: customerAddress,
      distanceKm: distanceKm,
      estimatedMinutes: estimatedMinutes,
      payment: double.tryParse(totalPrice) ?? 0,
      items: itemsList,
    );

    _countdownTimer?.cancel();
    state = IncomingOrderState(
      status: IncomingOrderStatus.pending,
      order: order,
      secondsLeft: expiresIn,
    );
    _startCountdown();

    OrderSoundService.play();
    NotificationService.showIncomingOrder(
      orderId: order.id,
      restaurantName: order.restaurantName,
      address: order.restaurantAddress,
    );
  }

  Future<void> accept() async {
    _countdownTimer?.cancel();
    final order = state.order;
    if (order == null) return;

    final orderId = int.tryParse(order.id.replaceAll('#', ''));
    if (orderId != null) {
      try {
        await _api.acceptOrder(orderId);
      } catch (_) {}
    }

    state = state.copyWith(status: IncomingOrderStatus.accepted);
    _stopAlert();
  }

  Future<void> decline() async {
    _countdownTimer?.cancel();
    final order = state.order;

    final orderId = order != null
        ? int.tryParse(order.id.replaceAll('#', ''))
        : null;
    if (orderId != null) {
      try {
        await _api.rejectOrder(orderId);
      } catch (_) {}
    }

    state = state.copyWith(status: IncomingOrderStatus.declined);
    _stopAlert();
  }

  void dismiss() {
    _countdownTimer?.cancel();
    state = const IncomingOrderState();
    _stopAlert();
  }

  void _stopAlert() {
    OrderSoundService.stop();
    NotificationService.cancelIncomingOrder();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = state.secondsLeft - 1;
      if (left <= 0) {
        // Auto-decline on timeout
        decline();
      } else {
        state = state.copyWith(secondsLeft: left);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final _incomingApiProvider = Provider<CourierApiService>((_) => CourierApiService());

final incomingOrderProvider =
    StateNotifierProvider<IncomingOrderNotifier, IncomingOrderState>(
  (ref) => IncomingOrderNotifier(ref.read(_incomingApiProvider)),
);
