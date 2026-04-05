import 'package:latlong2/latlong.dart';

import '../domain/order_model.dart';

abstract final class OrdersMockData {
  static final activeOrder = ActiveOrderModel(
    id: '9012',
    restaurantName: 'Dodici Pizza',
    restaurantAddress: 'ул. Ленина, 45',
    deliveryAddress: 'ул. Пушкина, 12',
    status: OrderStatus.courierPickedUp,
    estimatedTime: '18 мин',
    subtotal: 770,
    deliveryFee: 0,
    total: 770,
    paymentMethod: PaymentMethod.card,
    restaurantLocation: const LatLng(55.757, 37.617),
    deliveryLocation: const LatLng(55.763, 37.632),
    courier: const CourierModel(
      name: 'Михаил',
      avatarUrl: 'https://i.pravatar.cc/80?img=7',
      phone: '+7 (916) 000-11-22',
      rating: 4.9,
      location: LatLng(55.760, 37.625),
    ),
    items: const [
      OrderItem(name: 'Пицца Маргарита', quantity: 1, price: 590),
      OrderItem(name: 'Картофель фри', quantity: 1, price: 180),
    ],
  );

  static const pastOrders = [
    PastOrderModel(
      id: '8821',
      restaurantName: 'Суши Мастер',
      restaurantEmoji: '🍣',
      date: '2 апр 2026',
      total: 1890,
      itemsCount: 3,
      status: OrderStatus.delivered,
      items: [
        OrderItem(name: 'Ролл Филадельфия', quantity: 2, price: 420),
        OrderItem(name: 'Ролл Калифорния', quantity: 1, price: 380),
        OrderItem(name: 'Мисо-суп', quantity: 2, price: 135),
      ],
    ),
    PastOrderModel(
      id: '8804',
      restaurantName: 'Burger House',
      restaurantEmoji: '🍔',
      date: '29 мар 2026',
      total: 750,
      itemsCount: 2,
      status: OrderStatus.delivered,
      items: [
        OrderItem(name: 'Чизбургер двойной', quantity: 1, price: 450),
        OrderItem(name: 'Картофель фри L', quantity: 1, price: 200),
        OrderItem(name: 'Кола 0.5', quantity: 1, price: 100),
      ],
    ),
    PastOrderModel(
      id: '8799',
      restaurantName: 'Пицца 33',
      restaurantEmoji: '🍕',
      date: '25 мар 2026',
      total: 1120,
      itemsCount: 2,
      status: OrderStatus.cancelled,
      items: [
        OrderItem(name: 'Пепперони XL', quantity: 1, price: 890),
        OrderItem(name: 'Чесночный хлеб', quantity: 1, price: 230),
      ],
    ),
    PastOrderModel(
      id: '8755',
      restaurantName: 'Суши Мастер',
      restaurantEmoji: '🍣',
      date: '17 мар 2026',
      total: 2340,
      itemsCount: 5,
      status: OrderStatus.delivered,
      items: [
        OrderItem(name: 'Сет «Токио»', quantity: 1, price: 1890),
        OrderItem(name: 'Том-ям', quantity: 1, price: 450),
      ],
    ),
  ];
}
