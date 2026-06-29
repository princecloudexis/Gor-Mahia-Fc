import 'dart:async';
import 'package:eventsbooking/models/category_model.dart';
import 'package:eventsbooking/repositories/event_repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';

enum SearchStatus { initial, loading, success, error }

class SearchState {
  final SearchStatus status;
  final List<EventModel> results;
  final String? errorMessage;
  final String currentQuery;

  final List<CategoryModel> availableCategories;
  final bool areCategoriesLoading;
  final String selectedDateFilter;
  final int? selectedCategoryId; 

  SearchState({
    this.status = SearchStatus.initial,
    this.results = const [],
    this.errorMessage,
    this.currentQuery = '',
    this.availableCategories = const [],
    this.areCategoriesLoading = true, 
    this.selectedDateFilter = 'all',
    this.selectedCategoryId, 
  });

  bool get hasActiveFilters {
    return selectedDateFilter != 'all' || selectedCategoryId != null;
  }

  SearchState copyWith({
    SearchStatus? status,
    List<EventModel>? results,
    String? errorMessage,
    String? currentQuery,
    List<CategoryModel>? availableCategories,
    bool? areCategoriesLoading,
    String? selectedDateFilter,
    int? selectedCategoryId,
    bool clearSelectedCategory = false, 
  }) {
    return SearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
      currentQuery: currentQuery ?? this.currentQuery,
      availableCategories: availableCategories ?? this.availableCategories,
      areCategoriesLoading: areCategoriesLoading ?? this.areCategoriesLoading,
      selectedDateFilter: selectedDateFilter ?? this.selectedDateFilter,
      selectedCategoryId: clearSelectedCategory
          ? null
          : selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final EventRepository _eventRepository;
  Timer? _debounce;

  SearchNotifier(this._eventRepository) : super(SearchState()) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _eventRepository.searchAndFilterEvents(
        query: '',
        dateFilter: 'all',
        categoryIds: [],
      );
      state = state.copyWith(
        availableCategories: response.availableCategories,
        areCategoriesLoading: false, 
      );
    } catch (e) {
      print('Error loading categories: $e');
      state = state.copyWith(areCategoriesLoading: false);
    }
  }

  void _triggerSearch() {
    _debounce?.cancel();
    if (state.currentQuery.isEmpty && !state.hasActiveFilters) {
      resetSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), _performSearch);
  }

  Future<void> _performSearch() async {
    state = state.copyWith(status: SearchStatus.loading);
    try {
      final categoryIdList =
          state.selectedCategoryId == null ? <int>[] : [state.selectedCategoryId!];

      final response = await _eventRepository.searchAndFilterEvents(
        query: state.currentQuery,
        dateFilter: state.selectedDateFilter,
        categoryIds: categoryIdList,
      );

      state = state.copyWith(status: SearchStatus.success, results: response.events);
    } catch (e) {
      state = state.copyWith(status: SearchStatus.error, errorMessage: e.toString());
    }
  }

  void onQueryChanged(String query) {
    state = state.copyWith(currentQuery: query);
    _triggerSearch();
  }

  void setDateFilter(String newFilter) {
    state = state.copyWith(selectedDateFilter: newFilter);
    _updateFiltersAndTriggerSearch();
  }

  void selectCategory(int? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearSelectedCategory: true);
    } else {
      final newId = state.selectedCategoryId == categoryId ? null : categoryId;
      state = state.copyWith(
        selectedCategoryId: newId,
        clearSelectedCategory: newId == null,
      );
    }
    _updateFiltersAndTriggerSearch();
  }

  void _updateFiltersAndTriggerSearch() {
    if (state.currentQuery.isEmpty && !state.hasActiveFilters) {
      resetSearch();
    } else {
      triggerFilterSearch();
    }
  }

  void triggerFilterSearch() {
    _debounce?.cancel();
    _performSearch();
  }

  void resetSearch() {
    final categories = state.availableCategories;
    state = SearchState(
      status: SearchStatus.initial,
      availableCategories: categories,
      areCategoriesLoading: false, 
    );
  }

  void clearAllFilters() {
    resetSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return SearchNotifier(eventRepository);
});