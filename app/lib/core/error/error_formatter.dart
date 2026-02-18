import 'package:dio/dio.dart';

class ErrorFormatter {
  static String format(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your internet.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;

          if (data is Map && data.containsKey('error')) {
            return data['error'].toString();
          }
          if (data is Map && data.containsKey('message')) {
            return data['message'].toString();
          }

          switch (statusCode) {
            case 400:
              return 'Bad request. Please check your input.';
            case 401:
              return 'Invalid email or password.';
            case 403:
              return 'You do not have permission to perform this action.';
            case 404:
              return 'The requested resource was not found.';
            case 500:
              return 'Server error. Please try again later.';
            default:
              return 'Something went wrong. Please try again.';
          }
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to server. Please check your connection.';
        default:
          return 'Check your internet connection and try again.';
      }
    }
    return error.toString();
  }
}
