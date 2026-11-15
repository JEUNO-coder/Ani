import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_state.dart';
import '../../core/dekadal.dart';
import '../../data/bundle.dart';
import '../../data/live_outlook.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../alerts/alerts_screen.dart';
import '../home/settings_sheet.dart';
import '../labels.dart';
import 'heat_safety.dart';

/// Season outlook: El Niño tag and past seasons, the monthly dryness-index
/// chart, live dekadal D (from the synced POWER cache, bundled
/// `dryness.latest` offline) and heat-safety advice.
class OutlookScreen extends StatefulWidget {
  const OutlookScreen({super.key});

  @override
  State<OutlookScreen> createState() => _OutlookScreenState();
}

class _OutlookScreenState extends State<OutlookScreen> {
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) return;
    _asked = true;
    final state = AppScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) state.refreshLive().ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final bundle = state.bundle;
    final town = state.town;
    return Column(
      children: [
        AniAppHeader(
          child: Row(
            children: [
              Image.asset(
                'assets/icon/logowithtext.png',
                key: const ValueKey('outlook-header-logo'),
                height: 26,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              const AlertsBell(),
              IconButton(
                key: const ValueKey('outlook-settings'),
                tooltip: l.settingsTitle,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => showSettingsSheet(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('outlook-list'),
            padding: const EdgeInsets.fromLTRB(AniSpacing.screen, AniSpacing.lg, AniSpacing.screen, AniSpacing.xxl),
            children: [
              Text(l.outlookTitle, style: theme.textTheme.headlineMedium),
              if (town != null) Text(l.townName(town), style: theme.textTheme.bodyMedium?.copyWith(color: AniColors.muted)),
              const SizedBox(height: AniSpacing.lg),
              if (bundle == null)
            const SizedBox.shrink()
          else ...[
            _EnsoCard(enso: bundle.enso),
            const SizedBox(height: AniSpacing.md),
            LiveDrynessCard(bundle: bundle, live: state.live),
            const SizedBox(height: AniSpacing.md),
            DrynessChartCard(dryness: bundle.dryness, enso: bundle.enso),
            const SizedBox(height: AniSpacing.md),
            _PastSeasons(enso: bundle.enso),
            const SizedBox(height: AniSpacing.md),
            HeatSafetyCard(live: state.live),
          ],
        ],
      ),
    ),
  ],
);
  }
}

Color _tagColor(String tag) => switch (tag) {
  EnsoTag.elNino => AniColors.statusDelikado,
  EnsoTag.laNina => AniColors.statusNormal,
  _ => AniColors.muted,
};

String _signed(double x, int digits) => '${x >= 0 ? '+' : ''}${x.toStringAsFixed(digits)}';

// ------------------------------------------------------------------ El Niño

class _EnsoCard extends StatelessWidget {
  const _EnsoCard({required this.enso});

  final Enso enso;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = _tagColor(enso.tag);
    final strength = ensoStrengthKey(enso.jas);
    return AniCard(
      key: const ValueKey('outlook-enso'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow('${l.homeOutlookTitle} · ${enso.comingSeason}'),
          const SizedBox(height: AniSpacing.xs),
          Text(
            enso.isElNino ? l.elNinoExpected : l.ensoTagName(enso.tag),
            key: const ValueKey('outlook-enso-headline'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AniSpacing.sm),
          Wrap(
            spacing: AniSpacing.sm,
            runSpacing: AniSpacing.sm,
            children: [
              AniPill(l.ensoTagName(enso.tag), color: color),
              if (strength != null) AniPill(l.ensoStrength(strength), color: AniColors.muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _PastSeasons extends StatefulWidget {
  const _PastSeasons({required this.enso});

  final Enso enso;

  @override
  State<_PastSeasons> createState() => _PastSeasonsState();
}

class _PastSeasonsState extends State<_PastSeasons> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = widget.enso.past.reversed.toList();
    final items = _expanded ? all : all.take(5).toList();
    return AniCard(
      key: const ValueKey('outlook-past'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(l.outlookPastSeasons),
          const SizedBox(height: AniSpacing.sm),
          const _PastSeasonHeaderRow(),
          const Divider(color: AniColors.line, height: 1, thickness: 1),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(color: AniColors.line, height: 1, thickness: 1),
            _PastSeasonRow(season: items[i]),
          ],
          if (all.length > 5) ...[
            const Divider(color: AniColors.line, height: 1, thickness: 1),
            const SizedBox(height: AniSpacing.xs),
            Center(
              child: TextButton.icon(
                key: const ValueKey('outlook-past-toggle'),
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
                label: Text(_expanded ? l.showLess : l.showMore),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PastSeasonHeaderRow extends StatelessWidget {
  const _PastSeasonHeaderRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: AniColors.muted,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AniSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.outlookPastColSeason,
              key: const ValueKey('outlook-past-header-season'),
              style: style,
            ),
          ),
          Text(
            l.outlookPastColStatus,
            key: const ValueKey('outlook-past-header-status'),
            style: style,
          ),
        ],
      ),
    );
  }
}

class _PastSeasonRow extends StatelessWidget {
  const _PastSeasonRow({required this.season});

  final EnsoPastSeason season;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey('past-season-${season.season}'),
      padding: const EdgeInsets.symmetric(vertical: AniSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              season.season,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          AniPill(l.ensoTagName(season.tag), color: _tagColor(season.tag)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ live dryness

/// Dryness now: live dekadal D when the POWER cache can score it, else the
/// bundled `dryness.latest`.
class LiveDrynessCard extends StatelessWidget {
  const LiveDrynessCard({super.key, required this.bundle, required this.live});

  final AniBundle bundle;
  final LiveOutlook? live;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cur = live?.current;
    final isLive = live != null && cur != null && live!.state != null;
    final String label;
    final double d;
    final String source;
    if (isLive) {
      label = live!.state!.level.id;
      d = cur.d!;
      source = l.outlookLiveLive(DateFormat.MMMd(l.localeName).format(cur.end));
    } else {
      final latest = bundle.dryness.latest;
      label = latest.label;
      d = latest.d;
      source = l.outlookLiveBundled(latest.month);
    }
    final fg = drynessColor(label);
    final dekads = isLive ? live!.dekads.reversed.take(6).toList() : const <DekadD>[];
    return Container(
      key: const ValueKey('outlook-live'),
      decoration: BoxDecoration(
        color: drynessBgColor(label),
        borderRadius: AniRadius.card,
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(AniSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, color: fg),
              const SizedBox(width: AniSpacing.sm),
              Expanded(child: Eyebrow(l.outlookLiveTitle, color: fg)),
            ],
          ),
          const SizedBox(height: AniSpacing.xs),
          Wrap(
            spacing: AniSpacing.sm,
            runSpacing: AniSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l.drynessLabelName(label),
                key: const ValueKey('outlook-live-label'),
                style: theme.textTheme.headlineSmall?.copyWith(color: fg),
              ),
              AniPill(l.drynessDValue(_signed(d, 2)), key: const ValueKey('outlook-live-d'), color: fg),
            ],
          ),
          const SizedBox(height: AniSpacing.xs),
          Text(source, key: const ValueKey('outlook-live-source'), style: theme.textTheme.bodySmall),
          if (dekads.isNotEmpty) ...[
            const SizedBox(height: AniSpacing.md),
            Divider(color: fg.withValues(alpha: 0.25), height: 1, thickness: 1),
            const SizedBox(height: AniSpacing.md),
            Eyebrow(l.outlookDekadsTitle, color: fg),
            const SizedBox(height: AniSpacing.sm),
            _DekadHeaderRow(color: fg),
            Divider(color: fg.withValues(alpha: 0.25), height: 1, thickness: 1),
            for (var i = 0; i < dekads.length; i++) ...[
              if (i > 0)
                Divider(
                  color: fg.withValues(alpha: 0.25),
                  height: 1,
                  thickness: 1,
                ),
              _DekadRow(dekad: dekads[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _DekadHeaderRow extends StatelessWidget {
  const _DekadHeaderRow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: color.withValues(alpha: 0.8),
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AniSpacing.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              l.outlookDekadColPeriod,
              key: const ValueKey('outlook-header-period'),
              style: style,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              l.outlookDekadColDryness,
              key: const ValueKey('outlook-header-dryness'),
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
          const SizedBox(width: AniSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64, maxWidth: 84),
            child: Text(
              l.outlookDekadColStatus,
              key: const ValueKey('outlook-header-status'),
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _DekadRow extends StatelessWidget {
  const _DekadRow({required this.dekad});

  final DekadD dekad;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final start = dekad.dekad == 1 ? 1 : (dekad.dekad == 2 ? 11 : 21);
    final month = DateFormat.MMM(l.localeName).format(DateTime.utc(dekad.year, dekad.month));
    final range = l.outlookDekadRange(start, dekad.end.day, month);
    final d = dekad.d;
    final level = dekad.instant;
    final color = level == null ? AniColors.muted : drynessColor(level.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AniSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(dekad.partial ? '$range · ${l.outlookDekadPartial}' : range, style: theme.textTheme.bodyMedium),
          ),
          if (d == null)
            Text(l.outlookDekadNoData, style: theme.textTheme.bodySmall?.copyWith(color: AniColors.muted))
          else ...[
            SizedBox(
              width: 72,
              child: Text(
                _signed(d, 2),
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
            ),
            const SizedBox(width: AniSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, maxWidth: 84),
              child: Text(
                l.drynessLabelName(level!.id),
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ chart

/// Month index (0-based into [months]) range of the El Niño dry seasons
/// (Nov of the first year to Apr of the next) that overlap [months].
List<(int, int)> elNinoBands(List<String> months, List<EnsoPastSeason> past) {
  final idx = {for (final (i, m) in months.indexed) m: i};
  final out = <(int, int)>[];
  for (final s in past) {
    if (!s.isElNino) continue;
    final y = int.tryParse(s.season.substring(0, 4));
    if (y == null) continue;
    int? a, b;
    for (var m = 0; m < 6; m++) {
      final mm = 11 + m > 12 ? 11 + m - 12 : 11 + m;
      final yy = 11 + m > 12 ? y + 1 : y;
      final i = idx['$yy-${mm.toString().padLeft(2, '0')}'];
      if (i != null) {
        a ??= i;
        b = i;
      }
    }
    if (a != null && b != null) out.add((a, b));
  }
  return out;
}

/// Monthly dryness index with the El Niño dry seasons shaded.
class DrynessChartCard extends StatelessWidget {
  const DrynessChartCard({super.key, required this.dryness, required this.enso, this.months = 120});

  final Dryness dryness;
  final Enso enso;

  /// How many months to show (most recent).
  final int months;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final all = dryness.monthly;
    final pts = all.length > months ? all.sublist(all.length - months) : all;
    final labels = [for (final p in pts) p.month];
    final bands = elNinoBands(labels, enso.past);
    final ds = [for (final p in pts) p.d];
    var lo = ds.isEmpty ? -2.0 : ds.reduce((a, b) => a < b ? a : b);
    var hi = ds.isEmpty ? 2.0 : ds.reduce((a, b) => a > b ? a : b);
    lo = (lo - 0.5).floorToDouble().clamp(-6.0, -2.0);
    hi = (hi + 0.5).ceilToDouble().clamp(3.0, 8.0);
    final t = dryness.thresholds;
    return AniCard(
      key: const ValueKey('outlook-chart'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Eyebrow(l.drynessChartTitle)),
              Text(
                l.outlookChartYears((pts.length / 12).round()),
                style: theme.textTheme.bodySmall?.copyWith(color: AniColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AniSpacing.md),
          SizedBox(
            height: 190,
            child: pts.isEmpty
                ? const SizedBox.shrink()
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (pts.length - 1).toDouble(),
                      minY: lo,
                      maxY: hi,
                      clipData: const FlClipData.all(),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 2,
                            getTitlesWidget: (v, meta) => Text(
                              v.toStringAsFixed(0),
                              style: theme.textTheme.bodySmall?.copyWith(color: AniColors.muted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 1,
                            getTitlesWidget: (v, meta) {
                              final i = v.round();
                              if (i < 0 || i >= pts.length || (v - i).abs() > 0.01) return const SizedBox.shrink();
                              final p = pts[i];
                              if (p.monthOfYear != 1 || p.year % 2 != 0) return const SizedBox.shrink();
                              return Text(
                                '${p.year}',
                                style: theme.textTheme.bodySmall?.copyWith(color: AniColors.muted),
                              );
                            },
                          ),
                        ),
                      ),
                      rangeAnnotations: RangeAnnotations(
                        verticalRangeAnnotations: [
                          for (final (a, b) in bands)
                            VerticalRangeAnnotation(
                              x1: a - 0.5,
                              x2: b + 0.5,
                              color: AniColors.statusDelikado.withValues(alpha: 0.14),
                            ),
                        ],
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(y: t.bantay, color: AniColors.statusBantay, strokeWidth: 1, dashArray: [4, 4]),
                          HorizontalLine(
                            y: t.delikado,
                            color: AniColors.statusDelikado,
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ],
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [for (final (i, p) in pts.indexed) FlSpot(i.toDouble(), p.d)],
                          isCurved: false,
                          color: AniColors.olive,
                          barWidth: 1.6,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AniSpacing.sm),
          Row(
            children: [
              Container(
                width: 14,
                height: 10,
                decoration: BoxDecoration(
                  color: AniColors.statusDelikado.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AniSpacing.xs),
              Expanded(
                child: Text(
                  l.drynessChartElNino,
                  key: const ValueKey('outlook-chart-legend'),
                  style: theme.textTheme.bodySmall?.copyWith(color: AniColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AniSpacing.xs),
          Text(l.outlookChartNote, style: theme.textTheme.bodySmall?.copyWith(color: AniColors.muted)),
        ],
      ),
    );
  }
}
