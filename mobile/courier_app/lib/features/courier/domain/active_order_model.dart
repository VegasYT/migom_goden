import 'package:yandex_mapkit/yandex_mapkit.dart';

enum ActiveOrderStage {
  toRestaurant,
  toCustomer,
  awaitingConfirmation,
  delivered,
}

class ActiveOrderModel {
  final String id;
  final String restaurantName;
  final String restaurantAddress;
  final Point restaurantPoint;
  final String customerAddress;
  final Point customerPoint;
  final double distanceKm;
  final int estimatedToRestaurantMinutes;
  final int estimatedMinutes;
  final double payment;
  final List<ActiveOrderItem> items;

  const ActiveOrderModel({
    required this.id,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantPoint,
    required this.customerAddress,
    required this.customerPoint,
    required this.distanceKm,
    required this.estimatedToRestaurantMinutes,
    required this.estimatedMinutes,
    required this.payment,
    required this.items,
  });
}

class ActiveOrderItem {
  final String name;
  final int quantity;

  const ActiveOrderItem({required this.name, required this.quantity});
}

class ActiveOrderState {
  final ActiveOrderModel order;
  final ActiveOrderStage stage;
  final int elapsedSeconds;

  const ActiveOrderState({
    required this.order,
    this.stage = ActiveOrderStage.toRestaurant,
    this.elapsedSeconds = 0,
  });

  int get _targetMinutes => stage == ActiveOrderStage.toRestaurant
      ? order.estimatedToRestaurantMinutes
      : order.estimatedMinutes;

  int get secondsRemaining => _targetMinutes * 60 - elapsedSeconds;
  bool get isOverdue => secondsRemaining < 0;

  ActiveOrderState copyWith({
    ActiveOrderStage? stage,
    int? elapsedSeconds,
  }) =>
      ActiveOrderState(
        order: order,
        stage: stage ?? this.stage,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      );
}
