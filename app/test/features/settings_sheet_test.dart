import 'package:ani/app_shell.dart';
import 'package:ani/features/home/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/farm_harness.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

void main() {
  testWidgets('settings sheet shows logout and cancels without logging out', (tester) async {
    final h = await FarmHarness.start(tester, today: DateTime.utc(2026, 11, 15));
    await h.pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showSettingsSheet(context),
            child: const Text('open-settings'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-settings'));
    await tester.pumpAndSettle();

    // Verify logout tile is present
    expect(_key('settings-logout'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    // Tap logout
    await tester.tap(_key('settings-logout'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
    expect(_key('settings-logout-cancel'), findsOneWidget);
    expect(_key('settings-logout-confirm'), findsOneWidget);

    // Tap cancel
    await tester.tap(_key('settings-logout-cancel'));
    await tester.pumpAndSettle();

    // Dialog is dismissed, app state still has onboarding complete
    expect(find.text('Are you sure you want to log out?'), findsNothing);
    expect(h.state.onboardingComplete, isTrue);
  });

  testWidgets('settings sheet logs out on confirmation', (tester) async {
    final h = await FarmHarness.start(tester, today: DateTime.utc(2026, 11, 15));
    await h.pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showSettingsSheet(context),
            child: const Text('open-settings'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-settings'));
    await tester.pumpAndSettle();

    await tester.tap(_key('settings-logout'));
    await tester.pumpAndSettle();

    // Confirm logout
    await tester.tap(_key('settings-logout-confirm'));
    await tester.pumpAndSettle();

    // State is reset
    expect(h.state.onboardingComplete, isFalse);
    expect(h.state.town, isNull);
    expect(h.state.localeCode, isNull);
  });

  testWidgets('settings sheet logout in Filipino locale', (tester) async {
    final h = await FarmHarness.start(tester, locale: 'fil', today: DateTime.utc(2026, 11, 15));
    await h.pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showSettingsSheet(context),
            child: const Text('open-settings'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-settings'));
    await tester.pumpAndSettle();

    expect(find.text('Mag-log out'), findsOneWidget);

    await tester.tap(_key('settings-logout'));
    await tester.pumpAndSettle();

    expect(find.text('Sigurado ka bang nais mong mag-log out?'), findsOneWidget);
    expect(find.text('Kanselahin'), findsOneWidget);
  });

  testWidgets('settings button is present in headers of Outlook, Library, and Farm screens', (tester) async {
    final h = await FarmHarness.start(tester, today: DateTime.utc(2026, 11, 15));
    await h.pump(tester, const AppShell());
    await tester.pumpAndSettle();

    // Home has home-settings
    expect(_key('home-settings'), findsOneWidget);

    // Switch to Outlook tab
    await tester.tap(find.text('Outlook'));
    await tester.pumpAndSettle();
    expect(_key('outlook-settings'), findsOneWidget);

    // Open settings from Outlook
    await tester.tap(_key('outlook-settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    Navigator.of(tester.element(find.text('Settings'))).pop();
    await tester.pumpAndSettle();

    // Switch to Crops / Library tab
    await tester.tap(find.text('Crops'));
    await tester.pumpAndSettle();
    expect(_key('library-settings'), findsOneWidget);

    // Switch to Farm tab
    await tester.tap(find.text('My farm'));
    await tester.pumpAndSettle();
    expect(_key('farm-settings'), findsOneWidget);
  });
}
