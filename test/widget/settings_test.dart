import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/settings.dart';
import 'package:kogalo_network/providers/theme_provider.dart';

void main() {
  testWidgets('Settings renders theme options and handles logout dialog', (WidgetTester tester) async {
    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Settings(),
        ),
      ),
    );

    // Verify theme options exist
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System Default'), findsOneWidget);

    // Test Theme toggle
    expect(container.read(themeProvider), ThemeModeOption.dark);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(container.read(themeProvider), ThemeModeOption.light);

    // Verify logout button exists
    expect(find.text('Log Out'), findsWidgets);

    // Tap logout button
    await tester.tap(find.text('Log Out').first);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);

    container.dispose();
  });
}
