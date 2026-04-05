import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/payment_method_model.dart';

class PaymentMethodService {
  final _client = ApiClient();

  Future<List<PaymentMethodModel>> getMethods() async {
    try {
      final response = await _client.dio.get('/customers/me/payment-methods');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PaymentMethodModel> createMethod(PaymentMethodModel method) async {
    try {
      final response = await _client.dio.post(
        '/customers/me/payment-methods',
        data: method.toJson(),
      );
      return PaymentMethodModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteMethod(String id) async {
    try {
      await _client.dio.delete('/customers/me/payment-methods/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
