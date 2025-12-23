enum StaffRole {
  collectionManager,
  serviceMan,
  distributionManager,
  deliveryPartner,
}

extension StaffRoleX on StaffRole {
  String get label {
    switch (this) {
      case StaffRole.collectionManager:
        return 'Collection Manager';
      case StaffRole.serviceMan:
        return 'Service Man';
      case StaffRole.distributionManager:
        return 'Distribution Manager';
      case StaffRole.deliveryPartner:
        return 'Delivery Partner';
    }
  }
}
