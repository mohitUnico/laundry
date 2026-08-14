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
    // Hydrate cached catalog quickly on app start so UI doesn't fall back to hardcoded lists.
    _hydrateFromCache();
  }

  List<ServiceCategory> _categories = [];
  final Map<String, List<ServiceItem>> _servicesByCategoryId = {};
  final Map<String, List<ClothesItem>> _clothesItemsByServiceId = {};
  final Set<String> _loadingServiceIds = {};
  final Set<String> _loadingCategoryIds = {};
  bool _isLoading = false;
  String? _error;

  Future<void>? _categoriesFetchInFlight;
  final Map<String, Future<void>> _servicesFetchInFlight = {};
  final Map<String, Future<void>> _clothesFetchInFlight = {};
  int _lastRefreshMs = 0;

  // If callers "force" refresh too frequently (e.g., HomeScreen on every resume),
  // we still want to avoid hammering the backend and slowing the UI.
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
            if (key is! String) return;
            if (value is! List) return;
            _servicesByCategoryId[key] = value
                .whereType<Map>()
                .map((e) => ServiceItem.fromJson(e.cast<String, dynamic>()))
                .toList();
          });
        }
      }

      notifyListeners();
    } catch (_) {
      // Ignore cache errors; network fetch will repopulate.
    }
  }

  Future<void> _persistCategoriesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(_categories.map((c) => c.toJson()).toList());
      await prefs.setString(PrefsKeys.catalogCategoriesJson, payload);
      await prefs.setInt(PrefsKeys.catalogLastRefreshMs, _lastRefreshMs);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _persistServicesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{};
      _servicesByCategoryId.forEach((categoryId, services) {
        payload[categoryId] = services.map((s) => s.toJson()).toList();
      });
      await prefs.setString(PrefsKeys.catalogServicesByCategoryJson, jsonEncode(payload));
      await prefs.setInt(PrefsKeys.catalogLastRefreshMs, _lastRefreshMs);
    } catch (_) {
      // ignore
    }
  }

  Future<void> fetchServiceCategories({bool isActive = true, bool force = false}) async {
    // De-dupe concurrent fetches.
    if (_categoriesFetchInFlight != null) return _categoriesFetchInFlight!;

    // If force is requested too frequently, treat it as non-force to reduce latency spikes.
    final now = DateTime.now().millisecondsSinceEpoch;
    final isWithinCooldown =
        _lastRefreshMs > 0 && (now - _lastRefreshMs) < _forceRefreshCooldown.inMilliseconds;
    final effectiveForce = force && !isWithinCooldown;

    if (!effectiveForce && _categories.isNotEmpty) return;

    final future = () async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        _categories = await _repo.listServiceCategories(isActive: isActive);
        // Keep stable ordering for UI mapping.
        _categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        _lastRefreshMs = DateTime.now().millisecondsSinceEpoch;
        await _persistCategoriesToCache();
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
    final inFlight = _servicesFetchInFlight[categoryId];
    if (inFlight != null) return inFlight;
    if (!force && _servicesByCategoryId.containsKey(categoryId)) return;

    final future = () async {
      _isLoading = true;
      _loadingCategoryIds.add(categoryId);
      _error = null;
      notifyListeners();

      try {
        final services = await _repo.listServices(categoryId: categoryId, isActive: isActive);
        final sorted = [...services]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        _servicesByCategoryId[categoryId] = sorted;
        _lastRefreshMs = DateTime.now().millisecondsSinceEpoch;
        await _persistServicesToCache();
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
    final inFlight = _clothesFetchInFlight[serviceId];
    if (inFlight != null) return inFlight;
    if (!force && _clothesItemsByServiceId.containsKey(serviceId)) return;

    final future = () async {
      _isLoading = true;
      _loadingServiceIds.add(serviceId);
      _error = null;
      notifyListeners();

      try {
        final items = await _repo.listClothesItems(serviceId: serviceId, isActive: isActive);
        _clothesItemsByServiceId[serviceId] = items;
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


