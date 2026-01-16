import '../models/service_category.dart';
import '../models/clothes_item.dart';
import '../models/service_item.dart';
import 'api_service.dart';

class ServiceCatalogService {
  final ApiService _api;

  ServiceCatalogService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<ServiceCategory>> listServiceCategories({bool? isActive}) async {
    final response = await _api.get(
      '/clothes/service-categories',
      queryParameters: {
        if (isActive != null) 'isActive': isActive,
      },
    );

    final data = (response.data as Map?)?['data'];
    if (data is! List) {
      throw Exception('Invalid response from service-categories');
    }

    return data
        .whereType<Map>()
        .map((e) => ServiceCategory.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<ServiceItem>> listServices({
    required String categoryId,
    bool? isActive,
  }) async {
    final response = await _api.get(
      '/clothes/services',
      queryParameters: {
        'categoryId': categoryId,
        if (isActive != null) 'isActive': isActive,
      },
    );

    final data = (response.data as Map?)?['data'];
    if (data is! List) {
      throw Exception('Invalid response from services');
    }

    return data
        .whereType<Map>()
        .map((e) => ServiceItem.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<ClothesItem>> listClothesItems({
    required String serviceId,
    bool? isActive,
  }) async {
    final response = await _api.get(
      '/clothes/clothes-items',
      queryParameters: {
        'serviceId': serviceId,
        if (isActive != null) 'isActive': isActive,
      },
    );

    final data = (response.data as Map?)?['data'];
    if (data is! List) {
      throw Exception('Invalid response from clothes-items');
    }

    return data
        .whereType<Map>()
        .map((e) => ClothesItem.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}


