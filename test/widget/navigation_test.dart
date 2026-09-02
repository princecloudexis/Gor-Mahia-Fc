import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/home/main_shell.dart';
import 'package:kogalo_network/providers/navigation_providers.dart';

void main() {
  group('MainShell Navigation Tests', () {
    testWidgets('Renders MainShell with correct initial tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShell(),
          ),
        ),
      );
      // MainShell uses infinite animations for reels, so we shouldn't use pumpAndSettle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Home should be selected by default (index 0)
      expect(find.text('Home'), findsWidgets); // Nav label
      expect(find.text('Reels'), findsWidgets);
      expect(find.text('Community'), findsWidgets);
      expect(find.text('Contributions'), findsWidgets);
      expect(find.text('Matches'), findsWidgets);
    });

    testWidgets('Tapping bottom nav changes tab index', (WidgetTester tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MainShell(),
          ),
        ),
      );
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(mainShellTabIndexProvider), 0);

      // Tap on Community tab
      await tester.tap(find.byIcon(Icons.groups_outlined).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(mainShellTabIndexProvider), 2);
      
      // Tap on Matches tab
      await tester.tap(find.byIcon(Icons.sports_soccer_outlined).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(mainShellTabIndexProvider), 4);
      
      container.dispose();
    });
  });
}
