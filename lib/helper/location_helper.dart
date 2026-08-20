import 'package:dio/dio.dart';
import 'package:kogalo_network/models/location_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LocationHelper {
  static const String _storageKey = 'saved_user_location';
  static const String _permissionAskedKey = 'location_permission_asked';

  // DEFAULT = Nairobi
  final LocationModel _defaultLocation = LocationModel(
    city: 'Nairobi',
    state: 'Nairobi County',
    country: 'Kenya',
    latitude: -1.2921,
    longitude: 36.8219,
  );

  // GET SAVED OR DEFAULT
  Future<LocationModel> getSavedOrDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_storageKey);
      if (stored != null && stored.isNotEmpty) {
        final loc = LocationModel.fromJson(stored);
        // Automatically overwrite old cached "Ahmedabad" for users
        if (loc.city.toLowerCase() == 'ahmedabad') {
          return _defaultLocation;
        }
        return loc;
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

    // Return with Nairobi coords as fallback
    debugPrint('⚠️ Geocoding failed for ${location.city}, using Nairobi fallback');
    return LocationModel(
      city: location.city,
      state: location.state,
      country: location.country,
      subLocality: location.subLocality,
      latitude: -1.2921,
      longitude: 36.8219,
    );
  }


  // FETCH LOCATION FROM IP API IF PERMISSION DENIED
  Future<LocationModel?> getIpBasedLocation() async {
    try {
      final response = await Dio().get('http://ip-api.com/json');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          debugPrint('🌍 IP Location Success: ${data['city']}');
          return LocationModel(
            city: data['city'] ?? 'Unknown',
            state: data['regionName'] ?? '',
            country: data['country'] ?? '',
            latitude: (data['lat'] as num?)?.toDouble(),
            longitude: (data['lon'] as num?)?.toDouble(),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ IP Location Error: $e');
    }
    return _defaultLocation;
  }

  // GET LIVE GPS
  Future<LocationModel?> getLiveLocation({bool userInteracted = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (userInteracted) await Geolocator.openLocationSettings();
        return await getIpBasedLocation();
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