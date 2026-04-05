import 'vehicle_type.dart';

class CourierProfileModel {
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final double totalDistanceKm;
  final int totalDeliveries;
  final VehicleType vehicleType;

  const CourierProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.totalDistanceKm,
    required this.totalDeliveries,
    required this.vehicleType,
  });

  CourierProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    double? totalDistanceKm,
    int? totalDeliveries,
    VehicleType? vehicleType,
  }) =>
      CourierProfileModel(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
        totalDeliveries: totalDeliveries ?? this.totalDeliveries,
        vehicleType: vehicleType ?? this.vehicleType,
      );
}
