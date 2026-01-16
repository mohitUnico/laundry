import '../models/service_category.dart';
import '../models/clothes_item.dart';
import '../models/service_item.dart';
import '../services/service_catalog_service.dart';

class ServiceCatalogRepository {
  final ServiceCatalogService _service;

  ServiceCatalogRepository({ServiceCatalogService? service})
      : _service = service ?? ServiceCatalogService();

  Future<List<ServiceCategory>> listServiceCategories({bool? isActive}) {
    return _service.listServiceCategories(isActive: isActive);
  }

  Future<List<ServiceItem>> listServices({
    required String categoryId,
    bool? isActive,
  }) {
    return _service.listServices(categoryId: categoryId, isActive: isActive);
  }

  Future<List<ClothesItem>> listClothesItems({
    required String serviceId,
    bool? isActive,
  }) {
    return _service.listClothesItems(serviceId: serviceId, isActive: isActive);
  }
}


