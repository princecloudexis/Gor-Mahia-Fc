import 'package:flutter/material.dart';
import 'package:gormahiafc/models/giftcard_model.dart';

DateTime? _safeParseDateTime(String? dateString) {
  if (dateString == null) return null;
  return DateTime.tryParse(dateString);
}

class TicketDetailModel {
  final int id;
  final String eventName;
  final String? eventImage;
  final String slug;
  final String venueName;
  final String categoryName;
  final String symbol;
  final List<TicketCategoryModel> tickets;
  final List<DateTime> availableDates;
  final DateTime? eventStartDate;
  final DateTime? eventEndDate;
  final DateTime? ticketSalesStartDate;
  final DateTime? ticketSalesEndDate;
  final DateTime? preRegisterStartDate;
  final DateTime? preRegisterEndDate;
  final String facebookShareUrl;
  final InstagramShareInfo instagramShareUrl;
  final bool isUserPreRegistered;
  final List<GiftCardModel> giftcards;

  TicketDetailModel({
    required this.id,
    required this.eventName,
    this.eventImage,
    required this.slug,
    required this.venueName,
    required this.categoryName,
    required this.symbol,
    required this.tickets,
    required this.availableDates,
    this.eventStartDate,
    this.eventEndDate,
    this.ticketSalesStartDate,
    this.ticketSalesEndDate,
    this.preRegisterStartDate,
    this.preRegisterEndDate,
    required this.facebookShareUrl,
    required this.instagramShareUrl,
    required this.isUserPreRegistered,
    required this.giftcards,
  });

  List<TicketCategoryModel> get seasonalPassTickets =>
      tickets.where((t) => t.isSeasonalPass && t.isAvailable).toList();
  List<TicketCategoryModel> get perDayTickets =>
      tickets.where((t) => !t.isSeasonalPass && t.isAvailable).toList();
  bool get hasSeasonalPassTickets => seasonalPassTickets.isNotEmpty;
  bool get hasPerDayTickets => perDayTickets.isNotEmpty;
  bool get isPreRegistrationActive {
    if (preRegisterStartDate == null || preRegisterEndDate == null) {
      return false;
    }
    final now = DateTime.now();
    return !now.isBefore(preRegisterStartDate!) &&
        now.isBefore(preRegisterEndDate!);
  }

  bool get isBookingActive {
    final now = DateTime.now();
    bool anyTicketOnSale = tickets.where((t) => t.isAvailable).any((ticket) {
      if (ticket.saleStartDate == null || ticket.saleEndDate == null) {
        return false;
      }
      return !now.isBefore(ticket.saleStartDate!) &&
          !now.isAfter(ticket.saleEndDate!);
    });
    return anyTicketOnSale;
  }

  bool get isBookingClosed {
    final now = DateTime.now();
    final saleWindowTickets = tickets
        .where(
          (t) =>
              t.isAvailable && t.saleStartDate != null && t.saleEndDate != null,
        )
        .toList();

    if (saleWindowTickets.isEmpty) return false;

    return saleWindowTickets.every((t) => now.isAfter(t.saleEndDate!));
  }

