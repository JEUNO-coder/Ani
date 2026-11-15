import 'dart:convert';
import 'dart:io';

import 'package:ani/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, dynamic>;

Iterable<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fil = lookupAppLocalizations(const Locale('fil'));

  test('supported locales are en and fil', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      {'en', 'fil'},
    );
  });

  test('English strings', () {
    expect(en.appTitle, 'Ani');
    expect(en.onboardingLanguageTitle, 'Choose your language');
    expect(en.onboardingTownTitle, 'Where is your farm?');
    expect(en.townMunoz, 'Science City of Muñoz');
    expect(en.homeCta, 'What should I plant?');
    expect(en.onboardingStepOf(1, 2), 'Step 1 of 2');
    expect(en.cropPalay, 'Rice');
    expect(en.cropSibuyas, 'Onion');
    expect(en.cropMunggo, 'Mung bean');
    expect(en.cropMais, 'Corn');
    expect(en.cropKamote, 'Sweet potato');
    expect(en.holdTitle, 'Hold: Do not plant yet');
    expect(en.whyLabel, 'Why');
    expect(en.dryBantay, 'Watch');
    expect(en.dryDelikado, 'Danger');
    expect(en.consultMao, 'Consult the MAO');
    expect(en.workEarly, 'Work early');
    expect(en.elNinoExpected, 'El Niño expected this dry season');
  });

  test('Filipino strings', () {
    expect(fil.onboardingContinue, 'Magpatuloy');
    expect(fil.navHome, 'Simula');
    expect(fil.onboardingStepOf(2, 2), 'Hakbang 2 sa 2');
    expect(fil.cropPalay, 'Palay');
    expect(fil.cropSibuyas, 'Sibuyas');
    expect(fil.cropMunggo, 'Munggo');
    expect(fil.cropMais, 'Mais');
    expect(fil.cropKamote, 'Kamote');
    expect(fil.holdTitle, 'Huwag munang magtanim');
    expect(fil.whyLabel, 'Bakit?');
    expect(fil.dryBantay, 'Bantay');
    expect(fil.dryDelikado, 'Delikado');
    expect(fil.consultMao, 'Kumonsulta sa MAO');
    expect(fil.workEarly, 'Magtrabaho nang maaga');
    expect(fil.elNinoExpected, 'Inaasahan ang El Niño ngayong tag-araw');
  });

  test('plural placeholders', () {
    expect(en.drynessRank(1, 25), 'Driest of 25 years');
    expect(en.drynessRank(3, 25), 'No. 3 driest of 25 years');
    expect(fil.drynessRank(3, 25), 'Ika-3 sa pinakatuyo sa 25 na taon');
    expect(en.cardFailedSeasons(2, 9), 'Failed in 2 of 9 years');
    expect(fil.cardFailedSeasons(2, 9), 'Nasira sa 2 sa 9 na taon');
    expect(en.waitingForDataDays(1), '1 day waiting for data');
  });

  test('every en key exists in fil', () {
    final enKeys = _messageKeys(_arb('app_en.arb')).toSet();
    final filKeys = _messageKeys(_arb('app_fil.arb')).toSet();
    expect(enKeys.difference(filKeys), isEmpty);
    expect(filKeys.difference(enKeys), isEmpty);
  });

  test('every en key has a description', () {
    final arb = _arb('app_en.arb');
    for (final k in _messageKeys(arb)) {
      final meta = arb['@$k'] as Map<String, dynamic>?;
      expect(meta?['description'], isA<String>(), reason: k);
    }
  });
}
