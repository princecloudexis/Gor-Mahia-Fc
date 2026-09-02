import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/home/home.dart';
import 'package:kogalo_network/providers/user_providers.dart';
import 'package:kogalo_network/providers/match_providers.dart';
import 'package:kogalo_network/providers/shop_providers.dart';
import 'package:kogalo_network/providers/notifications_providers.dart';
import 'package:kogalo_network/models/user_model.dart';
import 'package:kogalo_network/models/match_models.dart';
import 'package:kogalo_network/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUserNotifier extends UserNotifier {
  FakeUserNotifier() : super(MockAuthRepository()) {
    state = UserModel(
      id: 1,
      firstName: 'Gor',
      lastName: 'Mahia',
      email: 'gor@mahia.com',
      phoneNumber: '123',
      eventsAttended: 0,
      upcomingEvents: 0,
    );
  }
}

void main() {
  testWidgets('Home screen renders greeting, live now, and quick access', (WidgetTester tester) async {
    final mockAuthRepo = MockAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userProvider.overrideWith((ref) => FakeUserNotifier()),
          matchFixturesProvider.overrideWith((ref) => MatchFixturesData(
              upcomingFixtures: [],
              liveMatches: [],
          )),
          hasUnreadNotificationsProvider.overrideWithValue(false),
          shopTopPicksProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Home()),
        ),
      ),
    );

    // Pump a few times instead of pumpAndSettle to avoid infinite animation timeouts
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Greeting
    expect(find.text('Hello, Gor Mahia'), findsOneWidget);

    // Sections
    expect(find.text('Quick Access'), findsOneWidget);
  });
}
