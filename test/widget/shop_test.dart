import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/shop/shop.dart';
import 'package:kogalo_network/models/shop_models.dart';
import 'package:kogalo_network/providers/shop_providers.dart';
import 'package:kogalo_network/pages/home/home_dashboard_sections.dart';
import 'package:kogalo_network/repositories/shop_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

class MockShopRepository extends Mock implements ShopRepository {}

void main() {
  late MockShopRepository mockRepo;

  setUp(() {
    mockRepo = MockShopRepository();
  });

  testWidgets('Shop Page renders loading states, empty states, and loaded data', (WidgetTester tester) async {
    // 1. Test Loading State (unresolved futures)
    final bannersCompleter = Completer<List<ShopBanner>>();
    final categoriesCompleter = Completer<List<ShopCategory>>();
    final arrivalsCompleter = Completer<List<ShopProduct>>();
    final topPicksCompleter = Completer<List<ShopProduct>>();
    final cartCompleter = Completer<ShopCart>();

    when(() => mockRepo.getBanners()).thenAnswer((_) => bannersCompleter.future);
    when(() => mockRepo.getCategories()).thenAnswer((_) => categoriesCompleter.future);
    when(() => mockRepo.getNewArrivals()).thenAnswer((_) => arrivalsCompleter.future);
    when(() => mockRepo.getTopPicks()).thenAnswer((_) => topPicksCompleter.future);
    when(() => mockRepo.getCart()).thenAnswer((_) => cartCompleter.future);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          shopRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(home: Shop()),
      ),
    );

    // Initial frame has loading shimmers
    await tester.pump();
    expect(find.byType(ShimmerBox), findsWidgets);
    
    // Resolve futures with empty data
    bannersCompleter.complete(<ShopBanner>[]);
    categoriesCompleter.complete(<ShopCategory>[]);
    arrivalsCompleter.complete(<ShopProduct>[]);
    topPicksCompleter.complete(<ShopProduct>[]);
    cartCompleter.complete(ShopCart(id: 1, cartTotal: 0, subtotal: 0, platformCharge: 0, totalPaymentCharge: 0, items: []));

    // Pump and settle to let the empty state rebuild
    await tester.pumpAndSettle();

    // 2. Test Empty State
    expect(find.text('No banners available'), findsOneWidget);
    expect(find.text('No categories available.'), findsOneWidget);
    expect(find.text('No new arrivals yet.'), findsOneWidget);
    expect(find.text('No top picks yet.'), findsOneWidget);

    // 3. Test Loaded State
    final mockBanner = ShopBanner(
      id: 1,
      title: 'Summer Sale',
      image: 'banner.png',
      subtitle: 'Up to 50% off',
      buttonText: 'Shop Now',
    );
    final mockCategory = ShopCategory(
      id: 1,
      name: 'Jerseys',
      icon: 'jersey.png',
    );
    final mockProduct = ShopProduct(
      id: 1,
      name: 'Home Jersey 23/24',
      description: 'Official home kit',
      price: 2500,
      image: 'home_jersey.png',
      isFavourite: false,
    );

    when(() => mockRepo.getBanners()).thenAnswer((_) async => [mockBanner]);
    when(() => mockRepo.getCategories()).thenAnswer((_) async => [mockCategory]);
    when(() => mockRepo.getNewArrivals()).thenAnswer((_) async => [mockProduct]);
    when(() => mockRepo.getTopPicks()).thenAnswer((_) async => [mockProduct]);
    when(() => mockRepo.getCategoryProducts(1)).thenAnswer((_) async => [mockProduct]);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          shopRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(home: Shop()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SUMMER SALE'), findsOneWidget); // Banner title is uppercase
    expect(find.text('Up to 50% off'), findsOneWidget);

    // Scroll down because Categories are off-screen
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Jerseys'), findsWidgets); // Category tab
    expect(find.text('Home Jersey 23/24'), findsWidgets); // Shown in new arrivals and top picks
  });
}
