import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/changelog_service.dart';
import '../widgets/whats_new_dialog.dart' show ChangelogHighlightRow;

/// Every release, newest first, from Settings or the What's New dialog.
class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.changelogTitle)),
      body: FutureBuilder<List<ChangelogRelease>>(
        future: ChangelogService.loadChangelog(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ChangelogReleaseCards(
              releases: snapshot.data!,
              localeCode: Localizations.localeOf(context).toLanguageTag(),
              currentVersion: isDevBuild ? null : kAppVersion,
            ),
          );
        },
      ),
    );
  }
}

/// The releases as cards, collapsed to version and date except for the
/// newest [expandedCount]. No scroll view of its own.
class ChangelogReleaseCards extends StatelessWidget {
  const ChangelogReleaseCards({
    super.key,
    required this.releases,
    required this.localeCode,
    this.currentVersion,
    this.expandedCount = 3,
  });

  final List<ChangelogRelease> releases;
  final String localeCode;

  /// Marked "Installed"; null for a dev build.
  final String? currentVersion;
  final int expandedCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd(localeCode);

    if (releases.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l.changelogEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < releases.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: PageStorageKey('changelog-${releases[i].version}'),
              initiallyExpanded: i < expandedCount,
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: Row(
                children: [
                  Text(
                    l.versionLabel(releases[i].version),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (currentVersion != null &&
                      compareVersions(releases[i].version, currentVersion!) ==
                          0) ...[
                    const SizedBox(width: 8),
                    _CurrentVersionBadge(
                        label: l.changelogCurrentVersionBadge),
                  ],
                  const Spacer(),
                  if (releases[i].date != null)
                    Text(
                      dateFormat.format(releases[i].date!),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              children: [
                for (final text in releases[i].highlightsFor(localeCode))
                  ChangelogHighlightRow(text: text),
              ],
            ),
          ),
      ],
    );
  }
}

class _CurrentVersionBadge extends StatelessWidget {
  const _CurrentVersionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
