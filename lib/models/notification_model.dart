import 'package:kogalo_network/providers/notifications_providers.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? eventSlug;
  final String? referenceId;
  final String? senderId;
  final String? senderAvatar;
  final String? postId;
  final String? groupId;
  final String? targetUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.eventSlug,
    this.referenceId,
    this.senderId,
    this.senderAvatar,
    this.postId,
    this.groupId,
    this.targetUrl,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? eventSlug,
    String? referenceId,
    String? senderId,
    String? senderAvatar,
    String? postId,
    String? groupId,
    String? targetUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      eventSlug: eventSlug ?? this.eventSlug,
      referenceId: referenceId ?? this.referenceId,
      senderId: senderId ?? this.senderId,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      postId: postId ?? this.postId,
      groupId: groupId ?? this.groupId,
      targetUrl: targetUrl ?? this.targetUrl,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType mapType(String? type) {
      switch (type) {
        case 'event': return NotificationType.event;
        case 'reminder': return NotificationType.reminder;
        case 'offer': return NotificationType.offer;
        case 'like': return NotificationType.like;
        case 'comment': return NotificationType.comment;
        case 'reply': return NotificationType.reply;
        default: return NotificationType.system;
      }
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'New Notification',
      message: json['body'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      type: mapType(json['type']),
      isRead: json['isRead'] == true,
      eventSlug: json['event_slug'],
      referenceId: json['reference_id']?.toString(),
      senderId: json['sender_id']?.toString(),
      senderAvatar: json['senderAvatar'],
      postId: json['post_id']?.toString(),
      groupId: json['group_id']?.toString(),
      targetUrl: json['target_url'],
    );
  }

  /// Parses the backend `target_url` to extract navigation ids.
  /// e.g. http://host/community/groups/1?post=12&comment=44
  Map<String, String?> get parsedTargetUrl {
    if (targetUrl == null) return {};
    try {
      final uri = Uri.parse(targetUrl!);
      final segments = uri.pathSegments; // ['community','groups','1']
      String? parsedGroupId = groupId;
      if (parsedGroupId == null) {
        final idx = segments.indexOf('groups');
        if (idx != -1 && idx + 1 < segments.length) {
          parsedGroupId = segments[idx + 1];
        }
      }
      return {
        'groupId': parsedGroupId,
        'postId': uri.queryParameters['post'] ?? postId,
        'commentId': uri.queryParameters['comment'] ?? referenceId,
      };
    } catch (_) {
      return {};
    }
  }
}