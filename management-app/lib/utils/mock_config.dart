import 'package:flutter/foundation.dart';

/// Local screen development. On by default so `flutter run` does not wait on the API.
/// Turn the backend back on with `--dart-define=USE_MOCK_DATA=false`.
class MockConfig {
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  static const double debugLatitude = 22.572645;
  static const double debugLongitude = 88.363892;

  /// Debug builds only. Release stays on the real flow even if the define is left on.
  static bool get bypassBackend => useMockData && kDebugMode;
}
