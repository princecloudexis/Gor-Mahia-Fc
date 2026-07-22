import 'dart:convert';
import 'dart:io';
import 'package:eventsbooking/controllers/auth_controller.dart';
import 'package:eventsbooking/firebase_options.dart';
import 'package:eventsbooking/models/notification_model.dart';
import 'package:eventsbooking/providers/community_providers.dart';
import 'package:eventsbooking/providers/notifications_providers.dart';
import 'package:eventsbooking/providers/user_providers.dart';
import 'package:eventsbooking/services/local_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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
  Future<void>? _initFuture;

  FcmService(this._ref);

  Future<void> init() async {
    if (_isInitialized) return;
    if (_initFuture != null) return _initFuture;

    _initFuture = _performInit();
    return _initFuture;
  }

  Future<void> _performInit() async {
    await _localNotificationService.init();
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
          referenceId: data['reference_id'],
          senderId: data['sender_id'],
        );
        _ref
            .read(notificationsProvider.notifier)
            .addNotification(newNotification);
        _localNotificationService.showNotification(message);
      }

      // If it's a comment or reply, signal the open PostCommentsSheet to refresh
      final type = data['type'];
      final postId = data['post_id'];
      if ((type == 'comment' || type == 'reply') && postId != null) {
        _ref.read(commentsRefreshSignalProvider.notifier).state = postId;
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
      case 'event':
        return NotificationType.event;
      case 'reminder':
        return NotificationType.reminder;
      case 'offer':
        return NotificationType.offer;
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'reply':
        return NotificationType.reply;
      default:
        return NotificationType.system;
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
    String platformValue;
    if (Platform.isAndroid) {
      platformValue = 'android';
    } else if (Platform.isIOS) {
      platformValue = 'ios';
    } else {
      print('Unsupported platform for FCM token saving.');
      return;
    }

    const String apiUrl =
        'https://footballclub.staging-workhub.com/api/user/save-token';

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
        print(
          'FCM token sent to backend successfully for platform: $platformValue',
        );
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
    if (navigator == null) return;

    final String? slug = data['event_slug'];
    final String? targetUrl = data['target_url'];
    final String? groupId = data['group_id']?.toString();
    final String? postId = data['post_id']?.toString();

    if (slug != null) {
      print("Navigating to event details for slug: $slug");
      navigator.pushNamed('/event-details', arguments: slug);
      return;
    }

    // Parse target_url if provided: e.g. /community/groups/1?post=12&comment=44
    String? resolvedGroupId = groupId;
    String? resolvedPostId = postId;
    String? resolvedCommentId = data['reference_id']?.toString();

    if (targetUrl != null) {
      try {
        final uri = Uri.parse(targetUrl);
        final segments = uri.pathSegments;
        final idx = segments.indexOf('groups');
        if (idx != -1 && idx + 1 < segments.length) {
          resolvedGroupId ??= segments[idx + 1];
        }
        resolvedPostId ??= uri.queryParameters['post'];
        resolvedCommentId ??= uri.queryParameters['comment'];
      } catch (_) {}
    }

    if (resolvedGroupId != null) {
      // Navigate to notifications page — it will pick up the tap via FCM
      // and the user can tap the notification card to deep-link into the group.
      // For a richer UX we push /notifications so the unread badge is visible.
      print(
        "Navigating to notifications page (group: $resolvedGroupId, post: $resolvedPostId)",
      );
      navigator.pushNamed('/notifications');
    } else {
      print("Navigating to default notifications page.");
      navigator.pushNamed('/notifications');
    }
  }
}
