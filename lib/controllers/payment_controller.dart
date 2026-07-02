import 'dart:async';
import 'package:eventsbooking/models/membership_models.dart';
import 'package:eventsbooking/repositories/membership_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PaymentStatus { initial, initiating, waitingForMpesa, success, error }

class PaymentState {
  final PaymentStatus status;
  final String? errorMessage;
  final PaymentStatusResponse? response;

  PaymentState({
    this.status = PaymentStatus.initial,
    this.errorMessage,
    this.response,
  });

  PaymentState copyWith({
    PaymentStatus? status,
    String? errorMessage = '',
    PaymentStatusResponse? response,
  }) {
    return PaymentState(
      status: status ?? this.status,
      errorMessage: errorMessage == '' ? this.errorMessage : errorMessage,
      response: response ?? this.response,
    );
  }
}

class PaymentController extends StateNotifier<PaymentState> {
  final MembershipRepository _repository;
  Timer? _pollingTimer;
  int _pollCount = 0;
  final int _maxPolls = 24; // 2 minutes with 5 second interval

  PaymentController(this._repository) : super(PaymentState());

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> initiatePayment({
    required String phone,
    required String membershipId,
    required String amount,
    required String packageName,
  }) async {
    state = state.copyWith(
      status: PaymentStatus.initiating,
      errorMessage: null,
    );
    try {
      final response = await _repository.initiatePayment(
        phone: phone,
        membershipId: membershipId,
        amount: amount,
        packageName: packageName,
      );

      state = state.copyWith(status: PaymentStatus.waitingForMpesa);
      _startPolling(response.checkoutRequestId, membershipId);
    } catch (e) {
      state = state.copyWith(
        status: PaymentStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _startPolling(String checkoutRequestId, String membershipId) {
    _pollCount = 0;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _pollCount++;
      if (_pollCount >= _maxPolls) {
        timer.cancel();
        state = state.copyWith(
          status: PaymentStatus.error,
          errorMessage:
              'Payment timed out. Please try again or check your M-Pesa messages.',
        );
        return;
      }

      try {
        final statusResponse = await _repository.checkPaymentStatus(
          checkoutRequestId: checkoutRequestId,
          membershipId: membershipId,
          plan: 'paid',
        );

        if (statusResponse.status == 'success') {
          timer.cancel();
          state = state.copyWith(
            status: PaymentStatus.success,
            response: statusResponse,
          );
        } else if (statusResponse.status == 'failed' ||
            statusResponse.status == 'cancelled') {
          timer.cancel();
          state = state.copyWith(
            status: PaymentStatus.error,
            errorMessage:
                'Payment was not completed successfully. Status: ${statusResponse.status}',
          );
        }
      } catch (e) {
        // Ignore errors during polling, as the payment might just be pending and returning success: false
        // The timeout will catch true permanent failures if the backend doesn't resolve it.
      }
    });
  }

  void resetStatus() {
    _pollingTimer?.cancel();
    state = state.copyWith(status: PaymentStatus.initial, errorMessage: null);
  }
}

final paymentControllerProvider =
    StateNotifierProvider.autoDispose<PaymentController, PaymentState>((ref) {
      return PaymentController(ref.watch(membershipRepositoryProvider));
    });
