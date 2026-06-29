import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  AppException(this.message);

  factory AppException.fromDioException(DioException e) {
    String errorMessage;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timed out. Please try again.';
        break;
      case DioExceptionType.badResponse:
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        } else {
          switch (e.response?.statusCode) {
            case 400:
              errorMessage = 'Bad request.';
              break;
            case 401:
              errorMessage = 'Authentication failed. Please log in again.';
              break;
            case 403:
              errorMessage =
                  'You do not have permission to perform this action.';
              break;
            case 404:
              errorMessage = 'The requested resource was not found.';
              break;
            case 500:
              errorMessage = 'Internal server error. Please try again later.';
              break;
            default:
              errorMessage =
                  'Server returned an error: ${e.response?.statusCode}';
          }
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        errorMessage =
            'Connection error. Please check your internet connection.';
        break;
      case DioExceptionType.unknown:
      default:
        if (e.message?.contains('HandshakeException') ?? false) {
          errorMessage =
              'Security certificate issue. Cannot connect to the server securely.';
        } else {
          errorMessage =
              'An unexpected error occurred. Please check your connection.';
        }
        break;
    }
    return AppException(errorMessage);
  }

  @override
  String toString() => message;
}

class SeatConflictException extends AppException {
  final List<String> seats;

  SeatConflictException({required String message, required this.seats})
    : super(message);
}
