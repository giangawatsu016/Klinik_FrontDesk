import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../injection_container.dart';
import '../network/dio_client.dart';
import '../constants/api_endpoints.dart';
import 'navigation_service.dart';

import '../utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream for handling foreground messages in UI
  final _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onForegroundMessage =>
      _foregroundMessageController.stream;

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Request notification permission only (called on app start before login)
  /// This shows the permission dialog immediately after app install
  Future<void> requestPermissionOnly() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      AppLogger.info(
        '[Notification] Permission requested on app start: ${settings.authorizationStatus}',
      );
    } catch (e) {
      AppLogger.error('[Notification] Error requesting permission', e);
    }
  }

  Future<AuthorizationStatus> getAuthorizationStatus() async {
    if (kIsWeb) {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus;
    }

    // On Mobile, use permission_handler for more accurate system status
    final status = await Permission.notification.status;
    if (status.isGranted) return AuthorizationStatus.authorized;
    if (status.isDenied || status.isPermanentlyDenied) {
      return AuthorizationStatus.denied;
    }
    if (status.isProvisional) return AuthorizationStatus.provisional;

    return AuthorizationStatus.notDetermined;
  }

  /// Initialize the notification service
  Future<void> initialize({bool forceSync = false}) async {
    AppLogger.log('[Notification] initialize called (forceSync: $forceSync)');
    try {
      // 1. Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.info(
        '[Notification] Permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 2. Setup listeners (only once unless forced)
        if (!_initialized || forceSync) {
          await _initializeLocalNotifications();

          // Clear old listeners if forced? No, Firebase handles it, but we should avoid multiple listeners.
          // For debugging, we just ensure listeners are active.
          if (!_initialized) {
            _messaging.onTokenRefresh.listen(_onTokenRefresh);
            FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
            FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
            _initialized = true;
          }
          AppLogger.info('[Notification] listeners initialized');
        }

        // 3. Always sync token (get and send to server)
        await _getFcmToken();
      } else {
        AppLogger.warn('[Notification] Permission denied');
      }
    } catch (e) {
      AppLogger.error('[Notification] Initialization error', e);
      rethrow;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // Request permission for Android 13+
    if (!kIsWeb) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _getFcmToken() async {
    AppLogger.info('[Notification] Getting FCM token...');
    try {
      // Retry logic: Sometimes getToken returns null right after permission is granted
      for (int i = 0; i < 3; i++) {
        try {
          if (kIsWeb) {
            final vapidKey = dotenv.env['VAPID_KEY'];
            if (vapidKey == null || vapidKey.isEmpty) {
              throw Exception('VAPID_KEY not found in .env');
            }
            _fcmToken = await _messaging.getToken(vapidKey: vapidKey);
          } else {
            // Mobile: Standard getToken
            // DEBUG: Force delete old token to fix "Requested entity was not found"
            try {
              await _messaging.deleteToken();
              AppLogger.log(
                '[Notification] Old token deleted to force refresh.',
              );
            } catch (e) {
              AppLogger.warn(
                '[Notification] Failed to delete old token (ignored): $e',
              );
            }

            _fcmToken = await _messaging.getToken();
          }
        } catch (e) {
          // Show the actual error for debugging
          AppLogger.error('[Notification] Inner error', e);
          // Rethrow with original message for UI display
          rethrow;
        }

        if (_fcmToken != null) break;

        AppLogger.warn('[Notification] Token is null, retrying ($i)...');
        await Future.delayed(const Duration(seconds: 2));
      }

      AppLogger.info(
        '[Notification] FCM Token retrieved: ${_fcmToken != null ? "YES (length: ${_fcmToken!.length})" : "NULL"}',
      );

      if (_fcmToken != null) {
        await _sendTokenToServer(_fcmToken!);
      } else {
        throw Exception(
          'FCM Token is NULL even after retries. Check Google Play Services or Network.',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('[Notification] Error getting FCM token', e, stackTrace);
      rethrow;
    }
  }

  void _onTokenRefresh(String token) async {
    AppLogger.info('[Notification] Token refreshed: $token');
    _fcmToken = token;
    await _sendTokenToServer(token);
  }

  Future<void> _sendTokenToServer(String token) async {
    AppLogger.log(
      '[Notification] _sendTokenToServer called with token of length: ${token.length}',
    );
    try {
      final dioClient = sl<DioClient>();
      AppLogger.log(
        '[Notification] DioClient instance retrieved. BaseUrl: ${dioClient.dio.options.baseUrl}',
      );

      final authHeader = dioClient.dio.options.headers['Authorization'];
      AppLogger.log(
        '[Notification] Auth Header present: ${authHeader != null} (${authHeader?.substring(0, 10)}...)',
      );

      if (authHeader == null) {
        AppLogger.warn(
          '[Notification] WARNING: No Auth token set in DioClient! Request might fail.',
        );
      }

      AppLogger.log(
        ' [Notification] Sending POST ${ApiEndpoints.updateFcmToken} ...',
      );
      final response = await dioClient.dio.post(
        ApiEndpoints.updateFcmToken,
        data: {'token': token},
      );
      AppLogger.info(
        '[Notification] Token sent to server successfully. Status: ${response.statusCode}, Data: ${response.data}',
      );
    } catch (e) {
      AppLogger.error('[Notification] Error sending token to server', e);
      if (e is DioException) {
        AppLogger.error(
          '[Notification] DioError info: ${e.response?.statusCode} - ${e.response?.data}',
          e,
        );
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info(
      '[Notification] Foreground message received: ${message.notification?.title}',
    );

    final notification = message.notification;

    // Show local notification when app is in foreground
    if (notification != null) {
      // Notify listeners (UI) about the foreground message
      _foregroundMessageController.add(message);

      if (!kIsWeb) {
        // Payload format: type:appointmentId for navigation
        final type = message.data['type'] ?? '';
        final appointmentId = message.data['appointmentId'] ?? '';
        final payload = '$type:$appointmentId';

        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
                  'This channel is used for important notifications.',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: payload,
        );
      }
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.info('[Notification] Notification tapped: ${message.data}');
    // Handle navigation based on message data
    _navigateToAppointment(message.data);
  }

  void _onNotificationTap(NotificationResponse response) {
    AppLogger.info(
      '[Notification] Local notification tapped: ${response.payload}',
    );
    // For local notifications, we store type:appointmentId in payload
    if (response.payload != null && response.payload!.contains(':')) {
      final parts = response.payload!.split(':');
      _navigateToAppointment({
        'type': parts[0],
        'appointmentId': parts.length > 1 ? parts[1] : null,
      });
    }
  }

  void _navigateToAppointment(Map<String, dynamic> data) {
    final type = data['type'];
    final appointmentId = data['appointmentId'];

    AppLogger.info(
      '[Notification] Navigating based on type: $type, appointmentId: $appointmentId',
    );

    // Navigate to home with appointment tab selected, the user can then tap on the appointment
    // This avoids needing to fetch appointment data in the notification service
    switch (type) {
      case 'CONSULTATION_COMPLETED':
      case 'PAYMENT_REMINDER':
      case 'SCHEDULE_REMINDER':
        // Navigate to schedule tab with appointment ID as argument
        NavigationService().navigateTo(
          '/home',
          arguments: {
            'tab': 1, // Schedule tab
            'appointmentId': appointmentId != null
                ? int.tryParse(appointmentId.toString())
                : null,
          },
        );
        break;
      case 'TEST_NOTIFICATION':
        // Just show the notification, no special navigation
        break;
    }
  }
}
