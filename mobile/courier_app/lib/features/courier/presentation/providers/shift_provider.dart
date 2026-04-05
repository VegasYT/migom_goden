import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/courier_api_service.dart';

enum ShiftStatus { idle, active, paused }

@immutable
class ShiftState {
  final ShiftStatus status;
  final DateTime? startedAt;
  final Duration elapsed;
  final int ordersCompleted;
  final double earned;
  final double distanceKm;
  final int? shiftId; // server-side shift id

  const ShiftState({
    this.status = ShiftStatus.idle,
    this.startedAt,
    this.elapsed = Duration.zero,
    this.ordersCompleted = 0,
    this.earned = 0,
    this.distanceKm = 0,
    this.shiftId,
  });

  bool get isActive => status == ShiftStatus.active;
  bool get isIdle => status == ShiftStatus.idle;

  ShiftState copyWith({
    ShiftStatus? status,
    DateTime? startedAt,
    Duration? elapsed,
    int? ordersCompleted,
    double? earned,
    double? distanceKm,
    int? shiftId,
  }) {
    return ShiftState(
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      elapsed: elapsed ?? this.elapsed,
      ordersCompleted: ordersCompleted ?? this.ordersCompleted,
      earned: earned ?? this.earned,
      distanceKm: distanceKm ?? this.distanceKm,
      shiftId: shiftId ?? this.shiftId,
    );
  }
}

class ShiftNotifier extends StateNotifier<ShiftState> {
  ShiftNotifier(this._api) : super(const ShiftState()) {
    _restoreActiveShift();
  }

  final CourierApiService _api;
  Timer? _timer;

  Future<void> _restoreActiveShift() async {
    try {
      final current = await _api.getCurrentShift();
      if (current != null && current['is_active'] == true) {
        final startedAt = DateTime.parse(current['started_at'] as String);
        final id = current['id'] as int;
        state = ShiftState(
          status: ShiftStatus.active,
          startedAt: startedAt,
          elapsed: DateTime.now().difference(startedAt),
          shiftId: id,
        );
        _startTimer();
      }
    } catch (_) {}
  }

  Future<void> startShift() async {
    // Send current GPS position before starting shift so the server knows
    // where to look for orders within the courier's zone.
    await _sendCurrentLocation();

    try {
      final data = await _api.startShift();
      final startedAt = DateTime.parse(data['started_at'] as String);
      state = ShiftState(
        status: ShiftStatus.active,
        startedAt: startedAt,
        elapsed: Duration.zero,
        shiftId: data['id'] as int,
      );
      _startTimer();
    } catch (_) {
      // Fallback: start locally if API fails
      final now = DateTime.now();
      state = state.copyWith(
        status: ShiftStatus.active,
        startedAt: now,
        elapsed: Duration.zero,
      );
      _startTimer();
    }
  }

  Future<void> _sendCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      await _api.updateLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      // Also set zone center to current position if not set yet
      await _api.updateProfile(
        zoneLatitude: pos.latitude,
        zoneLongitude: pos.longitude,
      );
    } catch (_) {}
  }

  void pauseShift() {
    _timer?.cancel();
    state = state.copyWith(status: ShiftStatus.paused);
  }

  void resumeShift() {
    state = state.copyWith(status: ShiftStatus.active);
    _startTimer();
  }

  Future<void> endShift() async {
    _timer?.cancel();
    try {
      if (state.shiftId != null) {
        await _api.endShift();
      }
    } catch (_) {}
    state = const ShiftState();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.startedAt != null) {
        state = state.copyWith(
          elapsed: DateTime.now().difference(state.startedAt!),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final _shiftApiProvider = Provider<CourierApiService>((_) => CourierApiService());

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>(
  (ref) => ShiftNotifier(ref.read(_shiftApiProvider)),
);
