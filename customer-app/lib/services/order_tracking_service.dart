import 'package:dio/dio.dart';

import 'api_service.dart';

class OrderTrackingPoint {
  final String? address;
  final double? latitude;
  final double? longitude;

  const OrderTrackingPoint({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory OrderTrackingPoint.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return OrderTrackingPoint(
      address: json['address'] as String?,
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
    );
  }
}

class OrderTrackingStaff {
  final String staffId;
  final String fullName;
  final double? latitude;
  final double? longitude;

  const OrderTrackingStaff({
    required this.staffId,
    required this.fullName,
    required this.latitude,
    required this.longitude,
  });

  factory OrderTrackingStaff.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return OrderTrackingStaff(
      staffId: (json['staffId'] ?? '') as String,
      fullName: (json['fullName'] ?? '') as String,
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
    );
  }
}

class OrderTrackingDeliveryLeg {
  final String deliveryId;
  final String deliveryType; // pickup | drop
  final String deliveryStatus;
  final String? staffId;
  final OrderTrackingStaff? staff;

  const OrderTrackingDeliveryLeg({
    required this.deliveryId,
    required this.deliveryType,
    required this.deliveryStatus,
    required this.staffId,
    required this.staff,
  });

  factory OrderTrackingDeliveryLeg.fromJson(Map<String, dynamic> json) {
    final staffRaw = json['staff'];
    return OrderTrackingDeliveryLeg(
      deliveryId: (json['deliveryId'] ?? '') as String,
      deliveryType: (json['deliveryType'] ?? '') as String,
      deliveryStatus: (json['deliveryStatus'] ?? '') as String,
      staffId: json['staffId'] as String?,
      staff: staffRaw is Map<String, dynamic> ? OrderTrackingStaff.fromJson(staffRaw) : null,
    );
  }
}

class OrderTrackingData {
  final String orderId;
  final String orderStatus;
  final String orderType; // pickup_only | drop_only | both
  final String shopName;
  final OrderTrackingPoint shop;
  final OrderTrackingPoint? pickup;
  final OrderTrackingPoint? delivery;
  final OrderTrackingDeliveryLeg? pickupLeg;
  final OrderTrackingDeliveryLeg? dropLeg;

  const OrderTrackingData({
    required this.orderId,
    required this.orderStatus,
    required this.orderType,
    required this.shopName,
    required this.shop,
    required this.pickup,
    required this.delivery,
    required this.pickupLeg,
    required this.dropLeg,
  });

  factory OrderTrackingData.fromJson(Map<String, dynamic> json) {
    final shopRaw = (json['shop'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final pickupRaw = json['pickup'];
    final deliveryRaw = json['delivery'];
    final deliveriesRaw = (json['deliveries'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    final pickupLegRaw = deliveriesRaw['pickup'];
    final dropLegRaw = deliveriesRaw['drop'];

    return OrderTrackingData(
      orderId: (json['orderId'] ?? '') as String,
      orderStatus: (json['orderStatus'] ?? '') as String,
      orderType: (json['orderType'] ?? '') as String,
      shopName: (shopRaw['name'] ?? '') as String,
      shop: OrderTrackingPoint.fromJson(shopRaw),
      pickup: pickupRaw is Map<String, dynamic> ? OrderTrackingPoint.fromJson(pickupRaw) : null,
      delivery: deliveryRaw is Map<String, dynamic> ? OrderTrackingPoint.fromJson(deliveryRaw) : null,
      pickupLeg: pickupLegRaw is Map<String, dynamic> ? OrderTrackingDeliveryLeg.fromJson(pickupLegRaw) : null,
      dropLeg: dropLegRaw is Map<String, dynamic> ? OrderTrackingDeliveryLeg.fromJson(dropLegRaw) : null,
    );
  }
}

class OrderTrackingService {
  final ApiService _api;

  OrderTrackingService({ApiService? api}) : _api = api ?? ApiService();

  Future<OrderTrackingData> getOrderTracking({required String orderId}) async {
    try {
      final res = await _api.get('/orders/$orderId/tracking');
      final root = (res.data as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final data = (root['data'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      return OrderTrackingData.fromJson(data);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to fetch tracking');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to fetch tracking: $e');
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


