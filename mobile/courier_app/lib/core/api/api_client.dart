import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// адрес API задаётся при сборке: flutter run --dart-define=API_URL=http://10.0.2.2/api/v1
const kBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://migom.site/api/v1');

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
      final newAccess = await _refresh();
      if (newAccess != null) {
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccess';
        try {
          handler.resolve(await _dio.fetch(opts));
        } on DioException catch (e) {
          // ошибка повтора (например, 404 "нет активного заказа") - ответ сервера, сессия жива
          handler.next(e);
        }
        return;
      }
    }
    handler.next(err);
  }

  /// Новый access-токен по refresh-токену; при отказе сессия сбрасывается.
  Future<String?> _refresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return null;
    try {
      final resp = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );
      final newAccess = resp.data['access_token'] as String;
      await _storage.write(key: 'access_token', value: newAccess);
      await _storage.write(key: 'refresh_token', value: resp.data['refresh_token'] as String);
      return newAccess;
    } catch (_) {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      return null;
    }
  }
}
