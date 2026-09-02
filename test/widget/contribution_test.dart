import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/membership/monthly_contribution.dart';
import 'package:kogalo_network/repositories/contribution_repository.dart';
import 'package:kogalo_network/models/contribution_models.dart';
import 'package:mocktail/mocktail.dart';

class MockContributionRepository extends Mock implements ContributionRepository {}

void main() {
  late MockContributionRepository mockRepo;

  setUp(() {
    mockRepo = MockContributionRepository();
  });

  testWidgets('Monthly Contribution renders error states', (WidgetTester tester) async {
    when(() => mockRepo.getContributionCount()).thenThrow(Exception('Failed count'));
    when(() => mockRepo.getContributions('pending', 1)).thenThrow(Exception('Failed pending'));
    when(() => mockRepo.getContributions('paid', 1)).thenThrow(Exception('Failed paid'));
    when(() => mockRepo.getContributionHistory(1)).thenThrow(Exception('Failed history'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contributionRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(home: MonthlyContribution()),
      ),
    );
    await tester.pumpAndSettle();
    
    expect(find.textContaining('Failed count'), findsOneWidget);
    expect(find.textContaining('Failed pending'), findsOneWidget);
  });

  testWidgets('Monthly Contribution renders empty state', (WidgetTester tester) async {
    when(() => mockRepo.getContributionCount()).thenAnswer((_) async => ContributionCount(
      totalContributed: 0,
      contributedThisMonth: 0,
      currency: 'KSh',
    ));
    when(() => mockRepo.getContributions('pending', 1)).thenAnswer((_) async => ContributionResponse(
      tab: 'pending',
      items: [],
      pagination: ContributionPagination(currentPage: 1, perPage: 10, total: 0, lastPage: 1, hasMorePages: false),
    ));
    when(() => mockRepo.getContributions('paid', 1)).thenAnswer((_) async => ContributionResponse(
      tab: 'paid',
      items: [],
      pagination: ContributionPagination(currentPage: 1, perPage: 10, total: 0, lastPage: 1, hasMorePages: false),
    ));
    when(() => mockRepo.getContributionHistory(1)).thenAnswer((_) async => ContributionHistoryResponse(
      items: [],
      pagination: ContributionPagination(currentPage: 1, perPage: 10, total: 0, lastPage: 1, hasMorePages: false),
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contributionRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(home: MonthlyContribution()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KSh 0'), findsWidgets);
    expect(find.text('No pending contributions.'), findsOneWidget);
  });

  testWidgets('Monthly Contribution renders loaded data and shows payment dialog', (WidgetTester tester) async {
    final mockContribution = Contribution(
      participantId: 1,
      contributionId: 1,
      title: 'October Contribution',
      description: 'Monthly club dues',
      amountDue: 500,
      amountPaid: 0,
      balance: 500,
      currency: 'KSh',
      minimumAmount: 100,
      isFullyFunded: false,
      status: 'pending',
      dueDate: '2023-10-31',
      canPay: true,
      totalAmount: 10000,
      amountCollected: 1000,
      remainingToTarget: 9000,
    );

    when(() => mockRepo.getContributionCount()).thenAnswer((_) async => ContributionCount(
      totalContributed: 5000,
      contributedThisMonth: 1000,
      currency: 'KSh',
    ));
    when(() => mockRepo.getContributions('pending', 1)).thenAnswer((_) async => ContributionResponse(
      tab: 'pending',
      items: [mockContribution],
      pagination: ContributionPagination(currentPage: 1, perPage: 10, total: 1, lastPage: 1, hasMorePages: false),
    ));
    when(() => mockRepo.getContributions('paid', 1)).thenAnswer((_) async => ContributionResponse(
      tab: 'paid',
      items: [],
      pagination: ContributionPagination(currentPage: 1, perPage: 10, total: 0, lastPage: 1, hasMorePages: false),
    ));
    when(() => mockRepo.getContributionHistory(1)).thenAnswer((_) async => ContributionHistoryResponse(
      items: [],
      pagination: ContributionPagination(currentPage: 1, perPage: 10, total: 0, lastPage: 1, hasMorePages: false),
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contributionRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(home: MonthlyContribution()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KSh 5000'), findsOneWidget);
    expect(find.text('KSh 1000'), findsOneWidget);
    expect(find.text('October Contribution'), findsOneWidget);
    expect(find.text('Pay Now'), findsOneWidget);
    
    // Test clicking Pay Now shows bottom sheet
    await tester.ensureVisible(find.text('Pay Now'));
    await tester.tap(find.text('Pay Now'));
    await tester.pumpAndSettle();
    
    expect(find.text('Complete Payment'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
  });
}
