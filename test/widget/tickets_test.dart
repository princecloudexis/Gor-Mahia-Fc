import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/tickets/tickets.dart';
import 'package:kogalo_network/pages/home/home_dashboard_sections.dart';
import 'package:kogalo_network/repositories/event_repositories.dart';
import 'package:kogalo_network/models/user_ticket_model.dart';
import 'package:kogalo_network/models/event_model.dart';
import 'package:kogalo_network/api/api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepo;

  setUp(() {
    mockRepo = MockEventRepository();
  });

  testWidgets('Tickets Page renders loading, error, empty, and loaded states', (WidgetTester tester) async {
    // 1. Loading State (unresolved completer)
    final upcomingCompleter = Completer<List<UserTicketModel>>();
    final pastCompleter = Completer<List<UserTicketModel>>();

    when(() => mockRepo.getTickets(tab: 'upcoming')).thenAnswer((_) => upcomingCompleter.future);
    when(() => mockRepo.getTickets(tab: 'past')).thenAnswer((_) => pastCompleter.future);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(home: Tickets()),
      ),
    );

    // Initial frame has loading shimmers
    await tester.pump();
    expect(find.byType(ListView), findsWidgets);
    
    // Resolve futures with empty data
    upcomingCompleter.complete(<UserTicketModel>[]);
    pastCompleter.complete(<UserTicketModel>[]);

    // Pump and settle to let the empty state rebuild
    await tester.pumpAndSettle();

    // 2. Empty State
    expect(find.text('No Upcoming Tickets'), findsOneWidget);

    // Switch to Past tab
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    expect(find.text('No Past Tickets'), findsOneWidget);

    // 3. Error State
    when(() => mockRepo.getTickets(tab: 'upcoming')).thenThrow(Exception('Failed to load tickets'));

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(home: Tickets()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to load tickets'), findsOneWidget);

    // 4. Loaded State
    final mockEvent = EventModel(
      id: 1,
      eventName: 'Derby Match',
      eventDescription: 'Gor Mahia vs AFC Leopards',
      eventStartDate: DateTime.now().add(const Duration(days: 1)),
      eventEndDate: DateTime.now().add(const Duration(days: 1, hours: 2)),
      slug: 'derby-match',
      venueName: 'Nyayo Stadium',
      totalPurchased: 0,
      tags: [],
      hideVenueFromUser: false,
      symbol: 'KSh',
    );
    final mockTicket = UserTicketModel(
      eventId: 1,
      totalQuantity: 2,
      event: mockEvent,
    );

    when(() => mockRepo.getTickets(tab: 'upcoming')).thenAnswer((_) async => [mockTicket]);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockRepo),
          storageBaseUrlProvider.overrideWithValue('https://storage.com'),
        ],
        child: const MaterialApp(home: Tickets()),
      ),
    );
    await tester.pumpAndSettle();
    
    // Switch back to Upcoming tab
    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();

    expect(find.text('Derby Match'), findsOneWidget);
    expect(find.text('2 Tickets'), findsOneWidget);
    expect(find.text('View Ticket'), findsOneWidget);
  });
}
