import '../models/coupon.dart';
import 'api_service.dart';

class CouponsService {
  final ApiService _api = ApiService();

  Future<List<Coupon>> listApplicableCoupons() async {
    final response = await _api.get(
      '/coupons',
      queryParameters: const {
        // Backend will enforce "active + valid_now" for customers anyway,
        // but sending this keeps behavior explicit.
        'valid_now': true,
        'is_active': true,
        'limit': 20,
        'page': 1,
      },
    );

    final root = (response.data as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final data = root['data'];
    if (data is! List) return const <Coupon>[];

    return data
        .whereType<Map>()
        .map((e) => Coupon.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}


