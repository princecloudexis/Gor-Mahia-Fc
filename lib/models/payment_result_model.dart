class PaymentResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? eventSlug;
  final String? authorizationUrl;
  final String? reference;

  PaymentResult({
    required this.isSuccess,
    this.errorMessage,
    this.eventSlug,
    this.authorizationUrl,
    this.reference,
  });
}