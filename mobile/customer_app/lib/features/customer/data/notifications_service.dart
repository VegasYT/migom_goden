import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/notification_model.dart';

class NotificationsService {
  final _client = ApiClient();

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _client.dio.get('/notifications');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _client.dio.post('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client.dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
