import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/repositories/event_repositories.dart';
import '../models/event_model.dart';
import 'event_providers.dart';

class CategoryRequestParams {
  final int categoryId;
  final double latitude;
  final double longitude;
  final String? city;
  final EventFilter filter;
  final SortOrder order;

  const CategoryRequestParams({
    required this.categoryId,
    required this.latitude,
    required this.longitude,
    this.city,
    required this.filter,
    required this.order,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryRequestParams &&
        other.categoryId == categoryId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.city == city &&
        other.filter == filter &&
        other.order == order;
  }

  @override
  int get hashCode =>
      categoryId.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      city.hashCode ^
      filter.hashCode ^
      order.hashCode;
}

final AutoDisposeStateProvider<String> sortByProvider =
    StateProvider.autoDispose<String>((ref) => 'Popular');

final categoryWiseEventsProvider = FutureProvider.autoDispose
    .family<List<EventModel>, CategoryRequestParams>((ref, params) {
      final eventRepository = ref.watch(eventRepositoryProvider);

      return eventRepository.getCategoryWiseEventsByCity(
        categoryId: params.categoryId,
        latitude: params.latitude,
        longitude: params.longitude,
        city: params.city,
        filter: params.filter,
        order: params.order,
      );
    });

final isFavoriteProvider = Provider.autoDispose.family<bool, int>((
  ref,
  eventId,
) {
  final favoritesState = ref.watch(favoritesProvider);
  return favoritesState.asData?.value.any((event) => event.id == eventId) ??
      false;
});
