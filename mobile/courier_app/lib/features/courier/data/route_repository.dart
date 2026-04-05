import 'dart:async';

import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../domain/vehicle_type.dart';

class RouteRepository {
  static Future<List<Point>> fetchRoute({
    required Point origin,
    required Point destination,
    required VehicleType vehicleType,
    required Completer<void> cancelCompleter,
  }) async {
    switch (vehicleType) {
      case VehicleType.car:
        return _fetchDriving(origin, destination, cancelCompleter);
      case VehicleType.scooter:
        return _fetchBicycle(origin, destination, cancelCompleter);
      case VehicleType.walk:
        return _fetchPedestrian(origin, destination, cancelCompleter);
    }
  }

  static Future<List<Point>> _fetchDriving(
    Point origin,
    Point destination,
    Completer<void> cancelCompleter,
  ) async {
    final (session, resultFuture) = await YandexDriving.requestRoutes(
      points: [
        RequestPoint(point: origin, requestPointType: RequestPointType.wayPoint),
        RequestPoint(point: destination, requestPointType: RequestPointType.wayPoint),
      ],
      drivingOptions: const DrivingOptions(routesCount: 1),
    );
    cancelCompleter.future.then((_) => session.cancel()).ignore();
    final result = await resultFuture;
    if (result.error != null) throw result.error!;
    final routes = result.routes;
    if (routes == null || routes.isEmpty) throw Exception('No routes found');
    await session.close();
    return routes.first.geometry.points;
  }

  static Future<List<Point>> _fetchBicycle(
    Point origin,
    Point destination,
    Completer<void> cancelCompleter,
  ) async {
    final (session, resultFuture) = await YandexBicycle.requestRoutes(
      points: [
        RequestPoint(point: origin, requestPointType: RequestPointType.wayPoint),
        RequestPoint(point: destination, requestPointType: RequestPointType.wayPoint),
      ],
      fitnessOptions: const FitnessOptions(avoidSteep: false, avoidStairs: false),
      timeOptions: const TimeOptions(),
    );
    cancelCompleter.future.then((_) => session.cancel()).ignore();
    final result = await resultFuture;
    if (result.error != null) throw result.error!;
    final routes = result.routes;
    if (routes == null || routes.isEmpty) throw Exception('No routes found');
    await session.close();
    return routes.first.geometry.points;
  }

  static Future<List<Point>> _fetchPedestrian(
    Point origin,
    Point destination,
    Completer<void> cancelCompleter,
  ) async {
    final (session, resultFuture) = await YandexPedestrian.requestRoutes(
      points: [
        RequestPoint(point: origin, requestPointType: RequestPointType.wayPoint),
        RequestPoint(point: destination, requestPointType: RequestPointType.wayPoint),
      ],
      timeOptions: const TimeOptions(),
      fitnessOptions: const FitnessOptions(avoidSteep: false, avoidStairs: false),
    );
    cancelCompleter.future.then((_) => session.cancel()).ignore();
    final result = await resultFuture;
    if (result.error != null) throw result.error!;
    final routes = result.routes;
    if (routes == null || routes.isEmpty) throw Exception('No routes found');
    await session.close();
    return routes.first.geometry.points;
  }
}
