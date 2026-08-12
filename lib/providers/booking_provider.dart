import 'package:gormahiafc/repositories/event_repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BookingStatus { initial, loading, success, error }

class BookingState {
  final BookingStatus status;
  final String? orderId;
  final String? errorMessage;
  final double? totalPrice;

  const BookingState({
    this.status = BookingStatus.initial,
    this.orderId,
    this.errorMessage,
    this.totalPrice,
  });

  BookingState copyWith({
    BookingStatus? status,
    String? orderId,
    String? errorMessage,
    double? totalPrice,
  }) {
    return BookingState(
      status: status ?? this.status,
      orderId: orderId,
      errorMessage: errorMessage,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

class BookingController extends StateNotifier<BookingState> {
  final EventRepository _eventRepository;

  BookingController(this._eventRepository) : super(const BookingState());

  Future<void> submitBooking({
    required Map<int, int> ticketQuantities,
    DateTime? selectedDate,
  }) async {
    state = state.copyWith(status: BookingStatus.loading);
    try {
      final orderId = await _eventRepository.bookTickets(
        ticketQuantities: ticketQuantities,
        selectedDate: selectedDate ?? DateTime.now(),
      );
      state = state.copyWith(status: BookingStatus.success, orderId: orderId);
    } catch (e) {
      state = state.copyWith(
        status: BookingStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void resetState() {
    state = const BookingState();
  }
}

final bookingControllerProvider =
    StateNotifierProvider.autoDispose<BookingController, BookingState>((ref) {
      return BookingController(ref.watch(eventRepositoryProvider));
    });
