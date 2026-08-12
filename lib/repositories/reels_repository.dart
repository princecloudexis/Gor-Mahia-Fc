import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gormahiafc/api/api_client.dart';
import '../models/reels_model.dart';

class ReelsRepository {
  final ApiClient _apiClient;

  ReelsRepository(this._apiClient);

  bool _isSuccess(dynamic data) {
    if (data is Map) {
      if (data['success'] == true ||
          data['status'] == true ||
          data['status'] == 200 ||
          data['status'] == 'success') {
        return true;
      }
      if (data.containsKey('data') &&
          !data.containsKey('success') &&
          !data.containsKey('status')) {
        return true;
      }
    }
    return false;
  }

  Future<ReelResponse> fetchReels({String? cursor, int? position, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/reels',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          if (position != null) 'position': position,
          'limit': limit
        },
      );
      if (_isSuccess(response.data)) {
        // 🔍 DEBUG: Only runs in debug builds — removed from production.
        if (kDebugMode && response.data['data'] is List) {
          final reelsList = response.data['data'] as List;
          debugPrint('🔍 DEBUG TOTAL REELS RECEIVED: ${reelsList.length}');
          for (int i = 0; i < reelsList.length; i++) {
            final reelJson = reelsList[i];
            debugPrint('🔍 REEL[$i] id=${reelJson['id']} | isLikedByMe=${reelJson['isLikedByMe']} | likesCount=${reelJson['likesCount']}');
          }
          if (reelsList.isNotEmpty) {
            debugPrint('🔍 ALL KEYS IN REEL[0]: ${(response.data['data'] as List)[0].keys.toList()}');
          }
        }
        return ReelResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch reels');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  Future<Reel> fetchReel(String reelId) async {
    try {
      final response = await _apiClient.dio.get('/v1/reels/$reelId');
      if (_isSuccess(response.data)) {
        final data = response.data['data'] ?? response.data;
        return Reel.fromJson(data);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch reel');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  Future<ReelResponse> fetchMyReels({String? cursor, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/reels/mine',
        queryParameters: {if (cursor != null) 'cursor': cursor, 'limit': limit},
      );
      if (_isSuccess(response.data)) {
        return ReelResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch my reels');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // The backend API currently lists this as a GET method for likes, but realistically it's meant to toggle likes.
  // We will call the endpoint exactly as defined: /v1/reels/{reelId}/like
  // I am using POST here since the backend *should* expect a POST for modifying data,
  // but if the backend strictly expects GET for this toggle, we might need to change this to _apiClient.dio.get
  Future<Map<String, dynamic>> toggleLike(String reelId) async {
    try {
      // NOTE: The backend route has likely been updated to POST, as GET now returns 405 Method Not Allowed.
      final response = await _apiClient.dio.post('/v1/reels/$reelId/like');
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to toggle like');
      }
      return response.data['data'] ?? {};
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markNotInterested(String reelId) async {
    try {
      final response = await _apiClient.dio.post('/v1/reels/$reelId/not-interested');
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to mark not interested');
      }
      return response.data;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          final message = responseData['message'] ?? '';
          final exception = responseData['exception'] ?? '';
          final file = responseData['file'] ?? '';
          final line = responseData['line'] ?? '';
          
          if (message.toString().isNotEmpty || exception.toString().isNotEmpty) {
            throw Exception('Server Error: $message\nException: $exception\nFile: $file:$line');
          }
        }
        throw Exception('Server Error: ${e.response!.data}');
      }
      rethrow;
    }
  }

  Future<String> uploadReelMedia(
    String filePath, {
    ProgressCallback? onSendProgress,
  }) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _apiClient.dio.post(
        '/v1/reels/upload',
        data: formData,
        onSendProgress: onSendProgress,
      );
      if (_isSuccess(response.data)) {
        final data = response.data['data'] ?? response.data;
        return data['videoUrl']?.toString() ?? '';
      }
      throw Exception(response.data['message'] ?? 'Failed to upload media');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  Future<Reel> createReel(
    String videoUrl,
    String caption, {
    int durationSeconds = 0,
    double? latitude,
    double? longitude,
    String? city,
    String? country,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/reels',
        data: {
          'videoUrl': videoUrl,
          'caption': caption,
          'durationSeconds': durationSeconds,
          'visibility': 'public',
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (city != null) 'city': city,
          if (country != null) 'country': country,
        },
      );
      if (_isSuccess(response.data)) {
        final data = response.data['data'] ?? response.data;
        return Reel.fromJson(data);
      }
      throw Exception(response.data['message'] ?? 'Failed to create reel');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  Future<void> shareReel(String reelId, {String platform = 'other'}) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/reels/$reelId/share',
        data: {'platform': platform},
      );
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to share reel');
      }
    } catch (e) {
      print('Failed to log share: $e');
    }
  }

  Future<void> viewReel(String reelId, {int watchedSeconds = 0}) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/reels/$reelId/view',
        data: {'watchedSeconds': watchedSeconds},
      );
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to log view');
      }
    } catch (e) {
      print('Failed to log view: $e');
    }
  }

  String _generateUuidV4() {
    final random = math.Random();
    final hexDigits = '0123456789abcdef';
    String uuid = '';
    for (int i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        uuid += '-';
      } else if (i == 14) {
        uuid += '4';
      } else if (i == 19) {
        uuid += hexDigits[(random.nextInt(4) + 8)];
      } else {
        uuid += hexDigits[random.nextInt(16)];
      }
    }
    return uuid;
  }

  Future<void> logActivity({
    required String reelId,
    required String eventType,
    required double watchedPercentage,
    required int watchedSeconds,
    double? latitude,
    double? longitude,
    String? city,
    String? country,
  }) async {
    try {
      // Try to parse reelId to int if the backend strictly requires an integer
      dynamic parsedReelId = int.tryParse(reelId);
      parsedReelId ??= reelId;

      // Ensure proper format for strict backend validation
      final eventId = _generateUuidV4();
      final dateStr =
          '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';

      final response = await _apiClient.dio.post(
        '/v1/reels/activity',
        data: {
          'eventId': eventId,
          'reelId': parsedReelId,
          'eventType': eventType,
          'watchedPercentage': watchedPercentage.toInt(),
          'watchedSeconds': watchedSeconds,
          'metadata': {'quality': 'auto'},
          'occurredAt': dateStr,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (city != null) 'city': city,
          if (country != null) 'country': country,
        },
      );
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to log activity');
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        print('Failed to log activity: Validation Error: ${e.response?.data}');
      } else {
        print('Failed to log activity: $e');
      }
    }
  }

  Future<ReelCommentResponse> fetchReelComments(
    String reelId, {
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/reels/$reelId/comments',
        queryParameters: {if (cursor != null) 'cursor': cursor, 'limit': limit},
      );
      if (_isSuccess(response.data)) {
        return ReelCommentResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch comments');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addReelComment(
    String reelId,
    String content, {
    String? parentId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/reels/$reelId/comments',
        data: {'content': content, if (parentId != null) 'parentId': parentId},
      );
      if (_isSuccess(response.data)) {
        final data = response.data['data'] ?? response.data;
        ReelComment? comment;
        int? commentsCount;

        if (data is List && data.isNotEmpty) {
          comment = ReelComment.fromJson(data.first);
        } else if (data is Map<String, dynamic>) {
          comment = ReelComment.fromJson(data);
          if (data['commentsCount'] != null) {
            commentsCount = int.tryParse(data['commentsCount'].toString());
          }
        }

        comment ??= ReelComment(
          id: DateTime.now().toString(),
          authorId: '',
          authorName: 'Me',
          content: content,
          timestamp: DateTime.now(),
        );

        return {'comment': comment, 'commentsCount': commentsCount};
      }
      throw Exception(response.data['message'] ?? 'Failed to add comment');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleCommentLike(String commentId) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/reels/comments/$commentId/like',
      );
      if (_isSuccess(response.data)) {
        return response.data['data'] ?? {};
      }
      throw Exception(
        response.data['message'] ?? 'Failed to toggle comment like',
      );
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  Future<Reel> editReel(
    String reelId, {
    String? caption,
    String? visibility,
    double? latitude,
    double? longitude,
    String? city,
    String? country,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (caption != null) data['caption'] = caption;
      if (visibility != null) data['visibility'] = visibility;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (city != null) data['city'] = city;
      if (country != null) data['country'] = country;

      final response = await _apiClient.dio.put(
        '/v1/reels/$reelId',
        data: data,
      );
      if (_isSuccess(response.data)) {
        final resData = response.data['data'] ?? response.data;
        return Reel.fromJson(resData);
      }
      throw Exception(response.data['message'] ?? 'Failed to edit reel');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  Future<void> deleteReel(String reelId) async {
    try {
      final response = await _apiClient.dio.delete('/v1/reels/$reelId');
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to delete reel');
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  Future<ReelCommentResponse> fetchCommentReplies(
    String commentId, {
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/reels/comments/$commentId/replies',
        queryParameters: {'page': page},
      );
      if (_isSuccess(response.data)) {
        return ReelCommentResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch replies');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }
}

final reelsRepositoryProvider = Provider<ReelsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReelsRepository(apiClient);
});
