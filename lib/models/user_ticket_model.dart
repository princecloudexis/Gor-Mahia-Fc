import 'package:gormahiafc/models/event_model.dart';

class UserTicketModel {
  final int eventId;
  final int totalQuantity;
  final EventModel event;

  UserTicketModel({
    required this.eventId,
    required this.totalQuantity,
    required this.event,
  });

  factory UserTicketModel.fromJson(Map<String, dynamic> json) {
    final EventModel event;

    if (json['event'] != null && json['event'] is Map<String, dynamic>) {
      event = EventModel.fromJson(json['event']);
    } else {
      event = EventModel.fromJson({
        'id': json['event_id'],
        'event_name': json['event_name'],
        'event_image': json['event_image'],
        'event_start_date': json['event_start_date'],
        'event_end_date': json['event_end_date'],
        'venue_name': json['venue_name'],
        'slug': json['slug'],
        'city': json['city'],
        'state': json['state'],
        'country': json['country'],
        'postal_code': json['postal_code'],
        'street': json['street'],
        'street_number': json['street_number'],
        'ticket_price': json['ticket_price'],
        'symbol': json['symbol'],
        'currencySymbol': json['currencySymbol'],
        'latitude': json['latitude'],
        'longitude': json['longitude'],
        'hide_venue_from_user': json['hide_venue_from_user'],
        'tags': json['tags'],
        'event_description': json['event_description'],
      });
    }

    return UserTicketModel(
      eventId: json['event_id'] is int
          ? json['event_id']
          : int.tryParse(json['event_id']?.toString() ?? '') ?? 0,
      totalQuantity: json['total_quantity'] is int
          ? json['total_quantity']
          : int.tryParse(json['total_quantity']?.toString() ?? '') ?? 0,
      event: event,
    );
  }
}