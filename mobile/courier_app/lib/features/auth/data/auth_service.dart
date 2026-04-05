import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class AuthService {
  final _dio = ApiClient.instance.dio;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final resp = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await ApiClient.instance.saveTokens(
      accessToken: resp.data['access_token'] as String,
      refreshToken: resp.data['refresh_token'] as String,
    );
  }

  /// Fetch available roles and return the courier role id.
  Future<int?> _getCourierRoleId() async {
    try {
      final resp = await _dio.get('/auth/roles');
      final roles = resp.data as List;
      for (final role in roles) {
        final name = (role['name'] as String?)?.toLowerCase() ?? '';
        if (name.contains('courier') || name.contains('курьер')) {
          return role['id'] as int;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final courierRoleId = await _getCourierRoleId();

    final resp = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (courierRoleId != null) 'role_id': courierRoleId,
    });
    await ApiClient.instance.saveTokens(
      accessToken: resp.data['access_token'] as String,
      refreshToken: resp.data['refresh_token'] as String,
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (_) {
      // ignore errors on logout
    } finally {
      await ApiClient.instance.clearTokens();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await ApiClient.instance.getAccessToken();
    return token != null;
  }
}
