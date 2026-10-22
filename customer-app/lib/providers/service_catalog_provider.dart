import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/service_category.dart';
import '../models/clothes_item.dart';
import '../models/service_item.dart';
import '../repositories/service_catalog_repository.dart';
import '../utils/prefs_keys.dart';

class ServiceCatalogProvider with ChangeNotifier {
  final ServiceCatalogRepository _repo;

  ServiceCatalogProvider({ServiceCatalogRepository? repo})
      : _repo = repo ?? ServiceCatalogRepository() {
    _cacheReady = _hydrateFromCache();
    // Pull once per launch. SharedPreferences keeps the copy until uninstall.
    syncCatalog();
  }

  List<ServiceCategory> _categories = [];
  final Map<String, List<ServiceItem>> _servicesByCategoryId = {};
  final Map<String, List<ClothesItem>> _clothesItemsByServiceId = {};
  final Set<String> _loadingServiceIds = {};
  final Set<String> _loadingCategoryIds = {};
  bool _isLoading = false;
  String? _error;

  late final Future<void> _cacheReady;
  Future<void>? _syncInFlight;
  Future<void>? _categoriesFetchInFlight;
  final Map<String, Future<void>> _servicesFetchInFlight = {};
  final Map<String, Future<void>> _clothesFetchInFlight = {};
  int _lastRefreshMs = 0;

  // Home can open again quickly. The saved catalogue still shows; this only
  // limits how often we ask the server for admin additions.
  static const Duration _forceRefreshCooldown = Duration(seconds: 30);

