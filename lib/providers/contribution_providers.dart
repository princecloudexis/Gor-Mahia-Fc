import 'package:kogalo_network/models/contribution_models.dart';
import 'package:kogalo_network/repositories/contribution_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contributionCountProvider = FutureProvider.autoDispose<ContributionCount>(
  (ref) async {
    final repo = ref.watch(contributionRepositoryProvider);
    return repo.getContributionCount();
  },
);

class ContributionsNotifier
    extends StateNotifier<AsyncValue<ContributionResponse>> {
  final ContributionRepository _repo;
  final String tab;

  ContributionsNotifier(this._repo, this.tab)
    : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch({int page = 1}) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repo.getContributions(tab, page);
      if (!mounted) return;
      state = AsyncValue.data(res);
    } catch (e, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.pagination.hasMorePages) return;

    try {
      final res = await _repo.getContributions(
        tab,
        currentState.pagination.currentPage + 1,
      );

      if (!mounted) return;
      state = AsyncValue.data(
        ContributionResponse(
          tab: res.tab,
          items: [...currentState.items, ...res.items],
          pagination: res.pagination,
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void updateItemAsPaid(Contribution updatedParticipant) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    if (tab == 'pending') {
      final newItems = currentState.items
          .where((i) => i.participantId != updatedParticipant.participantId)
          .toList();
      state = AsyncValue.data(
        ContributionResponse(
          tab: currentState.tab,
          items: newItems,
          pagination: currentState.pagination,
        ),
      );
    } else if (tab == 'paid') {
      final newItems = [updatedParticipant, ...currentState.items];
      state = AsyncValue.data(
        ContributionResponse(
          tab: currentState.tab,
          items: newItems,
          pagination: currentState.pagination,
        ),
      );
    }
  }
}

final contributionsProvider =
    StateNotifierProvider.family<
      ContributionsNotifier,
      AsyncValue<ContributionResponse>,
      String
    >((ref, tab) {
      final repo = ref.watch(contributionRepositoryProvider);
      return ContributionsNotifier(repo, tab);
    });

class ContributionHistoryNotifier extends StateNotifier<AsyncValue<ContributionHistoryResponse>> {
  final ContributionRepository _repo;

  ContributionHistoryNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch({int page = 1}) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repo.getContributionHistory(page);
      if (!mounted) return;
      state = AsyncValue.data(res);
    } catch (e, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.pagination.hasMorePages) return;

    try {
      final res = await _repo.getContributionHistory(
        currentState.pagination.currentPage + 1,
      );

      if (!mounted) return;
      state = AsyncValue.data(
        ContributionHistoryResponse(
          items: [...currentState.items, ...res.items],
          pagination: res.pagination,
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final contributionHistoryProvider = StateNotifierProvider.autoDispose<
    ContributionHistoryNotifier, AsyncValue<ContributionHistoryResponse>>((ref) {
  final repo = ref.watch(contributionRepositoryProvider);
  return ContributionHistoryNotifier(repo);
});
