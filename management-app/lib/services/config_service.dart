import 'package:dio/dio.dart';

import '../services/api_service.dart';

class ConfigService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>?> fetchConfig() async {
    try {
      final res = await _api.get('/config');
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      // If config fetch fails, return null (app will continue without Supabase)
      print('Failed to fetch config: $e');
      return null;
    }
  }
}

