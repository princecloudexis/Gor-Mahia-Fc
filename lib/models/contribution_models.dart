class Contribution {
  final int participantId;
  final int contributionId;
  final String title;
  final String description;
  final String currency;
  final int amountPaid;
  final int amountDue;
  final int balance;
  final String status;
  final String dueDate;
  final String? paidAt;
  final bool canPay;

  Contribution({
    required this.participantId,
    required this.contributionId,
    required this.title,
    required this.description,
    required this.currency,
    required this.amountPaid,
    required this.amountDue,
    required this.balance,
    required this.status,
    required this.dueDate,
    this.paidAt,
    required this.canPay,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      participantId: json['participant_id'] ?? 0,
      contributionId: json['contribution_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      currency: json['currency'] ?? 'KES',
      amountPaid: _toInt(json['amount_paid']),
      amountDue: _toInt(json['amount_due']),
      balance: _toInt(json['balance']),
      status: json['status'] ?? '',
      dueDate: json['due_date'] ?? '',
      paidAt: json['paid_at'],
      canPay: json['can_pay'] ?? false,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class ContributionPagination {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasMorePages;

  ContributionPagination({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.hasMorePages,
  });

  factory ContributionPagination.fromJson(Map<String, dynamic> json) {
    return ContributionPagination(
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
      hasMorePages: json['has_more_pages'] ?? false,
    );
  }
}

class ContributionResponse {
  final String tab;
  final List<Contribution> items;
  final ContributionPagination pagination;

  ContributionResponse({
    required this.tab,
    required this.items,
    required this.pagination,
  });

  factory ContributionResponse.fromJson(Map<String, dynamic> json) {
    return ContributionResponse(
      tab: json['tab'] ?? '',
      items: (json['items'] as List?)
              ?.map((e) => Contribution.fromJson(e))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? ContributionPagination.fromJson(json['pagination'])
          : ContributionPagination(
              currentPage: 1,
              perPage: 10,
              total: 0,
              lastPage: 1,
              hasMorePages: false),
    );
  }
}

class PaymentResponse {
  final String checkoutRequestId;
  final int contributionPaymentId;
  final int amount;

  PaymentResponse({
    required this.checkoutRequestId,
    required this.contributionPaymentId,
    required this.amount,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      checkoutRequestId: json['checkout_request_id'] ?? '',
      contributionPaymentId: json['contribution_payment_id'] ?? 0,
      amount: Contribution._toInt(json['amount']),
    );
  }
}

class PaymentStatusResponse {
  final String payment;
  final String mpesaReceipt;
  final int amount;
  final Contribution? participant;

  PaymentStatusResponse({
    required this.payment,
    required this.mpesaReceipt,
    required this.amount,
    this.participant,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      payment: json['payment'] ?? '',
      mpesaReceipt: json['mpesa_receipt'] ?? '',
      amount: Contribution._toInt(json['amount']),
      participant: json['participant'] != null
          ? Contribution.fromJson(json['participant'])
          : null,
    );
  }
}

class ContributionCount {
  final int totalContributed;
  final int pending;
  final String currency;

  ContributionCount({
    required this.totalContributed,
    required this.pending,
    required this.currency,
  });

  factory ContributionCount.fromJson(Map<String, dynamic> json) {
    return ContributionCount(
      totalContributed: Contribution._toInt(json['total_contributed']),
      pending: Contribution._toInt(json['pending']),
      currency: json['currency'] ?? 'KES',
    );
  }
}
