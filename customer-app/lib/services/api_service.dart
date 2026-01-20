import 'dart:async';

import 'package:dio/dio.dart';

import '../utils/auth_storage.dart';
import '../utils/jwt_utils.dart';

class ApiService {
  late Dio _dio;
  static Future<void>? _refreshInFlight;

  // Deployed backend at http://13.232.71.139:4000
  //
  // IMPORTANT:
  // - Default: Uses deployed backend at http://13.232.71.139:4000/api/v1
  // - For local development, override with:
  //   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
  // - Android emulator (local): use http://10.0.2.2:3000/api/v1
  // - Real device (local): use your PC LAN IP (e.g. http://192.168.x.x:3000/api/v1)
  static String resolveBaseUrl() {
    const defined = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (defined.isNotEmpty) return defined;

    // Default: Deployed backend
    return 'http://13.232.71.139:4000/api/v1';
  }

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 5), // Reduced from 10s to 5s
        receiveTimeout: const Duration(seconds: 5), // Reduced from 10s to 5s
        sendTimeout: const Duration(seconds: 5), // Added send timeout
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Request interceptor - ensures Authorization header is always added when token exists
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;
          if (!skipAuth) {
            // Get token without proactive refresh to avoid latency
            // Token refresh will happen on 401 error if needed
            final token = await AuthStorage.getAuthToken();
            
            // Only add token if it exists and is not obviously expired
            // Let the error handler deal with refresh on 401
            if (token != null && token.isNotEmpty) {
              // Quick check: only refresh if token is definitely expired (not "expiring soon")
              // This avoids blocking every request with token refresh
              if (JwtUtils.isExpired(token)) {
                // Token is already expired, try refresh in background (don't block request)
                _refreshIfPossible().catchError((_) {
                  // Ignore refresh errors, let 401 handler deal with it
                });
              }
              
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

          // Retry on 401 (Unauthorized) - token expired or invalid
          if (status == 401 && !alreadyRetried && !skipRefresh) {
            try {
              // Try to refresh the token
              await _refreshIfPossible();
              final token = await AuthStorage.getAuthToken();
              if (token != null && token.isNotEmpty) {
                // Update the request with new token and retry
                req.headers['Authorization'] = 'Bearer $token';
                req.extra['retried'] = true;
                final clone = await _dio.fetch(req);
                return handler.resolve(clone);
              }
            } catch (e) {
              // If refresh fails, clear session and let error propagate
              await AuthStorage.clearSession();
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

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(String path, {dynamic data, Options? options}) {
    return _dio.post(
      path,
      data: data,
      options: options,
    );
  }

  Future<Response> postFormData(String path, {required FormData data, Options? options}) {
    final mergedOptions = Options(
      contentType: 'multipart/form-data',
      extra: {...?options?.extra},
    );
    return _dio.post(
      path,
      data: data,
      options: mergedOptions,
    );
  }

  Future<Response> put(String path, {dynamic data, Options? options}) {
    return _dio.put(
      path,
      data: data,
      options: options,
    );
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) {
    return _dio.patch(
      path,
      data: data,
      options: options,
    );
  }

  Future<Response> delete(String path, {Options? options}) {
    return _dio.delete(
      path,
      options: options,
    );
  }
}
