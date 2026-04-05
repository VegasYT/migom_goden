class CourierProfile {
  final String name;
  final String phone;
  final double rating;
  final int totalDeliveries;
  final String vehicleType;
  final String avatarInitials;

  const CourierProfile({
    required this.name,
    required this.phone,
    required this.rating,
    required this.totalDeliveries,
    required this.vehicleType,
    required this.avatarInitials,
  });
}

class ShiftStats {
  final int ordersCompleted;
  final double earned;
  final double distanceKm;
  final Duration activeTime;

  const ShiftStats({
    required this.ordersCompleted,
    required this.earned,
    required this.distanceKm,
    required this.activeTime,
  });
}

class WeeklyEarning {
  final String day;
  final double amount;

  const WeeklyEarning({required this.day, required this.amount});
}

enum StatsPeriod { today, week, month }

class PeriodStats {
  final double earned;
  final int ordersCompleted;
  final double avgDeliveryMinutes;
  final double avgOrderAmount;
  final double distanceKm;

  const PeriodStats({
    required this.earned,
    required this.ordersCompleted,
    required this.avgDeliveryMinutes,
    required this.avgOrderAmount,
    required this.distanceKm,
  });
}

class ShiftRecord {
  final DateTime date;
  final Duration activeTime;
  final int ordersCompleted;
  final double earned;
  final double distanceKm;

  const ShiftRecord({
    required this.date,
    required this.activeTime,
    required this.ordersCompleted,
    required this.earned,
    required this.distanceKm,
  });
}

class IncomingOrderItem {
  final String name;
  final int quantity;

  const IncomingOrderItem({required this.name, required this.quantity});
}

class IncomingOrder {
  final String id;
  final String restaurantName;
  final String restaurantAddress;
  final String customerAddress;
  final double distanceKm;
  final int estimatedMinutes;
  final double payment;
  final List<IncomingOrderItem> items;

  const IncomingOrder({
    required this.id,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.customerAddress,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.payment,
    required this.items,
  });
}

abstract final class CourierMockData {
  static const profile = CourierProfile(
    name: 'Алексей Смирнов',
    phone: '+7 999 123 45 67',
    rating: 4.9,
    totalDeliveries: 348,
    vehicleType: 'Велосипед',
    avatarInitials: 'АС',
  );

  static const shiftStats = ShiftStats(
    ordersCompleted: 7,
    earned: 1840,
    distanceKm: 23.4,
    activeTime: Duration(hours: 3, minutes: 12),
  );

  static const weeklyEarnings = [
    WeeklyEarning(day: 'Пн', amount: 1200),
    WeeklyEarning(day: 'Вт', amount: 2100),
    WeeklyEarning(day: 'Ср', amount: 1650),
    WeeklyEarning(day: 'Чт', amount: 2840),
    WeeklyEarning(day: 'Пт', amount: 1900),
    WeeklyEarning(day: 'Сб', amount: 3200),
    WeeklyEarning(day: 'Вс', amount: 0),
  ];

  static const periodStats = {
    StatsPeriod.today: PeriodStats(
      earned: 2840,
      ordersCompleted: 7,
      avgDeliveryMinutes: 22,
      avgOrderAmount: 405,
      distanceKm: 23.4,
    ),
    StatsPeriod.week: PeriodStats(
      earned: 12890,
      ordersCompleted: 34,
      avgDeliveryMinutes: 24,
      avgOrderAmount: 379,
      distanceKm: 118.7,
    ),
    StatsPeriod.month: PeriodStats(
      earned: 48320,
      ordersCompleted: 142,
      avgDeliveryMinutes: 23,
      avgOrderAmount: 340,
      distanceKm: 491.2,
    ),
  };

  static final shiftHistory = [
    ShiftRecord(
      date: DateTime(2026, 4, 3),
      activeTime: const Duration(hours: 8, minutes: 14),
      ordersCompleted: 12,
      earned: 3200,
      distanceKm: 41.2,
    ),
    ShiftRecord(
      date: DateTime(2026, 4, 2),
      activeTime: const Duration(hours: 6, minutes: 45),
      ordersCompleted: 9,
      earned: 2540,
      distanceKm: 29.8,
    ),
    ShiftRecord(
      date: DateTime(2026, 4, 1),
      activeTime: const Duration(hours: 7, minutes: 30),
      ordersCompleted: 11,
      earned: 2980,
      distanceKm: 35.1,
    ),
    ShiftRecord(
      date: DateTime(2026, 3, 31),
      activeTime: const Duration(hours: 5, minutes: 20),
      ordersCompleted: 7,
      earned: 1900,
      distanceKm: 22.4,
    ),
    ShiftRecord(
      date: DateTime(2026, 3, 30),
      activeTime: const Duration(hours: 9, minutes: 5),
      ordersCompleted: 14,
      earned: 3850,
      distanceKm: 48.6,
    ),
    ShiftRecord(
      date: DateTime(2026, 3, 29),
      activeTime: const Duration(hours: 4, minutes: 50),
      ordersCompleted: 6,
      earned: 1650,
      distanceKm: 18.9,
    ),
    ShiftRecord(
      date: DateTime(2026, 3, 28),
      activeTime: const Duration(hours: 7, minutes: 0),
      ordersCompleted: 10,
      earned: 2700,
      distanceKm: 33.5,
    ),
  ];

  static const incomingOrder = IncomingOrder(
    id: '#4821',
    restaurantName: 'Burger King',
    restaurantAddress: 'ул. Большая Садовая, 75',
    customerAddress: 'пр. Ворошиловский, 45, кв. 18',
    distanceKm: 2.3,
    estimatedMinutes: 18,
    payment: 320,
    items: [
      IncomingOrderItem(name: 'Воппер', quantity: 2),
      IncomingOrderItem(name: 'Картофель фри (L)', quantity: 1),
      IncomingOrderItem(name: 'Кола 0.5', quantity: 2),
    ],
  );
}
