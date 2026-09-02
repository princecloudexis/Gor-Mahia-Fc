import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/shop/shop_cart.dart';
import 'package:kogalo_network/models/shop_models.dart';
import 'package:kogalo_network/providers/shop_providers.dart';
import 'package:kogalo_network/repositories/shop_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockShopRepository extends Mock implements ShopRepository {}

void main() {
  late MockShopRepository mockRepo;
  late ShopCart mockCart;

  setUp(() {
    mockRepo = MockShopRepository();
    
    mockCart = ShopCart(
      id: 1,
      cartTotal: 1500,
      subtotal: 1500,
      platformCharge: 0,
      totalPaymentCharge: 0,
      items: [
        ShopCartItem(
          id: 1,
          quantity: 1,
          effectivePrice: 1500,
          product: ShopCartProduct(id: 1, name: 'Home Jersey', price: 1500),
        )
      ],
    );
  });

  testWidgets('ShopCartPage renders items and handles quantity updates', (WidgetTester tester) async {
    when(() => mockRepo.updateCartItem(1, 2)).thenAnswer((_) async {});
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shopRepositoryProvider.overrideWithValue(mockRepo),
          shopCartProvider.overrideWith((ref) => mockCart),
        ],
        child: const MaterialApp(home: ShopCartPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home Jersey'), findsOneWidget);
    expect(find.text('KSh 1500.00'), findsWidgets);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    verify(() => mockRepo.updateCartItem(1, 2)).called(1);
  });

  testWidgets('ShopCartPage renders empty state', (WidgetTester tester) async {
    final emptyCart = ShopCart(
      id: 1,
      cartTotal: 0,
      subtotal: 0,
      platformCharge: 0,
      totalPaymentCharge: 0,
      items: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shopCartProvider.overrideWith((ref) => emptyCart),
        ],
        child: const MaterialApp(home: ShopCartPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Continue Shopping'), findsOneWidget);
  });
}
