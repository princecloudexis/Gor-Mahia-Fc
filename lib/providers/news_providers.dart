import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_model.dart';
import '../repositories/news_repository.dart';

// ─────────────────────────────────────────────
// Latest (home-page snippet — limit 3)
// ─────────────────────────────────────────────
final latestNewsProvider = FutureProvider.autoDispose<List<NewsModel>>((
  ref,
) async {
  final newsRepository = ref.watch(newsRepositoryProvider);
  final response = await newsRepository.getLatestNews(limit: 10);
  return response.data;
});

// ─────────────────────────────────────────────
// Paginated news list (full news page)
// ─────────────────────────────────────────────
class NewsListState {
  final List<NewsModel> items;
  final bool isLoading;
  final bool hasNextPage;
  final int currentPage;
  final String? error;

  const NewsListState({
    this.items = const [],
    this.isLoading = false,
    this.hasNextPage = true,
    this.currentPage = 0,
    this.error,
  });

  NewsListState copyWith({
    List<NewsModel>? items,
    bool? isLoading,
    bool? hasNextPage,
    int? currentPage,
    String? error,
  }) {
    return NewsListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class NewsListNotifier extends StateNotifier<NewsListState> {
  final NewsRepository _repo;

  NewsListNotifier(this._repo) : super(const NewsListState()) {
    fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasNextPage) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repo.getAllNews(page: nextPage);
      state = state.copyWith(
        items: [...state.items, ...response.data],
        isLoading: false,
        hasNextPage: response.meta.hasNextPage,
        currentPage: response.meta.currentPage,
      );
    } catch (e) {
      debugPrint('NewsListNotifier error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const NewsListState();
    await fetchNextPage();
  }
}

final newsListProvider =
    StateNotifierProvider.autoDispose<NewsListNotifier, NewsListState>((ref) {
      final repo = ref.watch(newsRepositoryProvider);
      return NewsListNotifier(repo);
    });

// ─────────────────────────────────────────────
// News detail (single article + related)
// ─────────────────────────────────────────────
final newsDetailProvider = FutureProvider.autoDispose
    .family<NewsDetailResponse, int>((ref, id) async {
      final repo = ref.watch(newsRepositoryProvider);
      return repo.getNewsDetail(id);
    });
