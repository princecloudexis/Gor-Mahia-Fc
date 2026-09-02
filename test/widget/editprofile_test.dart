import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/profile/editprofile.dart';
import 'package:kogalo_network/models/user_model.dart';

void main() {
  testWidgets('EditProfile renders user data and validates fields', (WidgetTester tester) async {
    final user = UserModel(
      id: 1,
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phoneNumber: '1234567890',
      eventsAttended: 0,
      upcomingEvents: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EditProfile(user: user),
        ),
      ),
    );

    // Wait for animations/images
    await tester.pumpAndSettle();

    // Verify initial values are populated
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Doe'), findsOneWidget);
    expect(find.text('john@example.com'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);

    // Clear First Name field to trigger validation
    await tester.enterText(find.byType(TextFormField).first, '');
    
    // Tap Save Changes (which should be on the FAB)
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify validation error appears
    expect(find.text('Please enter your First Name'), findsOneWidget);
  });
}
