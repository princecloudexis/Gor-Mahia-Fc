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
  final bool requiresPayment;

  MembershipSubmitResponse({
    required this.membershipId,
    required this.amount,
    required this.packageName,
    this.requiresPayment = true,
  });

  factory MembershipSubmitResponse.fromJson(Map<String, dynamic> json) {
    return MembershipSubmitResponse(
      membershipId: json['membership_id'] ?? 0,
      amount: json['amount']?.toString() ?? '0',
      packageName: json['package_name'] ?? '',
      requiresPayment: json['requires_payment'] ?? true,
    );
  }
}

class MembershipPaystackResponse {
  final String reference;
  final String accessCode;
  final String authorizationUrl;
  final String publicKey;
  final String membershipId;
  final int amount;

  MembershipPaystackResponse({
    required this.reference,
    required this.accessCode,
    required this.authorizationUrl,
    required this.publicKey,
    required this.membershipId,
    required this.amount,
  });

  factory MembershipPaystackResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return MembershipPaystackResponse(
      reference: data['reference'] ?? '',
      accessCode: data['access_code'] ?? '',
      authorizationUrl: data['authorization_url'] ?? '',
      publicKey: data['public_key'] ?? '',
      membershipId: data['membership_id']?.toString() ?? '',
      amount: data['amount'] != null ? int.tryParse(data['amount'].toString()) ?? 0 : 0,
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

class MembershipRenewalStatus {
  final bool needsRenewal;
  final String? validUntil;
  final int? daysRemaining;
  final int? renewalWindowDays;

  MembershipRenewalStatus({
    required this.needsRenewal,
    this.validUntil,
    this.daysRemaining,
    this.renewalWindowDays,
  });

  factory MembershipRenewalStatus.fromJson(Map<String, dynamic> json) {
    return MembershipRenewalStatus(
      needsRenewal: json['needs_renewal'] == true || json['needs_renewal'] == 'true',
      validUntil: json['valid_until']?.toString(),
      daysRemaining: json['days_remaining'] != null ? int.tryParse(json['days_remaining'].toString()) : null,
      renewalWindowDays: json['renewal_window_days'] != null ? int.tryParse(json['renewal_window_days'].toString()) : null,
    );
  }
}

class Pagination {
  final int currentPage;
  final bool hasMorePages;

  Pagination({
    required this.currentPage,
    required this.hasMorePages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] ?? 1,
      hasMorePages: json['has_more_pages'] == true,
    );
  }
}

class MembershipHistoryItem {
  final int membershipId;
  final String packageName;
  final String amount;
  final String price;
  final String platformCharge;
  final String paymentStatus;
  final String status;
  final String plan;
  final String createdAt;
  final String? startDate;
  final String? endDate;

  MembershipHistoryItem({
    required this.membershipId,
    required this.packageName,
    required this.amount,
    required this.price,
    required this.platformCharge,
    required this.paymentStatus,
    required this.status,
    required this.plan,
    required this.createdAt,
    this.startDate,
    this.endDate,
  });

  factory MembershipHistoryItem.fromJson(Map<String, dynamic> json) {
    return MembershipHistoryItem(
      membershipId: json['membership_id'] ?? 0,
      packageName: json['package_name']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      price: json['price']?.toString() ?? '0',
      platformCharge: json['platform_charge']?.toString() ?? '0',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      status: json['status']?.toString() ?? 'unknown',
      plan: json['plan']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
    );
  }
}

class MembershipHistoryResponse {
  final List<MembershipHistoryItem> items;
  final Pagination pagination;

  MembershipHistoryResponse({
    required this.items,
    required this.pagination,
  });

  factory MembershipHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data == null) {
      return MembershipHistoryResponse(
        items: [],
        pagination: Pagination(currentPage: 1, hasMorePages: false),
      );
    }
    
    List<dynamic> itemsList = [];
    if (data is List) {
      itemsList = data;
    } else if (data is Map && data['data'] is List) {
      itemsList = data['data']; 
    } else if (data is Map && data['items'] is List) {
      itemsList = data['items'];
    }

    int currentPage = 1;
    bool hasMorePages = false;

    if (data is Map) {
      if (data['pagination'] is Map) {
        currentPage = data['pagination']['current_page'] != null 
            ? int.tryParse(data['pagination']['current_page'].toString()) ?? 1 
            : 1;
        hasMorePages = data['pagination']['has_more_pages'] == true;
      } else if (data['current_page'] != null) {
        currentPage = int.tryParse(data['current_page'].toString()) ?? 1;
        final lastPage = data['last_page'] != null ? int.tryParse(data['last_page'].toString()) ?? currentPage : currentPage;
        hasMorePages = currentPage < lastPage;
      }
    }

    return MembershipHistoryResponse(
      items: itemsList.map((e) => MembershipHistoryItem.fromJson(e as Map<String, dynamic>)).toList(),
      pagination: Pagination(currentPage: currentPage, hasMorePages: hasMorePages),
    );
  }
}
