import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';

DateTime? _safeParseDateTime(String? dateString) {
  if (dateString == null) return null;
  return DateTime.tryParse(dateString);
}

class TicketHolderDetailModel {
  final int id;
  final int eventId;
  final String ticketType;
  final int quantity;
  final String orderId;
  final List<TicketHolder> holders;

  TicketHolderDetailModel({
    required this.id,
    required this.eventId,
    required this.ticketType,
    required this.quantity,
    required this.orderId,
    required this.holders,
  });

  factory TicketHolderDetailModel.fromJson(Map<String, dynamic> json) {
    final String? parentSeatLabel =
        json['alloted_seat']?['seat_label']?.toString();

    final holderList = (json['ticket_holder'] as List?) ?? [];

    final holders = holderList
        .map(
          (i) => TicketHolder.fromJson(
            i as Map<String, dynamic>,
            defaultSeatLabel: parentSeatLabel,
          ),
        )
        .toList();

    return TicketHolderDetailModel(
      id: json['id'] ?? 0,
      eventId: json['event_id'] ?? 0,
      ticketType: json['ticket_type'] ?? 'N/A',
      quantity: json['quantity'] ?? 0,
      orderId: json['order_id'] ?? '',
      holders: holders,
    );
  }
}

class TicketHolder {
  final int id;
  final String name;
  final String email;
  final String qrCodeUrl;
  final String eventName;
  final String dateOfAccess;
  final bool isSeasonalPass;
  final DateTime? validFrom;
  final DateTime? validTo;

  final String? seatLabel;

  TicketHolder({
    required this.id,
    required this.name,
    required this.email,
    required this.qrCodeUrl,
    required this.eventName,
    required this.dateOfAccess,
    required this.isSeasonalPass,
    this.validFrom,
    this.validTo,
    this.seatLabel,
  });

  String get displayDateString {
    if (isSeasonalPass && validFrom != null && validTo != null) {
      final from = DateFormat.yMMMd().format(validFrom!);
      final to = DateFormat.yMMMd().format(validTo!);
      return 'Valid: $from - $to';
    } else if (dateOfAccess.isNotEmpty) {
      final date = _safeParseDateTime(dateOfAccess);
      if (date != null) {
        return DateFormat.yMMMEd().format(date);
      }
    }
    return 'Date not specified';
  }

  String get base64QrCode {
    return qrCodeUrl.split(',').last;
  }

  Uint8List get qrCodeBytes {
    return base64Decode(base64QrCode);
  }

  factory TicketHolder.fromJson(
    Map<String, dynamic> json, {
    String? defaultSeatLabel,
  }) {
    final String ticketType = json['ticket_type']?.toString() ?? '0';
    final bool isSeasonal = ticketType == '1';

    // Seat can come from:
    // - ticket_holder.allotment_seat
    // - ticket_holder.seat
    // - parent alloted_seat.seat_label (defaultSeatLabel)
    final dynamic rawSeat =
        json['allotment_seat'] ?? json['seat'] ?? defaultSeatLabel;
    final String? seatLabel = rawSeat?.toString();

    return TicketHolder(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      qrCodeUrl: json['qrCodeUrl'] ?? '',
      eventName: json['eventname'] ?? 'N/A',
      dateOfAccess: json['date_of_access'] ?? '',
      isSeasonalPass: isSeasonal,
      validFrom: _safeParseDateTime(json['valid_from']),
      validTo: _safeParseDateTime(json['valid_to']),
      seatLabel: seatLabel,
    );
  }
}