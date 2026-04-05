import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class AuthService {
  final _client = ApiClient();

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await _client.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      await _client.saveTokens(
        data['access_token'] as String,
        data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'role_id': 1, // customer
      });
      final data = response.data as Map<String, dynamic>;
      await _client.saveTokens(
        data['access_token'] as String,
        data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } catch (_) {
    } finally {
      await _client.clearTokens();
    }
  }

  Future<bool> isLoggedIn() => _client.hasToken();
}
