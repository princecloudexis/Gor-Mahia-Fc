import 'dart:async';

import 'package:eventsbooking/models/checkout_model.dart';
import 'package:eventsbooking/models/holder_info_model.dart';
import 'package:eventsbooking/models/payment_model.dart';
import 'package:eventsbooking/models/payment_result_model.dart';
import 'package:eventsbooking/repositories/event_repositories.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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
  final Razorpay _razorpay = Razorpay();
  Completer<_RazorpayResult>? _razorpayCompleter;

  CheckoutController(this._repository, this._orderId)
    : super(const CheckoutState()) {
    _setupRazorpayCallbacks();
    _loadInitialDetails();
  }

  void _setupRazorpayCallbacks() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpayPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onRazorpayExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> proceedToPayment({required String streetAddress}) async {
    final details = state.checkoutDetails.valueOrNull;
    if (details == null || state.isProcessingPayment) {
      return;
    }
    state = state.copyWith(isProcessingPayment: true);

    try {
      double subtotal = details.tickets.fold(0, (sum, t) => sum + t.totalPrice);
      double totalTaxesAndFees = details.taxesAndFees.fold(0, (sum, fee) {
        final feeAmount = fee.chargeType == '0'
            ? (subtotal * fee.charges) / 100
            : fee.charges;
        return sum + feeAmount;
      });
      double grandTotal = subtotal + totalTaxesAndFees - state.promoDiscount;

      final paymentIntent = await _repository.createPaymentIntent(
        amount: grandTotal,
        eventId: details.event.id,
        streetAddress: streetAddress,
      );
      print('Successfully created Payment Intent!');
      print('Client Secret: ${paymentIntent.clientSecret}');
    } catch (e) {
      print('Error during payment processing: $e');
    } finally {
      state = state.copyWith(isProcessingPayment: false);
    }
  }

  Future<void> _loadInitialDetails() async {
    state = state.copyWith(checkoutDetails: const AsyncLoading());
    try {
      final details = await _repository.getCheckoutDetails(_orderId);
      state = state.copyWith(checkoutDetails: AsyncData(details));
      // _createAndCachePaymentIntent();
    } catch (e, st) {
      state = state.copyWith(checkoutDetails: AsyncError(e, st));
    }
  }

  // Future<void> _createAndCachePaymentIntent() async {
  //   final details = state.checkoutDetails.valueOrNull;
  //   if (details == null) return;
  //   state = state.copyWith(paymentIntentClientSecret: null);

  //   try {
  //     final grandTotal = _calculateGrandTotal();
  //     final paymentIntent = await _repository.createPaymentIntent(
  //       amount: grandTotal,
  //       eventId: details.event.id,
  //       streetAddress: 'Placeholder',
  //     );
  //     state = state.copyWith(
  //       paymentIntentClientSecret: paymentIntent.clientSecret,
  //     );
  //   } catch (e) {
  //     print("Error creating payment intent: $e");
  //   }
  // }

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
      // _createAndCachePaymentIntent();
    } catch (e) {
      state = state.copyWith(
        promoStatus: PromoStatus.error,
        promoErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void removePromoCode() {
    state = state.copyWith(promoStatus: PromoStatus.initial, clearPromo: true);
    // _createAndCachePaymentIntent();
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

  Future<PaymentResult> processPaymentAndSubmit({
    required String streetAddress,
    required String phoneNumber,
  }) async {
    // print("🅿️ [Controller] processPaymentAndSubmit called.");
    final details = state.checkoutDetails.valueOrNull;
    final eventSlug = details?.event.slug;

    if (details == null || state.isProcessingPayment || eventSlug == null) {
      // print("❌ [Controller] Pre-flight check FAILED. Returning failure immediately.");
      // print("   - Reason: details == null: ${details == null}");
      // print("   - Reason: state.isProcessingPayment: ${state.isProcessingPayment}");
      // print("   - Reason: eventSlug == null: ${eventSlug == null}");
      return PaymentResult(
        isSuccess: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
        eventSlug: eventSlug ?? '',
      );
    }

    state = state.copyWith(isProcessingPayment: true);
    try {
      // print('[1/5] Calculating grand total...');
      final grandTotal = _calculateGrandTotal();
      // print('   - Total: $grandTotal');

      // print('[2/5] Creating Payment Intent on server...');
      final paymentIntent = await _repository.createPaymentIntent(
        amount: grandTotal,
        eventId: details.event.id,
        streetAddress: streetAddress,
      );
      final expectedGateway = details.paymentGatewayType;
      if (paymentIntent.type != expectedGateway) {
        throw Exception(
          'Payment gateway mismatch. Checkout expected '
          '${expectedGateway.name}, but intent returned ${paymentIntent.type.name}.',
        );
      }
      if (paymentIntent.type == PaymentGatewayType.stripe) {
        await _configureStripePublishableKey(details);

        final clientSecret = paymentIntent.clientSecret;
        if (clientSecret == null || clientSecret.isEmpty) {
          throw Exception('Stripe client secret is missing.');
        }

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            merchantDisplayName: details.event.brandName ?? 'Gor Mahia FC',
            paymentIntentClientSecret: clientSecret,
            googlePay: PaymentSheetGooglePay(
              merchantCountryCode: 'IN',
              testEnv: !kReleaseMode,
            ),
            returnURL: 'eventsbooking://stripe-redirect',
          ),
        );

        await Stripe.instance.presentPaymentSheet();

        final paymentIntentId =
            paymentIntent.paymentIntentId?.trim().isNotEmpty == true
            ? paymentIntent.paymentIntentId!.trim()
            : clientSecret.split('_secret_').first;

        await _repository.checkoutSubmit(
          orderId: _orderId,
          phoneNumber: phoneNumber,
          streetAddress: streetAddress,
          eventId: details.event.id,
          paymentIntentId: paymentIntentId,
          promoCode: state.appliedPromoCode,
          ticketHolders: state.ticketHolderInfo,
        );
      } else {
        final razorpayOrderId = paymentIntent.orderId?.trim() ?? '';
        final razorpayKey = paymentIntent.key?.trim() ?? '';
        final razorpayAmount = paymentIntent.amount ?? 0;
        if (razorpayOrderId.isEmpty ||
            razorpayKey.isEmpty ||
            razorpayAmount <= 0) {
          throw Exception('Razorpay details are missing from payment intent.');
        }

        final razorpayResult = await _startRazorpayPayment(
          key: razorpayKey,
          amount: razorpayAmount,
          orderId: razorpayOrderId,
          eventName: details.event.eventName,
          contact: phoneNumber,
        );

        if (!razorpayResult.isSuccess) {
          return PaymentResult(
            isSuccess: false,
            errorMessage: razorpayResult.errorMessage,
            eventSlug: eventSlug,
          );
        }

        await _repository.checkoutSubmit(
          orderId: _orderId,
          phoneNumber: phoneNumber,
          streetAddress: streetAddress,
          eventId: details.event.id,
          razorpayPaymentId: razorpayResult.paymentId,
          razorpayOrderId: razorpayResult.orderId,
          razorpaySignature: razorpayResult.signature,
          promoCode: state.appliedPromoCode,
          ticketHolders: state.ticketHolderInfo,
        );
      }
      // print('   - Order submitted successfully.');

      state = state.copyWith(
        paymentSuccessful: true,
        isProcessingPayment: false,
      );
      return PaymentResult(isSuccess: true);
    } on StripeException catch (e) {
      // print('❌ STRIPE EXCEPTION CAUGHT!');
      // print('   - Error Code: ${e.error.code}');
      // print('   - Message: ${e.error.localizedMessage}');

      state = state.copyWith(isProcessingPayment: false);

      if (e.error.code == FailureCode.Canceled) {
        // print('   - Reason: User canceled the payment flow.');
        return PaymentResult(isSuccess: false);
      } else {
        // print('   - Reason: A payment error occurred.');
        return PaymentResult(
          isSuccess: false,
          errorMessage: e.error.localizedMessage ?? 'A payment error occurred.',
          eventSlug: eventSlug,
        );
      }
    } catch (e) {
      // print('❌ UNEXPECTED GENERIC ERROR CAUGHT!');
      // print('   - Error Type: ${e.runtimeType}');
      // print('   - Error: $e');

      state = state.copyWith(isProcessingPayment: false);
      return PaymentResult(
        isSuccess: false,
        errorMessage:
            'An unexpected error occurred on our end. Please try again.',
        eventSlug: eventSlug,
      );
    }
  }

  double _calculateGrandTotal() {
    final details = state.checkoutDetails.value!;
    return details.grandTotal(promoDiscount: state.promoDiscount);
  }

  Future<void> _configureStripePublishableKey(
    CheckoutDetailsModel details,
  ) async {
    final backendKey = details.admin?.stripeKey?.trim();
    final preferredKey = (backendKey != null && backendKey.isNotEmpty)
        ? backendKey
        : _fallbackStripePublishableKey.trim();
    final effectiveKey = preferredKey.isNotEmpty
        ? preferredKey
        : Stripe.publishableKey.trim();

    if (effectiveKey.isEmpty) {
      throw Exception(
        'Stripe publishable key is missing. '
        'Send `admin.stripe_key` from backend or pass --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxx.',
      );
    }

    if (Stripe.publishableKey != effectiveKey) {
      Stripe.publishableKey = effectiveKey;
      await Stripe.instance.applySettings();
    }
  }

  Future<_RazorpayResult> _startRazorpayPayment({
    required String key,
    required int amount,
    required String orderId,
    required String eventName,
    required String contact,
  }) async {
    _razorpayCompleter = Completer<_RazorpayResult>();
    try {
      _razorpay.open({
        'key': key,
        'amount': amount,
        'order_id': orderId,
        'name': 'Gor Mahia FC',
        'description': eventName,
        'prefill': {'contact': contact},
        'send_sms_hash': true,
      });
      return await _razorpayCompleter!.future;
    } catch (_) {
      return const _RazorpayResult(
        isSuccess: false,
        errorMessage: 'Could not launch Razorpay checkout.',
      );
    }
  }

  void _onRazorpayPaymentSuccess(PaymentSuccessResponse response) {
    if (_razorpayCompleter == null || _razorpayCompleter!.isCompleted) return;
    _razorpayCompleter!.complete(
      _RazorpayResult(
        isSuccess: true,
        paymentId: response.paymentId,
        orderId: response.orderId,
        signature: response.signature,
      ),
    );
  }

  void _onRazorpayPaymentError(PaymentFailureResponse response) {
    if (_razorpayCompleter == null || _razorpayCompleter!.isCompleted) return;
    final rawMessage = response.message?.trim();
    final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    _razorpayCompleter!.complete(
      _RazorpayResult(
        isSuccess: false,
        errorMessage: isCancelled
            ? null
            : (rawMessage?.isNotEmpty == true
                  ? rawMessage
                  : 'Razorpay payment failed.'),
      ),
    );
  }

  void _onRazorpayExternalWallet(ExternalWalletResponse response) {
    if (_razorpayCompleter == null || _razorpayCompleter!.isCompleted) return;
    _razorpayCompleter!.complete(
      const _RazorpayResult(
        isSuccess: false,
        errorMessage:
            'External wallet selected. Please complete payment in Razorpay.',
      ),
    );
  }
}

class _RazorpayResult {
  final bool isSuccess;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorMessage;

  const _RazorpayResult({
    required this.isSuccess,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorMessage,
  });
}

final checkoutControllerProvider = StateNotifierProvider.autoDispose
    .family<CheckoutController, CheckoutState, String>((ref, orderId) {
      return CheckoutController(ref.watch(eventRepositoryProvider), orderId);
    });
