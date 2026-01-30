import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await _api.get('/delivery-staff-app/profile');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch profile'));
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

  Future<Map<String, dynamic>> getPerKgItems({required String orderId}) async {
    try {
      final res = await _api.get('/delivery-staff-app/orders/$orderId/items/weights');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to fetch per-kg items'));
    }
  }

  Future<Map<String, dynamic>> updatePerKgWeights({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await _api.patch(
        '/delivery-staff-app/orders/$orderId/items/weights',
        data: {'items': items},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to update weights'));
    }
  }

  Future<Map<String, dynamic>> markPickedUpWithProof({
    required String deliveryId,
    required XFile file,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      });
      final res = await _api.postFormData(
        '/delivery-staff-app/deliveries/$deliveryId/mark-picked-up',
        data: formData,
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to mark picked up'));
    }
  }

  Future<Map<String, dynamic>> markDeliveredWithProof({
    required String deliveryId,
    required XFile file,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      });
      final res = await _api.postFormData(
        '/delivery-staff-app/deliveries/$deliveryId/mark-delivered',
        data: formData,
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to mark delivered'));
    }
  }

  Future<Map<String, dynamic>> markSubmittedToCm({required String deliveryId}) async {
    try {
      final res = await _api.patch(
        '/delivery-staff-app/deliveries/$deliveryId/status',
        data: {'action': 'submitted_to_cm'},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to mark submitted'));
    }
  }

  Future<Map<String, dynamic>> acceptAssignmentRequest({required String requestId}) async {
    try {
      final res = await _api.post('/delivery-staff/assignment-requests/$requestId/accept');
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to accept assignment request'));
    }
  }

  Future<Map<String, dynamic>> rejectAssignmentRequest({
    required String requestId,
    String? rejectionNote,
  }) async {
    try {
      final res = await _api.post(
        '/delivery-staff/assignment-requests/$requestId/reject',
        data: rejectionNote != null ? {'rejectionNote': rejectionNote} : {},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) return body;
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Failed to reject assignment request'));
    }
  }
}


