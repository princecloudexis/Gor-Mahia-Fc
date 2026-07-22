import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import 'package:flutter/material.dart';

enum NotificationType { event, reminder, offer, system, like, comment, reply }

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  (ref) {
    final repo = ref.watch(notificationRepositoryProvider);
    final notifier = NotificationsNotifier(repo);
    notifier.fetchNotifications();
    return notifier;
  }
);

class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  final NotificationRepository repo;
  
  NotificationsNotifier(this.repo) : super([]);

  Future<void> fetchNotifications() async {
    try {
      final list = await repo.getNotifications();
      state = list;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    try {
      await repo.markAsRead(id);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
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