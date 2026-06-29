import 'package:eventsbooking/models/location_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LocationHelper {
  static const String _storageKey = 'saved_user_location';
  static const String _permissionAskedKey = 'location_permission_asked';

  // DEFAULT = Ahmedabad
  final LocationModel _defaultLocation = LocationModel(
    city: 'Ahmedabad',
    state: 'Gujarat',
    country: 'India',
    latitude: 23.0225,
    longitude: 72.5714,
  );

  // GET SAVED OR DEFAULT
  Future<LocationModel> getSavedOrDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_storageKey);
      if (stored != null && stored.isNotEmpty) {
        return LocationModel.fromJson(stored);
      }
    } catch (e) {
      debugPrint("Storage Error: $e");
    }
    return _defaultLocation;
  }

  // SAVE LOCATION
  Future<void> saveLocation(LocationModel location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, location.toJson());
    } catch (e) {
      debugPrint("Save Error: $e");
    }
  }

  // CHECK IF PERMISSION WAS ASKED BEFORE
  Future<bool> wasPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionAskedKey) ?? false;
  }

  // MARK PERMISSION AS ASKED
  Future<void> markPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionAskedKey, true);
  }

  // ✅ NEW: GEOCODE CITY NAME → COORDINATES
  Future<LocationModel> enrichWithCoordinates(LocationModel location) async {
    // Already has coordinates
    if (location.latitude != null && location.longitude != null) {
      return location;
    }

    try {
      final query = location.state.isNotEmpty
          ? '${location.city}, ${location.state}, ${location.country}'
          : '${location.city}, ${location.country}';

      debugPrint('🌍 Geocoding: $query');

      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final loc = locations.first;
        debugPrint('✅ Geocoded ${location.city} → ${loc.latitude}, ${loc.longitude}');

        return LocationModel(
          city: location.city,
          state: location.state,
          country: location.country,
          subLocality: location.subLocality,
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
      }
    } catch (e) {
      debugPrint('❌ Geocoding city error: $e');
    }

    // Return with Ahmedabad coords as fallback
    debugPrint('⚠️ Geocoding failed for ${location.city}, using Ahmedabad fallback');
    return LocationModel(
      city: location.city,
      state: location.state,
      country: location.country,
      subLocality: location.subLocality,
      latitude: 23.0225,
      longitude: 72.5714,
    );
  }

  // GET LIVE GPS
  Future<LocationModel?> getLiveLocation({bool userInteracted = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (userInteracted) await Geolocator.openLocationSettings();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        if (userInteracted) {
          await markPermissionAsked();
          permission = await Geolocator.requestPermission();
        } else {
          final asked = await wasPermissionAsked();
          if (!asked) {
            await markPermissionAsked();
            permission = await Geolocator.requestPermission();
          } else {
            return null;
          }
        }
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) {
        if (userInteracted) await Geolocator.openAppSettings();
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return await _getAddressFromPosition(position);
    } catch (e) {
      debugPrint("GPS Error: $e");
      return null;
    }
  }

  Future<LocationModel> _getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        final area = place.subLocality?.isNotEmpty == true
            ? place.subLocality
            : place.thoroughfare?.isNotEmpty == true
                ? place.thoroughfare
                : null;

        return LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          city: place.locality ?? place.subAdministrativeArea ?? 'Unknown',
          state: place.administrativeArea ?? '',
          country: place.country ?? '',
          subLocality: area,
        );
      }
    } catch (e) {
      debugPrint("Geocoding Error: $e");
    }

    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      city: 'Unknown Area',
      state: '',
      country: '',
      subLocality: null,
    );
  }
}