  factory TicketDetailModel.fromJson(Map<String, dynamic> json) {
    final List<DateTime> dates = [];
    final startDate = _safeParseDateTime(json['event_start_date']);
    final endDate = _safeParseDateTime(json['event_end_date']);

    final eventSaleStartDate = _safeParseDateTime(
      json['ticket_sales_start_date'],
    );
    final eventSaleEndDate = _safeParseDateTime(json['ticket_sales_end_date']);

    if (startDate != null && endDate != null) {
      var currentDate = DateUtils.dateOnly(startDate);
      final lastDate = DateUtils.dateOnly(endDate);
      while (!currentDate.isAfter(lastDate)) {
        dates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
    } else if (startDate != null) {
      dates.add(DateUtils.dateOnly(startDate));
    }

    final List<TicketCategoryModel> allTickets =
        (json['tickets'] as List<dynamic>)
            .map(
              (ticketJson) => TicketCategoryModel.fromJson(
                ticketJson,
                fallbackSaleStart: eventSaleStartDate,
                fallbackSaleEnd: eventSaleEndDate,
              ),
            )
            .toList();

    final List<dynamic> giftcardData =
        json['giftcards'] as List<dynamic>? ?? [];
    final List<GiftCardModel> giftcards = giftcardData
        .map((gcJson) => GiftCardModel.fromJson(gcJson))
        .toList();
    final dynamic igShareData = json['instagramShareUrl'];
    InstagramShareInfo igShareInfo;
    if (igShareData is Map<String, dynamic>) {
      igShareInfo = InstagramShareInfo.fromJson(igShareData);
    } else if (igShareData is String) {
      igShareInfo = InstagramShareInfo(imageUrl: '', shareLink: igShareData);
    } else {
      igShareInfo = InstagramShareInfo(imageUrl: '', shareLink: '');
    }

    return TicketDetailModel(
      id: json['id'],
      eventName: json['event_name'] ?? 'Untitled Match',
      eventImage: json['event_image'],
      slug: json['slug'] ?? '',
      venueName: json['venue_name'] ?? 'TBA',
      categoryName: json['category_name'] ?? 'General',
      symbol: json['symbol'] ?? 'KSh ',
      tickets: allTickets,
      availableDates: dates,
      eventStartDate: startDate,
      eventEndDate: endDate,
      ticketSalesStartDate: eventSaleStartDate,
      ticketSalesEndDate: eventSaleEndDate,
      preRegisterStartDate: _safeParseDateTime(json['pre_register_start_date']),
      preRegisterEndDate: _safeParseDateTime(json['pre_register_end_date']),
      facebookShareUrl: json['facebookShareUrl'] ?? '',
      instagramShareUrl: igShareInfo,
      isUserPreRegistered: json['is_user_pre_registered'] ?? false,
      giftcards: giftcards,
    );
  }
}

class TicketCategoryModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int available;
  final int maxPerOrder;
  final DateTime? saleStartDate;
  final DateTime? saleEndDate;
  final int ticketType;
  final bool isAvailable;
  final bool isSeasonalPass;

  TicketCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.available,
    required this.maxPerOrder,
    this.saleStartDate,
    this.saleEndDate,
    required this.ticketType,
    required this.isAvailable,
    required this.isSeasonalPass,
  });

  factory TicketCategoryModel.fromJson(
    Map<String, dynamic> json, {
    DateTime? fallbackSaleStart,
    DateTime? fallbackSaleEnd,
  }) {
    final rawDescription = json['description'] ?? 'No description available.';
    final cleanDescription = rawDescription.replaceAll(RegExp(r'<[^>]*>'), '');
    final int ticketTypeValue =
        int.tryParse(json['ticket_type']?.toString() ?? '0') ?? 0;

    return TicketCategoryModel(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Ticket',
      description: cleanDescription,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      available: json['max_no_of_sale'] ?? 0,
      maxPerOrder:
          int.tryParse(json['must_be_bought_in_multi_of']?.toString() ?? '1') ??
          1,
      saleStartDate:
          _safeParseDateTime(json['sale_start_op2']) ?? fallbackSaleStart,
      saleEndDate: _safeParseDateTime(json['sale_end_op2']) ?? fallbackSaleEnd,
      ticketType: ticketTypeValue,
      isAvailable: json['isavailable']?.toString() == '1',
      isSeasonalPass: ticketTypeValue == 1,
    );
  }
}

class InstagramShareInfo {
  final String imageUrl;
  final String shareLink;

  InstagramShareInfo({required this.imageUrl, required this.shareLink});

  factory InstagramShareInfo.fromJson(Map<String, dynamic> json) {
    return InstagramShareInfo(
      imageUrl: json['image_url'] ?? '',
      shareLink: json['share_link'] ?? '',
    );
  }
}
