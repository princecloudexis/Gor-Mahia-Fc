import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import 'package:flutter/material.dart';

enum NotificationType { event, reminder, offer, system, like, comment, reply }

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoadingMore;
  final bool hasMore;
  
  NotificationState({
    required this.notifications,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationState>(
  (ref) {
    final repo = ref.watch(notificationRepositoryProvider);
    final notifier = NotificationsNotifier(repo);
    notifier.fetchNotifications();
    return notifier;
  }
);

class NotificationsNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository repo;
  int _currentPage = 1;
  final int _limit = 15;
  
  NotificationsNotifier(this.repo) : super(NotificationState(notifications: []));

  Future<void> fetchNotifications() async {
    try {
      _currentPage = 1;
      final response = await repo.getNotifications(page: _currentPage, limit: _limit);
      state = NotificationState(
        notifications: response.notifications,
        hasMore: _currentPage < response.lastPage,
      );
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    
    state = state.copyWith(isLoadingMore: true);
    try {
      _currentPage++;
      final response = await repo.getNotifications(page: _currentPage, limit: _limit);
      state = state.copyWith(
        notifications: [...state.notifications, ...response.notifications],
        hasMore: _currentPage < response.lastPage,
        isLoadingMore: false,
      );
    } catch (e) {
      _currentPage--;
      state = state.copyWith(isLoadingMore: false);
      debugPrint('Error fetching more notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    final updatedList = [
      for (final n in state.notifications)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    state = state.copyWith(notifications: updatedList);
    try {
      await repo.markAsRead(id);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  void addNotification(NotificationModel newNotification) {
    state = state.copyWith(notifications: [newNotification, ...state.notifications]);
  }

  void deleteNotification(String id) {
    final updatedList = state.notifications.where((notification) => notification.id != id).toList();
    state = state.copyWith(notifications: updatedList);
  }

  void clearAll() {
    state = NotificationState(notifications: []);
  }
}

final isNotificationsPageVisibleProvider = StateProvider.autoDispose<bool>((ref) => false);

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final notificationState = ref.watch(notificationsProvider);
  return notificationState.notifications.any((n) => !n.isRead);
});