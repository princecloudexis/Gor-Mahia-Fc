import 'package:eventsbooking/models/event_model.dart';
import 'package:eventsbooking/models/payment_model.dart';
import 'dart:math' as math;

extension DoubleRounding on double {
  double toPrecision(int n) {
    double mod = math.pow(10.0, n).toDouble();
    return ((this * mod).round().toDouble() / mod);
  }
}

class SeatDetail {
  final String row;
  final String number;

  SeatDetail({required this.row, required this.number});

  @override
  String toString() => '$row$number';
}

DateTime? _safeParseDateTime(String? dateString) {
  if (dateString == null) return null;
  return DateTime.tryParse(dateString);
}

class CheckoutTicketModel {
  final int id;
  final String ticketType;
  final double price;
  final int quantity;
  final double totalPrice;
  final String? dateOfAccess;
  final bool isSeasonalPass;
  final List<SeatDetail> seats;

  CheckoutTicketModel({
    required this.id,
    required this.ticketType,
    required this.price,
    required this.quantity,
    required this.totalPrice,
    this.dateOfAccess,
    required this.isSeasonalPass,
    this.seats = const [],
  });

  CheckoutTicketModel copyWithAddedQuantity(CheckoutTicketModel other) {
    return CheckoutTicketModel(
      id: this.id,
      ticketType: this.ticketType,
      price: this.price,
      quantity: this.quantity + other.quantity,
      totalPrice: this.totalPrice + other.totalPrice,
      dateOfAccess: this.dateOfAccess,
      isSeasonalPass: this.isSeasonalPass,
      seats: [...this.seats, ...other.seats],
    );
  }

  factory CheckoutTicketModel.fromJson(Map<String, dynamic> json) {
    String type = json['ticket_type'] ?? 'General Admission';
    double priceVal = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    double totalVal =
        double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0;
    int qtyVal = int.tryParse(json['quantity']?.toString() ?? '1') ?? 1;

    List<SeatDetail> parsedSeats = [];

    if (json['alloted_seat'] != null) {
      final seatObj = json['alloted_seat'];
      String r = seatObj['row_no']?.toString() ?? '';
      String c = seatObj['col_no']?.toString() ?? '';
      if (c.contains('_')) {
        c = c.split('_').first;
      }
      if (r.isNotEmpty || c.isNotEmpty) {
        parsedSeats.add(SeatDetail(row: r, number: c));
      } else {
        String label = seatObj['seat_label']?.toString() ?? '';
        if (label.isNotEmpty) {
          parsedSeats.add(SeatDetail(row: '', number: label.split('_').first));
        }
      }
    }

    return CheckoutTicketModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      ticketType: type,
      price: priceVal,
      quantity: qtyVal,
      totalPrice: totalVal,
      dateOfAccess: json['date_of_access'],
      isSeasonalPass: false,
      seats: parsedSeats,
    );
  }
}

class TaxAndFeeModel {
  final int id;
  final String title;
  final double charges;
  final String chargeType;

  TaxAndFeeModel({
    required this.id,
    required this.title,
    required this.charges,
    required this.chargeType,
  });

  factory TaxAndFeeModel.fromJson(Map<String, dynamic> json) {
    return TaxAndFeeModel(
      id: json['id'],
      title: json['text_title'] ?? 'Fee',
      charges: double.tryParse(json['charges']?.toString() ?? '0') ?? 0.0,
      chargeType: json['charge_type']?.toString() ?? '1',
    );
  }
}

class CheckoutAdminModel {
  final String globalVariableStatus;
  final double? fixPercentage;
  final double? fixAmount;
  final String paymentMethod;
  final String? stripeKey;
  final String? razorKey;

  const CheckoutAdminModel({
    required this.globalVariableStatus,
    this.fixPercentage,
    this.fixAmount,
    required this.paymentMethod,
    this.stripeKey,
    this.razorKey,
  });

  factory CheckoutAdminModel.fromJson(Map<String, dynamic> json) {
    return CheckoutAdminModel(
      globalVariableStatus: json['global_variable_status']?.toString() ?? '1',
      fixPercentage: double.tryParse(json['fix_percentage']?.toString() ?? ''),
      fixAmount: double.tryParse(json['fix_amount']?.toString() ?? ''),
      paymentMethod: json['payment_method']?.toString() ?? '0',
      stripeKey: json['stripe_key']?.toString(),
      razorKey: json['razor_key']?.toString(),
    );
  }
}

class CheckoutDetailsModel {
  final List<CheckoutTicketModel> tickets;
  final List<TaxAndFeeModel> taxesAndFees;
  final EventModel event;
  final String symbol;
  final CheckoutAdminModel? admin;
  final double creatorFixPercentage;
  final double creatorFixAmount;

