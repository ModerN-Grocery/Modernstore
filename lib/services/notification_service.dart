import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background handler - must be top-level function
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background notification: ${message.messageId}');
}

// ─────────────────────────────────────────────────────────────────────────────
// FcmDirectService - sends FCM via HTTP v1 API directly (no backend needed)
// ─────────────────────────────────────────────────────────────────────────────
class FcmDirectService {
  FcmDirectService._();
  static final FcmDirectService instance = FcmDirectService._();

  static const String _tokenUrl =
      'https://oauth2.googleapis.com/token';
  static const String _scope =
      'https://www.googleapis.com/auth/firebase.messaging';

  Map<String, dynamic>? _serviceAccount;
  String? _cachedToken;
  DateTime? _tokenExpiry;

  // Load service account JSON from assets
  Future<void> _loadServiceAccount() async {
    if (_serviceAccount != null) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/service_account.json');
      _serviceAccount = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to load service account: $e');
      rethrow;
    }
  }

  // Get OAuth2 access token using JWT
  Future<String?> _getAccessToken() async {
    // Return cached token if still valid
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }

    await _loadServiceAccount();
    final sa = _serviceAccount!;

    try {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      // Create JWT
      final jwt = JWT(
        {
          'iss': sa['client_email'],
          'sub': sa['client_email'],
          'aud': _tokenUrl,
          'iat': now.millisecondsSinceEpoch ~/ 1000,
          'exp': expiry.millisecondsSinceEpoch ~/ 1000,
          'scope': _scope,
        },
      );

      final privateKey = RSAPrivateKey(sa['private_key'] as String);
      final token = jwt.sign(privateKey, algorithm: JWTAlgorithm.RS256);

      // Exchange JWT for OAuth2 access token
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedToken = data['access_token'] as String;
        _tokenExpiry = now.add(Duration(seconds: (data['expires_in'] as int) - 60));
        return _cachedToken;
      } else {
        debugPrint('Token exchange failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('JWT/Token error: $e');
      return null;
    }
  }

  // Send FCM notification to admin_orders topic
  Future<void> sendToAdminTopic({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await _loadServiceAccount();
      final projectId = _serviceAccount!['project_id'] as String;
      final accessToken = await _getAccessToken();
      if (accessToken == null) return;

      final fcmUrl =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final payload = {
        'message': {
          'topic': 'admin_orders',
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'order_channel',
              'sound': 'order_sound',
              'default_vibrate_timings': false,
              'vibrate_timings': ['0s', '0.500s', '0.200s', '0.500s', '0.200s', '0.500s'],
              'color': '#4CAF50',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'order_sound.aiff',
                'badge': 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM sent to admin_orders topic successfully');
      } else {
        debugPrint('FCM send failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM direct send error: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService - handles local notifications, FCM receive, vibration
// ─────────────────────────────────────────────────────────────────────────────
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'order_channel';
  static const String _channelName = 'Order Notifications';
  static const String _channelDesc = 'Notifications for new orders';

  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 500, 200, 500, 200, 500]);

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    await _fcm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);
    await _initLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');
  }

  Future<String?> getToken() async => await _fcm.getToken();

  // Admin topic subscription
  Future<void> subscribeToAdminTopic() async {
    await _fcm.subscribeToTopic('admin_orders');
    debugPrint('Subscribed to admin_orders topic');
  }

  Future<void> unsubscribeFromAdminTopic() async {
    await _fcm.unsubscribeFromTopic('admin_orders');
    debugPrint('Unsubscribed from admin_orders topic');
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handlePayload(response.payload);
      },
    );

    if (Platform.isAndroid) {
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('order_sound'),
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        enableLights: true,
        ledColor: const Color(0xFF4CAF50),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground notification: ${message.notification?.title}');
    await _triggerVibration();
    await _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('order_sound'),
      enableVibration: true,
      vibrationPattern: _vibrationPattern,
      styleInformation: BigTextStyleInformation(
        message.data['body'] ?? notification.body ?? '',
        contentTitle: notification.title,
        summaryText: 'Modern Store',
      ),
      color: const Color(0xFF4CAF50),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'order_sound.aiff',
    );
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) return;
      Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _handlePayload(jsonEncode(message.data));
  }

  void _handlePayload(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      debugPrint('Notification payload: $data');
      // Navigate: navigatorKey.currentState?.pushNamed('/admin-orders');
    } catch (e) {
      debugPrint('Payload parse error: $e');
    }
  }
}
