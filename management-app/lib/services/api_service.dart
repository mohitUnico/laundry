import 'package:dio/dio.dart';

import '../utils/api_config.dart';
import '../utils/auth_storage.dart';
import '../utils/mock_config.dart';

class ApiService {
  late Dio _dio;

  static String get baseUrl => '${ApiConfig.backendBaseUrl}/api/v1';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle errors globally
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    _blockIfMock(path);
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    _blockIfMock(path);
    return _dio.post(path, data: data);
  }

  Future<Response> postFormData(String path, {required FormData data}) {
    _blockIfMock(path);
    return _dio.post(
      path,
      data: data,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response> put(String path, {dynamic data}) {
    _blockIfMock(path);
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    _blockIfMock(path);
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) {
    _blockIfMock(path);
    return _dio.delete(path, data: data);
  }

  void _blockIfMock(String path) {
    if (!MockConfig.bypassBackend) return;
    throw StateError('Mock mode is on, so $path was not sent to the backend.');
  }
}
