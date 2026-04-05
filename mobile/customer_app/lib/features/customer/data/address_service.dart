import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/address_model.dart';

class AddressService {
  final _client = ApiClient();

  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _client.dio.get('/customers/me/addresses');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AddressModel> createAddress(AddressModel address) async {
    try {
      final response = await _client.dio.post(
        '/customers/me/addresses',
        data: address.toJson(),
      );
      return AddressModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AddressModel> updateAddress(String id, AddressModel address) async {
    try {
      final response = await _client.dio.patch(
        '/customers/me/addresses/$id',
        data: address.toJson(),
      );
      return AddressModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _client.dio.delete('/customers/me/addresses/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
