class PaymentResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? eventSlug;

  PaymentResult({
    required this.isSuccess,
    this.errorMessage,
    this.eventSlug,
  });
}