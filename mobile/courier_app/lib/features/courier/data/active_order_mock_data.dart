import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../domain/active_order_model.dart';

abstract final class ActiveOrderMockData {
  static const order = ActiveOrderModel(
    id: '#4821',
    restaurantName: 'Burger King',
    restaurantAddress: 'ул. Большая Садовая, 75',
    restaurantPoint: Point(latitude: 47.22527726635149, longitude: 39.699146046506606),
    customerAddress: 'пр. Ворошиловский, 45, кв. 18',
    customerPoint: Point(latitude: 47.233326657730856, longitude: 39.70359795493966),
    distanceKm: 1.4,
    estimatedToRestaurantMinutes: 5,
    estimatedMinutes: 12,
    payment: 280,
    items: [
      ActiveOrderItem(name: 'Воппер', quantity: 2),
      ActiveOrderItem(name: 'Картофель фри (L)', quantity: 1),
      ActiveOrderItem(name: 'Кола 0.5', quantity: 2),
    ],
  );
}
