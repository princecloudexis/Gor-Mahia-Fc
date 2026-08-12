import 'dart:async';
import 'package:gormahiafc/models/category_model.dart';
import 'package:gormahiafc/models/checkout_model.dart';
import 'package:gormahiafc/models/ticket_holder_model.dart';
import 'package:gormahiafc/models/ticket_model.dart';
import 'package:gormahiafc/models/user_ticket_model.dart';
import 'package:gormahiafc/providers/location_providers.dart';
import 'package:gormahiafc/repositories/event_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import 'package:gormahiafc/main.dart';
import 'package:gormahiafc/services/fcm_service.dart';
import 'package:gormahiafc/controllers/auth_controller.dart';
import 'package:gormahiafc/pages/login.dart';

class HomePageData {
  final List<CategoryModel> categories;
  final List<EventModel> recentEvents;
  final List<EventModel> discoverThisWeekEvents;
  final List<EventModel> eventsByCity;
  final List<EventModel> upcomingEvents;

  HomePageData({
    required this.categories,
    required this.recentEvents,
    required this.discoverThisWeekEvents,
    required this.eventsByCity,
    required this.upcomingEvents,
  });
}

typedef EventDetailsParams = ({String slug, double lat, double lng});
final bookedSeatsByDateProvider = FutureProvider.autoDispose
    .family<Set<String>, (int, DateTime)>((ref, params) async {
      final repo = ref.watch(eventRepositoryProvider);
      return repo.getBookedSeatsByDate(eventId: params.$1, date: params.$2);
    });
final eventDetailsProvider = FutureProvider.autoDispose
    .family<EventModel, EventDetailsParams>((ref, params) {
      final link = ref.keepAlive();
      final timer = Timer(const Duration(minutes: 5), () {
        link.close();
      });
      ref.onDispose(() => timer.cancel());

      final eventRepository = ref.watch(eventRepositoryProvider);
      return eventRepository.getEventDetails(
        slug: params.slug,
        latitude: params.lat,
        longitude: params.lng,
      );
    });

class FavoritesNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final Ref _ref;
  late final EventRepository _repo;

  FavoritesNotifier(this._ref) : super(const AsyncLoading()) {
    _repo = _ref.read(eventRepositoryProvider);
    _fetchInitialFavorites();
  }

  Future<void> _fetchInitialFavorites() async {
    state = const AsyncLoading();
    try {
      final events = await _repo.getFavoriteEvents();
      if (!mounted) return;
      state = AsyncData(events);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleFavorite(EventModel event) async {
    final authState = _ref.read(authControllerProvider);
    if (authState.status != AuthStatus.authenticated) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('Please log in to save favorites'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Login',
            textColor: Colors.white,
            onPressed: () {
              final context = NavigationService.navigatorKey.currentContext;
              if (context != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
              }
            },
          ),
        ),
      );
      return;
    }

    final List<EventModel> previousState = state.valueOrNull ?? [];
    final bool isCurrentlyFavorite = previousState.any((e) => e.id == event.id);
    if (isCurrentlyFavorite) {
      state = AsyncData(previousState.where((e) => e.id != event.id).toList());
    } else {
      state = AsyncData([...previousState, event]);
    }
    try {
      await _repo.toggleFavoriteStatus(event.id);
    } catch (e) {
      state = AsyncData(previousState);
      final msg = e.toString().replaceFirst('Exception: ', '').replaceFirst('AppException: ', '');
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final events = await _repo.getFavoriteEvents();
      if (!mounted) return;
      state = AsyncData(events);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncError(e, st);
      }
    }
  }
}

final availableCitiesProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(eventRepositoryProvider).getAvailableCities();
});

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<EventModel>>>((
      ref,
    ) {
      return FavoritesNotifier(ref);
    });

final selectedCityProvider = StateProvider<String?>((ref) => null);

