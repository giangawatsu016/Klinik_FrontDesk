import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/api_endpoints.dart';
import '../utils/logger.dart';

class DioClient {
  final Dio _dio;

  DioClient(this._dio) {
    _dio
      ..options.baseUrl = ApiEndpoints.baseUrl
      ..options.connectTimeout = const Duration(seconds: 15)
      ..options.receiveTimeout = const Duration(seconds: 15)
      ..options.responseType = ResponseType.json
      ..interceptors.add(
        LogInterceptor(
          requestBody:
              (dotenv.env['DEBUG_LOGS'] ?? 'false').toLowerCase() == 'true',
          responseBody:
              (dotenv.env['DEBUG_LOGS'] ?? 'false').toLowerCase() == 'true',
          logPrint: (o) => AppLogger.log(o.toString()),
        ),
      );
  }

  Dio get dio => _dio;

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}
