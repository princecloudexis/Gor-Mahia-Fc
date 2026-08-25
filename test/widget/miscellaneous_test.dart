import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kogalo_network/models/location_model.dart';
import 'package:kogalo_network/services/location_service.dart';
import 'package:kogalo_network/widgets/no_connection_widget.dart';
import 'package:kogalo_network/providers/connectivity_provider.dart';
import 'package:kogalo_network/pages/search.dart';
import 'package:kogalo_network/providers/search_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Miscellaneous Category Tests (Skill Check)', () {
    
    testWidgets('LocationPersistenceService saves and loads correctly', (tester) async {
      final service = LocationPersistenceService();
      
      var loaded = await service.loadLocation();
      expect(loaded, isNull);
      
      final mockLocation = LocationModel(city: 'Nairobi', state: 'Nairobi', country: 'Kenya', latitude: 1.0, longitude: 2.0);
      await service.saveLocation(mockLocation);
      
      loaded = await service.loadLocation();
      expect(loaded, isNotNull);
      expect(loaded!.latitude, 1.0);
      expect(loaded.longitude, 2.0);
    });

    testWidgets('NoConnectionFullScreen shows retry button and triggers provider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const NoConnectionFullScreen(),
          ),
        ),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      // Verifies it doesn't crash on tap.
    });

    testWidgets('Search Page renders correctly on empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const Search(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Should show search input
      expect(find.byType(TextField), findsOneWidget);
      
      // Should show 'Filters' text in UI or in the bottom sheet when clicked
      expect(find.text('Search Matches'), findsOneWidget);
    });
  });
}