// REPLACE homePageDataProvider
final homePageDataProvider = FutureProvider.autoDispose<HomePageData>((
  ref,
) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final locationAsync = ref.watch(userLocationProvider);
  final location = locationAsync.valueOrNull;
  final selectedCity = ref.watch(selectedCityProvider);

  // This logic correctly determines the city being viewed
  final cityName = selectedCity?.isNotEmpty == true
      ? selectedCity!.toLowerCase().trim()
      : (location?.city != null && location!.city.isNotEmpty)
      ? location.city.toLowerCase().trim()
      : 'nairobi';

  debugPrint('🏙️ Loading home data for city: $cityName');

  final results = await Future.wait([
    eventRepository.getCategoriesAndRecentEvents(city: cityName),
    // UPDATE THIS LINE to pass cityName:
    eventRepository.getDiscoverThisWeekEvents(city: cityName),
    eventRepository.getEventsByCity(city: cityName),
    eventRepository.getUpcomingEvents(city: cityName),
  ]);

  final categoriesAndRecentData = results[0] as HomeCategoriesResponse;

  return HomePageData(
    categories: categoriesAndRecentData.categories,
    recentEvents: categoriesAndRecentData.recentEvents,
    discoverThisWeekEvents: results[1] as List<EventModel>,
    eventsByCity: results[2] as List<EventModel>,
    upcomingEvents: results[3] as List<EventModel>,
  );
});
// });

// final discoverThisWeekEventsProvider = FutureProvider<List<EventModel>>((ref) {
//   return ref.watch(eventRepositoryProvider).getDiscoverThisWeekEvents();
// });

// final categoriesAndRecentEventsProvider =
//     FutureProvider<HomeCategoriesResponse>((ref) {
//       return ref.watch(eventRepositoryProvider).getCategoriesAndRecentEvents();
//     });

final eventsByCityProvider = FutureProvider.autoDispose
    .family<List<EventModel>, String>((ref, city) {
      final eventRepository = ref.watch(eventRepositoryProvider);
      return eventRepository.getEventsByCity(city: city);
    });

typedef Coords = ({double lat, double lng});
final nearYouEventsProvider = FutureProvider.autoDispose
    .family<List<EventModel>, Coords>((ref, coords) {
      final eventRepository = ref.watch(eventRepositoryProvider);
      return eventRepository.getNearYouEvents(
        latitude: coords.lat,
        longitude: coords.lng,
      );
    });

// typedef CategoryWiseParams = ({
//   int categoryId,
//   double latitude,
//   double longitude,
//   EventFilter filter,
//   SortOrder order,
// });

// final categoryWiseEventsProvider = FutureProvider.autoDispose
//     .family<List<EventModel>, CategoryWiseParams>((ref, params) {
//       final eventRepository = ref.watch(eventRepositoryProvider);
//       return eventRepository.getCategoryWiseEvents(
//         categoryId: params.categoryId,
//         latitude: params.latitude,
//         longitude: params.longitude,
//         filter: params.filter,
//         order: params.order,
//       );
//     });

final ticketDetailsProvider = FutureProvider.autoDispose
    .family<TicketDetailModel, String>((ref, slug) {
      final link = ref.keepAlive();
      final timer = Timer(const Duration(minutes: 2), () {
        link.close();
      });
      ref.onDispose(() => timer.cancel());

      final eventRepository = ref.watch(eventRepositoryProvider);
      return eventRepository.getTicketDetails(slug: slug);
    });

final ticketsProvider = FutureProvider.autoDispose
    .family<List<UserTicketModel>, String>((ref, tab) {
      final eventRepository = ref.watch(eventRepositoryProvider);
      return eventRepository.getTickets(tab: tab);
    });

final ticketHolderDetailsProvider = FutureProvider.autoDispose
    .family<List<TicketHolderDetailModel>, int>((ref, eventId) {
      final repository = ref.watch(eventRepositoryProvider);
      return repository.getTicketHolderDetails(eventId: eventId);
    });

final checkoutDetailsProvider = FutureProvider.autoDispose
    .family<CheckoutDetailsModel, String>((ref, orderId) {
      final eventRepository = ref.watch(eventRepositoryProvider);
      return eventRepository.getCheckoutDetails(orderId);
    });
