import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/auth/login.dart';
import 'package:kogalo_network/pages/auth/signup.dart';
import 'package:kogalo_network/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kogalo_network/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

// A fake user model to return on login success
final fakeUser = UserModel(
  id: 1,
  firstName: 'Test',
  lastName: 'User',
  email: 'test@example.com',
  phoneNumber: '1234567890',
  eventsAttended: 0,
  upcomingEvents: 0,
);

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    mockAuthRepository = MockAuthRepository();
  });

  Widget createLoginWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: const MaterialApp(
        home: Login(),
      ),
    );
  }

  Widget createSignupWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: const MaterialApp(
        home: Signup(),
      ),
    );
  }

  group('Login Flow Tests', () {
    testWidgets('Shows validation errors on empty submission', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginWidget());
      await tester.pumpAndSettle();

      final signInButton = find.text('Sign In');
      expect(signInButton, findsOneWidget);

      await tester.tap(signInButton);
      await tester.pump(); // Start animation
      await tester.pump(const Duration(seconds: 1)); // wait for it

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Shows error snackbar on login failure', (WidgetTester tester) async {
      when(() => mockAuthRepository.login(any(), any()))
          .thenThrow(Exception('Invalid email or password.'));

      await tester.pumpWidget(createLoginWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'wrong@email.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');

      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // Wait for error to propagate

      expect(find.text('Invalid email or password.'), findsOneWidget);
    });


  });

  group('Signup Flow Tests', () {
    testWidgets('Shows validation errors on empty submission', (WidgetTester tester) async {
      await tester.pumpWidget(createSignupWidget());
      await tester.pumpAndSettle();

      final nextButton = find.text('Next');
      expect(nextButton, findsOneWidget);

      // Scroll down to the button to make it visible before tapping
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.tap(nextButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Please enter your first name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Validates password match', (WidgetTester tester) async {
      await tester.pumpWidget(createSignupWidget());
      await tester.pumpAndSettle();

      // Enter mismatched passwords
      await tester.enterText(find.byType(TextFormField).at(5), 'password123'); // Password
      await tester.enterText(find.byType(TextFormField).at(6), 'password456'); // Confirm Password

      // Scroll to Next
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
