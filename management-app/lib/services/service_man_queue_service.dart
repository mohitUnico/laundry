import 'package:dio/dio.dart';

import '../services/api_service.dart';

class ServiceManQueueService {
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

  Future<Map<String, dynamic>> listQueue({
    required String statusCsv,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _api.get(
        '/staff-app/service-man/queue',
        queryParameters: {
          'status': statusCsv,
          'page': page,
          'limit': limit,
        },
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch queue'));
    }
  }

  Future<Map<String, dynamic>> listCompleted({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _api.get(
        '/staff-app/service-man/completed',
        queryParameters: {'page': page, 'limit': limit},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch completed items'));
    }
  }

  Future<Map<String, dynamic>> updateQueueItem({
    required String queueId,
    required String action,
    String? comments,
  }) async {
    try {
      final res = await _api.patch(
        '/staff-app/service-man/queue/$queueId',
        data: {
          'action': action,
          if (comments != null && comments.trim().isNotEmpty) 'comments': comments.trim(),
        },
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to update item'));
    }
  }
}


