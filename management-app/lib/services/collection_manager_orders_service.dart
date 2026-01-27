import 'package:dio/dio.dart';

import '../services/api_service.dart';

class CollectionManagerOrdersService {
  final ApiService _api = ApiService();

  String _extractErrorMessage(Object error, {String fallback = 'Request failed'}) {
    if (error is DioException) {
      final res = error.response;
      final data = res?.data;
      if (data is Map) {
        final map = data.cast<String, dynamic>();
        final message = map['message'];
        final normalizedMessage = (message is String) ? message.trim() : '';

        final errors = map['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is Map) {
            final firstMap = first.cast<String, dynamic>();
            final field = firstMap['field']?.toString();
            final msg = firstMap['message']?.toString();
            if ((msg ?? '').trim().isNotEmpty) {
              return field != null && field.isNotEmpty ? '$field: $msg' : msg!.trim();
            }
          }
        }

        if (normalizedMessage.isNotEmpty &&
            normalizedMessage.toLowerCase() != 'validation failed' &&
            normalizedMessage.toLowerCase() != 'query validation failed') {
          return normalizedMessage;
        }
      }
      return res != null ? 'Request failed (${res.statusCode})' : fallback;
    }
    return fallback;
  }

  Future<Map<String, dynamic>> listIncomingOrders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _api.get(
        '/staff-app/collection-manager/orders/incoming',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch incoming orders'));
    }
  }

  Future<Map<String, dynamic>> listReceivedOrders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _api.get(
        '/staff-app/collection-manager/orders/received',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch received orders'));
    }
  }

  Future<Map<String, dynamic>> getOrderItems({required String orderId}) async {
    try {
      final res = await _api.get('/staff-app/collection-manager/orders/$orderId/items');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch order items'));
    }
  }

  Future<Map<String, dynamic>> markOrderReceived({required String orderId}) async {
    try {
      final res = await _api.post('/staff-app/collection-manager/orders/$orderId/receive');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to mark order as received'));
    }
  }

  Future<Map<String, dynamic>> submitToServices({required String orderId}) async {
    try {
      final res = await _api.post('/staff-app/collection-manager/orders/$orderId/submit-to-services');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to submit order to services'));
    }
  }

  Future<Map<String, dynamic>> assignPickupDirect({
    required String orderId,
    required String deliveryStaffId,
  }) async {
    try {
      final res = await _api.post(
        '/staff-app/collection-manager/orders/$orderId/assign-pickup-direct',
        data: {'deliveryStaffId': deliveryStaffId},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to assign pickup to delivery staff'));
    }
  }

  Future<Map<String, dynamic>> listSubmissionHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _api.get(
        '/staff-app/collection-manager/orders/history',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch history'));
    }
  }
}


