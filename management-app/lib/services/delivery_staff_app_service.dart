import 'package:dio/dio.dart';

import '../services/api_service.dart';

class DeliveryStaffAppService {
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

  Future<Map<String, dynamic>> getHomeStats() async {
    try {
      final res = await _api.get('/delivery-staff-app/home/stats');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch home stats'));
    }
  }

  Future<Map<String, dynamic>> listAcceptedOrders({int page = 1, int limit = 20}) async {
    try {
      final res = await _api.get(
        '/delivery-staff-app/orders/accepted',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch accepted orders'));
    }
  }

  Future<Map<String, dynamic>> listOrderHistory({
    int page = 1,
    int limit = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final qp = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (from != null) qp['from'] = from.toIso8601String();
      if (to != null) qp['to'] = to.toIso8601String();

      final res = await _api.get(
        '/delivery-staff-app/orders/history',
        queryParameters: qp,
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch order history'));
    }
  }
}


