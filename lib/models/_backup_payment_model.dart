enum PaymentGatewayType { stripe, razorpay }

class PaymentIntentModel {
  final PaymentGatewayType type;

  // Stripe fields
  final String? paymentIntentId;
  final String? clientSecret;

  // Razorpay fields
  final String? orderId;
  final int? amount;
  final String? key;

  const PaymentIntentModel({
    required this.type,
    this.paymentIntentId,
    this.clientSecret,
    this.orderId,
    this.amount,
    this.key,
  });

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) {
    final typeString = (json['type']?.toString() ?? '').toLowerCase().trim();
    final isRazorpay =
        typeString == 'razorpay' ||
        json['order_id'] != null ||
        json['razorpay_order_id'] != null;

    if (isRazorpay) {
      return PaymentIntentModel(
        type: PaymentGatewayType.razorpay,
        orderId:
            json['order_id']?.toString() ??
            json['razorpay_order_id']?.toString(),
        amount: int.tryParse(json['amount']?.toString() ?? ''),
        key: json['key']?.toString(),
      );
    }

    return PaymentIntentModel(
      type: PaymentGatewayType.stripe,
      paymentIntentId: json['paymentIntentId']?.toString(),
      clientSecret: json['client_secret']?.toString(),
    );
  }
}
