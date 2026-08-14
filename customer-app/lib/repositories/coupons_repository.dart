import '../models/coupon.dart';
import '../services/coupons_service.dart';

class CouponsRepository {
  final CouponsService _service;

  CouponsRepository({CouponsService? service}) : _service = service ?? CouponsService();

  Future<List<Coupon>> listApplicableCoupons() {
    return _service.listApplicableCoupons();
  }
}


