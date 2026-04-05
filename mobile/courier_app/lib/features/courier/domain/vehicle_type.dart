enum VehicleType {
  walk,
  scooter,
  car;

  String get label => switch (this) {
        VehicleType.walk => 'Пеший',
        VehicleType.scooter => 'Самокат',
        VehicleType.car => 'Автомобиль',
      };

  String get emoji => switch (this) {
        VehicleType.walk => '🚶',
        VehicleType.scooter => '🛴',
        VehicleType.car => '🚗',
      };
}
