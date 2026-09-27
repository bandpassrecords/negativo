import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/changelog_service.dart';

/// Shows the "What's New" dialog for [releases]. No-op when there is nothing
/// to show, so callers don't have to check first.
Future<void> showWhatsNewDialog(
  BuildContext context,
  List<ChangelogRelease> releases, {
  VoidCallback? onViewFullChangelog,
}) async {
  if (releases.isEmpty) return;
  final localeCode = Localizations.localeOf(context).toLanguageTag();
  await showDialog<void>(
    context: context,
    // Good news, not a warning, and already marked seen by the time it opens.
    barrierDismissible: true,
    builder: (ctx) => WhatsNewView(
      releases: releases,
      localeCode: localeCode,
      onClose: () => Navigator.of(ctx).pop(),
      onViewFullChangelog: onViewFullChangelog == null
          ? null
          : () {
              Navigator.of(ctx).pop();
              onViewFullChangelog();
            },
    ),
  );
}

/// The dialog's contents, with no asset or storage dependency of its own so
/// it can be widget-tested directly.
class WhatsNewView extends StatelessWidget {
  const WhatsNewView({
    super.key,
    required this.releases,
    required this.localeCode,
    required this.onClose,
    this.onViewFullChangelog,
  });

  /// Newest first. More than one when the user skipped a version or two —
  /// each keeps its own heading so it stays clear what arrived when.
  final List<ChangelogRelease> releases;

  /// Which locale's highlights to show.
  final String localeCode;

  final VoidCallback onClose;

  /// Opens the full history; omitted where there is nowhere to go.
  final VoidCallback? onViewFullChangelog;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final showVersionHeadings = releases.length > 1;

    return AlertDialog(
      // Grows with each skipped version; scroll rather than overflow.
      scrollable: true,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      icon: const Icon(Icons.auto_awesome, size: 32),
      iconColor: theme.colorScheme.primary,
      title: Text(
        showVersionHeadings
            ? l.whatsNewTitle
            : l.whatsNewTitleWithVersion(releases.first.version),
      ),
      content: SizedBox(
        width: math.min(460, MediaQuery.of(context).size.width - 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.whatsNewIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            for (final release in releases) ...[
              if (showVersionHeadings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    l.versionLabel(release.version),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              for (final text in release.highlightsFor(localeCode))
                ChangelogHighlightRow(text: text),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      actions: [
        if (onViewFullChangelog != null)
          TextButton(
            onPressed: onViewFullChangelog,
            child: Text(l.changelogFullButton),
          ),
        FilledButton(onPressed: onClose, child: Text(l.whatsNewGotIt)),
      ],
    );
  }
}

/// One bulleted highlight. Shared with the changelog page so both lists read
/// the same.
class ChangelogHighlightRow extends StatelessWidget {
  const ChangelogHighlightRow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 10),
            child: Icon(
              Icons.check_circle_outline,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
