import 'package:flutter/widgets.dart';

import '../../core/planner.dart';
import '../../data/bundle.dart';
import '../../data/planner_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

/// Localized labels for the recommendation flow.
extension RecommendLabels on AppLocalizations {
  /// Crop name by id (planner.NAME); same in both locales.
  String cropNameOf(String id) => switch (id) {
        CropId.rice => cropPalay,
        CropId.onion => cropSibuyas,
        CropId.mungbean => cropMunggo,
        CropId.maize => cropMais,
        CropId.sweetPotato => cropKamote,
        _ => kCropName[id] ?? id,
      };

  /// English gloss of a crop name (shown in the English locale only).
  String? cropGlossOf(String id) => null;

  /// Localizes planner.py reason strings to English when locale is English.
  String localizeWhy(String why) {
    if (localeName != 'en') return why;
    if (why.startsWith('Kita:')) {
      return why
          .replaceFirst('Kita: mga', 'Income: about')
          .replaceFirst('bawat ektarya', 'per hectare')
          .replaceFirst('(gitnang tantiya)', '(median estimate)');
    }
    if (why.startsWith('Tsansang masira:')) {
      return why.replaceFirst('Tsansang masira:', 'Risk of failure:');
    }
    if (why == 'Mababa ang tsansang masira ngayong tag-araw') {
      return 'Low risk of failure this dry season';
    }
    if (why.startsWith('Kaunting tubig:')) {
      return why
          .replaceFirst('Kaunting tubig: mga', 'Low water need: about')
          .replaceFirst('sa buong panahon', 'over the season');
    }
    if (why == 'Nagdadagdag ng nitrogen sa lupa (legume)') {
      return 'Adds nitrogen to the soil (legume)';
    }
    if (why == 'Iba ang pamilya sa huling tanim: pumuputol sa siklo ng peste') {
      return 'Different family from last crop: breaks the pest cycle';
    }
    return why;
  }

  String waterLevelName(String water) => switch (water) {
        WaterScenario.rainfed => waterRainfed,
        WaterScenario.limited2 => waterLimited2,
        WaterScenario.limited4 => waterLimited4,
        _ => waterFull,
      };

  String waterSourceName(String source) => switch (source) {
        WaterSource.rain => sourceRain,
        WaterSource.pump => sourcePump,
        WaterSource.canal => sourceCanal,
        _ => sourceRiver,
      };

  String priorityName(String criterion) => switch (criterion) {
        'income' => priorityIncome,
        'risk' => priorityRisk,
        'water' => priorityWater,
        'soil' => prioritySoil,
        _ => priorityPest,
      };

  String confidenceName(String level) => switch (level) {
        Confidence.high => confidenceHigh,
        Confidence.medium => confidenceMedium,
        _ => confidenceLow,
      };

  /// English Hold reason per guard (the Filipino locale shows the planner's
  /// own `hold_message` text instead).
  String holdGuardReason(String guard) => switch (guard) {
        Guard.water => holdGuardWater,
        Guard.farmer => holdGuardFarmer,
        Guard.heat => holdGuardHeat,
        Guard.profit => holdGuardProfit,
        _ => holdGuardSeason,
      };
}

/// Pill colour for a confidence level.
Color confidenceColor(String level) => switch (level) {
      Confidence.high => AniColors.statusNormal,
      Confidence.medium => AniColors.statusBantay,
      _ => AniColors.statusDelikado,
    };

/// Percent as planner.py prints it (`format(x, '.0%')`).
String pct0(double x) => '${pyFixed(x * 100, 0)}%';

/// Peso amount with grouping and a leading minus sign, e.g. `−₱12,300`.
String peso(double x) {
  final s = pyFixed(x.abs(), 0, group: true);
  return x < 0 ? '−₱$s' : '₱$s';
}
