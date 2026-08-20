import 'dart:async';

import 'package:kogalo_network/models/checkout_model.dart';
import 'package:kogalo_network/models/holder_info_model.dart';
import 'package:kogalo_network/models/payment_model.dart';
import 'package:kogalo_network/models/payment_result_model.dart';
import 'package:kogalo_network/repositories/event_repositories.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PromoStatus { initial, loading, applied, error }

const _fallbackStripePublishableKey = String.fromEnvironment(
  'STRIPE_PUBLISHABLE_KEY',
  defaultValue: '',
);

class CheckoutState {
  final AsyncValue<CheckoutDetailsModel> checkoutDetails;
  final PromoStatus promoStatus;
  final String? appliedPromoCode;
  final double promoDiscount;
  final String? promoErrorMessage;
  final bool isProcessingPayment;
  final Map<String, TicketHolderInfoModel> ticketHolderInfo;
  final bool paymentSuccessful;
  final String? paymentIntentClientSecret;

  const CheckoutState({
    this.checkoutDetails = const AsyncLoading(),
    this.promoStatus = PromoStatus.initial,
    this.appliedPromoCode,
    this.promoDiscount = 0.0,
    this.promoErrorMessage,
    this.isProcessingPayment = false,
    this.ticketHolderInfo = const {},
    this.paymentSuccessful = false,
    this.paymentIntentClientSecret,
  });

  CheckoutState copyWith({
    AsyncValue<CheckoutDetailsModel>? checkoutDetails,
    PromoStatus? promoStatus,
    String? appliedPromoCode,
    double? promoDiscount,
    String? promoErrorMessage,
    bool? isProcessingPayment,
    Map<String, TicketHolderInfoModel>? ticketHolderInfo,
    bool? paymentSuccessful,
    String? paymentIntentClientSecret,
    bool clearPromo = false,
  }) {
    return CheckoutState(
      checkoutDetails: checkoutDetails ?? this.checkoutDetails,
      promoStatus: promoStatus ?? this.promoStatus,
      appliedPromoCode: clearPromo
          ? null
          : appliedPromoCode ?? this.appliedPromoCode,
      promoDiscount: clearPromo ? 0.0 : promoDiscount ?? this.promoDiscount,
      promoErrorMessage: clearPromo ? null : promoErrorMessage,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      ticketHolderInfo: ticketHolderInfo ?? this.ticketHolderInfo,
      paymentSuccessful: paymentSuccessful ?? this.paymentSuccessful,
      paymentIntentClientSecret:
          paymentIntentClientSecret ?? this.paymentIntentClientSecret,
    );
  }
}

class CheckoutController extends StateNotifier<CheckoutState> {
  final EventRepository _repository;
  final String _orderId;

  CheckoutController(this._repository, this._orderId)
    : super(const CheckoutState()) {
    _loadInitialDetails();
  }

  Future<void> _loadInitialDetails() async {
    state = state.copyWith(checkoutDetails: const AsyncLoading());
    try {
      final details = await _repository.getCheckoutDetails(_orderId);
      state = state.copyWith(checkoutDetails: AsyncData(details));
    } catch (e, st) {
      state = state.copyWith(checkoutDetails: AsyncError(e, st));
    }
  }

