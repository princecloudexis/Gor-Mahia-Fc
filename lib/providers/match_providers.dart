import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_models.dart';
import '../repositories/match_repository.dart';
import '../services/echo_service.dart';

final matchFixturesProvider = FutureProvider.autoDispose<MatchFixturesData>((
  ref,
) async {
  final matchRepository = ref.watch(matchRepositoryProvider);
  final response = await matchRepository.getFixtures();
  return response.data;
});

final matchResultsProvider = FutureProvider.autoDispose<List<MatchModel>>((
  ref,
) async {
  final matchRepository = ref.watch(matchRepositoryProvider);
  final response = await matchRepository.getResults();
  return response.data;
});

final matchLiveProvider = FutureProvider.autoDispose<List<MatchModel>>((
  ref,
) async {
  final matchRepository = ref.watch(matchRepositoryProvider);
  final response = await matchRepository.getLiveMatches();
  return response.data;
});

final matchLineupProvider = FutureProvider.autoDispose.family<LineupData, int>((
  ref,
  matchId,
) async {
  final matchRepository = ref.watch(matchRepositoryProvider);
  final response = await matchRepository.getMatchLineup(matchId);
  return response.data;
});

final matchStatsProvider = StreamProvider.autoDispose
    .family<MatchStatsData, int>((ref, matchId) async* {
      final matchRepository = ref.watch(matchRepositoryProvider);

      while (true) {
        try {
          final response = await matchRepository.getMatchStats(matchId);
          yield response.data;
        } catch (e) {
          debugPrint('Error polling match stats for $matchId: $e');
        }
        await Future.delayed(const Duration(seconds: 30));
      }
    });

class MatchChatNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<MatchChatMessage>, int> {
  @override
  Future<List<MatchChatMessage>> build(int arg) async {
    final matchId = arg;
    final matchRepository = ref.watch(matchRepositoryProvider);
    final echoService = ref.watch(echoServiceProvider);

    // Subscribe to real-time events
    echoService.subscribeToMatchChat(matchId, (newMessage) {
      addMessage(newMessage);
    });

    ref.onDispose(() {
      echoService.unsubscribeFromMatchChat(matchId);
    });

    final response = await matchRepository.getMatchChat(matchId);
    return response.data;
  }

  void addMessage(MatchChatMessage message) {
    if (state.value != null) {
      // Check if message already exists (prevent duplicate rendering)
      if (!state.value!.any((m) => m.id == message.id)) {
        state = AsyncValue.data([...state.value!, message]);
      }
    }
  }
}

final matchChatProvider = AsyncNotifierProvider.autoDispose
    .family<MatchChatNotifier, List<MatchChatMessage>, int>(
      MatchChatNotifier.new,
    );

final matchSummaryStreamProvider = StreamProvider.autoDispose
    .family<MatchModel, int>((ref, matchId) async* {
      final matchRepository = ref.watch(matchRepositoryProvider);

      // Poll every 30 seconds as requested
      while (true) {
        try {
          final response = await matchRepository.getMatchSummary(matchId);
          yield response.data;
        } catch (e) {
          debugPrint('Error polling match summary for $matchId: $e');
        }
        // Wait 30 seconds before the next fetch to avoid overloading the API
        await Future.delayed(const Duration(seconds: 30));
      }
    });

final matchOverviewProvider = FutureProvider.autoDispose
    .family<MatchOverviewData, int>((ref, matchId) async {
      final matchRepository = ref.watch(matchRepositoryProvider);
      final response = await matchRepository.getMatchOverview(matchId);
      return response.data;
    });
