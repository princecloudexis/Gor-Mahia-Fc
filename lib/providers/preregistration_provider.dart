import 'package:gormahiafc/repositories/event_repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PreRegistrationStatus { initial, loading, success, error }

class PreRegistrationState {
  final PreRegistrationStatus status;
  final String? errorMessage;
  const PreRegistrationState({
    this.status = PreRegistrationStatus.initial,
    this.errorMessage,
  });

  PreRegistrationState copyWith({
    PreRegistrationStatus? status,
    String? errorMessage,
  }) {
    return PreRegistrationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PreRegistrationController extends StateNotifier<PreRegistrationState> {
  final EventRepository _eventRepository;
  final Ref _ref;

  PreRegistrationController(this._eventRepository, this._ref)
    : super(const PreRegistrationState());

  Future<void> submitPreRegistration({
    required String eventSlug,
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    state = state.copyWith(status: PreRegistrationStatus.loading);
    try {
      await _eventRepository.preRegistrationSubmit(
        eventSlug: eventSlug,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(status: PreRegistrationStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: PreRegistrationStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void resetState() {
    state = const PreRegistrationState();
  }
}

final preRegistrationControllerProvider =
    StateNotifierProvider.autoDispose<
      PreRegistrationController,
      PreRegistrationState
    >((ref) {
      return PreRegistrationController(ref.watch(eventRepositoryProvider), ref);
    });