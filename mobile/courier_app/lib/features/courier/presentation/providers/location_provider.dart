import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../data/courier_api_service.dart';

class LocationNotifier extends StateNotifier<Point?> {
  LocationNotifier(this._api) : super(null);

  final CourierApiService _api;
  StreamSubscription<Position>? _sub;
  DateTime? _lastSent;

  Future<void> init() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[Location] Location services disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        print('[Location] Permission denied: $permission');
        return;
      }

      print('[Location] Starting position stream');
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (pos) {
          if (mounted) {
            state = Point(latitude: pos.latitude, longitude: pos.longitude);
            _maybeSendLocation(pos.latitude, pos.longitude);
          }
        },
        onError: (e) {
          print('[Location] Stream error: $e');
        },
      );
    } catch (e) {
      print('[Location] init error: $e');
    }
  }

  void _maybeSendLocation(double lat, double lng) {
    final now = DateTime.now();
    if (_lastSent != null && now.difference(_lastSent!).inSeconds < 10) return;
    _lastSent = now;
    _api.updateLocation(latitude: lat, longitude: lng).ignore();
  }

  void setPosition(Point point) {
    if (mounted) state = point;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final _locationApiProvider = Provider<CourierApiService>((_) => CourierApiService());

final locationProvider = StateNotifierProvider<LocationNotifier, Point?>((ref) {
  final notifier = LocationNotifier(ref.read(_locationApiProvider));
  notifier.init();
  return notifier;
});
