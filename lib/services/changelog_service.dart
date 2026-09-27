import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// The version this build is, stamped in by CI from the release tag
/// (`--dart-define=APP_VERSION=x.y.z`, see .github/workflows). Local builds
/// have none and report [kDevVersion].
const String kAppVersion =
    String.fromEnvironment('APP_VERSION', defaultValue: kDevVersion);

/// What a build without a version reports — a local `flutter run`.
const String kDevVersion = '0.0.0';

/// Whether this is a local build rather than a tagged release.
bool get isDevBuild => kAppVersion == kDevVersion;

/// Where the changelog lives: a committed JSON asset, so it works offline
/// and a release only has to add an entry to one file
/// (`scripts/new_changelog_entry.py`) before tagging. Highlight text is data,
/// so each release can carry per-locale lines without new ARB keys.
const String kChangelogAssetPath = 'assets/changelog/changelog.json';

/// One shipped version and the handful of changes worth telling someone
/// about. Highlights, not a commit log — the GitHub release notes stay the
/// complete record.
@immutable
class ChangelogRelease {
  const ChangelogRelease({
    required this.version,
    required this.date,
    required this.highlightsByLocale,
  });

  /// Bare semver, no leading `v` — compared against [kAppVersion].
  final String version;

  /// Release date as written in the asset (`YYYY-MM-DD`), or null.
  final DateTime? date;

  /// Locale code (`en`, `pt`, …) to that locale's highlight lines.
  final Map<String, List<String>> highlightsByLocale;

  /// The highlights for [localeCode], falling back to English, so a release
  /// can ship before its translations do.
  List<String> highlightsFor(String localeCode) {
    final exact = highlightsByLocale[localeCode];
    if (exact != null && exact.isNotEmpty) return exact;
    // `pt_BR` and the like resolve to their base language.
    final base = localeCode.split(RegExp(r'[_-]')).first;
    final baseMatch = highlightsByLocale[base];
    if (baseMatch != null && baseMatch.isNotEmpty) return baseMatch;
    return highlightsByLocale['en'] ?? const [];
  }
}

/// Parses the changelog asset. Tolerant by design: a malformed changelog must
/// never stop the app from starting, so anything unparseable yields an empty
/// list, and entries missing a version or highlights are skipped. Sorted
/// newest first whatever the file's order.
List<ChangelogRelease> parseChangelog(String jsonSource) {
  try {
    final decoded = jsonDecode(jsonSource);
    if (decoded is! Map<String, dynamic>) return const [];
    final entries = decoded['releases'];
    if (entries is! List) return const [];

    final releases = <ChangelogRelease>[];
    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) continue;
      final version = (entry['version'] as String?)?.trim();
      if (version == null || version.isEmpty) continue;

      final rawHighlights = entry['highlights'];
      if (rawHighlights is! Map) continue;
      final highlights = <String, List<String>>{};
      rawHighlights.forEach((locale, lines) {
        if (locale is! String || lines is! List) return;
        final texts = [
          for (final line in lines)
            if (line is String && line.trim().isNotEmpty) line.trim(),
        ];
        if (texts.isNotEmpty) highlights[locale] = texts;
      });
      if (highlights.isEmpty) continue;

      releases.add(ChangelogRelease(
        version: version,
        date: DateTime.tryParse((entry['date'] as String?) ?? ''),
        highlightsByLocale: highlights,
      ));
    }
    releases.sort((a, b) => compareVersions(b.version, a.version));
    return releases;
  } catch (e) {
    debugPrint('[Changelog] failed to parse changelog asset: $e');
    return const [];
  }
}

/// Compares two bare semver strings: negative if [a] is older than [b], zero
/// if the same, positive if newer. Missing or unparseable parts count as zero.
int compareVersions(String a, String b) {
  final pa = _parseVersion(a);
  final pb = _parseVersion(b);
  for (var i = 0; i < 3; i++) {
    if (pa[i] != pb[i]) return pa[i] - pb[i];
  }
  return 0;
}

