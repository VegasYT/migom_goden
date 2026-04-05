enum OrderStatus { delivered, cancelled, inProgress }

class ProfileModel {
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final int ordersCount;
  final int bonusPoints;

  const ProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.ordersCount,
    required this.bonusPoints,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      ordersCount: json['orders_count'] as int? ?? 0,
      bonusPoints: json['bonus_points'] as int? ?? 0,
    );
  }
}

class ProfileOrderItem {
  final String id;
  final String restaurantName;
  final String date;
  final int total;
  final OrderStatus status;

  const ProfileOrderItem({
    required this.id,
    required this.restaurantName,
    required this.date,
    required this.total,
    required this.status,
  });
}
