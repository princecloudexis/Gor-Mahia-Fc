import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:kogalo_network/pages/reels/reels_feed.dart';
import 'package:kogalo_network/models/reels_model.dart';
import 'package:kogalo_network/repositories/reels_repository.dart';
import 'package:kogalo_network/providers/reels_providers.dart';
import 'package:kogalo_network/providers/navigation_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

class MockReelsRepository extends Mock implements ReelsRepository {}

void main() {
  late MockReelsRepository mockReelsRepo;

  setUp(() {
    mockReelsRepo = MockReelsRepository();
  });

  testWidgets('ReelsFeed renders loading, empty, and data states', (WidgetTester tester) async {
    await mockNetworkImagesFor(() async {
      final mockReelResponse = ReelResponse(
        data: [
          Reel(
            id: '1',
            authorId: '1',
            postedBy: '1',
            videoUrl: 'https://example.com/video1.mp4',
            caption: 'Test Reel 1',
            likesCount: 10,
            commentsCount: 5,
            sharesCount: 2,
            isLikedByMe: false,
            authorName: 'Test Author',
          ),
        ],
        meta: ReelPagination(
          hasNextPage: false,
          nextCursor: null,
        ),
      );

      // 1. Loading State
      final reelsCompleter = Completer<ReelResponse>();
      when(() => mockReelsRepo.fetchReels()).thenAnswer((_) => reelsCompleter.future);
      
      // Allow logView to be called
      when(() => mockReelsRepo.viewReel(any(), watchedSeconds: any(named: 'watchedSeconds')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            reelsRepositoryProvider.overrideWithValue(mockReelsRepo),
            mainShellTabIndexProvider.overrideWith((ref) => 1), // Reels is active
          ],
          child: const MaterialApp(home: Scaffold(body: ReelsFeed())),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // 2. Empty State
      reelsCompleter.complete(ReelResponse(data: [], meta: null));
      await tester.pumpAndSettle();

      expect(find.text('No reels found.'), findsOneWidget);

      // 3. Loaded State
      when(() => mockReelsRepo.fetchReels()).thenAnswer((_) async => mockReelResponse);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            reelsRepositoryProvider.overrideWithValue(mockReelsRepo),
            mainShellTabIndexProvider.overrideWith((ref) => 1),
          ],
          child: const MaterialApp(home: Scaffold(body: ReelsFeed())),
        ),
      );
      await tester.pumpAndSettle();
      
      // The author name should be visible
      expect(find.text('@Test Author'), findsWidgets);
      // The caption should be visible
      expect(find.text('Test Reel 1'), findsOneWidget);

      // Flush all timers created by ReelsPreloadManager to prevent pending timer errors
      await tester.pump(const Duration(seconds: 15));
    });
  });
}
