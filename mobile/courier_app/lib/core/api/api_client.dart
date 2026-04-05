import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const kBaseUrl = 'https://shawnna-polyatomic-pseudocritically.ngrok-free.dev/api/v1';

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(_AuthInterceptor(_storage, _dio));
  }

  static final ApiClient instance = ApiClient._();

  static String get baseUrl => kBaseUrl;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Dio get dio => _dio;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage, this._dio);

  final FlutterSecureStorage _storage;
  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final resp = await _dio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: Options(headers: {'Authorization': null}),
          );
          final newAccess = resp.data['access_token'] as String;
          final newRefresh = resp.data['refresh_token'] as String;
          await _storage.write(key: 'access_token', value: newAccess);
          await _storage.write(key: 'refresh_token', value: newRefresh);

          // Retry original request
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccess';
          final retryResp = await _dio.fetch(opts);
          handler.resolve(retryResp);
          return;
        } catch (_) {
          await _storage.delete(key: 'access_token');
          await _storage.delete(key: 'refresh_token');
        }
      }
    }
    handler.next(err);
  }
}
