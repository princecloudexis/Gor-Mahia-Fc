import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/membership/my_membership.dart';
import 'package:kogalo_network/models/user_model.dart';
import 'package:kogalo_network/models/membership_models.dart';
import 'package:kogalo_network/repositories/auth_repository.dart';
import 'package:kogalo_network/repositories/membership_repository.dart';
import 'package:kogalo_network/providers/user_providers.dart';
import 'package:kogalo_network/controllers/membership_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockMembershipRepository mockMembershipRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockMembershipRepo = MockMembershipRepository();
  });

  testWidgets('MyMembership renders loading, empty/free plan, and active plan states', (WidgetTester tester) async {
    final mockUser = UserModel(
      id: 1,
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      phoneNumber: '1234567890',
      eventsAttended: 0,
      upcomingEvents: 0,
    );

    final mockDetailsFree = MembershipDetails(
      memberName: 'Test User',
      membershipType: 'Free Plan',
      memberId: null,
      status: 'Inactive',
    );

    final mockDetailsActive = MembershipDetails(
      memberName: 'Test User',
      membershipType: 'Gold Plan',
      memberId: 'GM12345',
      status: 'Active',
      validUntil: '2027-01-01',
      branch: 'Nairobi',
    );

    final mockRenewalStatus = MembershipRenewalStatus(
      needsRenewal: false,
      validUntil: '2027-01-01',
      daysRemaining: 365,
      renewalWindowDays: 7,
    );

    // 1. Loading State
    final detailsCompleter = Completer<MembershipDetails>();
    final renewalCompleter = Completer<MembershipRenewalStatus>();

    when(() => mockAuthRepo.getMembershipDetails()).thenAnswer((_) => detailsCompleter.future);
    when(() => mockMembershipRepo.getRenewalStatus()).thenAnswer((_) => renewalCompleter.future);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          membershipRepositoryProvider.overrideWithValue(mockMembershipRepo),
          userProvider.overrideWith((ref) => UserNotifier(mockAuthRepo)..updateUser(mockUser)),
        ],
        child: const MaterialApp(home: MyMembership()),
      ),
    );

    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    // Resolve as Free Plan
    detailsCompleter.complete(mockDetailsFree);
    renewalCompleter.complete(mockRenewalStatus);
    await tester.pumpAndSettle();

    // 2. Free Plan State
    expect(find.text('Free Plan'), findsWidgets); // Shown in card header and details list
    expect(find.text('Purchase Membership'), findsOneWidget); // Shown for free plans

    // 3. Active Plan State
    when(() => mockAuthRepo.getMembershipDetails()).thenAnswer((_) async => mockDetailsActive);
    when(() => mockMembershipRepo.getRenewalStatus()).thenAnswer((_) async => mockRenewalStatus);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          membershipRepositoryProvider.overrideWithValue(mockMembershipRepo),
          userProvider.overrideWith((ref) => UserNotifier(mockAuthRepo)..updateUser(mockUser)),
        ],
        child: const MaterialApp(home: MyMembership()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gold Plan'), findsWidgets);
    expect(find.text('Member ID: GM12345'), findsOneWidget);
    expect(find.text('Nairobi'), findsOneWidget);
    expect(find.text('Purchase Membership'), findsNothing); // Not shown for active plans
    expect(find.text('Membership Renewal'), findsOneWidget); // Shown for active plans
  });
}