List<int> _parseVersion(String v) {
  final parts = v.split('.').map((s) => int.tryParse(s.trim()) ?? 0).toList();
  while (parts.length < 3) {
    parts.add(0);
  }
  return parts.sublist(0, 3);
}

/// The changelog entries to show on this launch, newest first.
///
/// Empty when:
/// - [lastSeenVersion] is null: a fresh install, where changes since a
///   version the user never ran would be noise;
/// - the app is on the same version as last time, or an older one;
/// - no entry falls between the two.
///
/// Entries newer than [currentVersion] are left out: a build can only
/// describe itself and what came before it.
List<ChangelogRelease> changelogToShow({
  required String? lastSeenVersion,
  required String currentVersion,
  required List<ChangelogRelease> changelog,
}) {
  if (lastSeenVersion == null || lastSeenVersion.isEmpty) return const [];
  if (compareVersions(currentVersion, lastSeenVersion) <= 0) return const [];
  return [
    for (final release in changelog)
      if (compareVersions(release.version, lastSeenVersion) > 0 &&
          compareVersions(release.version, currentVersion) <= 0)
        release,
  ]..sort((a, b) => compareVersions(b.version, a.version));
}

/// The version to treat as "last seen" for an install that has been used
/// but never recorded one: the newest release older than [currentVersion].
///
/// Needed for the update that introduces the changelog: earlier builds never
/// recorded a version, so without this an upgrade from them would look like
/// a fresh install and stay silent. Assuming the user came from the previous
/// release shows the notes for the version just installed, and nothing older.
String? upgradeBaselineVersion(
  String currentVersion, {
  required List<ChangelogRelease> changelog,
}) {
  String? best;
  for (final release in changelog) {
    if (compareVersions(release.version, currentVersion) >= 0) continue;
    if (best == null || compareVersions(release.version, best) > 0) {
      best = release.version;
    }
  }
  return best;
}

/// Where the last version whose changelog was shown is remembered. Kept on
/// the device: it records what this install has already displayed.
const String kLastSeenChangelogVersionKey = 'lastSeenChangelogVersion';

class ChangelogService {
  const ChangelogService._();

  /// Parsed once per run; the asset never changes while the app is open.
  static List<ChangelogRelease>? _cache;

  static Future<List<ChangelogRelease>> loadChangelog() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final source = await rootBundle.loadString(kChangelogAssetPath);
      return _cache = parseChangelog(source);
    } catch (e) {
      // A missing asset must not be fatal — the app just has no changelog.
      debugPrint('[Changelog] failed to load $kChangelogAssetPath: $e');
      return _cache = const [];
    }
  }

  /// Records a baseline last-seen version for an install that has been used
  /// before but has none yet (see [upgradeBaselineVersion]). [hadPriorUse]
  /// must be decided before this run creates anything.
  static Future<void> seedBaselineForUpgrade({
    required bool hadPriorUse,
    required String currentVersion,
  }) async {
    if (!hadPriorUse) return;
    if (await loadLastSeenVersion() != null) return;
    final baseline = upgradeBaselineVersion(
      currentVersion,
      changelog: await loadChangelog(),
    );
    if (baseline != null) await saveLastSeenVersion(baseline);
  }

  static Future<String?> loadLastSeenVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(kLastSeenChangelogVersionKey);
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  static Future<void> saveLastSeenVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLastSeenChangelogVersionKey, version);
  }

  /// Resolves what to show for [currentVersion] and marks it seen in the same
  /// step, so the dialog never appears twice for one update — even if the
  /// app is closed before it's dismissed.
  static Future<List<ChangelogRelease>> takePendingChangelog(
    String currentVersion,
  ) async {
    final lastSeen = await loadLastSeenVersion();
    final pending = changelogToShow(
      lastSeenVersion: lastSeen,
      currentVersion: currentVersion,
      changelog: await loadChangelog(),
    );
    if (lastSeen == null || compareVersions(currentVersion, lastSeen) > 0) {
      await saveLastSeenVersion(currentVersion);
    }
    return pending;
  }
}
