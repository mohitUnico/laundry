import 'package:dio/dio.dart';

import '../services/api_service.dart';

class DeliveryShiftService {
  final ApiService _api = ApiService();

  String _extractErrorMessage(Object error, {String fallback = 'Request failed'}) {
    if (error is DioException) {
      final res = error.response;
      final data = res?.data;
      if (data is Map) {
        final map = data.cast<String, dynamic>();
        final message = map['message'];
        final normalizedMessage = (message is String) ? message.trim() : '';
        if (normalizedMessage.isNotEmpty) return normalizedMessage;
      }
      return res != null ? 'Request failed (${res.statusCode})' : fallback;
    }
    return fallback;
  }

  /// GET /api/v1/delivery-staff/shift/status
  /// Returns { success, data: null | { shiftId, staffId, startedAt, isActive, ... }, message }
  Future<Map<String, dynamic>> getShiftStatus() async {
    try {
      final res = await _api.get('/delivery-staff/shift/status');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to get shift status'));
    }
  }

  Future<Map<String, dynamic>> startShift() async {
    try {
      final res = await _api.post('/delivery-staff/shift/start');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to start shift'));
    }
  }

  Future<Map<String, dynamic>> stopShift() async {
    try {
      final res = await _api.post('/delivery-staff/shift/stop');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to stop shift'));
    }
  }
}


