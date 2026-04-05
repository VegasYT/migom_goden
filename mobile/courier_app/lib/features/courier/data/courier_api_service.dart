import '../../../core/api/api_client.dart';

class CourierApiService {
  final _dio = ApiClient.instance.dio;

  // ── Профиль ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final resp = await _dio.get('/couriers/me');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? typeMovement,  // walk | scooter | car
    int? radiusKm,
    double? zoneLatitude,
    double? zoneLongitude,
  }) async {
    final body = <String, dynamic>{
      if (typeMovement != null) 'type_movement': typeMovement,
      if (radiusKm != null) 'radius_km': radiusKm,
      if (zoneLatitude != null) 'zone_latitude': zoneLatitude,
      if (zoneLongitude != null) 'zone_longitude': zoneLongitude,
    };
    final resp = await _dio.patch('/couriers/me', data: body);
    return resp.data as Map<String, dynamic>;
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    await _dio.post('/couriers/me/location', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // ── Смены ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> startShift() async {
    final resp = await _dio.post('/shifts/start');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> endShift() async {
    final resp = await _dio.post('/shifts/end');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getCurrentShift() async {
    try {
      final resp = await _dio.get('/shifts/me/current');
      return resp.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getShiftHistory({
    int offset = 0,
    int limit = 20,
  }) async {
    final resp = await _dio.get('/shifts/me/history', queryParameters: {
      'offset': offset,
      'limit': limit,
    });
    final data = resp.data as Map<String, dynamic>;
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  // ── Заказы ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getActiveOrder() async {
    try {
      final resp = await _dio.get('/courier/orders/active');
      return resp.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    final resp = await _dio.get('/courier/orders/available');
    final data = resp.data as Map<String, dynamic>;
    return (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    final resp = await _dio.post('/courier/orders/$orderId/accept');
    return resp.data as Map<String, dynamic>;
  }

  Future<void> rejectOrder(int orderId) async {
    await _dio.post('/courier/orders/$orderId/reject');
  }

  Future<Map<String, dynamic>> pickupOrder(int orderId) async {
    final resp = await _dio.post('/courier/orders/$orderId/pickup');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deliverOrder(int orderId) async {
    final resp = await _dio.post('/courier/orders/$orderId/deliver');
    return resp.data as Map<String, dynamic>;
  }

  // ── Торговая точка (ресторан) ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getOutlet(int outletId) async {
    final resp = await _dio.get('/outlets/$outletId');
    return resp.data as Map<String, dynamic>;
  }

  // ── История заказов ────────────────────────────────────────────────────────
  // NOTE: No API endpoint for courier order history exists.
  // See COMMENTED_FEATURES.md §2.
}
