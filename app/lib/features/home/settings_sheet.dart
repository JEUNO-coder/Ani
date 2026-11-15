
import 'package:flutter/material.dart';
 
import '../../app_state.dart';
import '../../data/bundle.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../about/about_screen.dart';
import '../farm/demo_screen.dart';
import '../labels.dart';
 
/// Opens the settings sheet (change language / change town).
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AniColors.cream,
    showDragHandle: true,
    builder: (_) => const SettingsSheet(),
  );
}
 
/// Language and town pickers; language applies immediately, picking a town
/// reloads the bundle and closes the sheet.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});
 
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = AppScope.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AniSpacing.screen, 0, AniSpacing.screen, AniSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.settingsTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AniSpacing.lg),
            Eyebrow(l.settingsChangeLanguage),
            const SizedBox(height: AniSpacing.sm),
            for (final (code, name) in [('en', l.languageEnglish), ('fil', l.languageFilipino)]) ...[
              ChoiceTile(
                key: ValueKey('settings-lang-$code'),
                title: name,
                selected: state.localeCode == code,
                onTap: () => state.setLocale(code),
              ),
              const SizedBox(height: AniSpacing.sm),
            ],
            const SizedBox(height: AniSpacing.md),
            Eyebrow(l.settingsChangeTown),
            const SizedBox(height: AniSpacing.sm),
            for (final t in Town.values) ...[
              ChoiceTile(
                key: ValueKey('settings-town-${t.id}'),
                title: l.townName(t),
                selected: state.town == t,
                onTap: () {
                  state.setTown(t);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: AniSpacing.sm),
            ],
            const SizedBox(height: AniSpacing.md),
            AniCard(
              key: const ValueKey('settings-demo'),
              padding: const EdgeInsets.all(AniSpacing.md),
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(MaterialPageRoute<void>(builder: (_) => const DemoPickerScreen()));
              },
              child: Row(
                children: [
                  const Icon(Icons.replay_outlined, color: AniColors.gold),
                  const SizedBox(width: AniSpacing.md),
                  Expanded(child: Text(l.demoTitle, style: Theme.of(context).textTheme.titleSmall)),
                  const Icon(Icons.chevron_right, color: AniColors.muted),
                ],
              ),
            ),
            const SizedBox(height: AniSpacing.sm),
            AniCard(
              key: const ValueKey('settings-about'),
              padding: const EdgeInsets.all(AniSpacing.md),
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));
              },
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AniColors.gold),
                  const SizedBox(width: AniSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.aboutTitle, style: Theme.of(context).textTheme.titleSmall),
                        Text(l.aboutLinkSubtitle, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AniColors.muted),
                ],
              ),
            ),
            const SizedBox(height: AniSpacing.sm),
            AniCard(
              key: const ValueKey('settings-logout'),
              padding: const EdgeInsets.all(AniSpacing.md),
              onTap: () => _confirmLogout(context, state, l),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: AniColors.statusDelikado),
                  const SizedBox(width: AniSpacing.md),
                  Expanded(
                    child: Text(
                      l.settingsLogout,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AniColors.statusDelikado,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AniColors.muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Future<void> _confirmLogout(BuildContext context, AppState state, AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AniColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AniRadius.lg)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AniSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.settingsLogout,
                style: Theme.of(dialogContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: AniSpacing.md),
              Text(
                l.settingsLogoutConfirm,
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: AniSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('settings-logout-cancel'),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(l.actionCancel),
                    ),
                  ),
                  const SizedBox(width: AniSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('settings-logout-confirm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AniColors.statusDelikado,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(l.settingsLogout),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
 
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
      await state.logout();
    }
  }
}
 