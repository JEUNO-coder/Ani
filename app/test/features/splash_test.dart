import 'package:ani/app_state.dart';
import 'package:ani/data/bundle.dart';
import 'package:ani/data/settings_store.dart';
import 'package:ani/features/farm/farm_screen.dart';
import 'package:ani/features/home/home_screen.dart';
import 'package:ani/features/library/library_screen.dart';
import 'package:ani/features/outlook/outlook_screen.dart';
import 'package:ani/l10n/app_localizations.dart';
import 'package:ani/main.dart';
import 'package:ani/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, AppState state) => AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          theme: AniTheme.light(),
          locale: state.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: child),
        ),
      ),
    );

void main() {
  setUp(BundleLoader.instance.clear);

  testWidgets('SplashScreen renders logowithtext and animates fade in and out', (tester) async {
    var completed = false;
    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(
        duration: const Duration(milliseconds: 1000),
        onComplete: () => completed = true,
      ),
    ));

    // Initially at t=0, opacity is 0.0.
    final finder = find.byKey(const ValueKey('splash-fade'));
    expect(finder, findsOneWidget);
    var fade = tester.widget<FadeTransition>(finder);
    expect(fade.opacity.value, equals(0.0));

    // Finds the logowithtext image.
    final imageFinder = find.byWidgetPredicate(
      (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/icon/logowithtext.png',
    );
    expect(imageFinder, findsOneWidget);

    // Pump to mid-way (500ms): fully faded in.
    await tester.pump(const Duration(milliseconds: 500));
    fade = tester.widget<FadeTransition>(finder);
    expect(fade.opacity.value, equals(1.0));
    expect(completed, isFalse);

    // Pump to end: wait for animation to settle.
    await tester.pumpAndSettle();
    fade = tester.widget<FadeTransition>(finder);
    expect(fade.opacity.value, equals(0.0));
    expect(completed, isTrue);
  });

  testWidgets('Headers across app use correct logos and no text ANI', (tester) async {
    SharedPreferences.setMockInitialValues({
      SettingsStore.keyLocale: 'en',
      SettingsStore.keyTown: 'guimba',
      SettingsStore.keyOnboardingComplete: true,
    });
    final state = AppState();
    await tester.runAsync(state.init);

    // 1. Home screen header logo (logowithtext, no word ANI)
    await tester.pumpWidget(_host(const HomeScreen(), state));
    await tester.pumpAndSettle();
    final homeLogo = find.byKey(const ValueKey('home-header-logo'));
    expect(homeLogo, findsOneWidget);
    expect(
      tester.widget<Image>(homeLogo).image,
      isA<AssetImage>().having((a) => a.assetName, 'assetName', 'assets/icon/logowithtext.png'),
    );
    expect(find.text('ANI'), findsNothing);

    // 2. Outlook screen header logo (logowithtext, no word ANI)
    await tester.pumpWidget(_host(const OutlookScreen(), state));
    await tester.pumpAndSettle();
    final outlookLogo = find.byKey(const ValueKey('outlook-header-logo'));
    expect(outlookLogo, findsOneWidget);
    expect(
      tester.widget<Image>(outlookLogo).image,
      isA<AssetImage>().having((a) => a.assetName, 'assetName', 'assets/icon/logowithtext.png'),
    );
    expect(find.text('ANI'), findsNothing);

    // 3. Library screen header logo (logowithtext, no word ANI)
    await tester.pumpWidget(_host(const LibraryScreen(), state));
    await tester.pumpAndSettle();
    final libraryLogo = find.byKey(const ValueKey('library-header-logo'));
    expect(libraryLogo, findsOneWidget);
    expect(
      tester.widget<Image>(libraryLogo).image,
      isA<AssetImage>().having((a) => a.assetName, 'assetName', 'assets/icon/logowithtext.png'),
    );
    expect(find.text('ANI'), findsNothing);

    // 4. Farm screen header logo (logowithtext, no word ANI)
    await tester.pumpWidget(_host(const FarmScreen(), state));
    await tester.pumpAndSettle();
    final farmLogo = find.byKey(const ValueKey('farm-header-logo'));
    expect(farmLogo, findsOneWidget);
    expect(
      tester.widget<Image>(farmLogo).image,
      isA<AssetImage>().having((a) => a.assetName, 'assetName', 'assets/icon/logowithtext.png'),
    );
    expect(find.text('ANI'), findsNothing);
  });
}
