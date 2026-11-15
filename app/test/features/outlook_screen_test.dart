import 'package:ani/data/bundle.dart';
import 'package:ani/data/power_client.dart';
import 'package:ani/features/home/home_screen.dart';
import 'package:ani/features/outlook/outlook_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/live_outlook_test.dart' show weatherDays;
import '../support/farm_harness.dart';

final _today = DateTime.utc(2026, 11, 15);

Future<FarmHarness> _start(WidgetTester tester, List<DailyWeather> days, {String locale = 'en'}) async {
  final h = await FarmHarness.start(tester,
      locale: locale, today: _today, weather: {Town.guimba: days}, size: const Size(900, 4000));
  await h.pump(tester, const Scaffold(body: OutlookScreen()));
  await tester.runAsync(() => h.state.refreshLive());
  await tester.pumpAndSettle();
  return h;
}

Finder _in(String key, Finder f) => find.descendant(of: find.byKey(ValueKey(key)), matching: f);

void main() {
  setUp(BundleLoader.instance.clear);

  testWidgets('offline (empty cache): bundled dryness.latest, El Niño tag, past seasons, chart', (tester) async {
    final h = await _start(tester, const []);
    final b = h.state.bundle!;
    expect(_in('outlook-enso', find.text('El Niño expected this dry season')), findsOneWidget);
    expect(_in('outlook-enso', find.text('Very strong')), findsOneWidget);
    // bundled fallback
    expect(_in('outlook-live', find.text('Normal')), findsOneWidget);
    expect(_in('outlook-live', find.text('D -1.45')), findsOneWidget);
    expect(find.byKey(const ValueKey('outlook-live-source')), findsOneWidget);
    expect(find.textContaining('Saved reading for ${b.dryness.latest.month}'), findsOneWidget);
    // past seasons: table header and initial 5 stacked rows with dividing lines
    expect(_in('outlook-past', find.byKey(const ValueKey('outlook-past-header-season'))), findsOneWidget);
    expect(_in('outlook-past', find.text('Season')), findsOneWidget);
    expect(_in('outlook-past', find.text('Status')), findsWidgets);
    expect(_in('outlook-past', find.text('2024-25')), findsOneWidget);
    expect(_in('outlook-past', find.text('2022-23')), findsOneWidget);
    expect(_in('outlook-past', find.text('2015-16')), findsNothing);
    expect(_in('outlook-past', find.byType(Divider)), findsWidgets);
    expect(_in('outlook-past', find.text('Show more')), findsOneWidget);
    // expand to show all
    await tester.tap(find.byKey(const ValueKey('outlook-past-toggle')));
    await tester.pumpAndSettle();
    expect(_in('outlook-past', find.text('2015-16')), findsOneWidget);
    expect(_in('outlook-past', find.text('Show less')), findsOneWidget);
    // collapse back
    await tester.tap(find.byKey(const ValueKey('outlook-past-toggle')));
    await tester.pumpAndSettle();
    expect(_in('outlook-past', find.text('2015-16')), findsNothing);
    // chart + legend
    expect(find.byKey(const ValueKey('outlook-chart')), findsOneWidget);
    expect(find.byKey(const ValueKey('outlook-chart-legend')), findsOneWidget);
    // heat: no live data
    expect(find.byKey(const ValueKey('heat-no-live')), findsOneWidget);
    expect(find.text('Work early'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live dry cache: live D, Delikado and the dekad list replace the bundled value', (tester) async {
    final h = await _start(tester, weatherDays(DateTime.utc(2026, 1, 1), DateTime.utc(2026, 11, 14), et0: 7, gwet: 0.05));
    final live = h.state.live!;
    expect(live.hasLiveD, isTrue);
    expect(tester.widget<Text>(find.byKey(const ValueKey('outlook-live-label'))).data, 'Danger');
    expect(find.textContaining('Live from NASA POWER'), findsOneWidget);
    expect(_in('outlook-live', find.textContaining('so far')), findsOneWidget);
    expect(_in('outlook-live', find.byType(Divider)), findsWidgets);
    expect(_in('outlook-live', find.byKey(const ValueKey('outlook-header-period'))), findsOneWidget);
    expect(_in('outlook-live', find.text('Period')), findsOneWidget);
    expect(_in('outlook-live', find.text('Dryness (D)')), findsOneWidget);
    expect(_in('outlook-live', find.text('Status')), findsOneWidget);
    expect(find.textContaining('Saved reading'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('danger-day heat shows Magtrabaho nang maaga on Outlook and Home', (tester) async {
    final days = [
      ...weatherDays(DateTime.utc(2026, 11, 1), DateTime.utc(2026, 11, 10)),
      ...weatherDays(DateTime.utc(2026, 11, 11), DateTime.utc(2026, 11, 13), tmax: 38, tdew: 28),
    ];
    final h = await _start(tester, days);
    expect(_in('outlook-heat', find.byKey(const ValueKey('heat-live-work-early'))), findsOneWidget);
    expect(find.byKey(const ValueKey('outlook-heat-danger-days')), findsOneWidget);
    expect(_in('outlook-heat', find.byKey(const ValueKey('heat-live-reading'))), findsOneWidget);

    // heat table headers
    expect(_in('outlook-heat', find.byKey(const ValueKey('outlook-heat-header-date'))), findsOneWidget);
    expect(_in('outlook-heat', find.text('Date')), findsOneWidget);
    expect(_in('outlook-heat', find.byKey(const ValueKey('outlook-heat-header-index'))), findsOneWidget);
    expect(_in('outlook-heat', find.text('Heat index (°C)')), findsOneWidget);
    expect(_in('outlook-heat', find.byKey(const ValueKey('outlook-heat-header-status'))), findsOneWidget);

    // initial 5 rows + toggle
    expect(_in('outlook-heat', find.byType(Divider)), findsWidgets);
    expect(_in('outlook-heat', find.text('Show more')), findsOneWidget);
    expect(_in('outlook-heat', find.text('Nov 13')), findsOneWidget);
    expect(_in('outlook-heat', find.text('Nov 9')), findsOneWidget);
    expect(_in('outlook-heat', find.text('Nov 8')), findsNothing);

    // expand to show all 7 days
    await tester.tap(find.byKey(const ValueKey('outlook-heat-toggle')));
    await tester.pumpAndSettle();
    expect(_in('outlook-heat', find.text('Nov 8')), findsOneWidget);
    expect(_in('outlook-heat', find.text('Nov 7')), findsOneWidget);
    expect(_in('outlook-heat', find.text('Show less')), findsOneWidget);

    // collapse back
    await tester.tap(find.byKey(const ValueKey('outlook-heat-toggle')));
    await tester.pumpAndSettle();
    expect(_in('outlook-heat', find.text('Nov 8')), findsNothing);
    expect(_in('outlook-heat', find.text('Show more')), findsOneWidget);

    await h.pump(tester, const Scaffold(body: HomeScreen()));
    expect(_in('home-heat', find.byKey(const ValueKey('heat-live-reading'))), findsOneWidget);
    expect(_in('home-heat', find.byKey(const ValueKey('heat-live-work-early'))), findsOneWidget);
  });

  testWidgets('cool day: live reading but no work-early line from the live reading; Filipino strings', (tester) async {
    final h = await _start(tester, weatherDays(DateTime.utc(2026, 11, 1), DateTime.utc(2026, 11, 13), tmax: 29, tdew: 20),
        locale: 'fil');
    expect(find.byKey(const ValueKey('heat-live-reading')), findsOneWidget);
    expect(find.byKey(const ValueKey('heat-live-work-early')), findsNothing);
    expect(find.text('Tanaw sa panahon'), findsOneWidget);
    expect(find.textContaining('Naka-save na basa'), findsOneWidget); // 13 days cached: too thin to score, bundled D
    expect(h.l.localeName, 'fil');
  });

  testWidgets('live dry cache in Filipino: Petsa, Tuyot (D), Katayuan without overflow on small screen', (tester) async {
    final h = await FarmHarness.start(
      tester,
      locale: 'fil',
      today: _today,
      weather: {
        Town.guimba: weatherDays(DateTime.utc(2026, 1, 1), DateTime.utc(2026, 11, 14), et0: 7, gwet: 0.05),
      },
      size: const Size(360, 640),
    );
    await h.pump(tester, const Scaffold(body: OutlookScreen()));
    await tester.runAsync(() => h.state.refreshLive());
    await tester.pumpAndSettle();
    expect(_in('outlook-live', find.text('Petsa')), findsOneWidget);
    expect(_in('outlook-live', find.text('Tuyot (D)')), findsOneWidget);
    expect(_in('outlook-live', find.text('Katayuan')), findsWidgets);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('outlook-past')), 200);
    expect(_in('outlook-past', find.text('Tag-araw')), findsOneWidget);
    expect(_in('outlook-past', find.text('Katayuan')), findsWidgets);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('outlook-heat')), 200);
    expect(_in('outlook-heat', find.text('Petsa')), findsOneWidget);
    expect(_in('outlook-heat', find.text('Init (°C)')), findsOneWidget);
    expect(_in('outlook-heat', find.text('Katayuan')), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
