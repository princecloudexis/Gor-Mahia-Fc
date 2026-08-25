import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/favorites.dart';
import 'package:kogalo_network/models/event_model.dart';
import 'package:kogalo_network/models/shop_models.dart';
import 'package:kogalo_network/repositories/event_repositories.dart';
import 'package:kogalo_network/repositories/shop_repository.dart';
import 'package:kogalo_network/providers/event_providers.dart';
import 'package:kogalo_network/providers/shop_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

class MockEventRepository extends Mock implements EventRepository {}
class MockShopRepository extends Mock implements ShopRepository {}

void main() {
  late MockEventRepository mockEventRepo;
  late MockShopRepository mockShopRepo;

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockShopRepo = MockShopRepository();
  });

  testWidgets('Favorites renders empty states and loaded states', (WidgetTester tester) async {
    final mockEvent = EventModel(
      id: 1,
      eventName: 'Test Match',
      eventDescription: 'A test match',
      slug: 'test-match',
      venueName: 'Test Venue',
      totalPurchased: 0,
      tags: [],
      hideVenueFromUser: false,
      symbol: 'KSh',
    );

    final mockProduct = ShopProduct(
      id: 1,
      name: 'Test Product',
      price: 1000,
      description: 'A test product',
      isFavourite: true,
    );

    // 1. Loading State
    final eventsCompleter = Completer<List<EventModel>>();
    final shopCompleter = Completer<List<ShopProduct>>();

    when(() => mockEventRepo.getFavoriteEvents()).thenAnswer((_) => eventsCompleter.future);
    when(() => mockShopRepo.getFavorites()).thenAnswer((_) => shopCompleter.future);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
          shopRepositoryProvider.overrideWithValue(mockShopRepo),
        ],
        child: const MaterialApp(home: Favorites()),
      ),
    );

    await tester.pump();
    expect(find.byType(CustomScrollView), findsWidgets); // Contains shimmer inside sliver list
    
    // Resolve empty
    eventsCompleter.complete(<EventModel>[]);
    shopCompleter.complete(<ShopProduct>[]);
    await tester.pumpAndSettle();

    // 2. Empty State (Matches Tab)
    expect(find.text('No Favorite Matches Yet'), findsOneWidget);

    // Switch to Shop tab
    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();

    expect(find.text('No Favorite Products Yet'), findsOneWidget);

    // 3. Loaded State
    when(() => mockEventRepo.getFavoriteEvents()).thenAnswer((_) async => [mockEvent]);
    when(() => mockShopRepo.getFavorites()).thenAnswer((_) async => [mockProduct]);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepo),
          shopRepositoryProvider.overrideWithValue(mockShopRepo),
        ],
        child: const MaterialApp(home: Favorites()),
      ),
    );
    await tester.pumpAndSettle();
    
    // Shop tab is currently active because ProviderScope is rebuilt, but wait...
    // The TabController is internal to the widget and will reset to index 0 on a completely fresh pump.
    expect(find.text('Test Match'), findsOneWidget);

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    
    expect(find.text('Test Product'), findsOneWidget);
  });
}
