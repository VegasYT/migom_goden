import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/cart_model.dart';

class CartService {
  final _client = ApiClient();

  Future<AllCartsResponse> getAllCarts() async {
    try {
      final response = await _client.dio.get('/cart');
      return AllCartsResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CartModel> getCompanyCart(int companyId) async {
    try {
      final response = await _client.dio.get('/cart/$companyId');
      return CartModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> addItem({required int catalogItemId, required int quantity}) async {
    try {
      await _client.dio.post('/cart/items', data: {
        'catalog_item_id': catalogItemId,
        'quantity': quantity,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateItem({required int itemId, required int quantity}) async {
    try {
      await _client.dio.patch('/cart/items/$itemId', data: {'quantity': quantity});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> removeItem(int itemId) async {
    try {
      await _client.dio.delete('/cart/items/$itemId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> clearCompanyCart(int companyId) async {
    try {
      await _client.dio.delete('/cart/$companyId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> clearAllCarts() async {
    try {
      await _client.dio.delete('/cart');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
