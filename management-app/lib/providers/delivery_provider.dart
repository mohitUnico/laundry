import 'package:flutter/foundation.dart';

class DeliveryProvider with ChangeNotifier {
  List<Map<String, dynamic>> _availableTasks = [];
  Map<String, dynamic>? _activeDelivery;
  bool _isLoading = false;
  Map<String, double>? _currentLocation;

  List<Map<String, dynamic>> get availableTasks => _availableTasks;
  Map<String, dynamic>? get activeDelivery => _activeDelivery;
  bool get isLoading => _isLoading;
  Map<String, double>? get currentLocation => _currentLocation;

  Future<void> fetchAvailableTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Fetch tasks from API
      await Future.delayed(const Duration(seconds: 1));
      _availableTasks = [];
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptTask(String taskId) async {
    // TODO: Implement task acceptance
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    _currentLocation = {'latitude': latitude, 'longitude': longitude};
    // TODO: Send location update to server
    notifyListeners();
  }

  Future<void> completePickup(String proofPhoto) async {
    // TODO: Implement pickup completion
  }

  Future<void> completeDelivery(String proofPhoto) async {
    // TODO: Implement delivery completion
    _activeDelivery = null;
    notifyListeners();
  }
}
