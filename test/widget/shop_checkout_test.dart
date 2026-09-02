import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/shop/shop_checkout.dart';

void main() {
  testWidgets('ShopCheckoutPage renders cart total and validates fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ShopCheckoutPage(cartTotal: 1500.00)),
      ),
    );

    await tester.pumpAndSettle();

    // Verify cart total
    expect(find.text('KSh 1500.00'), findsOneWidget);

    // Tap checkout without entering anything (fields are empty because userProvider is null)
    await tester.ensureVisible(find.text('Place Order & Pay Online'));
    await tester.tap(find.text('Place Order & Pay Online'));
    await tester.pumpAndSettle();

    // Verify validation errors
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your phone number'), findsOneWidget);
    expect(find.text('Please enter your delivery address'), findsOneWidget);
  });
}
