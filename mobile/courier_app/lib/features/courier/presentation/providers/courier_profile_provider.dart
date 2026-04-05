import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../data/courier_api_service.dart';
import '../../domain/courier_profile_model.dart';
import '../../domain/vehicle_type.dart';

final _apiServiceProvider = Provider<CourierApiService>((_) => CourierApiService());

class CourierProfileNotifier extends AsyncNotifier<CourierProfileModel?> {
  CourierApiService get _api => ref.read(_apiServiceProvider);

  @override
  Future<CourierProfileModel?> build() async {
    return _fetchFromApi();
  }

  Future<CourierProfileModel?> _fetchFromApi() async {
    try {
      // User data (name, email, phone, avatar) from business_service
      final userResp = await ApiClient.instance.dio.get('/users/me');
      final userData = userResp.data as Map<String, dynamic>;

      // Courier data (movement type, radius) from delivery_service
      final courierData = await _api.getProfile();

      return CourierProfileModel(
        name: userData['full_name'] as String? ?? '',
        email: userData['email'] as String? ?? '',
        phone: userData['phone'] as String? ?? '',
        avatarUrl: userData['avatar_url'] as String?,
        totalDistanceKm: 0,
        totalDeliveries: 0,
        vehicleType: _movementToVehicle(courierData['type_movement'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  VehicleType _movementToVehicle(String? movement) {
    switch (movement) {
      case 'car':
        return VehicleType.car;
      case 'scooter':
        return VehicleType.scooter;
      default:
        return VehicleType.walk;
    }
  }

  Future<void> updatePersonalData({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      await ApiClient.instance.dio.patch('/users/me', data: {
        'full_name': name,
        if (phone.isNotEmpty) 'phone': phone,
      });
      state = AsyncData(state.value?.copyWith(
        name: name,
        email: email,
        phone: phone,
      ));
    } catch (_) {}
  }

  Future<void> updateVehicleType(VehicleType type) async {
    try {
      await _api.updateProfile(typeMovement: _vehicleToMovement(type));
      state = AsyncData(state.value?.copyWith(vehicleType: type));
    } catch (_) {}
  }

  String _vehicleToMovement(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'car';
      case VehicleType.scooter:
        return 'scooter';
      case VehicleType.walk:
        return 'walk';
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchFromApi());
  }
}

final courierProfileProvider =
    AsyncNotifierProvider<CourierProfileNotifier, CourierProfileModel?>(
  CourierProfileNotifier.new,
);

// Convenience sync provider - returns last value or empty fallback
final courierProfileSyncProvider = Provider<CourierProfileModel>((ref) {
  return ref.watch(courierProfileProvider).valueOrNull ??
      const CourierProfileModel(
        name: '',
        email: '',
        phone: '',
        totalDistanceKm: 0,
        totalDeliveries: 0,
        vehicleType: VehicleType.walk,
      );
});
