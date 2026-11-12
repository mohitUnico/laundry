import 'package:dio/dio.dart';

import 'api_service.dart';

class CreateOrderResult {
  final String orderId;
  final String? pickupAddressId;
  final String? deliveryAddressId;
  final String pricingModel;
  final String orderType;
  final double totalAmount;
  final String billingStatus;

  const CreateOrderResult({
    required this.orderId,
    this.pickupAddressId,
    this.deliveryAddressId,
    required this.pricingModel,
    required this.orderType,
    required this.totalAmount,
    required this.billingStatus,
  });

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) {
    return CreateOrderResult(
      orderId: (json['order_id'] ?? '') as String,
      pickupAddressId: json['pickup_address_id'] as String?,
      deliveryAddressId: json['delivery_address_id'] as String?,
      pricingModel: (json['pricing_model'] ?? '') as String,
      orderType: (json['order_type'] ?? '') as String,
      totalAmount: (json['total_amount'] is num)
          ? (json['total_amount'] as num).toDouble()
          : 0.0,
      billingStatus: (json['billing_status'] ?? '') as String,
    );
  }
}

class _Window {
  final String? from;
  final String? to;
  const _Window(this.from, this.to);
}

/// Delivery must fall on or after the pickup calendar day plus the default
/// two-day buffer (Asia/Kolkata). A same-day or next-day choice is moved
/// forward so place order matches `validateSchedule`.
_Window _deliveryOnOrAfterBuffer({
  required String? pickupFrom,
  required String? deliveryFrom,
  required String? deliveryTo,
}) {
  const bufferDays = 2;
  if (deliveryFrom == null || deliveryFrom.isEmpty) {
    return _Window(deliveryFrom, deliveryTo);
  }
  final delivery = DateTime.parse(deliveryFrom);
  final pickupYmd = (pickupFrom == null || pickupFrom.isEmpty)
      ? _istYmd(DateTime.now())
      : _istYmd(DateTime.parse(pickupFrom));
  final earliest = _addDaysYmd(pickupYmd, bufferDays);
  final gap = _daysBetweenYmd(_istYmd(delivery), earliest);
  if (gap <= 0) return _Window(deliveryFrom, deliveryTo);
  final shiftedFrom = delivery.add(Duration(days: gap)).toUtc().toIso8601String();
  final shiftedTo = (deliveryTo == null || deliveryTo.isEmpty)
      ? deliveryTo
      : DateTime.parse(deliveryTo).add(Duration(days: gap)).toUtc().toIso8601String();
  return _Window(shiftedFrom, shiftedTo);
}

String _istYmd(DateTime instant) {
  final ist = instant.toUtc().add(const Duration(hours: 5, minutes: 30));
  final y = ist.year.toString().padLeft(4, '0');
  final m = ist.month.toString().padLeft(2, '0');
  final d = ist.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _addDaysYmd(String ymd, int days) {
  final base = DateTime.utc(
    int.parse(ymd.substring(0, 4)),
    int.parse(ymd.substring(5, 7)),
    int.parse(ymd.substring(8, 10)),
  ).add(Duration(days: days));
  final y = base.year.toString().padLeft(4, '0');
  final m = base.month.toString().padLeft(2, '0');
  final d = base.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

int _daysBetweenYmd(String from, String to) {
  final a = DateTime.utc(
    int.parse(from.substring(0, 4)),
    int.parse(from.substring(5, 7)),
    int.parse(from.substring(8, 10)),
  );
  final b = DateTime.utc(
    int.parse(to.substring(0, 4)),
    int.parse(to.substring(5, 7)),
    int.parse(to.substring(8, 10)),
  );
  return b.difference(a).inDays;
}

class OrderService {
  final ApiService _api;

  OrderService({ApiService? api}) : _api = api ?? ApiService();

  Future<CreateOrderResult> createOrder({
    String? cartId,
    required String pickupAddressId,
    required String deliveryAddressId,
    bool isExpress = false,
    String pickupMode = 'instant',
    String deliveryMode = 'instant',
    String? specialInstructions,
    String? pickupTimeFrom,
    String? pickupTimeTo,
    String? deliveryTimeFrom,
    String? deliveryTimeTo,
  }) async {
    try {
      final payload = <String, dynamic>{
        'pickup_address_id': pickupAddressId,
        'delivery_address_id': deliveryAddressId,
        'is_express': isExpress,
        'pickup_mode': isExpress ? 'instant' : pickupMode,
        'delivery_mode': isExpress ? 'instant' : deliveryMode,
      };

      if (cartId != null && cartId.isNotEmpty) {
        payload['cart_id'] = cartId;
      }
      if (specialInstructions != null && specialInstructions.isNotEmpty) {
        payload['special_instructions'] = specialInstructions;
      }
      // Express place rejects any time fields. Instant legs must omit them too.
      if (!isExpress && pickupMode == 'scheduled') {
        if (pickupTimeFrom != null && pickupTimeFrom.isNotEmpty) {
          payload['pickup_time_from'] = pickupTimeFrom;
        }
        if (pickupTimeTo != null && pickupTimeTo.isNotEmpty) {
          payload['pickup_time_to'] = pickupTimeTo;
        }
      }
      if (!isExpress && deliveryMode == 'scheduled') {
        final buffered = _deliveryOnOrAfterBuffer(
          pickupFrom: pickupMode == 'scheduled' ? pickupTimeFrom : null,
          deliveryFrom: deliveryTimeFrom,
          deliveryTo: deliveryTimeTo,
        );
        if (buffered.from != null && buffered.from!.isNotEmpty) {
          payload['delivery_time_from'] = buffered.from;
        }
        if (buffered.to != null && buffered.to!.isNotEmpty) {
          payload['delivery_time_to'] = buffered.to;
        }
      }

      final res = await _api.post(
        '/orders/create_order',
        data: payload,
      );

      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return CreateOrderResult.fromJson(data);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to create order');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final res = await _api.get(
        '/orders',
        queryParameters: queryParams,
      );

      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data;
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to fetch orders');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<void> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      await _api.post('/orders/$orderId/cancel', data: {'reason': reason});
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to cancel order'));
    }
  }

  Future<Map<String, dynamic>> rescheduleOrder({
    required String orderId,
    String? pickupFrom,
    String? pickupTo,
    String? deliveryFrom,
    String? deliveryTo,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (pickupFrom != null && pickupTo != null) {
        payload['pickup_mode'] = 'scheduled';
        payload['pickup_time_from'] = pickupFrom;
        payload['pickup_time_to'] = pickupTo;
      }
      if (deliveryFrom != null && deliveryTo != null) {
        payload['delivery_mode'] = 'scheduled';
        payload['delivery_time_from'] = deliveryFrom;
        payload['delivery_time_to'] = deliveryTo;
      }
      final res = await _api.patch('/orders/$orderId/schedule', data: payload);
      final data = (res.data as Map<String, dynamic>)['data'];
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to change schedule'));
    }
  }

  Future<void> payOrder(String orderId) async {
    try {
      final intent = await _api.post('/payments/orders/$orderId/pay-intent');
      final data = (intent.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final attempt = data['attempt'] as Map<String, dynamic>?;
      final attemptId = attempt?['attemptId'] as String?;
      if (attemptId == null || attemptId.isEmpty) {
        throw Exception('Payment could not be started');
      }
      await _api.post(
        '/payments/mock/attempts/$attemptId/complete',
        data: {'status': 'succeeded'},
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Payment failed'));
    }
  }

  String _extractErrorMessage(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // ignore
    }
    return fallback;
  }
}

