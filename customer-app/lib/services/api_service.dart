import 'dart:async';

import 'package:dio/dio.dart';

import '../utils/auth_storage.dart';
import '../utils/jwt_utils.dart';

class ApiService {
  late Dio _dio;
  static Future<void>? _refreshInFlight;

  // Local backend (see backend/.env PORT=3000).
  //
  // IMPORTANT:
  // - Android emulator: use http://10.0.2.2:3000/api/v1
  // - Real device: use your PC LAN IP (e.g. http://192.168.x.x:3000/api/v1)
  // - USB-only (no Wi‑Fi): use adb reverse and then http://localhost:3000/api/v1
  //
  // You can always override:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.9:3000/api/v1
  static String resolveBaseUrl() {
    const defined = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (defined.isNotEmpty) return defined;

    // Default for local dev. For real devices or emulators, pass API_BASE_URL.
    return 'http://localhost:3000/api/v1';
  }

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;
          if (!skipAuth) {
            var token = await AuthStorage.getAuthToken();
            if (token != null && token.isNotEmpty && JwtUtils.isExpired(token)) {
              // Try to refresh once before sending the request.
              await _refreshIfPossible();
              token = await AuthStorage.getAuthToken();
            }
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final res = error.response;
          final status = res?.statusCode ?? 0;
          final req = error.requestOptions;

          final alreadyRetried = req.extra['retried'] == true;
          final skipRefresh = req.extra['skipRefresh'] == true;

          if (status == 401 && !alreadyRetried && !skipRefresh) {
            try {
              await _refreshIfPossible();
              final token = await AuthStorage.getAuthToken();
              if (token != null && token.isNotEmpty) {
                req.headers['Authorization'] = 'Bearer $token';
                req.extra['retried'] = true;
                final clone = await _dio.fetch(req);
                return handler.resolve(clone);
              }
            } catch (_) {
              // fallthrough to original error
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  static Future<void> _refreshIfPossible() async {
    if (_refreshInFlight != null) return _refreshInFlight!;

    final completer = Completer<void>();
    _refreshInFlight = completer.future;

    try {
      final refresh = await AuthStorage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        throw Exception('Missing refresh token');
      }

      // Use a fresh Dio instance with the same base URL but without interceptors,
      // so refresh doesn't recurse into 401 handler.
      final dio = Dio(BaseOptions(baseUrl: resolveBaseUrl()));
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
        options: Options(extra: {'skipAuth': true, 'skipRefresh': true}),
      );

      final data = (response.data as Map?)?['data'] as Map?;
      final token = (data?['token'] ?? '') as String;
      final newRefresh = (data?['refreshToken'] ?? '') as String;

      if (token.isEmpty || newRefresh.isEmpty) {
        throw Exception('Invalid refresh response');
      }

      await AuthStorage.setAuthToken(token);
      await AuthStorage.setRefreshToken(newRefresh);
      completer.complete();
    } catch (e) {
      // If refresh fails, clear stored session to force re-login.
      await AuthStorage.clearSession();
      completer.completeError(e);
    } finally {
      _refreshInFlight = null;
    }

    return completer.future;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> postFormData(String path, {required FormData data}) {
    return _dio.post(
      path,
      data: data,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
