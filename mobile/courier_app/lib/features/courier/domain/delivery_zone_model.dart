import 'package:yandex_mapkit/yandex_mapkit.dart';

class DeliveryZoneModel {
  final Point center;
  final double radiusKm;

  const DeliveryZoneModel({
    required this.center,
    required this.radiusKm,
  });

  DeliveryZoneModel copyWith({Point? center, double? radiusKm}) =>
      DeliveryZoneModel(
        center: center ?? this.center,
        radiusKm: radiusKm ?? this.radiusKm,
      );
}
