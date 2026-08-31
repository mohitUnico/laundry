class ApiConfig {
  /// Override at build/run time:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3001
  static String get backendBaseUrl {
    const defined = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (defined.isNotEmpty) return defined;
    return 'http://127.0.0.1:3001';
  }
}
