import 'dart:convert';
import 'package:gormahiafc/models/location_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _locationKey = 'last_known_location';

class LocationPersistenceService {
  Future<void> saveLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    final locationJsonString = json.encode(location.toJson());
    await prefs.setString(_locationKey, locationJsonString);
  }

  Future<LocationModel?> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final locationJsonString = prefs.getString(_locationKey);
    if (locationJsonString != null) {
      return LocationModel.fromJson(json.decode(locationJsonString));
    }
    return null;
  }
}
