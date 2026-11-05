/// BusSense AI - Structured Application Exceptions
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'AppException: $message (Status: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode, super.details});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.statusCode, super.details});
}

class RoleException extends AppException {
  const RoleException(super.message, {super.statusCode, super.details});
}
