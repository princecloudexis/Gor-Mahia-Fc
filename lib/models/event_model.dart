DateTime? _safeParseDateTime(String? dateString) {
  if (dateString == null) return null;
  return DateTime.tryParse(dateString);
}

class EventModel {
  final int id;
  final String eventName;
  final String venueName;
  final String? eventImage;
  final String? slug;
  final DateTime? eventStartDate;
  final double? ticketPrice;
  final String? city;
  final String? country;
  final String? eventDescription;
  final DateTime? eventEndDate;
  final int? minimumAge;
  final int totalPurchased;
  final List<String> tags;
  final String? state;
  final double? distance;
  final String? latitude;
  final String? longitude;
  final String? brandName;
  final String? brandIcon;
  final String? creatorName;
  final String? currencySymbol;
  final String? symbol;
  final bool hideVenueFromUser;

  EventModel({
    required this.id,
    required this.eventName,
    required this.venueName,
    this.eventImage,
    this.slug,
    this.eventStartDate,
    this.ticketPrice,
    this.city,
    this.country,
    this.eventDescription,
    this.eventEndDate,
    this.minimumAge,
    required this.totalPurchased,
    required this.tags,
    this.state,
    this.distance,
    this.latitude,
    this.longitude,
    this.brandName,
    this.brandIcon,
    this.creatorName,
    this.currencySymbol,
    required this.hideVenueFromUser,
    required this.symbol,
  });

  String get displayVenueName {
    return hideVenueFromUser ? 'Venue to be announced' : venueName;
  }

  bool get shouldShowMap {
    return !hideVenueFromUser &&
        latitude != null &&
        longitude != null &&
        latitude!.isNotEmpty &&
        longitude!.isNotEmpty;
  }

  String get displayLocationString {
    if (hideVenueFromUser) {
      if (city != null &&
          state != null &&
          city!.isNotEmpty &&
          state!.isNotEmpty) {
        return '$city, $state';
      }
      return 'Location to be announced';
    }
    return '$venueName, $city';
  }

  String getFullImageUrl(String storageBaseUrl) {
    if (eventImage == null || eventImage!.isEmpty) {
      return 'https://via.placeholder.com/400x300.png?text=No+Image';
    }

    if (eventImage!.startsWith('http://') ||
        eventImage!.startsWith('https://')) {
      final uri = Uri.parse(eventImage!);
      final fixedPath = uri.path.replaceAll(RegExp(r'/{2,}'), '/');
      return '${uri.scheme}://${uri.host}$fixedPath';
    }

    final baseUrl = storageBaseUrl.endsWith('/')
        ? storageBaseUrl.substring(0, storageBaseUrl.length - 1)
        : storageBaseUrl;

    return '$baseUrl/storage/Creator/event/image/$eventImage';
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    double? price;
    if (json['ticket_price'] != null) {
      price = double.tryParse(json['ticket_price'].toString());
    }

    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = List<String>.from(
        (json['tags'] as List).map((tagJson) => tagJson['tag'] ?? ''),
      );
    } else if (json['hashtag'] != null) {
      parsedTags.add(json['hashtag']);
    }

    double? distance;
    if (json['distance'] != null) {
      distance = double.tryParse(json['distance'].toString());
    }

    String? brandName;
    String? brandIcon;

    if (json['brand_name'] is Map<String, dynamic>) {
      brandName = json['brand_name']['name'];
      brandIcon = json['brand_name']['icon'];
    } else {
      brandName = json['brand_name'];
      brandIcon = json['brand_icon'];
    }

    String? parsedEventImage = json['event_image'];
    if (parsedEventImage != null && parsedEventImage.startsWith('http:https://')) {
      parsedEventImage = parsedEventImage.replaceFirst('http:https://', 'https://');
    }

    return EventModel(
      id: json['favouriteEventId'] ?? json['id'] ?? 0,
      eventName: json['event_name'] ?? 'Untitled Match',
      venueName: json['venue_name'] ?? 'TBA',
      eventImage: parsedEventImage,
      slug: json['slug'] ?? json['event_url'],
      eventStartDate: _safeParseDateTime(json['event_start_date']),
      ticketPrice: price,
      city: json['city'],
      country: json['country'],
      eventDescription: json['event_description'],
      eventEndDate: _safeParseDateTime(json['event_end_date']),
      minimumAge: json['minimum_age'] is int
          ? json['minimum_age']
          : int.tryParse(json['minimum_age']?.toString() ?? ''),
      totalPurchased: json['total_purchased'] is int
          ? json['total_purchased']
          : int.tryParse(json['total_purchased']?.toString() ?? '') ?? 0,
      tags: parsedTags,
      state: json['state'],
      distance: distance,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      brandName: brandName,
      brandIcon: brandIcon,
      creatorName: json['creator_name'],
      currencySymbol: json['currencySymbol'],
      symbol: json['symbol']?.toString() ?? '',
      hideVenueFromUser: json['hide_venue_from_user']?.toString() == '1',
    );
  }
}
