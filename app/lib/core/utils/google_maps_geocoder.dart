import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'logger.dart'; // Import AppLogger

class GoogleMapsGeocoder {
  static final _dio = Dio();

  /// Get the appropriate API key based on platform
  static String get _apiKey {
    String key = '';

    if (kIsWeb) {
      key =
          dotenv.env['GOOGLE_MAPS_API_KEY_WEB'] ??
          dotenv.env['GOOGLE_MAPS_API_KEY'] ??
          '';
      if (key.isEmpty) {
        AppLogger.error(
          'WEB API key is empty! Keys in env: ${dotenv.env.keys.toList()}',
        );
      } else {
        AppLogger.log(
          'Using WEB API key: ${key.substring(0, key.length > 10 ? 10 : key.length)}...',
        );
      }
    } else {
      // Only import dart:io on non-web platforms
      try {
        // Check Android/iOS using defaultTargetPlatform instead
        key =
            dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ??
            dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ??
            dotenv.env['GOOGLE_MAPS_API_KEY'] ??
            '';
        if (key.isEmpty) {
          AppLogger.error('MOBILE API key is empty!');
        } else {
          AppLogger.log(
            'Using MOBILE API key: ${key.substring(0, key.length > 10 ? 10 : key.length)}...',
          );
        }
      } catch (e) {
        key = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
        AppLogger.log(
          'Using FALLBACK API key: ${key.isEmpty ? "EMPTY" : key.substring(0, key.length > 10 ? 10 : key.length)}...',
        );
      }
    }

    return key;
  }

  static Future<String> getAddressFromCoordinates(LatLng location) async {
    final apiKey = _apiKey;

    if (apiKey.isEmpty) {
      AppLogger.error('API key is empty! Check your .env file');
      return _formatCoordinates(location);
    }

    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${location.latitude},${location.longitude}'
          '&key=$apiKey'
          '&language=id';

      AppLogger.log('Geocoding Request: $url');

      // Use a fresh Dio instance with reasonable timeout for this specific call
      final geoDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await geoDio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        final status = data['status'];

        AppLogger.log('Geocoding Status: $status');

        if (status == 'OK' &&
            data['results'] != null &&
            data['results'] is List &&
            (data['results'] as List).isNotEmpty) {
          final results = data['results'] as List;

          // Try to find the most specific address (usually the first one)
          final result = results[0];
          final formattedAddress = result['formatted_address'] as String?;

          if (formattedAddress != null && formattedAddress.isNotEmpty) {
            AppLogger.log('Geocoding Success: $formattedAddress');
            return formattedAddress;
          }
        }

        // Handle specific error statuses
        if (status == 'ZERO_RESULTS') {
          AppLogger.warn('Geocoding: No results found for coordinates');
        } else if (status == 'OVER_QUERY_LIMIT') {
          AppLogger.error('Geocoding: Over query limit. Check billing.');
        } else if (status == 'REQUEST_DENIED') {
          AppLogger.error(
            'Geocoding: Request denied. Error: ${data['error_message']}',
          );
        } else if (status == 'INVALID_REQUEST') {
          AppLogger.error('Geocoding: Invalid request.');
        }

        return _formatCoordinates(location);
      } else {
        AppLogger.error('Geocoding HTTP error: ${response.statusCode}');
        return _formatCoordinates(location);
      }
    } catch (e) {
      AppLogger.error('Geocoding unexpected error', e);
      return _formatCoordinates(location);
    }
  }

  /// Search for location coordinates from address query
  static Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(address)}'
          '&key=$_apiKey'
          '&language=id';

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        } else if (data['status'] == 'REQUEST_DENIED') {
          throw 'API Access Denied. Please enable Geocoding API in Google Cloud Console.';
        } else if (data['status'] == 'ZERO_RESULTS') {
          throw 'No location found for this address.';
        } else {
          throw data['error_message'] ?? 'Search failed';
        }
      } else {
        throw 'Network error';
      }
    } catch (e) {
      rethrow;
    }
  }

  static String _formatCoordinates(LatLng location) {
    return 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
  }
}
