import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/api_endpoints.dart';
import '../utils/logger.dart';

import 'package:flutter/foundation.dart';

class DioClient {
  final Dio _dio;

  DioClient(this._dio) {
    _dio
      ..options.baseUrl = ApiEndpoints.baseUrl
      ..options.connectTimeout = const Duration(seconds: 15)
      ..options.receiveTimeout = const Duration(seconds: 15)
      ..options.responseType = ResponseType.json;

    if (kIsWeb) {
      _dio.options.extra['withCredentials'] = true;
    } else {
      _dio.interceptors.add(CookieManager(CookieJar()));
    }

    // DEBUG: Force logger to print BASE URL
    AppLogger.log(
      "DioClient initialized with Base URL: ${ApiEndpoints.baseUrl}",
    );

    // API Key Auth (if provided in .env)
    final apiKey = dotenv.env['API_KEY'];
    final apiSecret = dotenv.env['API_SECRET'];
    if (apiKey != null && apiSecret != null) {
      _dio.options.headers['Authorization'] = 'token $apiKey:$apiSecret';
      AppLogger.log("DioClient: Using API Key Authentication");
    }

    _dio.interceptors.add(
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
