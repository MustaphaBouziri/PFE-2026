// =============================================================================
// AppExceptions
// Path   : lib/core/errors/app_exceptions.dart
// Purpose: Typed exception hierarchy for the MES app.
//          All repositories throw one of these subtypes — never a raw
//          DioException or generic Exception — so UI and providers can handle
//          errors with a clean type-switch without importing Dio.
// =============================================================================

/// Base class for all MES application exceptions.
abstract class AppException implements Exception {
  const AppException(this.message, {this.code});

  /// Human-readable description (may be shown directly in the UI).
  final String message;

  /// Optional error code from the BC API "error" field.
  final String? code;

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

/// BC API returned { "success": false } — a business-logic error.
class ApiException extends AppException {
  const ApiException(super.message, {super.code});
}

/// Network-level failure: no connection, timeout, DNS failure, etc.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// HTTP 401/403 from the BC OData middleware (not the MES auth layer).
/// Distinct from ApiException so the UI can auto-redirect to login.
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired. Please log in again.']);
}

/// The user's MES session token is invalid or expired.
class SessionExpiredException extends AppException {
  const SessionExpiredException([super.message = 'Your session has expired. Please log in again.']);
}

/// A required field was missing or a value failed client-side validation.
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Unexpected error that doesn't fit any other category.
class UnexpectedException extends AppException {
  const UnexpectedException([super.message = 'An unexpected error occurred.']);
}
