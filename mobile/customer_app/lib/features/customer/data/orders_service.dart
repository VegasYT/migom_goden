import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/order_model.dart';

class OrdersService {
  final _client = ApiClient();

  Future<List<ApiOrderModel>> getOrders({int offset = 0, int limit = 20}) async {
    try {
      final response = await _client.dio.get('/orders', queryParameters: {
        'offset': offset,
        'limit': limit,
      });
      final data = response.data as Map<String, dynamic>;
      final list = data['items'] as List<dynamic>;
      return list
          .map((e) => ApiOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiOrderModel> getOrder(int orderId) async {
    try {
      final response = await _client.dio.get('/orders/$orderId');
      return ApiOrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiOrderModel> createOrder({
    required int outletId,
    required String deliveryType,
    required int customerPaymentMethodId,
    int? customerAddressId,
    String? comment,
    bool leaveAtDoor = false,
  }) async {
    final body = {
      'outlet_id': outletId,
      'delivery_type': deliveryType,
      'customer_payment_method_id': customerPaymentMethodId,
      if (customerAddressId != null) 'customer_address_id': customerAddressId,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'leave_at_door': leaveAtDoor,
    };
    print('[createOrder] POST /orders body: $body');
    try {
      final response = await _client.dio.post('/orders', data: body);
      print('[createOrder] response: ${response.data}');
      return ApiOrderModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('[createOrder] error: ${e.response?.statusCode} ${e.response?.data}');
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> cancelOrder(int orderId) async {
    try {
      await _client.dio.post('/orders/$orderId/cancel');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> confirmDelivery(int orderId) async {
    try {
      await _client.dio.post('/orders/$orderId/confirm');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> confirmPickup(int orderId) async {
    try {
      await _client.dio.post('/orders/$orderId/receive');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
