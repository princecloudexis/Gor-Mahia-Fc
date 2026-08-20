import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/match_models.dart';

class MatchRepository {
  final ApiClient _apiClient;

  MatchRepository(this._apiClient);

  Future<MatchFixturesResponse> getFixtures() async {
    try {
      final response = await _apiClient.dio.get('/user/matches/fixtures');
      return MatchFixturesResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching fixtures: $e');
      rethrow;
    }
  }

  Future<MatchResultsResponse> getResults() async {
    try {
      final response = await _apiClient.dio.get('/user/matches/results');
      return MatchResultsResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching results: $e');
      rethrow;
    }
  }

  Future<MatchLiveResponse> getLiveMatches() async {
    try {
      final response = await _apiClient.dio.get('/user/matches/live');
      return MatchLiveResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching live matches: $e');
      rethrow;
    }
  }

  Future<MatchLineupResponse> getMatchLineup(int matchId) async {
    try {
      final response = await _apiClient.dio.get('/user/matches/$matchId/lineup');
      return MatchLineupResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching match lineup for $matchId: $e');
      rethrow;
    }
  }

  Future<MatchStatsResponse> getMatchStats(int matchId) async {
    try {
      final response = await _apiClient.dio.get('/user/matches/$matchId/stats');
      return MatchStatsResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching match stats for $matchId: $e');
      rethrow;
    }
  }

  Future<MatchChatResponse> getMatchChat(int matchId) async {
    try {
      final response = await _apiClient.dio.get('/user/matches/$matchId/chat');
      return MatchChatResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching match chat for $matchId: $e');
      rethrow;
    }
  }

  Future<MatchChatMessage> postMatchChat(int matchId, String message) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/matches/$matchId/chat',
        data: {'message': message},
      );
      // Ensure 'data' object exists in the response and parse it
      if (response.data['data'] != null) {
        return MatchChatMessage.fromJson(response.data['data']);
      } else {
        throw Exception("Failed to get message data from response.");
      }
    } catch (e) {
      debugPrint('Error posting match chat for $matchId: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBroadcastingConfig() async {
    try {
      final response = await _apiClient.dio.get('/broadcasting-config');
      if (response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception("No broadcasting config data found.");
    } catch (e) {
      debugPrint('Error fetching broadcasting config: $e');
      rethrow;
    }
  }

  Future<MatchSummaryResponse> getMatchSummary(int matchId) async {
    try {
      final response = await _apiClient.dio.get('/user/matches/$matchId/summary');
      return MatchSummaryResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching match summary for $matchId: $e');
      rethrow;
    }
  }

  Future<MatchOverviewResponse> getMatchOverview(int matchId) async {
    try {
      final response = await _apiClient.dio.get('/user/matches/$matchId');
      return MatchOverviewResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching match overview for $matchId: $e');
      rethrow;
    }
  }
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MatchRepository(apiClient);
});
