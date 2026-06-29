import 'dart:convert';
import 'dart:io';
import 'package:eventsbooking/controllers/auth_controller.dart';
import 'package:eventsbooking/firebase_options.dart';
import 'package:eventsbooking/models/notification_model.dart';
import 'package:eventsbooking/providers/notifications_providers.dart';
import 'package:eventsbooking/providers/user_providers.dart';
import 'package:eventsbooking/services/local_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}

class FcmService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final ProviderRef _ref;
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  bool _isInitialized = false;
  FcmService(this._ref);
  Future<void> init() async {
    if (_isInitialized) return;
    await _localNotificationService.init();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _firebaseMessaging.requestPermission();
    _setupMessageListeners();
    _isInitialized = true;
  }
   Future<void> sendTokenToServer({
    required String? userAuthToken,
    required int? userId,
  }) async {
    final fcmToken = await _firebaseMessaging.getToken();

    print("Attempting to send FCM token to server...");
    await _sendTokenToBackend(
      token: fcmToken,
      userAuthToken: userAuthToken,
      userId: userId,
    );
    print("FCM token sent to server. Token: $fcmToken");
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      final currentAuthState = _ref.read(authControllerProvider);
      final currentUser = _ref.read(userProvider);
      
      _sendTokenToBackend(
        token: newToken,
        userAuthToken: currentAuthState.token,
        userId: currentUser?.id,
      );
    });
  }

  void _setupMessageListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      final notification = message.notification;
      final data = message.data;
      if (notification != null) {
        final newNotification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: notification.title ?? 'New Notification',
          message: notification.body ?? '',
          timestamp: DateTime.now(),
          type: _mapType(data['type']),
          eventSlug: data['event_slug'],
        );
        _ref
            .read(notificationsProvider.notifier)
            .addNotification(newNotification);
        _localNotificationService.showNotification(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message.data);
    });
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }
  }

  NotificationType _mapType(String? type) {
    switch (type) {
      case 'event': return NotificationType.event;
      case 'reminder': return NotificationType.reminder;
      case 'offer': return NotificationType.offer;
      default: return NotificationType.system;
    }
  }

  Future<void> _sendTokenToBackend({
    required String? token,
    String? userAuthToken,
    int? userId,
  }) async {
    if (token == null || userAuthToken == null || userId == null) {
      print('Cannot send FCM token: Token, Auth, or UserID is null.');
      return;
    }
    int platformValue;
    if (Platform.isAndroid) {
      platformValue = 0;
    } else if (Platform.isIOS) {
      platformValue = 1;
    } else {
      print('Unsupported platform for FCM token saving.');
      return;
    }

    const String apiUrl = 'https://undrgrnd.staging-workhub.com/api/user/save-token';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userAuthToken',
        },
        body: jsonEncode(<String, dynamic>{
          'user_id': userId,
          'token': token,
          'platform': platformValue,
        }),
      );

      if (response.statusCode == 200) {
        print('FCM token sent to backend successfully for platform: $platformValue');
      } else {
        print(
          'Failed to send FCM token.'
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      print('Error sending FCM token to backend: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    print("Notification tapped! Data payload: $data");
    final navigator = NavigationService.navigatorKey.currentState;
    final String? slug = data['event_slug'];

    if (navigator != null) {
      if (slug != null) {
        print("Navigating to details page for slug: $slug");
        navigator.pushNamed('/event-details', arguments: slug);
      } else {
        print("Navigating to default notifications page.");
        navigator.pushNamed('/notifications');
      }
    }
  }
}