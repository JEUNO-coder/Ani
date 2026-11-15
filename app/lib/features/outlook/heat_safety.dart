import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/heat_index.dart';
import '../../data/live_outlook.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../labels.dart';

/// PAGASA band name (matches `heat.index_categories_c[].label`), or null for none.
String? bandLabel(PagasaBand b) => b.bundleLabel;

Color bandColor(PagasaBand b) => switch (b) {
      PagasaBand.danger || PagasaBand.extremeDanger => AniColors.statusDelikado,
      PagasaBand.none => AniColors.statusNormal,
      _ => AniColors.gold,
    };

String _hi(double v) => v.toStringAsFixed(1);

/// "Caution · 31.2" style pill text for a reading.
String heatBandText(AppLocalizations l, HeatDay h) {
  final label = bandLabel(h.band);
  final name = label == null ? l.dryNormal : l.heatCategoryName(label);
  return '$name · ${l.heatIndexValue(_hi(h.hi))}';
}

/// The latest live heat reading with the as-of date. On danger days it adds
/// "Magtrabaho nang maaga". People-safety advice only: nothing here feeds the
/// planner or the field machine.
class LiveHeatReading extends StatelessWidget {
  const LiveHeatReading({super.key, required this.live});

  final LiveOutlook? live;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final h = live?.latestHeat;
    if (h == null) {
      return Text(
        l.heatNoLive,
        key: const ValueKey('heat-no-live'),
        style: theme.textTheme.bodySmall?.copyWith(color: AniColors.muted),
      );
    }
    final color = bandColor(h.band);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AniSpacing.sm,
          runSpacing: AniSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AniPill(heatBandText(l, h), key: const ValueKey('heat-live-reading'), color: color),
            Text(
              l.heatAsOf(DateFormat.MMMd(l.localeName).format(h.date)),
              style: theme.textTheme.bodySmall?.copyWith(color: AniColors.muted),
            ),
          ],
        ),
        if (h.isDanger) ...[
          const SizedBox(height: AniSpacing.xs),
          Text(
            l.workEarly,
            key: const ValueKey('heat-live-work-early'),
            style: theme.textTheme.titleSmall?.copyWith(color: AniColors.statusDelikado),
          ),
          Text(l.heatDangerToday, style: theme.textTheme.bodySmall?.copyWith(color: AniColors.statusDelikado)),
        ],
      ],
    );
  }
}

/// Heat-safety card for the Outlook tab: latest reading, recent days and the
/// PAGASA bands.
class HeatSafetyCard extends StatefulWidget {
  const HeatSafetyCard({super.key, required this.live});

  final LiveOutlook? live;

  @override
  State<HeatSafetyCard> createState() => _HeatSafetyCardState();
}

class _HeatSafetyCardState extends State<HeatSafetyCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final heat = widget.live?.heat ?? const <HeatDay>[];
    final dangerDays = widget.live?.dangerDays ?? 0;
    final all = heat.reversed.toList();
    final items = _expanded ? all : all.take(5).toList();

    return AniCard(
      key: const ValueKey('outlook-heat'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thermostat_outlined, color: AniColors.gold),
              const SizedBox(width: AniSpacing.sm),
              Expanded(child: Eyebrow(l.heatSafetyTitle)),
            ],
          ),
          const SizedBox(height: AniSpacing.sm),
          LiveHeatReading(live: widget.live),
          if (heat.length > 1) ...[
            const SizedBox(height: AniSpacing.md),
            Eyebrow(l.heatRecentTitle),
            const SizedBox(height: AniSpacing.sm),
            const _HeatTableHeaderRow(),
            const Divider(color: AniColors.line, height: 1, thickness: 1),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(color: AniColors.line, height: 1, thickness: 1),
              _HeatTableRow(heatDay: items[i]),
            ],
            if (all.length > 5) ...[
              const Divider(color: AniColors.line, height: 1, thickness: 1),
              const SizedBox(height: AniSpacing.xs),
              Center(
                child: TextButton.icon(
                  key: const ValueKey('outlook-heat-toggle'),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
                  label: Text(_expanded ? l.showLess : l.showMore),
                ),
              ),
            ],
            if (dangerDays > 0) ...[
              const SizedBox(height: AniSpacing.sm),
              Text(
                l.heatDangerDays(dangerDays),
                key: const ValueKey('outlook-heat-danger-days'),
                style: theme.textTheme.bodySmall?.copyWith(color: AniColors.statusDelikado),
              ),
            ],
          ],
          const SizedBox(height: AniSpacing.sm),
          Text(l.heatSafetyNote, style: theme.textTheme.bodySmall?.copyWith(color: AniColors.muted)),
        ],
      ),
    );
  }
}

class _HeatTableHeaderRow extends StatelessWidget {
  const _HeatTableHeaderRow();

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
              l.outlookHeatColDate,
              key: const ValueKey('outlook-heat-header-date'),
              style: style,
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              l.outlookHeatColIndex,
              key: const ValueKey('outlook-heat-header-index'),
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
          const SizedBox(width: AniSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64, maxWidth: 84),
            child: Text(
              l.outlookHeatColStatus,
              key: const ValueKey('outlook-heat-header-status'),
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatTableRow extends StatelessWidget {
  const _HeatTableRow({required this.heatDay});

  final HeatDay heatDay;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = bandLabel(heatDay.band);
    final name = label == null ? l.dryNormal : l.heatCategoryName(label);
    final color = bandColor(heatDay.band);
    final dateStr = DateFormat.MMMd(l.localeName).format(heatDay.date);

    return Padding(
      key: ValueKey('heat-row-${DateFormat('yyyyMMdd').format(heatDay.date)}'),
      padding: const EdgeInsets.symmetric(vertical: AniSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dateStr,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              '${_hi(heatDay.hi)}°C',
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
          ),
          const SizedBox(width: AniSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64, maxWidth: 84),
            child: Text(
              name,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