  CheckoutDetailsModel({
    required this.tickets,
    required this.taxesAndFees,
    required this.event,
    required this.symbol,
    this.admin,
    this.creatorFixPercentage = 0,
    this.creatorFixAmount = 0,
  });

  factory CheckoutDetailsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) throw FormatException("No data");

    final eventJson = data['event'] as Map<String, dynamic>? ?? {};
    final adminJson = data['admin'] as Map<String, dynamic>?;

    // ✅ Creator is at data.creator
    final creatorJson = data['creator'] as Map<String, dynamic>?;

    // ✅ Creator uses "percentage" key
    final creatorFixPercentage =
        double.tryParse(creatorJson?['percentage']?.toString() ?? '0') ?? 0.0;

    // ✅ Creator uses "fix_amount" key
    final creatorFixAmount =
        double.tryParse(creatorJson?['fix_amount']?.toString() ?? '0') ?? 0.0;

    return CheckoutDetailsModel(
      tickets: (data['tickets'] as List? ?? [])
          .map((t) => CheckoutTicketModel.fromJson(t))
          .toList(),
      taxesAndFees: (data['textdata'] as List? ?? [])
          .map((t) => TaxAndFeeModel.fromJson(t))
          .toList(),
      event: EventModel.fromJson(eventJson),
      symbol: data['symbol'] ?? 'KSh ',
      admin: adminJson == null ? null : CheckoutAdminModel.fromJson(adminJson),
      creatorFixPercentage: creatorFixPercentage,
      creatorFixAmount: creatorFixAmount,
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return null;
}

double? _readDoubleFromKeys(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final parsed = double.tryParse(value.toString());
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

double _readDoubleFromSources(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    final value = _readDoubleFromKeys(source, keys);
    if (value != null) {
      return value;
    }
  }
  return 0;
}

extension CheckoutGrouping on CheckoutDetailsModel {
  List<CheckoutTicketModel> get groupedTickets {
    Map<String, CheckoutTicketModel> groups = {};

    for (var ticket in tickets) {
      final key = '${ticket.ticketType}-${ticket.price}';
      if (groups.containsKey(key)) {
        groups[key] = groups[key]!.copyWithAddedQuantity(ticket);
      } else {
        groups[key] = ticket;
      }
    }
    return groups.values.toList();
  }

  PaymentGatewayType get paymentGatewayType {
    if (admin?.paymentMethod == '1') {
      return PaymentGatewayType.razorpay;
    }
    return PaymentGatewayType.stripe;
  }

  double get subtotal => tickets.fold(0, (sum, t) => sum + t.totalPrice);

  double get taxesAndFeesTotal {
    return taxesAndFees.fold(0, (sum, fee) {
      final feeAmount = fee.chargeType == '0'
          ? (subtotal * fee.charges) / 100
          : fee.charges;
      // ✅ Round each tax line to 2 decimal places
      return sum + feeAmount.toPrecision(2);
    });
  }

  ({double percentage, double fixedAmount}) get resolvedBookingFeeParams {
    final useCreator = admin?.globalVariableStatus == '0';

    if (useCreator) {
      // global_variable_status == "0" → Creator values
      // creator.percentage = "1.5"
      // creator.fix_amount = "0"
      return (percentage: creatorFixPercentage, fixedAmount: creatorFixAmount);
    } else {
      // global_variable_status == "1" → Admin values
      // admin.fix_percentage = "x"
      // admin.fix_amount = "x"
      return (
        percentage: admin?.fixPercentage ?? 0,
        fixedAmount: admin?.fixAmount ?? 0,
      );
    }
  }

  /// The raw booking fee before service taxes
  double get bookingFeeBase {
    final params = resolvedBookingFeeParams;
    final percentValue = subtotal * (params.percentage / 100);
    return (params.fixedAmount + percentValue).toPrecision(2);
  }

  /// 18% IGST applied specifically to the booking fee base
  double get bookingFeeTax {
    return (bookingFeeBase * 0.18).toPrecision(2);
  }

  /// The final booking fee shown to the user (Base + 18% IGST)
  double get bookingFee {
    return (bookingFeeBase + bookingFeeTax).toPrecision(2);
  }

  double totalBeforeDiscount() {
    // ✅ Sum of Subtotal + Ticket Taxes + Booking Fee (which now includes its own tax)
    return subtotal + taxesAndFeesTotal + bookingFee;
  }

  double grandTotal({double promoDiscount = 0}) {
    return math.max(0, (totalBeforeDiscount() - promoDiscount).toPrecision(2));
  }
}
