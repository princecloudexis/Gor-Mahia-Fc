enum PaymentGatewayType { mpesa, stripe, razorpay }

class PaymentIntentModel {
  final PaymentGatewayType type;
  
  // M-Pesa fields
  final String? checkoutRequestId;
  final String? merchantRequestId;
  final String? customerMessage;
  
  // Legacy / Other possible fields if API still returns them for some reason
  final String? paymentIntentId;
  final String? clientSecret;
  final String? orderId;

  const PaymentIntentModel({
    required this.type,
    this.checkoutRequestId,
    this.merchantRequestId,
    this.customerMessage,
    this.paymentIntentId,
    this.clientSecret,
    this.orderId,
  });

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) {
    final typeString = (json['type']?.toString() ?? '').toLowerCase().trim();
    
    // Default to mpesa if it matches or if it's implicitly M-Pesa based on keys
    PaymentGatewayType gatewayType = PaymentGatewayType.mpesa;
    
    if (typeString == 'stripe') {
      gatewayType = PaymentGatewayType.stripe;
    } else if (typeString == 'razorpay') {
      gatewayType = PaymentGatewayType.razorpay;
    }

    return PaymentIntentModel(
      type: gatewayType,
      checkoutRequestId: json['CheckoutRequestID']?.toString() ?? json['checkoutRequestId']?.toString(),
      merchantRequestId: json['MerchantRequestID']?.toString() ?? json['merchantRequestId']?.toString(),
      customerMessage: json['CustomerMessage']?.toString() ?? json['customerMessage']?.toString(),
      paymentIntentId: json['paymentIntentId']?.toString(),
      clientSecret: json['client_secret']?.toString(),
      orderId: json['order_id']?.toString(),
    );
  }
}
