import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/profile_model.dart';

class ProfileService {
  final _client = ApiClient();

  Future<ProfileModel> getProfile() async {
    try {
      final response = await _client.dio.get('/users/me');
      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ProfileModel> updateProfile({String? fullName, String? phone}) async {
    try {
      final response = await _client.dio.patch('/users/me', data: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      });
      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.dio.post('/users/me/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
