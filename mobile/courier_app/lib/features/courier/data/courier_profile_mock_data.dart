import '../domain/courier_profile_model.dart';
import '../domain/vehicle_type.dart';

abstract final class CourierProfileMockData {
  static const profile = CourierProfileModel(
    name: 'Алексей Смирнов',
    email: 'alexey.smirnov@example.com',
    phone: '+7 999 123 45 67',
    avatarUrl: null,
    totalDistanceKm: 1247.3,
    totalDeliveries: 348,
    vehicleType: VehicleType.walk,
  );
}