  Future<void> applyPromoCode(String code) async {
    if (code.isEmpty) return;

    final details = state.checkoutDetails.valueOrNull;
    if (details == null) {
      state = state.copyWith(
        promoStatus: PromoStatus.error,
        promoErrorMessage: "Details not loaded. Please wait.",
      );
      return;
    }
    state = state.copyWith(
      promoStatus: PromoStatus.loading,
      promoErrorMessage: null,
    );
    final double priceToSendToApi = details.totalBeforeDiscount();

    try {
      final discount = await _repository.applyPromoCode(
        orderId: _orderId,
        promoCode: code,
        totalPrice: priceToSendToApi,
      );

      state = state.copyWith(
        promoStatus: PromoStatus.applied,
        promoDiscount: discount,
        appliedPromoCode: code,
      );
    } catch (e) {
      state = state.copyWith(
        promoStatus: PromoStatus.error,
        promoErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void removePromoCode() {
    state = state.copyWith(promoStatus: PromoStatus.initial, clearPromo: true);
  }

  void clearPromoError() {
    state = state.copyWith(
      promoStatus: PromoStatus.initial,
      promoErrorMessage: null,
    );
  }

  void updateTicketHolderInfo({
    required String key,
    String? firstName,
    String? lastName,
    String? email,
    String? address,
  }) {
    final currentInfo = Map<String, TicketHolderInfoModel>.from(
      state.ticketHolderInfo,
    );
    final holder = currentInfo[key] ?? TicketHolderInfoModel();

    holder.firstName = firstName ?? holder.firstName;
    holder.lastName = lastName ?? holder.lastName;
    holder.email = email ?? holder.email;
    holder.address = address ?? holder.address;

    currentInfo[key] = holder;
    state = state.copyWith(ticketHolderInfo: currentInfo);
  }

  Future<PaymentResult> initiatePaystackPayment({
    required String streetAddress,
    required String email,
  }) async {
    final details = state.checkoutDetails.valueOrNull;
    final eventSlug = details?.event.slug;

    if (details == null || state.isProcessingPayment || eventSlug == null) {
      return PaymentResult(
        isSuccess: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
        eventSlug: eventSlug ?? '',
      );
    }

    state = state.copyWith(isProcessingPayment: true);
    try {
      final grandTotal = _calculateGrandTotal();

      final paystackData = await _repository.createPaystackPaymentIntent(
        amount: grandTotal,
        orderId: _orderId,
        eventId: details.event.id,
        streetAddress: streetAddress,
        email: email,
      );
      
      final authUrl = paystackData['authorization_url']?.toString();
      final reference = paystackData['reference']?.toString();
      
      if (authUrl == null || reference == null) {
          throw Exception("Paystack authorization failed.");
      }
      
      state = state.copyWith(isProcessingPayment: false);
      return PaymentResult(
          isSuccess: true, 
          authorizationUrl: authUrl, 
          reference: reference, 
          eventSlug: eventSlug
      );
    } catch (e) {
      state = state.copyWith(isProcessingPayment: false);
      return PaymentResult(
        isSuccess: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        eventSlug: eventSlug,
      );
    }
  }

  Future<PaymentResult> verifyAndCompletePayment({
    required String reference,
    required String streetAddress,
    required String phoneNumber,
  }) async {
    final details = state.checkoutDetails.valueOrNull;
    final eventSlug = details?.event.slug;

    state = state.copyWith(isProcessingPayment: true);
    try {
      final status = await _repository.checkPaystackPaymentStatus(reference);
      
      if (status == 'success') {
          // Confirm checkout
          await _repository.checkoutSubmit(
            orderId: _orderId,
            phoneNumber: phoneNumber,
            streetAddress: streetAddress,
            eventId: details!.event.id,
            reference: reference,
            promoCode: state.appliedPromoCode,
            ticketHolders: state.ticketHolderInfo,
          );

          state = state.copyWith(
            paymentSuccessful: true,
            isProcessingPayment: false,
          );
          return PaymentResult(isSuccess: true, eventSlug: eventSlug);
      } else {
          throw Exception("Payment failed or was cancelled by the user.");
      }
    } catch (e) {
      state = state.copyWith(isProcessingPayment: false);
      return PaymentResult(
        isSuccess: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        eventSlug: eventSlug,
      );
    }
  }

  double _calculateGrandTotal() {
    final details = state.checkoutDetails.value!;
    return details.grandTotal(promoDiscount: state.promoDiscount);
  }
}

final checkoutControllerProvider = StateNotifierProvider.autoDispose
    .family<CheckoutController, CheckoutState, String>((ref, orderId) {
      return CheckoutController(ref.watch(eventRepositoryProvider), orderId);
    });
