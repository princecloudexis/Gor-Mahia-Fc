import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/models/location_model.dart';
import 'package:kogalo_network/helper/location_helper.dart';

class LocationController extends StateNotifier<AsyncValue<LocationModel>> {
  final LocationHelper _locationHelper = LocationHelper();

  LocationController() : super(const AsyncValue.loading()) {
    initializeLocation();
  }

  Future<void> initializeLocation() async {
    try {
      // Get saved or default (cityname with coords)
      final cachedOrDefault = await _locationHelper.getSavedOrDefault();
      state = AsyncValue.data(cachedOrDefault);

      // Try live GPS
      final liveLocation = await _locationHelper.getLiveLocation(
        userInteracted: false,
      );

      if (liveLocation != null) {
        state = AsyncValue.data(liveLocation);
        await _locationHelper.saveLocation(liveLocation);
      }
    } catch (e) {
      debugPrint('LocationController init error: $e');
      if (state.hasError || state.isLoading) {
        final defaultLoc = await _locationHelper.getSavedOrDefault();
        state = AsyncValue.data(defaultLoc);
      }
    }
  }

  Future<void> getUserLocation() async {
    state = const AsyncValue.loading();
    try {
      final liveLocation = await _locationHelper.getLiveLocation(
        userInteracted: true,
      );

      if (liveLocation != null) {
        state = AsyncValue.data(liveLocation);
        await _locationHelper.saveLocation(liveLocation);
      } else {
        final saved = await _locationHelper.getSavedOrDefault();
        state = AsyncValue.data(saved);
      }
    } catch (e) {
      final saved = await _locationHelper.getSavedOrDefault();
      state = AsyncValue.data(saved);
    }
  }

  // ✅ FIXED: Geocodes city to get coordinates
  Future<void> setLocation(LocationModel location) async {
    // Set immediately for fast UI update
    state = AsyncValue.data(location);

    try {
      // Geocode city → get lat/lng in background
      final enriched = await _locationHelper.enrichWithCoordinates(location);

      // Update with real coordinates
      state = AsyncValue.data(enriched);
      await _locationHelper.saveLocation(enriched);

      debugPrint(
        '📍 Location set: ${enriched.city} '
        '→ lat:${enriched.latitude}, lng:${enriched.longitude}',
      );
    } catch (e) {
      await _locationHelper.saveLocation(location);
      debugPrint('setLocation error: $e');
    }
  }
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, AsyncValue<LocationModel>>((ref) {
      return LocationController();
    });

final userLocationProvider = Provider<AsyncValue<LocationModel>>((ref) {
  return ref.watch(locationControllerProvider);
});

final selectedCityProvider = StateProvider<String?>((ref) {
  final location = ref.watch(userLocationProvider);
  return location.whenData((loc) => loc.city).value;
});
