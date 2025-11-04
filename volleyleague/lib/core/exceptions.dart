class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => 'AppException: $message';
}

class ApiException extends AppException {
  const ApiException(super.message, {this.statusCode});
  final int? statusCode;

  @override
  String toString() => 'ApiException(${statusCode ?? 'unknown'}): $message';
}
