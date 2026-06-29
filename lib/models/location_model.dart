import 'dart:convert';

class LocationModel {
  final String city;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? subLocality;

  LocationModel({
    required this.city,
    required this.state,
    required this.country,
    this.latitude,
    this.longitude,
    this.subLocality,
  });

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'subLocality': subLocality,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      subLocality: map['subLocality'],
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationModel.fromJson(String source) =>
      LocationModel.fromMap(json.decode(source));

  String get displayAddress {
    final bool hasCity =
        city.isNotEmpty && !city.toLowerCase().contains('unknown');
    final bool hasSubLocality =
        subLocality != null &&
        subLocality!.isNotEmpty &&
        !subLocality!.toLowerCase().contains('unknown');

    if (hasSubLocality && hasCity) {
      return '$subLocality, $city';
    }
    if (hasCity) {
      return city;
    }
    return 'Select Location';
  }
}
