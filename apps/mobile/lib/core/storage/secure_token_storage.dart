import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Token Storage Abstraction
abstract class ISecureTokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<bool> hasToken();
  Future<void> clearToken();
}

/// Production implementation using FlutterSecureStorage (Encrypted SharedPreferences / Keychain)
class SecureTokenStorage implements ISecureTokenStorage {
  static const String _tokenKey = 'bussense_jwt_token';
  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  @override
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

/// In-memory token storage for mock/unit testing environments
class InMemoryTokenStorage implements ISecureTokenStorage {
  String? _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<bool> hasToken() async {
    return _token != null && _token!.isNotEmpty;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}
