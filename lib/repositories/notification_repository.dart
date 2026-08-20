import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/notification_model.dart';

class PaginatedNotificationsResponse {
  final List<NotificationModel> notifications;
  final int currentPage;
  final int lastPage;
  final int total;

  PaginatedNotificationsResponse({
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory PaginatedNotificationsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List? ?? [];
    final meta = json['meta'] ?? {};
    return PaginatedNotificationsResponse(
      notifications: data.map((e) => NotificationModel.fromJson(e)).toList(),
      currentPage: meta['currentPage'] ?? 1,
      lastPage: meta['lastPage'] ?? 1,
      total: meta['total'] ?? 0,
    );
  }
}

class NotificationRepository {
  final ApiClient _apiClient;
  NotificationRepository(this._apiClient);

  Future<PaginatedNotificationsResponse> getNotifications({int page = 1, int limit = 15}) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.data['status'] == 200 || response.data['success'] == true) {
        return PaginatedNotificationsResponse.fromJson(response.data);
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to fetch notifications.',
        );
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ??
          'An error occurred fetching notifications.';
      throw Exception(errorMessage);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final response = await _apiClient.dio.post('/v1/notifications/$id/read');
      if (response.data['status'] != 200 && response.data['success'] != true) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});
