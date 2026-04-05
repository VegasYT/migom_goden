import '../domain/profile_model.dart';

abstract final class ProfileMockData {
  static final profile = ProfileModel(
    name: 'Алексей Иванов',
    email: 'alexey@example.com',
    phone: '+7 (999) 123-45-67',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
    ordersCount: 24,
    bonusPoints: 1350,
  );

  static const orders = [
    ProfileOrderItem(
      id: '8821',
      restaurantName: 'Суши Мастер',
      date: '02 апр 2026',
      total: 1890,
      status: OrderStatus.delivered,
    ),
    ProfileOrderItem(
      id: '8804',
      restaurantName: 'Burger House',
      date: '29 мар 2026',
      total: 750,
      status: OrderStatus.delivered,
    ),
    ProfileOrderItem(
      id: '8799',
      restaurantName: 'Пицца 33',
      date: '25 мар 2026',
      total: 1120,
      status: OrderStatus.cancelled,
    ),
  ];
}
