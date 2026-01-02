import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:laundry_customer_app/app.dart';

void main() {
  testWidgets('App boots and renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const LaundryCustomerApp());

    // Bootstrap screen shows a loader while deciding initial route.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
