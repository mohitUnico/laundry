import 'package:shared_preferences/shared_preferences.dart';
import 'role_constants.dart';

/// Utility class to manage user role throughout the app
class RoleManager {
  static const String _roleKey = 'user_role';

  /// Save the selected role
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  /// Get the current role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  /// Clear the stored role
  static Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }

  /// Check if role is delivery partner
  static Future<bool> isDeliveryPartner() async {
    final role = await getRole();
    return role == RoleConstants.deliveryPartner;
  }

  /// Check if role is service man
  static Future<bool> isServiceMan() async {
    final role = await getRole();
    return role == RoleConstants.serviceMan;
  }

  /// Check if role is collection manager
  static Future<bool> isCollectionManager() async {
    final role = await getRole();
    return role == RoleConstants.collectionManager;
  }

  /// Check if role is distribution manager
  static Future<bool> isDistributionManager() async {
    final role = await getRole();
    return role == RoleConstants.distributionManager;
  }

  /// Get role display name
  static Future<String> getRoleDisplayName() async {
    final role = await getRole();
    if (role == null) return 'Unknown';
    return RoleConstants.roleDisplayNames[role] ?? role;
  }

  /// Check if current role is in a specific category
  static Future<bool> isRoleInCategory(String category) async {
    final role = await getRole();
    if (role == null) return false;
    return RoleConstants.getRoleCategory(role) == category;
  }
}

