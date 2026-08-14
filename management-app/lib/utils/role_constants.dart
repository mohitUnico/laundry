/// Role constants for the management app
/// All role names used throughout the application should reference these constants
class RoleConstants {
  // Role Names
  static const String deliveryPartner = 'Delivery Partner';
  static const String serviceMan = 'Service Man';
  static const String collectionManager = 'Collection Manager';
  static const String distributionManager = 'Distribution Manager';

  // Role Display Names (for UI)
  static const Map<String, String> roleDisplayNames = {
    deliveryPartner: 'Delivery Partner',
    serviceMan: 'Service Man',
    collectionManager: 'Collection Manager',
    distributionManager: 'Distribution Manager',
  };

  // All available roles
  static const List<String> allRoles = [
    deliveryPartner,
    serviceMan,
    collectionManager,
    distributionManager,
  ];

  // Role Categories
  static const List<String> deliveryRoles = [
    deliveryPartner,
  ];

  static const List<String> collectionRoles = [
    collectionManager,
  ];

  static const List<String> serviceRoles = [
    serviceMan,
  ];

  static const List<String> distributionRoles = [
    distributionManager,
  ];

  // Check if role is delivery-related
  static bool isDeliveryRole(String role) {
    return deliveryRoles.contains(role);
  }

  // Check if role is collection-related
  static bool isCollectionRole(String role) {
    return collectionRoles.contains(role);
  }

  // Check if role is service-related
  static bool isServiceRole(String role) {
    return serviceRoles.contains(role);
  }

  // Check if role is distribution-related
  static bool isDistributionRole(String role) {
    return distributionRoles.contains(role);
  }

  // Get role category
  static String? getRoleCategory(String role) {
    if (isDeliveryRole(role)) return 'delivery';
    if (isCollectionRole(role)) return 'collection';
    if (isServiceRole(role)) return 'service';
    if (isDistributionRole(role)) return 'distribution';
    return null;
  }
}

