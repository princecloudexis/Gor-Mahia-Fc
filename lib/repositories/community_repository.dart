import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kogalo_network/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_models.dart';

class CommunityRepository {
  final ApiClient _apiClient;

  CommunityRepository(this._apiClient);

  bool _isSuccess(dynamic data) {
    if (data is Map) {
      if (data['success'] == true || 
          data['status'] == true || 
          data['status'] == 200 ||
          data['status'] == 'success') {
        return true;
      }
      // Fallback if the API only returns a 'data' object without a status/success wrapper
      if (data.containsKey('data') && !data.containsKey('success') && !data.containsKey('status')) {
        return true;
      }
    }
    return false;
  }

  // 1.1 Fetch User's Joined Groups
  Future<List<CommunityGroup>> fetchJoinedGroups() async {
    try {
      final response = await _apiClient.dio.get('/v1/groups/me');
      if (_isSuccess(response.data)) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => CommunityGroup.fromJson(e)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch joined groups');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 1.2 Search & Explore Groups
  Future<PaginatedResponse<CommunityGroup>> exploreGroups({
    String query = '',
    String? cursor,
    int limit = 6,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/groups',
        queryParameters: {
          if (query.isNotEmpty) 'search': query,
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      if (_isSuccess(response.data)) {
        return PaginatedResponse.fromJson(
            response.data, (json) => CommunityGroup.fromJson(json));
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch groups');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 1.3 Join a Public Group
  Future<void> joinGroup(String groupId) async {
    try {
      final response = await _apiClient.dio.post('/v1/groups/$groupId/join');
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to join group');
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

  // 1.4 Request to Join a Private Group
  Future<void> requestJoinGroup(String groupId) async {
    try {
      final response = await _apiClient.dio.post('/v1/groups/$groupId/request-join');
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to request join');
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

  // 1.5 Leave a Group
  Future<String> leaveGroup(String groupId) async {
    try {
      final response = await _apiClient.dio.get('/v1/groups/$groupId/leave');
      if (_isSuccess(response.data)) {
        return response.data['message'] as String? ?? 'You have left the group';
      }
      throw Exception(response.data['message'] ?? 'Failed to leave group');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 2.1 Fetch Group Details
  Future<CommunityGroup> fetchGroupDetails(String groupId) async {
    try {
      final response = await _apiClient.dio.get('/v1/groups/$groupId');
      if (_isSuccess(response.data)) {
        return CommunityGroup.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch group details');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 2.2 Fetch Group Posts
  Future<PaginatedResponse<CommunityPost>> fetchGroupPosts(
      String groupId, {String? cursor, int limit = 6}) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/groups/$groupId/posts',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          if (cursor != null && int.tryParse(cursor) != null) 'page': cursor,
          'limit': limit,
        },
      );
      if (_isSuccess(response.data)) {
        return PaginatedResponse.fromJson(
          response.data,
          (json) => CommunityPost.fromJson(json),
          limit: limit,
        );
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch posts');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 2.3 Fetch Group Members
  Future<PaginatedResponse<CommunityMember>> fetchGroupMembers(
      String groupId, {String? cursor, int limit = 6}) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/groups/$groupId/members',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          if (cursor != null && int.tryParse(cursor) != null) 'page': cursor,
          'limit': limit,
        },
      );
      if (_isSuccess(response.data)) {
        return PaginatedResponse.fromJson(
          response.data,
          (json) => CommunityMember.fromJson(json),
          limit: limit,
        );
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch members');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 3.1 Upload Media
  Future<CommunityMedia> uploadMedia(String filePath) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _apiClient.dio.post(
        '/v1/media/upload',
        data: formData,
      );
      if (_isSuccess(response.data)) {
        return CommunityMedia.fromJson(response.data['data']);
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

  // 3.0 Fetch GIFs
  Future<PaginatedResponse<CommunityGif>> fetchGifs({String? category, String? search, int limit = 6, String? cursor}) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/gifs',
        queryParameters: {
          if (category != null) 'category': category,
          if (search != null) 'search': search,
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      if (_isSuccess(response.data)) {
        return PaginatedResponse.fromJson(
            response.data, (json) => CommunityGif.fromJson(json));
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch GIFs');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 3.2 Create Standard Post
  Future<CommunityPost> createPost(String groupId, String content, List<CommunityMedia> media, {int? gifId}) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/groups/$groupId/posts',
        data: {
          'content': content,
          if (gifId != null) 'gif_id': gifId,
          if (gifId == null) 'media': media.map((e) => e.toJson()).toList(),
        },
      );
      if (_isSuccess(response.data)) {
        return CommunityPost.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create post');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 3.3 Create Poll Post
  Future<CommunityPost> createPoll(String groupId, String question, List<String> options, int durationHours) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/groups/$groupId/polls',
        data: {
          'question': question,
          'options': options,
          'durationHours': durationHours,
        },
      );
      if (_isSuccess(response.data)) {
        return CommunityPost.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create poll');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 4.1 Toggle Like
  Future<Map<String, dynamic>> toggleLikePost(String postId) async {
    try {
      final response = await _apiClient.dio.post('/v1/posts/$postId/like');
      if (_isSuccess(response.data)) {
        return response.data['data']; // Returns { 'liked': bool, 'likesCount': int }
      }
      throw Exception(response.data['message'] ?? 'Failed to toggle like');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 4.4 Fetch Replies
  Future<PaginatedResponse<CommunityComment>> fetchReplies(
      String commentId, {String? cursor, int limit = 6}) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/comments/$commentId/replies',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      if (_isSuccess(response.data)) {
        return PaginatedResponse.fromJson(
            response.data, (json) => CommunityComment.fromJson(json));
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

  // 4.2 Fetch Comments
  Future<PaginatedResponse<CommunityComment>> fetchComments(
      String postId, {String? cursor, int limit = 6}) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/posts/$postId/comments',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      if (_isSuccess(response.data)) {
        return PaginatedResponse.fromJson(
            response.data, (json) => CommunityComment.fromJson(json));
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

  // 4.3 Add Comment
  Future<CommunityComment> addComment(String postId, String content, {int? gifId, String? parentId}) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/posts/$postId/comments',
        data: {
          'content': content,
          if (gifId != null) 'gif_id': gifId,
          if (parentId != null) 'parent_id': parentId,
        },
      );
      if (_isSuccess(response.data)) {
        return CommunityComment.fromJson(response.data['data']);
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
  // 3.4 Edit Post
  Future<CommunityPost> editPost(String postId, String content, List<CommunityMedia> media, {int? gifId}) async {
    try {
      final response = await _apiClient.dio.put(
        '/v1/posts/$postId',
        data: {
          'content': content,
          if (gifId != null) 'gif_id': gifId,
          if (gifId == null) 'media': media.map((e) => e.toJson()).toList(),
        },
      );
      if (_isSuccess(response.data)) {
        return CommunityPost.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to edit post');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 3.5 Delete Post
  Future<void> deletePost(String postId) async {
    try {
      final response = await _apiClient.dio.delete('/v1/posts/$postId');
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to delete post');
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

  // 4.4 Track/Generate Share Link
  Future<Map<String, dynamic>> sharePost(String postId) async {
    try {
      final response = await _apiClient.dio.post('/v1/posts/$postId/share');
      if (_isSuccess(response.data)) {
        return response.data['data']; // Returns { 'shareUrl': String, 'sharesCount': int }
      }
      throw Exception(response.data['message'] ?? 'Failed to share post');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 4.5 Vote on a Poll
  Future<void> votePoll(String pollId, int optionIndex) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/polls/$pollId/vote',
        data: {
          'optionIndex': optionIndex,
        },
      );
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to vote on poll');
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        debugPrint('VOTE POLL ERROR RESPONSE: ${e.response?.data}');
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 4.6 Edit Comment
  Future<CommunityComment> editComment(String commentId, String content, {int? gifId}) async {
    try {
      final response = await _apiClient.dio.put(
        '/v1/comments/$commentId',
        data: {
          'content': content,
          if (gifId != null) 'gif_id': gifId,
        },
      );
      if (_isSuccess(response.data)) {
        return CommunityComment.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to edit comment');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      rethrow;
    }
  }

  // 4.7 Delete Comment
  Future<void> deleteComment(String commentId) async {
    try {
      final response = await _apiClient.dio.delete('/v1/comments/$commentId');
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Failed to delete comment');
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
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommunityRepository(apiClient);
});
