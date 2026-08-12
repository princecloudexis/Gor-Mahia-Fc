import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:gormahiafc/models/checkout_model.dart';
import 'package:gormahiafc/models/holder_info_model.dart';
import 'package:gormahiafc/models/map_booking_response.dart';
import 'package:gormahiafc/models/payment_model.dart';
import 'package:gormahiafc/models/search_model.dart';
import 'package:gormahiafc/models/ticket_holder_model.dart';
import 'package:gormahiafc/models/ticket_model.dart';
import 'package:gormahiafc/models/user_ticket_model.dart';
import 'package:gormahiafc/providers/user_providers.dart';
import 'package:gormahiafc/utils/app_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../models/event_model.dart';
import '../models/category_model.dart';

enum EventFilter { date, price, distance, popular }

enum SortOrder { asc, desc }

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventRepository(apiClient, ref);
});

class EventRepository {
  final ApiClient _apiClient;
  final Ref _ref;
  EventRepository(this._apiClient, this._ref);

  dynamic _decodeIfJsonString(dynamic value) {
    if (value is! String) return value;
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  dynamic _unwrapDataEnvelope(dynamic value) {
    final decoded = _decodeIfJsonString(value);
    if (decoded is Map<String, dynamic>) {
      final inner = decoded['data'];
      if (inner != null) {
        return _decodeIfJsonString(inner);
      }
    }
    return decoded;
  }

  Set<String> _collectBookedSeatVariants(dynamic raw) {
    final bookedSeats = <String>{};
    final visited = <int>{};

    void addSeat(String seatValue, {String? groupKey}) {
      final seat = seatValue.trim();
      if (seat.isEmpty) return;

      // Helper to match the UI parser's ID generation logic
      String normalizeIdPart(String? input) {
        if (input == null || input.trim().isEmpty) return 'unknown';
        return input.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
      }

      final normalizedSeat = normalizeIdPart(seat);

      bookedSeats.add(seat);
      bookedSeats.add(seat.toLowerCase());

      // If the seat ID itself needs normalization (e.g. "Main Hall_A1" -> "Main_Hall_A1")
      if (normalizedSeat != seat) {
        bookedSeats.add(normalizedSeat);
        bookedSeats.add(normalizedSeat.toLowerCase());
      }

      if (groupKey != null && groupKey.trim().isNotEmpty) {
        final group = groupKey.trim();
        final normalizedGroup = normalizeIdPart(group);

        // 1. Add raw group variant: "Main Hall_A1"
        bookedSeats.add('${group}_$seat');
        bookedSeats.add('${group}_${seat.toLowerCase()}');

        // 2. Add normalized group variant: "Main_Hall_A1" (Crucial for matching UI parser)
        if (normalizedGroup != group) {
          bookedSeats.add('${normalizedGroup}_$seat');
          bookedSeats.add('${normalizedGroup}_${seat.toLowerCase()}');
        }

        if (seat.startsWith('${group}_')) {
          final stripped = seat.replaceFirst('${group}_', '');
          if (stripped.isNotEmpty) {
            bookedSeats.add(stripped);
            bookedSeats.add(stripped.toLowerCase());
          }
        }
      }

      final match = RegExp(r'([A-Za-z]+\d+)').firstMatch(seat);
      final extracted = match?.group(1);
      if (extracted != null && extracted.isNotEmpty) {
        bookedSeats.add(extracted);
        bookedSeats.add(extracted.toLowerCase());
        if (groupKey != null && groupKey.trim().isNotEmpty) {
          final group = groupKey.trim();
          final normalizedGroup = normalizeIdPart(group);
          bookedSeats.add('${group}_$extracted');
          bookedSeats.add('${normalizedGroup}_$extracted');
        }
      }
    }

    void visit(dynamic node, {String? groupKey}) {
      if (node == null) return;

      final unwrapped = _unwrapDataEnvelope(node);
      if (unwrapped is Map) {
        final identity = identityHashCode(unwrapped);
        if (visited.contains(identity)) return;
        visited.add(identity);

        unwrapped.forEach((key, value) {
          final keyString = key.toString();
          if (keyString == 'success' ||
              keyString == 'status' ||
              keyString == 'message') {
            return;
          }
          visit(value, groupKey: keyString);
        });
        return;
      }

      if (unwrapped is List) {
        for (final item in unwrapped) {
          visit(item, groupKey: groupKey);
        }
        return;
      }

      if (unwrapped is String || unwrapped is num) {
        addSeat(unwrapped.toString(), groupKey: groupKey);
      }
    }

    visit(raw);
    return bookedSeats;
  }

  // GET CITIES LIST (no body needed)
  Future<List<String>> getAvailableCities() async {
    try {
      final response = await _apiClient.dio.post('/user/location');
      final List<dynamic> cities = response.data['cities'] ?? [];
      return cities.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      debugPrint('❌ getAvailableCities error: ${e.message}');
      if (e.error is AppException) throw e.error!;
      throw AppException.fromDioException(e);
    }
  }

  Future<List<EventModel>> getEventsByCity({required String city}) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/location',
        data: {'city': city.toLowerCase().trim()},
      );

