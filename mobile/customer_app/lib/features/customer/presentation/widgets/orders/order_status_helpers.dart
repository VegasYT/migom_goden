import 'package:flutter/material.dart';

import '../../../domain/order_model.dart';

String orderStatusLabel(OrderStatus status) => switch (status) {
      OrderStatus.newOrder => 'Новый заказ',
      OrderStatus.assigned => 'Курьер назначен',
      OrderStatus.assembling => 'Ресторан готовит заказ',
      OrderStatus.readyForPickup => 'Ожидает курьера',
      OrderStatus.courierPickedUp => 'Курьер везёт заказ',
      OrderStatus.nearYou => 'Курьер рядом',
      OrderStatus.inDelivery => 'В доставке',
      OrderStatus.delivered => 'Доставлен',
      OrderStatus.received => 'Получен',
      OrderStatus.cancelled => 'Отменён',
    };

String orderStatusShort(OrderStatus status) => switch (status) {
      OrderStatus.newOrder => 'Новый',
      OrderStatus.assigned => 'Назначен',
      OrderStatus.assembling => 'Готовится',
      OrderStatus.readyForPickup => 'Ждёт курьера',
      OrderStatus.courierPickedUp => 'В пути',
      OrderStatus.nearYou => 'Рядом',
      OrderStatus.inDelivery => 'В пути',
      OrderStatus.delivered => 'Доставлен',
      OrderStatus.received => 'Получен',
      OrderStatus.cancelled => 'Отменён',
    };

Color orderStatusColor(OrderStatus status, ColorScheme cs) => switch (status) {
      OrderStatus.newOrder => cs.onSurfaceVariant,
      OrderStatus.assigned => cs.tertiary,
      OrderStatus.assembling => cs.tertiary,
      OrderStatus.readyForPickup => cs.tertiary,
      OrderStatus.courierPickedUp => cs.primary,
      OrderStatus.nearYou => cs.primary,
      OrderStatus.inDelivery => cs.primary,
      OrderStatus.delivered => const Color(0xFF16A34A),
      OrderStatus.received => const Color(0xFF16A34A),
      OrderStatus.cancelled => cs.error,
    };

IconData orderStatusIcon(OrderStatus status) => switch (status) {
      OrderStatus.newOrder => Icons.pending_outlined,
      OrderStatus.assigned => Icons.person_pin_circle_rounded,
      OrderStatus.assembling => Icons.restaurant_rounded,
      OrderStatus.readyForPickup => Icons.access_time_rounded,
      OrderStatus.courierPickedUp => Icons.delivery_dining_rounded,
      OrderStatus.nearYou => Icons.near_me_rounded,
      OrderStatus.inDelivery => Icons.delivery_dining_rounded,
      OrderStatus.delivered => Icons.check_circle_rounded,
      OrderStatus.received => Icons.check_circle_rounded,
      OrderStatus.cancelled => Icons.cancel_rounded,
    };

/// Шаги прогресс-бара: индекс текущего шага (0-3).
int orderProgressStep(OrderStatus status) => switch (status) {
      OrderStatus.newOrder => 0,
      OrderStatus.assigned => 0,
      OrderStatus.assembling => 0,
      OrderStatus.readyForPickup => 1,
      OrderStatus.courierPickedUp => 2,
      OrderStatus.nearYou => 3,
      OrderStatus.inDelivery => 2,
      OrderStatus.delivered => 4,
      OrderStatus.received => 4,
      OrderStatus.cancelled => -1,
    };
