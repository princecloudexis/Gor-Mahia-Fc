import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

enum NotificationType { event, reminder, offer, system }

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  (ref) => NotificationsNotifier(),
);

class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationsNotifier() : super([]);
  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void addNotification(NotificationModel newNotification) {
    state = [newNotification, ...state];
  }
  void deleteNotification(String id) {
    state = state.where((notification) => notification.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}
final isNotificationsPageVisibleProvider = StateProvider.autoDispose<bool>((ref) => false);