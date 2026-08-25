import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/settings.dart';
import 'package:kogalo_network/pages/help_and_support.dart';
import 'package:kogalo_network/pages/policy.dart';
import 'package:kogalo_network/models/policy_model.dart';
import 'package:kogalo_network/models/user_model.dart';
import 'package:kogalo_network/providers/user_providers.dart';
import 'package:kogalo_network/providers/theme_provider.dart';
import 'package:kogalo_network/controllers/auth_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

class MockAuthController extends StateNotifier<AuthState> with Mock implements AuthController {
  MockAuthController() : super(const AuthState());
}

class MockUserNotifier extends StateNotifier<UserModel?> with Mock implements UserNotifier {
  MockUserNotifier(super.state);
}

void main() {
  group('Utilities Tests', () {
    testWidgets('Settings renders theme options and logout', (WidgetTester tester) async {
      final mockAuthController = MockAuthController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => mockAuthController),
            themeProvider.overrideWith((ref) => ThemeNotifier()),
          ],
          child: const MaterialApp(home: Settings()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Tap Log Out
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      
      // Dialog appears
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('HelpAndSupport renders form and populates user info', (WidgetTester tester) async {
      final mockUser = UserModel(
        id: 1,
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phoneNumber: '1234567890',
        eventsAttended: 0,
        upcomingEvents: 0,
      );
      
      final mockUserNotifier = MockUserNotifier(mockUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => mockUserNotifier),
          ],
          child: const MaterialApp(home: HelpAndSupport()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);
      expect(find.text('John'), findsOneWidget); // First Name
      expect(find.text('Doe'), findsOneWidget); // Last Name
      expect(find.text('john.doe@example.com'), findsOneWidget); // Email
      expect(find.text('1234567890'), findsOneWidget); // Phone Number
      
      expect(find.text('Send Message'), findsOneWidget);
    });

    testWidgets('PolicyPage renders loading, empty, and loaded states', (WidgetTester tester) async {
      final policyCompleter = Completer<List<PolicyModel>>();
      final testPolicyProvider = FutureProvider.autoDispose<List<PolicyModel>>((ref) {
        return policyCompleter.future;
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PolicyPage(
              title: 'Privacy Policy',
              contentProvider: testPolicyProvider,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Loading state (shimmer might not be easily found by text, but we know it's not error/empty)
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('No Content Available'), findsNothing);

      // Complete with empty
      policyCompleter.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('No Content Available'), findsOneWidget);

      // Now loaded state (we need a new widget/provider to simulate loaded state easily)
      final loadedPolicyProvider = FutureProvider.autoDispose<List<PolicyModel>>((ref) async {
        return [
          PolicyModel(id: 1, title: 'Data Collection', description: 'We collect your data'),
        ];
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PolicyPage(
              title: 'Privacy Policy',
              contentProvider: loadedPolicyProvider,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Collection'), findsOneWidget);
      
      // Tap to expand the policy item
      await tester.tap(find.text('Data Collection'));
      await tester.pumpAndSettle();
      
      expect(find.text('We collect your data'), findsOneWidget);
    });
  });
}
