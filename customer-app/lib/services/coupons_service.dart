import '../models/coupon.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class CouponsService {
  final ApiService _api = ApiService();

  Future<List<Coupon>> listApplicableCoupons() async {
    if (kDebugMode) {
      debugPrint('[CouponsService] listApplicableCoupons: start');
    }
    try {
      const qp = {
        // Backend will enforce "active + valid_now" for customers anyway,
        // but sending this keeps behavior explicit.
        'valid_now': true,
        'is_active': true,
        'limit': 20,
        'page': 1,
      };

      final response = await _api.get(
        '/coupons',
        queryParameters: qp,
      );

      final root = (response.data as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final data = root['data'];
      if (kDebugMode) {
        debugPrint(
          '[CouponsService] listApplicableCoupons: status=${response.statusCode} '
          'path=${response.requestOptions.path} '
          'query=${response.requestOptions.queryParameters} '
          'responseKeys=${root.keys.toList()} dataType=${data.runtimeType}',
        );
      }
      if (data is! List) return const <Coupon>[];

      final coupons = data
          .whereType<Map>()
          .map((e) => Coupon.fromJson(e.cast<String, dynamic>()))
          .toList();
      if (kDebugMode) {
        debugPrint('[CouponsService] listApplicableCoupons: parsed coupons=${coupons.length}');
      }
      return coupons;
    } on DioException catch (e) {
      if (kDebugMode) {
        final status = e.response?.statusCode;
        final body = e.response?.data;
        debugPrint(
          '[CouponsService] listApplicableCoupons: DioException status=$status '
          'path=${e.requestOptions.path} query=${e.requestOptions.queryParameters} '
          'body=$body',
        );
      }
      rethrow;
    }
  }
}


