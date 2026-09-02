import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/news_model.dart';

class NewsRepository {
  final ApiClient _apiClient;

  NewsRepository(this._apiClient);

  Future<NewsResponse> getLatestNews({int limit = 3}) async {
    try {
      final response = await _apiClient.dio.get(
        '/user/news/latest',
        queryParameters: {'limit': limit},
      );
      return NewsResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching latest news: $e');
      rethrow;
    }
  }

  Future<PaginatedNewsResponse> getAllNews({int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        '/user/news',
        queryParameters: {'page': page},
      );
      return PaginatedNewsResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching all news (page $page): $e');
      rethrow;
    }
  }

  Future<NewsDetailResponse> getNewsDetail(int id) async {
    try {
      final response = await _apiClient.dio.get('/user/news/$id');
      return NewsDetailResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching news detail for id $id: $e');
      rethrow;
    }
  }
}

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NewsRepository(apiClient);
});
