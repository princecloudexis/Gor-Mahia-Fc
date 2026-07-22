import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;
  NotificationRepository(this._apiClient);

  Future<List<NotificationModel>> getNotifications({int limit = 15}) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/notifications',
        queryParameters: {'limit': limit},
      );

      if (response.data['status'] == 200 || response.data['success'] == true) {
        final data = response.data['data'] as List;
        return data.map((e) => NotificationModel.fromJson(e)).toList();
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
