/// Google Maps / Places API configuration.
///
/// The Maps SDK key is injected from android/local.properties (MAPS_SDK_KEY)
/// into the Android manifest. It is not stored in source.
///
/// Places and Directions calls need a separate key passed at build time:
///   flutter build appbundle --release --dart-define=GOOGLE_MAPS_API_KEY=...
class GoogleMapsKeys {
  static const String placesApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
}
