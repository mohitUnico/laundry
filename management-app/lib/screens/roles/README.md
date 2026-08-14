# Role-Based Screen Organization

This directory contains role-specific screens organized by user role. This modular structure makes it easy to find and maintain code for each role.

## Directory Structure

```
roles/
├── delivery_partner/          # Screens for Delivery Partner role
│   └── pages/
│       ├── home_screen.dart
│       ├── active_delivery_screen.dart
│       ├── orders_screen.dart
│       ├── profile_screen.dart
│       └── help_screen.dart
├── service_man/              # Screens for Service Man role
│   └── pages/
│       └── pending_orders_screen.dart
├── collection_manager/        # Screens for Collection Manager role
│   └── (to be implemented)
└── distribution_manager/      # Screens for Distribution Manager role
    └── (to be implemented)
```

## Common Screens and Widgets

Shared screens that are used across multiple roles are located in the `../common/` directory:
- `earnings_screen.dart` - Earnings and payment history

Shared widgets used across multiple roles are in `../common/widgets/`:
- `bottom_nav_bar.dart` - Bottom navigation bar
- `order_summary_card.dart` - Order summary card widget
- `task_card.dart` - Task card widget

## Adding New Role Screens

1. Create a new directory under `roles/` with the role name (snake_case)
2. Create a `pages/` subdirectory
3. Add role-specific screens to `roles/[role_name]/pages/`
4. Update `app_routes.dart` to include routes for the new screens
5. Update `role_manager.dart` if needed for role-specific logic

## Import Paths

When importing role-specific screens, use relative paths from the pages directory:
```dart
import '../../../../theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
```

For common widgets:
```dart
import '../../../common/widgets/bottom_nav_bar.dart';
```

For common screens:
```dart
import '../../../common/earnings_screen.dart';
```

For delivery partner screens:
```dart
import '../delivery_partner/pages/profile_screen.dart';
import '../delivery_partner/pages/help_screen.dart';
```
