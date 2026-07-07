class MembershipBranch {
  final int id;
  final String name;

  MembershipBranch({required this.id, required this.name});

  factory MembershipBranch.fromJson(Map<String, dynamic> json) {
    return MembershipBranch(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name'] ?? '',
    );
  }
}

class MembershipPackage {
  final int id;
  final String name;
  final String price;
  final String type;

  MembershipPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
  });

  factory MembershipPackage.fromJson(Map<String, dynamic> json) {
    return MembershipPackage(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0',
      type: json['type'] ?? '',
    );
  }
}

class MembershipData {
  final List<MembershipBranch> branches;
  final List<MembershipPackage> packages;

  MembershipData({required this.branches, required this.packages});

  factory MembershipData.fromJson(Map<String, dynamic> json) {
    var branchesJson = json['branches'] as List? ?? [];
    var packagesJson = json['packages'] as List? ?? [];

    return MembershipData(
      branches: branchesJson.map((e) => MembershipBranch.fromJson(e)).toList(),
      packages: packagesJson.map((e) => MembershipPackage.fromJson(e)).toList(),
    );
  }
}

class MembershipSubmitResponse {
  final int membershipId;
  final String amount;
  final String packageName;

  MembershipSubmitResponse({
    required this.membershipId,
    required this.amount,
    required this.packageName,
  });

  factory MembershipSubmitResponse.fromJson(Map<String, dynamic> json) {
    return MembershipSubmitResponse(
      membershipId: json['membership_id'] ?? 0,
      amount: json['amount']?.toString() ?? '0',
      packageName: json['package_name'] ?? '',
    );
  }
}

class PaymentInitiateResponse {
  final String checkoutRequestId;
  final String membershipId;

  PaymentInitiateResponse({
    required this.checkoutRequestId,
    required this.membershipId,
  });

  factory PaymentInitiateResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return PaymentInitiateResponse(
      checkoutRequestId: (data is Map && data['checkout_request_id'] != null) ? data['checkout_request_id'].toString() : '',
      membershipId: (data is Map && data['membership_id'] != null) ? data['membership_id'].toString() : '',
    );
  }
}

class PaymentStatusResponse {
  final String status;      // 'pending', 'success', or 'failed'
  final String membershipId;
  final String mpesaReceipt;
  final String message;     // Real error/success message from M-Pesa

  PaymentStatusResponse({
    required this.status,
    required this.membershipId,
    required this.mpesaReceipt,
    this.message = '',
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final apiMessage = json['message']?.toString() ?? '';

    // === EXACT API CONTRACT FOR MEMBERSHIP /user/status ===
    //
    // PENDING:  { "success": true,  "status": "pending", "message": "Waiting..." }
    //             → status is a STRING "pending"
    //
    // FAILED:   { "status": 200, "success": true, "message": "insufficient funds" }
    //             → status is an INTEGER 200, NO data field
    //
    // SUCCESS:  { "status": 200, "success": true, "message": "Payment confirmed.",
    //             "data": { "membership_id": 55, "mpesa_receipt": "SGH123ABCD" } }
    //             → status is an INTEGER 200, WITH data.mpesa_receipt

    String parsedStatus = 'pending';

    final statusValue = json['status'];

    if (statusValue is String) {
      // Pending case: "status": "pending"
      parsedStatus = statusValue.toLowerCase();
    } else if (statusValue is int) {
      // Success or Failed: "status": 200
      // We can distinguish because the backend ONLY returns the "data" object on success!
      final hasData = data is Map;
      parsedStatus = hasData ? 'success' : 'failed';
    }

    // Normalize any other aliases just in case
    if (parsedStatus == 'completed' || parsedStatus == 'paid') {
      parsedStatus = 'success';
    } else if (parsedStatus == 'cancelled' || parsedStatus == 'canceled') {
      parsedStatus = 'failed';
    }

    return PaymentStatusResponse(
      status: parsedStatus,
      message: apiMessage,
      membershipId: (data is Map && data['membership_id'] != null)
          ? data['membership_id'].toString()
          : '',
      mpesaReceipt: (data is Map && data['mpesa_receipt'] != null)
          ? data['mpesa_receipt'].toString()
          : '',
    );
  }
}
