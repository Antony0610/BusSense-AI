import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../errors/app_exception.dart';
import '../storage/secure_token_storage.dart';

/// Unified HTTP API Client for BusSense AI Mobile Application
class ApiClient {
  final http.Client _client;
  final ISecureTokenStorage _tokenStorage;
  final String _baseUrl;

  ApiClient({
    http.Client? client,
    ISecureTokenStorage? tokenStorage,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage(),
        _baseUrl = baseUrl ?? EnvConfig.apiBaseUrl;

  Future<Map<String, String>> _headers({Map<String, String>? extraHeaders}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'apikey': EnvConfig.supabaseAnonKey,
    };

    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _uri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$_baseUrl$cleanEndpoint';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
    }
    return uri;
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _uri(endpoint, queryParams);
      final headers = await _headers();
      final response = await _client.get(uri, headers: headers).timeout(EnvConfig.requestTimeout);
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final uri = _uri(endpoint);
      final headers = await _headers();
      final response = await _client
          .post(uri, headers: headers, body: body != null ? json.encode(body) : null)
          .timeout(EnvConfig.requestTimeout);
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body}) async {
    try {
      final uri = _uri(endpoint);
      final headers = await _headers();
      final response = await _client
          .put(uri, headers: headers, body: body != null ? json.encode(body) : null)
          .timeout(EnvConfig.requestTimeout);
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    try {
      final uri = _uri(endpoint);
      final headers = await _headers();
      final response = await _client
          .patch(uri, headers: headers, body: body != null ? json.encode(body) : null)
          .timeout(EnvConfig.requestTimeout);
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = _uri(endpoint);
      final headers = await _headers();
      final response = await _client.delete(uri, headers: headers).timeout(EnvConfig.requestTimeout);
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    String errorMessage = 'Request failed with status: ${response.statusCode}';
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('detail')) {
        errorMessage = decoded['detail'].toString();
      } else if (decoded.containsKey('message')) {
        errorMessage = decoded['message'].toString();
      }
    }

    if (response.statusCode == 401) {
      throw AuthException(errorMessage, statusCode: 401);
    } else if (response.statusCode == 403) {
      throw RoleException(errorMessage, statusCode: 403);
    } else {
      throw NetworkException(errorMessage, statusCode: response.statusCode);
    }
  }

  Never _handleError(Object error) {
    if (error is AppException) throw error;
    throw NetworkException('Network connection failed: $error');
  }
}