      if (response.data == null || response.data['data'] == null) return [];
      final List<dynamic> data = response.data['data'];
      return data.map((json) => EventModel.fromJson(json)).toList();
    } on DioException catch (e) {
      debugPrint('❌ getEventsByCity error: ${e.message}');
      if (e.error is AppException) throw e.error!;
      throw AppException.fromDioException(e);
    }
  }

  Future<Set<String>> getBookedSeatsByDate({
    required int eventId,
    required DateTime date,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    try {
      final response = await _apiClient.dio.get(
        '/user/booked-seats/$eventId/$formattedDate',
      );

      final payload = _unwrapDataEnvelope(response.data);
      if (payload == null) return {};

      final seatsSource = payload is Map<String, dynamic>
          ? (payload['bookedSeats'] ??
                payload['booked_seats'] ??
                payload['seats'] ??
                payload)
          : payload;

      final bookedSeats = _collectBookedSeatVariants(seatsSource);

      debugPrint('✅ Booked seats for $formattedDate: $bookedSeats');
      return bookedSeats;
    } on DioException catch (e) {
      debugPrint('❌ getBookedSeatsByDate error: ${e.message}');
      return {};
    }
  }

  Future<void> cancelOrder(String orderId) async {
    debugPrint('🚫 Cancelling Pending Order: $orderId');
    try {
      final response = await _apiClient.dio.post(
        '/user/checkout/cancel',
        data: {'order_id': orderId},
      );

      if (response.statusCode == 200) {
        debugPrint("Seats released successfully.");
      } else {
        debugPrint("⚠️ Failed to release seats: ${response.data}");
      }
    } on DioException catch (e) {
      debugPrint("❌ DioError cancelling order: ${e.message}");
    } catch (e) {
      debugPrint("❌ Error cancelling order: $e");
    }
  }

  Future<Map<String, dynamic>?> getSeatMap(int eventId) async {
    debugPrint('🔍 Fetching seat map for event ID: $eventId');
    try {
      final response = await _apiClient.dio.get('/user/seat-map/$eventId');

      if (response.data == null) return null;
      dynamic data = _unwrapDataEnvelope(response.data);

      if (data is! Map<String, dynamic>) {
        debugPrint('getSeatMap: response is not a Map<String,dynamic>');
        return null;
      }

      if (data['seat_map_json'] != null) {
        final innerJson = data['seat_map_json'];
        if (innerJson is String) {
          debugPrint('📦 seat_map_json is a String, decoding...');
          data['seat_map_json'] = jsonDecode(innerJson);
        }
      } else if (data.containsKey('attrs')) {
        data = {'seat_map_json': data, 'bookedSeats': []};
      }

      final rawBooked = data['bookedSeats'] ?? data['booked_seats'];

      if (rawBooked != null) {
        debugPrint('raw bookedSeats from API: $rawBooked');
        final bookedSet = _collectBookedSeatVariants(rawBooked);

        debugPrint('parsed bookedSeats set: $bookedSet');
        data['bookedSeats'] = bookedSet.toList();
      } else {
        data['bookedSeats'] = <String>[];
      }

      return data;
    } on DioException catch (e, st) {
      debugPrint('getSeatMap DioException: type=${e.type}');
      debugPrint('message: ${e.message}');
      debugPrint('error: ${e.error}');
      debugPrint('response: ${e.response?.data}');
      debugPrint('stack: $st');
      return null;
    } catch (e, st) {
      debugPrint('getSeatMap unknown error: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<MapBookingResponse> bookFromMapTickets({
    required List<Map<String, dynamic>> assigned,
    required List<Map<String, dynamic>> blocks,
  }) async {
    final Map<String, String> data = {};

    // assigned[i][seat], [ticket_id], [ticket], [allotment], date field
    // NOTE: Backend variants exist (`date_of_access` and `dateofaccess`).
    // Send both to avoid seats being saved without date and becoming globally blocked.
    for (var i = 0; i < assigned.length; i++) {
      final item = assigned[i];
      data['assigned[$i][seat]'] = item['seat'].toString();
      data['assigned[$i][ticket_id]'] = item['ticket_id'].toString();
      data['assigned[$i][ticket]'] = item['ticket'].toString();
      data['assigned[$i][allotment]'] = item['allotment'].toString();
      if (item['date_of_access'] != null) {
        final dateValue = item['date_of_access'].toString();
        data['assigned[$i][date_of_access]'] = dateValue;
        data['assigned[$i][dateofaccess]'] = dateValue;
      }
    }

    // blocks[i][block_id], [ticket_id], [ticket], [quantity], [allotment], date field
    for (var i = 0; i < blocks.length; i++) {
      final item = blocks[i];
      data['blocks[$i][block_id]'] = item['block_id'].toString();
      data['blocks[$i][ticket_id]'] = item['ticket_id'].toString();
      data['blocks[$i][ticket]'] = item['ticket'].toString();
      data['blocks[$i][quantity]'] = item['quantity'].toString();
      data['blocks[$i][allotment]'] = item['allotment'].toString();
      if (item['date_of_access'] != null) {
        final dateValue = item['date_of_access'].toString();
        data['blocks[$i][date_of_access]'] = dateValue;
        data['blocks[$i][dateofaccess]'] = dateValue;
      }
    }

    try {
      final response = await _apiClient.dio.post(
        '/user/tickets/map-book',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is! Map<String, dynamic>) {
        throw AppException(
          'Invalid response format from seat map booking API.',
        );
      }

      final json = response.data as Map<String, dynamic>;
      final result = MapBookingResponse.fromJson(json);

      if (!result.success) {
        throw AppException(
          result.message.isNotEmpty ? result.message : 'Seat booking failed.',
        );
      }

      return result;
    } on DioException catch (e) {
      debugPrint('checkout error status: ${e.response?.statusCode}');
      debugPrint('checkout error data: ${e.response?.data}');

      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message']?.toString();
        final seats = responseData['seats'];
        if (message != null && message.isNotEmpty) {
          if (seats is List && seats.isNotEmpty) {
            final seatList = seats.map((s) => s.toString()).join(', ');
            throw SeatConflictException(
              message: '$message: $seatList',
              seats: seats.map((s) => s.toString()).toList(),
            );
          }
          throw AppException(message);
        }
      }

      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<CheckoutDetailsModel> getCheckoutDetails(String orderId) async {
    try {
      final response = await _apiClient.dio.get('/user/checkout/$orderId');
      if (response.data is! Map<String, dynamic>) {
        throw AppException('Invalid response format from server.');
      }
      final jsonResponse = response.data as Map<String, dynamic>;
      final bool success = jsonResponse['success'] ?? false;

      if (success) {
        return CheckoutDetailsModel.fromJson(jsonResponse);
      } else {
        final errorMessage =
            jsonResponse['message'] ?? 'An unknown API error occurred.';
        throw AppException(errorMessage);
      }
    } on DioException catch (e) {
      debugPrint('checkout error status: ${e.response?.statusCode}');
      debugPrint('checkout error data: ${e.response?.data}');
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<String> bookTickets({
    required Map<int, int> ticketQuantities,
    required DateTime selectedDate,
  }) async {
    final Map<String, String> data = {};
    int index = 0;

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    ticketQuantities.forEach((ticketId, quantity) {
      if (quantity > 0) {
        data['tickets[$index][id]'] = ticketId.toString();
        data['tickets[$index][quantity]'] = quantity.toString();
        data['tickets[$index][dateofaccess]'] = formattedDate;
        index++;
      }
    });

    if (data.isEmpty) {
      throw Exception('No tickets were selected.');
    }

    try {
      final response = await _apiClient.dio.post(
        '/user/tickets/book',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data['success'] == true &&
          response.data['order_id'] != null) {
        return response.data['order_id'];
      } else {
        throw Exception(response.data['message'] ?? 'Ticket booking failed.');
      }
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<EventModel> getEventDetails({
    required String slug,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/event/details',
        data: {
          'slug': slug,
          'userLat': latitude.toString(),
          'userLng': longitude.toString(),
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data == null || response.data['data'] == null) {
        throw AppException('Event details not found.');
      }

      return EventModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<List<EventModel>> getFavoriteEvents() async {
    try {
      final response = await _apiClient.dio.get('/user/favourite/list');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => EventModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<void> toggleFavoriteStatus(int eventId) async {
    final user = _ref.read(userProvider);
    if (user == null) {
      throw Exception('Cannot toggle favorite: User is not logged in.');
    }
    final userId = user.id;
    try {
      await _apiClient.dio.post(
        '/user/favourties',
        data: {'event_id': eventId, 'user_id': userId.toString()},
      );
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Could not update favorite status.';
      throw Exception(errorMessage);
    }
  }

  Future<SearchResponseModel> searchAndFilterEvents({
    required String query,
    String dateFilter = 'all',
    List<int> categoryIds = const [],
  }) async {
    try {
      final categoriesString = categoryIds.join(',');

      final response = await _apiClient.dio.post(
        '/user/search',
        data: {
          'search': query,
          'date': dateFilter,
          'categories': categoriesString,
        },
      );
      return SearchResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<List<EventModel>> getUpcomingEvents({String? city}) async {
    try {
      final response = await _apiClient.dio.get('/user/upcoming/events');
      final List<dynamic> data = response.data['data'] ?? [];
      final events = data.map((json) => EventModel.fromJson(json)).toList();

      if (city != null && city.trim().isNotEmpty) {
        final filterCity = city.toLowerCase().trim();
        final filtered = events.where((e) {
          final eventCity = (e.city ?? '').toLowerCase().trim();
          return eventCity == filterCity || eventCity.contains(filterCity);
        }).toList();

        debugPrint(
          '🏙️ Upcoming events for "$city": '
          '${filtered.length}/${events.length}',
        );
        return filtered;
      }

      return events;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException.fromDioException(e);
    }
  }

  Future<List<EventModel>> getDiscoverThisWeekEvents({String? city}) async {
    try {
      final response = await _apiClient.dio.get('/user/week/events');
      final List<dynamic> data = response.data['data'] ?? [];
      final events = data.map((json) => EventModel.fromJson(json)).toList();

      if (city != null && city.trim().isNotEmpty) {
        final filterCity = city.toLowerCase().trim();
        final filtered = events.where((e) {
          final eventCity = (e.city ?? '').toLowerCase().trim();
          return eventCity == filterCity || eventCity.contains(filterCity);
        }).toList();

        debugPrint(
          '📅 Discover This Week for "$city": ${filtered.length}/${events.length}',
        );
        return filtered;
      }

      return events;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException.fromDioException(e);
    }
  }

  Future<HomeCategoriesResponse> getCategoriesAndRecentEvents({
    String? city,
  }) async {
    final normalizedCity = city?.toLowerCase().trim();
    final response = await _apiClient.dio.get(
      '/user/categories',
      queryParameters: normalizedCity != null && normalizedCity.isNotEmpty
          ? {'city': normalizedCity}
          : null,
    );
    final responseData = response.data;
    final List<dynamic> categoryData = responseData['data'];
    final List<CategoryModel> categories = categoryData
        .map((json) => CategoryModel.fromJson(json))
        .toList();
    final List<dynamic> recentEventData = responseData['recentEvent'];
    final List<EventModel> recentEvents = recentEventData
        .map((json) => EventModel.fromJson(json))
        .toList();

    final filteredRecentEvents =
        normalizedCity != null && normalizedCity.isNotEmpty
        ? recentEvents.where((event) {
            final eventCity = (event.city ?? '').toLowerCase().trim();
            return eventCity == normalizedCity ||
                eventCity.contains(normalizedCity);
          }).toList()
        : recentEvents;

    if (normalizedCity != null && normalizedCity.isNotEmpty) {
      debugPrint(
        '🎯 Top banner events for "$normalizedCity": '
        '${filteredRecentEvents.length}/${recentEvents.length}',
      );
    }

    return HomeCategoriesResponse(
      categories: categories,
      recentEvents: filteredRecentEvents,
    );
  }

  Future<List<EventModel>> getNearYouEvents({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/near_you',
        data: {'userLat': latitude.toString(), 'userLng': longitude.toString()},
      );
      final List<dynamic> data = response.data['data'];
      return data.map((json) => EventModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<List<EventModel>> getCategoryWiseEvents({
    required int categoryId,
    required double latitude,
    required double longitude,
    EventFilter filter = EventFilter.popular,
    SortOrder order = SortOrder.desc,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/categories/wise/event',
        data: {
          'category': categoryId.toString(),
          'userLat': latitude.toString(),
          'userLng': longitude.toString(),
          'filter': filter.name,
          'order': order.name,
        },
      );
      final List<dynamic> data = response.data['data'];
      return data.map((json) => EventModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<List<EventModel>> getCategoryWiseEventsByCity({
    required int categoryId,
    required double latitude,
    required double longitude,
    required String? city,
    EventFilter filter = EventFilter.popular,
    SortOrder order = SortOrder.desc,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/categories/wise/event',
        data: {
          'category': categoryId.toString(),
          'userLat': latitude.toString(),
          'userLng': longitude.toString(),
          'filter': filter.name,
          'order': order.name,
        },
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final events = data.map((json) => EventModel.fromJson(json)).toList();

      // Client-side city filter
      if (city != null && city.trim().isNotEmpty) {
        final filterCity = city.toLowerCase().trim();
        final filtered = events.where((e) {
          final eventCity = (e.city ?? '').toLowerCase().trim();
          return eventCity == filterCity || eventCity.contains(filterCity);
        }).toList();

        debugPrint(
          '🏙️ Category $categoryId for "$city": '
          '${filtered.length}/${events.length}',
        );
        return filtered;
      }

      return events;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException.fromDioException(e);
    }
  }

  Future<TicketDetailModel> getTicketDetails({required String slug}) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/ticket/details',
        data: {'slug': slug},
      );

      if (response.data == null || response.data['data'] == null) {
        throw AppException('Ticket details are currently unavailable.');
      }

      return TicketDetailModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('❌ getTicketDetails status: ${e.response?.statusCode}');
      debugPrint('❌ getTicketDetails data: ${e.response?.data}');

      // Catch the raw SQL error from backend and replace with friendly message
      final responseData = e.response?.data;
      if (responseData != null &&
          responseData.toString().contains('SQLSTATE')) {
        throw AppException(
          'Tickets are temporarily unavailable due to a server issue. Please try again later.',
        );
      }

      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      debugPrint('❌ getTicketDetails unexpected: $e');
      throw AppException('Failed to load ticket details. Please try again.');
    }
  }

  Future<List<UserTicketModel>> getTickets({required String tab}) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/tickets/list',
        data: {'tab': tab},
      );
      final List<dynamic> data = response.data['data'];
      return data.map((json) => UserTicketModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<List<TicketHolderDetailModel>> getTicketHolderDetails({
    required int eventId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/holder/list',
        data: {'eventId': eventId.toString()},
      );
      final List<dynamic> data = response.data['data'];
      return data
          .map((json) => TicketHolderDetailModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<double> applyPromoCode({
    required String orderId,
    required String promoCode,
    required double totalPrice,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/checkout/apply-promo-code',
        data: {
          'order_id': orderId,
          'promo_code': promoCode,
          'total_price': totalPrice.toString(),
        },
      );
      if (response.data['success'] == true) {
        final discount =
            double.tryParse(response.data['discounted']?.toString() ?? '0') ??
            0.0;
        return discount;
      } else {
        throw Exception(response.data['message'] ?? 'Invalid promo code.');
      }
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<PaymentIntentModel> createPaymentIntent({
    required double amount,
    required String orderId,
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/mpesa/stk-push',
        data: {
          'order_id': orderId,
          'amount': amount.round(),
          'phone': int.tryParse(phoneNumber) ?? phoneNumber,
        },
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format from M-Pesa API.');
      }

      final Map<String, dynamic> body = response.data as Map<String, dynamic>;
      // Assuming backend returns success: true and maybe some M-Pesa fields
      final success = body['success'] == true || body['CheckoutRequestID'] != null;

      if (success) {
        return PaymentIntentModel.fromJson(body);
      } else {
        throw Exception(body['message'] ?? 'Failed to initiate M-Pesa payment.');
      }
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<String> checkMpesaPaymentStatus(String checkoutRequestId) async {
    try {
      final response = await _apiClient.dio.get('/user/mpesa/status/$checkoutRequestId');
      
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final status = (data['status']?.toString() ?? '').toLowerCase();
        
        if (status == 'success' || status == 'completed' || data['success'] == true) {
          return 'success';
        } else if (status == 'failed' || status == 'cancelled' || status == 'error') {
          return 'failed';
        }
        // Otherwise assume it's still pending
        return 'pending';
      }
      return 'pending';
    } on DioException catch (e) {
      // If the webhook hasn't processed, it might return 404 or similar, treat as pending
      if (e.response?.statusCode == 404) return 'pending';
      throw AppException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> createPaystackPaymentIntent({
    required double amount,
    required String orderId,
    required int eventId,
    required String streetAddress,
    required String email,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/payment/intent',
        data: {
          'amount': amount.toString(),
          'event_id': eventId.toString(),
          'street_address': streetAddress,
          'order_id': orderId,
          'email': email,
          'callback_url': 'gormahiafc://payment-callback',
        },
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format from Paystack API.');
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<String> checkPaystackPaymentStatus(String reference) async {
    try {
      final response = await _apiClient.dio.get('/user/payment/paystack/status/$reference');
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true && data['payment'] != 'failed') {
          return 'success';
        }
        if (data['payment'] == 'failed') {
          return 'failed';
        }
      }
      return 'pending';
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return 'pending';
      throw AppException.fromDioException(e);
    }
  }

  Future<void> checkoutSubmit({
    required String orderId,
    required String phoneNumber,
    required String streetAddress,
    required int eventId,
    String? paymentIntentId,
    String? checkoutRequestId,
    String? reference,
    String? promoCode,
    required Map<String, TicketHolderInfoModel> ticketHolders,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'phone_number': phoneNumber,
        'street_address': streetAddress,
        'event_id': eventId.toString(),
        if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
      };
      if (paymentIntentId != null && paymentIntentId.isNotEmpty) {
        data['paymentIntentId'] = paymentIntentId;
      }
      if (checkoutRequestId != null && checkoutRequestId.isNotEmpty) {
        data['checkoutRequestId'] = checkoutRequestId;
        data['CheckoutRequestID'] = checkoutRequestId; // send both just in case
      }
      if (reference != null && reference.isNotEmpty) {
        data['reference'] = reference;
      }
      
      if (!data.containsKey('paymentIntentId') &&
          !data.containsKey('checkoutRequestId') &&
          !data.containsKey('reference')) {
        throw Exception('No payment confirmation details were provided.');
      }

      ticketHolders.forEach((key, info) {
        data['name$key'] = info.firstName;
        data['lname$key'] = info.lastName;
        data['email$key'] = info.email;
        data['address$key'] = info.address;
      });

      final response = await _apiClient.dio.post(
        '/user/checkout/$orderId/complete',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to complete checkout.',
        );
      }
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> preRegistrationSubmit({
    required String eventSlug,
    required String name,
    required String email,
    required String phoneNumber,
    int? userId,
    String? socialType,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'event_slug': eventSlug,
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        if (userId != null) 'user_id': userId,
        if (socialType != null) 'social_type': socialType,
      };

      final response = await _apiClient.dio.post(
        '/user/pre-registration',
        data: data,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to pre-register.');
      }
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }
}

class HomeCategoriesResponse {
  final List<CategoryModel> categories;
  final List<EventModel> recentEvents;

  HomeCategoriesResponse({
    required this.categories,
    required this.recentEvents,
  });
}
