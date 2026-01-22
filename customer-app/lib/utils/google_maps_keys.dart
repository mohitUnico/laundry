/// Google Maps / Places API configuration.
///
/// NOTE:
/// - For this codebase, the Maps SDK API key is already configured in:
///   - Android: `android/app/src/main/AndroidManifest.xml`
///   - iOS: `ios/Runner/AppDelegate.swift`
/// - Places Web Service calls (autocomplete/details) also need an API key.
/// - Prefer passing the key via `--dart-define=GOOGLE_MAPS_API_KEY=...` for security.
///
/// If `GOOGLE_MAPS_API_KEY` is not provided, we fall back to the currently configured key
/// to keep the app working in local/dev builds.
class GoogleMapsKeys {
  static const String placesApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyAGubuEWBTo6vqErrefsi6KkKKu2u_Pptc',
  );
}


