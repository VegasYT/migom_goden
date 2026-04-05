import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../data/route_repository.dart';
import 'courier_profile_provider.dart';

class RouteState {
  final List<Point> points;
  final bool isLoading;

  const RouteState({this.points = const [], this.isLoading = false});
}

class RouteNotifier extends StateNotifier<RouteState> {
  final Ref _ref;

  RouteNotifier(this._ref) : super(const RouteState());

  Completer<void>? _cancelCompleter;

  Future<void> fetch({required Point origin, required Point destination}) async {
    _cancelCompleter?.complete();
    _cancelCompleter = Completer<void>();

    if (!mounted) return;
    state = const RouteState(isLoading: true);

    final vehicleType = _ref.read(courierProfileSyncProvider).vehicleType;

    try {
      final points = await RouteRepository.fetchRoute(
        origin: origin,
        destination: destination,
        vehicleType: vehicleType,
        cancelCompleter: _cancelCompleter!,
      );
      if (!mounted) return;
      state = RouteState(points: points);
    } catch (e) {
      if (e.toString() == 'cancelled') return;
      if (!mounted) return;
      state = RouteState(points: [origin, destination]);
    }
  }

  void clear() {
    _cancelCompleter?.complete();
    _cancelCompleter = null;
    if (mounted) state = const RouteState();
  }

  @override
  void dispose() {
    _cancelCompleter?.complete();
    super.dispose();
  }
}

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>(
  (ref) => RouteNotifier(ref),
);