  List<ServiceCategory> get categories => _categories;
  List<ServiceItem> servicesForCategory(String categoryId) =>
      _servicesByCategoryId[categoryId] ?? const [];
  List<ClothesItem> clothesItemsForService(String serviceId) =>
      _clothesItemsByServiceId[serviceId] ?? const [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isLoadingServices(String categoryId) => _loadingCategoryIds.contains(categoryId);
  bool isLoadingClothesItems(String serviceId) => _loadingServiceIds.contains(serviceId);

  bool get _refreshIsFresh {
    if (_lastRefreshMs <= 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - _lastRefreshMs) < _forceRefreshCooldown.inMilliseconds;
  }

  Future<void> _hydrateFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastRefreshMs = prefs.getInt(PrefsKeys.catalogLastRefreshMs) ?? 0;
      final categoriesJson = prefs.getString(PrefsKeys.catalogCategoriesJson);
      if (categoriesJson != null && categoriesJson.isNotEmpty) {
        final decoded = jsonDecode(categoriesJson);
        if (decoded is List) {
          _categories = decoded
              .whereType<Map>()
              .map((e) => ServiceCategory.fromJson(e.cast<String, dynamic>()))
              .toList();
        }
      }

      final servicesByCategoryJson = prefs.getString(PrefsKeys.catalogServicesByCategoryJson);
      if (servicesByCategoryJson != null && servicesByCategoryJson.isNotEmpty) {
        final decoded = jsonDecode(servicesByCategoryJson);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is! String || value is! List) return;
            _servicesByCategoryId[key] = value
                .whereType<Map>()
                .map((e) => ServiceItem.fromJson(e.cast<String, dynamic>()))
                .toList();
          });
        }
      }

      final clothesByServiceJson = prefs.getString(PrefsKeys.catalogClothesByServiceJson);
      if (clothesByServiceJson != null && clothesByServiceJson.isNotEmpty) {
        final decoded = jsonDecode(clothesByServiceJson);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is! String || value is! List) return;
            _clothesItemsByServiceId[key] = value
                .whereType<Map>()
                .map((e) => ClothesItem.fromJson(e.cast<String, dynamic>()))
                .toList();
          });
        }
      }

      notifyListeners();
    } catch (_) {
      // Ignore cache errors; network fetch will repopulate.
    }
  }

  Future<void> _persistCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        PrefsKeys.catalogCategoriesJson,
        jsonEncode(_categories.map((c) => c.toJson()).toList()),
      );
      final servicesPayload = <String, dynamic>{};
      _servicesByCategoryId.forEach((categoryId, services) {
        servicesPayload[categoryId] = services.map((s) => s.toJson()).toList();
      });
      await prefs.setString(
        PrefsKeys.catalogServicesByCategoryJson,
        jsonEncode(servicesPayload),
      );
      final clothesPayload = <String, dynamic>{};
      _clothesItemsByServiceId.forEach((serviceId, items) {
        clothesPayload[serviceId] = items.map((item) => item.toJson()).toList();
      });
      await prefs.setString(
        PrefsKeys.catalogClothesByServiceJson,
        jsonEncode(clothesPayload),
      );
      await prefs.setInt(PrefsKeys.catalogLastRefreshMs, _lastRefreshMs);
    } catch (_) {
      // ignore
    }
  }

  /// Load the saved catalogue, then replace it when the server has changes.
  /// A failed request leaves the saved copy in place.
  Future<void> syncCatalog({bool isActive = true}) {
    final existing = _syncInFlight;
    if (existing != null) return existing;

    final future = _runSync(isActive);
    _syncInFlight = future;
    return future.whenComplete(() {
      if (identical(_syncInFlight, future)) _syncInFlight = null;
    });
  }

  Future<void> _runSync(bool isActive) async {
    await _cacheReady;
    if (_refreshIsFresh && _categories.isNotEmpty) return;

    final showLoading = _categories.isEmpty;
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final categories = await _repo.listServiceCategories(isActive: isActive);
      categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      final serviceLists = await Future.wait(
        categories.map(
          (category) => _repo.listServices(categoryId: category.categoryId, isActive: isActive),
        ),
      );
      final servicesByCategory = <String, List<ServiceItem>>{};
      final services = <ServiceItem>[];
      for (var i = 0; i < categories.length; i++) {
        final sorted = [...serviceLists[i]]
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        servicesByCategory[categories[i].categoryId] = sorted;
        services.addAll(sorted);
      }

      final clothLists = await Future.wait(
        services.map(
          (service) => _repo.listClothesItems(serviceId: service.serviceId, isActive: isActive),
        ),
      );
      final clothesByService = <String, List<ClothesItem>>{};
      for (var i = 0; i < services.length; i++) {
        clothesByService[services[i].serviceId] = clothLists[i];
      }

      _categories = categories;
      _servicesByCategoryId
        ..clear()
        ..addAll(servicesByCategory);
      _clothesItemsByServiceId
        ..clear()
        ..addAll(clothesByService);
      _lastRefreshMs = DateTime.now().millisecondsSinceEpoch;
      _error = null;
      await _persistCatalog();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _awaitSync() async {
    final sync = _syncInFlight;
    if (sync == null) return;
    try {
      await sync;
    } catch (_) {
      // syncCatalog records the error and keeps the saved catalogue.
    }
  }

  Future<void> fetchServiceCategories({bool isActive = true, bool force = false}) async {
    await _cacheReady;
    await _awaitSync();
    if (_categoriesFetchInFlight != null) return _categoriesFetchInFlight!;

    final effectiveForce = force && !_refreshIsFresh;
    if (!effectiveForce && _categories.isNotEmpty) return;

    final future = () async {
      final showLoading = _categories.isEmpty;
      if (showLoading) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      try {
        final categories = await _repo.listServiceCategories(isActive: isActive);
        categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        _categories = categories;
        _error = null;
        await _persistCatalog();
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }();

    _categoriesFetchInFlight = future;
    try {
      await future;
    } finally {
      _categoriesFetchInFlight = null;
    }
  }

  Future<void> fetchServicesForCategory({
    required String categoryId,
    bool isActive = true,
    bool force = false,
  }) async {
    await _cacheReady;
    await _awaitSync();
    final inFlight = _servicesFetchInFlight[categoryId];
    if (inFlight != null) return inFlight;

    final effectiveForce = force && !_refreshIsFresh;
    if (!effectiveForce && _servicesByCategoryId.containsKey(categoryId)) return;

    final future = () async {
      final showLoading = !_servicesByCategoryId.containsKey(categoryId);
      if (showLoading) {
        _isLoading = true;
        _loadingCategoryIds.add(categoryId);
        _error = null;
        notifyListeners();
      }

      try {
        final services = await _repo.listServices(categoryId: categoryId, isActive: isActive);
        final sorted = [...services]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        _servicesByCategoryId[categoryId] = sorted;
        _error = null;
        await _persistCatalog();
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        _loadingCategoryIds.remove(categoryId);
        notifyListeners();
      }
    }();

    _servicesFetchInFlight[categoryId] = future;
    try {
      await future;
    } finally {
      _servicesFetchInFlight.remove(categoryId);
    }
  }

  Future<void> fetchClothesItemsForService({
    required String serviceId,
    bool isActive = true,
    bool force = false,
  }) async {
    await _cacheReady;
    await _awaitSync();
    final inFlight = _clothesFetchInFlight[serviceId];
    if (inFlight != null) return inFlight;

    final effectiveForce = force && !_refreshIsFresh;
    if (!effectiveForce && _clothesItemsByServiceId.containsKey(serviceId)) return;

    final future = () async {
      final showLoading = !_clothesItemsByServiceId.containsKey(serviceId);
      if (showLoading) {
        _isLoading = true;
        _loadingServiceIds.add(serviceId);
        _error = null;
        notifyListeners();
      }

      try {
        final items = await _repo.listClothesItems(serviceId: serviceId, isActive: isActive);
        _clothesItemsByServiceId[serviceId] = items;
        _error = null;
        await _persistCatalog();
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        _loadingServiceIds.remove(serviceId);
        notifyListeners();
      }
    }();

    _clothesFetchInFlight[serviceId] = future;
    try {
      await future;
    } finally {
      _clothesFetchInFlight.remove(serviceId);
    }
  }
}
