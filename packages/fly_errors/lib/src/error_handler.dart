import 'package:fly_errors/src/app_exception.dart';

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});
}

/// Validation-related exceptions
class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.details});
}

/// Database-related exceptions
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.details});
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  AuthenticationException(super.message, {super.code, super.details});
}

/// Permission-related exceptions
class PermissionException extends AppException {
  PermissionException(super.message, {super.code, super.details});
}

/// Timeout-related exceptions
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code, super.details});
}

