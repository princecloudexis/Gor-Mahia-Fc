import 'package:kogalo_network/models/membership_models.dart';
import 'package:kogalo_network/repositories/membership_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembershipHistoryNotifier extends StateNotifier<AsyncValue<MembershipHistoryResponse>> {
  final MembershipRepository _repository;

  MembershipHistoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    try {
      state = const AsyncValue.loading();
      final response = await _repository.getMembershipHistory(page: 1);
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final currentData = state.value;
    if (currentData == null) return;
    if (!currentData.pagination.hasMorePages) return;

    final nextPage = currentData.pagination.currentPage + 1;
    
    try {
      final response = await _repository.getMembershipHistory(page: nextPage);
      
      final newItems = [...currentData.items, ...response.items];
      
      state = AsyncValue.data(MembershipHistoryResponse(
        items: newItems,
        pagination: response.pagination,
      ));
    } catch (e) {
      // Intentionally swallow error on load more to avoid breaking current list.
    }
  }
}

final membershipHistoryProvider = StateNotifierProvider.autoDispose<MembershipHistoryNotifier, AsyncValue<MembershipHistoryResponse>>((ref) {
  final repository = ref.watch(membershipRepositoryProvider);
  return MembershipHistoryNotifier(repository);
});
