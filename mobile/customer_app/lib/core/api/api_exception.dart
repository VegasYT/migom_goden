import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Произошла ошибка';

    if (data is Map<String, dynamic> && data['detail'] != null) {
      message = data['detail'].toString();
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Превышено время ожидания';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Нет подключения к серверу';
    }

    return ApiException(message, statusCode: code);
  }

  @override
  String toString() => message;
}
