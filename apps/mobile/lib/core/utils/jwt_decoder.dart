import 'dart:convert';
import '../../shared/models/user_model.dart';

/// Lightweight utility to parse unencrypted claims from a signed JWT payload
class JwtDecoder {
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Base64Url decode with appropriate padding
      String normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      return json.decode(payloadString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static UserRole getRole(String token) {
    final claims = decode(token);
    return UserRole.fromString(claims?['role'] as String?);
  }

  static String? getUserId(String token) {
    final claims = decode(token);
    return claims?['sub'] as String?;
  }

  static String? getEmail(String token) {
    final claims = decode(token);
    return claims?['email'] as String?;
  }

  static String? getFullName(String token) {
    final claims = decode(token);
    return claims?['full_name'] as String?;
  }

  static UserModel? toUserModel(String token) {
    final claims = decode(token);
    if (claims == null) return null;
    return UserModel(
      id: claims['sub'] as String? ?? '',
      email: claims['email'] as String? ?? '',
      fullName: claims['full_name'] as String? ?? 'BusSense User',
      role: UserRole.fromString(claims['role'] as String?),
    );
  }

  static bool isExpired(String token) {
    final claims = decode(token);
    if (claims == null || !claims.containsKey('exp')) return true;
    final exp = claims['exp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= exp;
  }
}
