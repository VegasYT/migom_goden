import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../data/courier_api_service.dart';
import '../../domain/delivery_zone_model.dart';

class DeliveryZoneNotifier extends StateNotifier<DeliveryZoneModel> {
  DeliveryZoneNotifier(this._api)
      : super(const DeliveryZoneModel(
          // Default: Rostov-on-Don center
          center: Point(latitude: 47.2357, longitude: 39.7015),
          radiusKm: 3.0,
        )) {
    _loadFromApi();
  }

  final CourierApiService _api;

  Future<void> _loadFromApi() async {
    try {
      final data = await _api.getProfile();
      final lat = (data['zone_latitude'] as num?)?.toDouble();
      final lng = (data['zone_longitude'] as num?)?.toDouble();
      final radius = (data['radius_km'] as num?)?.toDouble() ?? 3.0;
      if (lat != null && lng != null) {
        state = DeliveryZoneModel(
          center: Point(latitude: lat, longitude: lng),
          radiusKm: radius,
        );
      } else {
        state = state.copyWith(radiusKm: radius);
      }
    } catch (_) {}
  }

  void updateCenter(Point center) =>
      state = state.copyWith(center: center);

  void updateRadius(double radiusKm) =>
      state = state.copyWith(radiusKm: radiusKm.clamp(0.5, 15.0));

  void update({required Point center, required double radiusKm}) {
    state = DeliveryZoneModel(center: center, radiusKm: radiusKm);
    _api.updateProfile(
      zoneLatitude: center.latitude,
      zoneLongitude: center.longitude,
      radiusKm: radiusKm.round(),
    ).ignore();
  }
}

final _zoneApiProvider = Provider<CourierApiService>((_) => CourierApiService());

final deliveryZoneProvider =
    StateNotifierProvider<DeliveryZoneNotifier, DeliveryZoneModel>(
  (ref) => DeliveryZoneNotifier(ref.read(_zoneApiProvider)),
);
