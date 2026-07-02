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
  final String status;
  final String membershipId;
  final String mpesaReceipt;

  PaymentStatusResponse({
    required this.status,
    required this.membershipId,
    required this.mpesaReceipt,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return PaymentStatusResponse(
      status: json['status']?.toString() ?? 'pending',
      membershipId: (data is Map && data['membership_id'] != null) ? data['membership_id'].toString() : '',
      mpesaReceipt: (data is Map && data['mpesa_receipt'] != null) ? data['mpesa_receipt'].toString() : '',
    );
  }
}
