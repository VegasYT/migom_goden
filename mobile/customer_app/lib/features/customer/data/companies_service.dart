import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/company_model.dart';

class CompaniesService {
  final _client = ApiClient();

  Future<List<CompanyModel>> getCompanies({int offset = 0, int limit = 20, String? search}) async {
    try {
      final response = await _client.dio.get('/companies', queryParameters: {
        'offset': offset,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final data = response.data as Map<String, dynamic>;
      final list = data['items'] as List<dynamic>;
      return list
          .map((e) => CompanyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CompanyMenu> getCompanyMenu(int companyId) async {
    try {
      final response = await _client.dio.get('/companies/$companyId/menu');
      return CompanyMenu.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CompanyMenu> getOutletMenu(int outletId) async {
    try {
      final response = await _client.dio.get('/outlets/$outletId/menu');
      return CompanyMenu.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<OutletModel>> getCompanyOutlets(int companyId) async {
    try {
      final response = await _client.dio.get('/companies/$companyId/outlets');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => OutletModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
