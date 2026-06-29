class MapBookingResponse {
  final int status;
  final bool success;
  final String message;
  final String orderId;
  final double totalPrice;

  MapBookingResponse({
    required this.status,
    required this.success,
    required this.message,
    required this.orderId,
    required this.totalPrice,
  });

  factory MapBookingResponse.fromJson(Map<String, dynamic> json) {
    final String orderId = json['order_id']?.toString() ?? '';
    final String message = json['message']?.toString() ?? '';

    bool isSuccess;
    if (json.containsKey('success')) {
      isSuccess = json['success'] == true;
    } else {
      isSuccess = orderId.isNotEmpty;
    }

    return MapBookingResponse(
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? '200') ?? 200,
      success: isSuccess,
      message: message,
      orderId: orderId,
      totalPrice: (json['total_price'] is num)
          ? (json['total_price'] as num).toDouble()
          : double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
    );
  }
}