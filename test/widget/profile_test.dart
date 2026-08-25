import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/profile.dart';
import 'package:kogalo_network/controllers/auth_controller.dart';
import 'package:kogalo_network/providers/user_providers.dart';
import 'package:kogalo_network/models/user_model.dart';
import 'package:kogalo_network/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

// Fake AuthController to force state
class FakeAuthController extends AuthController {
  FakeAuthController(AuthRepository repo, UserNotifier userNotifier, Ref ref) 
      : super(repo, userNotifier, ref) {
    state = const AuthState(status: AuthStatus.authenticated, token: 'token');
  }
}

// Fake UserNotifier
class FakeUserNotifier extends UserNotifier {
  FakeUserNotifier(AuthRepository repo, UserModel? initialUser) : super(repo) {
    state = initialUser;
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Widget createProfileWidget(UserModel? user) {
    final mockRepo = MockAuthRepository();
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        userProvider.overrideWith((ref) => FakeUserNotifier(mockRepo, user)),
        authControllerProvider.overrideWith((ref) => FakeAuthController(mockRepo, ref.watch(userProvider.notifier), ref)),
      ],
      child: const MaterialApp(
        home: Profile(),
      ),
    );
  }

  group('Profile UI Tests', () {
    testWidgets('Shows loading or fail state if user is null', (WidgetTester tester) async {
      await tester.pumpWidget(createProfileWidget(null));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load profile'), findsOneWidget);
    });

    testWidgets('Shows authenticated view when user exists', (WidgetTester tester) async {
      final user = UserModel(
        id: 1,
        firstName: 'Gor',
        lastName: 'Mahia',
        email: 'fan@gormahia.com',
        phoneNumber: '1234567890',
        eventsAttended: 5,
        upcomingEvents: 2,
      );

      await tester.pumpWidget(createProfileWidget(user));
      await tester.pumpAndSettle();

      expect(find.text('Gor Mahia'), findsOneWidget);
      expect(find.text('fan@gormahia.com'), findsOneWidget);
      expect(find.text('My Reels'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
