import 'dart:convert';

class JwtUtils {
  static Map<String, dynamic> decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return <String, dynamic>{};

    final payloadBase64 = base64Url.normalize(parts[1]);
    final payloadJson = utf8.decode(base64Url.decode(payloadBase64));
    final payload = jsonDecode(payloadJson);
    if (payload is Map<String, dynamic>) return payload;
    return <String, dynamic>{};
  }

  static bool isExpired(String token) {
    try {
      final payload = decodePayload(token);
      if (payload.isEmpty) return true;

      final exp = payload['exp'];
      if (exp is! num) return true;

      final expMs = (exp * 1000).toInt();
      return DateTime.now().millisecondsSinceEpoch >= expMs;
    } catch (_) {
      return true;
    }
  }

  /// Check if token will expire within the specified minutes
  static bool willExpireSoon(String token, {int minutes = 5}) {
    try {
      final payload = decodePayload(token);
      if (payload.isEmpty) return true;

      final exp = payload['exp'];
      if (exp is! num) return true;

      final expMs = (exp * 1000).toInt();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final expiresInMs = expMs - nowMs;
      
      // Return true if expired or will expire within specified minutes
      return expiresInMs <= minutes * 60 * 1000;
    } catch (_) {
      return true;
    }
  }
}


