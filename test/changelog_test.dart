import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:negativo/l10n/app_localizations.dart';
import 'package:negativo/services/changelog_service.dart';
import 'package:negativo/widgets/whats_new_dialog.dart';

ChangelogRelease _release(String version, [List<String>? en]) =>
    ChangelogRelease(
      version: version,
      date: null,
      highlightsByLocale: {
        'en': en ?? ['Change in $version'],
      },
    );

final _history = [
  _release('0.4.0'),
  _release('0.3.1'),
  _release('0.3.0'),
  _release('0.2.0'),
];

List<String> _versions(List<ChangelogRelease> releases) =>
    [for (final r in releases) r.version];

void main() {
  group('compareVersions', () {
    test('orders by major, minor, then patch', () {
      expect(compareVersions('0.3.1', '0.3.0'), isPositive);
      expect(compareVersions('0.3.10', '0.4.0'), isNegative);
      expect(compareVersions('1.0.0', '0.99.99'), isPositive);
      expect(compareVersions('0.3', '0.3.0'), 0);
    });

    test('anything unparseable counts as zero rather than throwing', () {
      expect(compareVersions('garbage', '0.0.0'), 0);
    });
  });

  group('parseChangelog', () {
    test('reads entries newest first whatever the file order', () {
      final parsed = parseChangelog(jsonEncode({
        'releases': [
          {
            'version': '0.2.0',
            'date': '2026-04-23',
            'highlights': {
              'en': ['Old'],
            },
          },
          {
            'version': '0.3.0',
            'highlights': {
              'en': ['New'],
            },
          },
        ],
      }));
      expect(_versions(parsed), ['0.3.0', '0.2.0']);
      expect(parsed.last.date, DateTime(2026, 4, 23));
    });

    test('skips broken entries and never throws', () {
      expect(parseChangelog('not json'), isEmpty);
      expect(parseChangelog('{"releases": 3}'), isEmpty);
      final parsed = parseChangelog(jsonEncode({
        'releases': [
          {'highlights': {'en': ['no version']}},
          {'version': '0.1.0', 'highlights': {'en': []}},
          {'version': '0.2.0', 'highlights': {'en': ['kept']}},
        ],
      }));
      expect(_versions(parsed), ['0.2.0']);
    });
  });

  group('highlightsFor', () {
    final release = ChangelogRelease(
      version: '0.3.1',
      date: null,
      highlightsByLocale: const {
        'en': ['English'],
        'pt': ['Português'],
      },
    );

    test('picks the locale, or its base language', () {
      expect(release.highlightsFor('pt'), ['Português']);
      expect(release.highlightsFor('pt-BR'), ['Português']);
    });

    test('falls back to English for a missing translation', () {
      expect(release.highlightsFor('it'), ['English']);
    });
  });

  group('changelogToShow', () {
    List<String> shown(String? lastSeen, String current) => _versions(
          changelogToShow(
            lastSeenVersion: lastSeen,
            currentVersion: current,
            changelog: _history,
          ),
        );

    test('a fresh install shows nothing', () {
      expect(shown(null, '0.3.1'), isEmpty);
    });

    test('an update shows what arrived since the last version seen', () {
      expect(shown('0.3.0', '0.3.1'), ['0.3.1']);
    });

    test('skipping versions shows each of them, newest first', () {
      expect(shown('0.2.0', '0.4.0'), ['0.4.0', '0.3.1', '0.3.0']);
    });

    test('the same version or a downgrade shows nothing', () {
      expect(shown('0.3.1', '0.3.1'), isEmpty);
      expect(shown('0.4.0', '0.3.1'), isEmpty);
    });

    test('never shows entries newer than the running build', () {
      expect(shown('0.3.0', '0.3.1'), isNot(contains('0.4.0')));
    });
  });

  group('upgradeBaselineVersion', () {
    test('is the newest release before the running one', () {
      expect(upgradeBaselineVersion('0.4.0', changelog: _history), '0.3.1');
    });

    test('is null when nothing came before', () {
      expect(upgradeBaselineVersion('0.2.0', changelog: _history), isNull);
    });
  });

  group('the bundled changelog', () {
    final source = File(kChangelogAssetPath).readAsStringSync();
    final raw = (jsonDecode(source) as Map<String, dynamic>)['releases'] as List;
    final parsed = parseChangelog(source);

    test('every entry parses, with English highlights', () {
      expect(parsed, hasLength(raw.length));
      for (final release in parsed) {
        expect(release.highlightsByLocale['en'], isNotEmpty,
            reason: release.version);
      }
    });

    test('is kept newest first, as CI reads the first entry as the newest', () {
      expect([for (final r in raw) r['version']], _versions(parsed));
    });

    test('only uses languages the app ships in', () {
      final supported = {
        for (final l in AppLocalizations.supportedLocales) l.languageCode,
      };
      for (final release in parsed) {
        expect(supported, containsAll(release.highlightsByLocale.keys),
            reason: release.version);
      }
    });
  });

  group('WhatsNewView', () {
    Future<void> pump(
      WidgetTester tester,
      List<ChangelogRelease> releases, {
      VoidCallback? onClose,
      VoidCallback? onViewFullChangelog,
    }) =>
        tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WhatsNewView(
              releases: releases,
              localeCode: 'en',
              onClose: onClose ?? () {},
              onViewFullChangelog: onViewFullChangelog,
            ),
          ),
        ));

    testWidgets('one version: its number in the title, no headings',
        (tester) async {
      await pump(tester, [
        _release('0.3.1', ['Widgets on the home screen']),
      ]);
      expect(find.text("What's new in 0.3.1"), findsOneWidget);
      expect(find.text('Widgets on the home screen'), findsOneWidget);
      expect(find.text('Version 0.3.1'), findsNothing);
    });

    testWidgets('several versions: a heading for each', (tester) async {
      await pump(tester, [_release('0.4.0'), _release('0.3.1')]);
      expect(find.text("What's new"), findsOneWidget);
      expect(find.text('Version 0.4.0'), findsOneWidget);
      expect(find.text('Version 0.3.1'), findsOneWidget);
    });

    testWidgets('the buttons close it and open the full changelog',
        (tester) async {
      var closed = false;
      var openedFull = false;
      await pump(
        tester,
        [_release('0.3.1')],
        onClose: () => closed = true,
        onViewFullChangelog: () => openedFull = true,
      );
      await tester.tap(find.text('Got it'));
      await tester.tap(find.text('Full changelog'));
      expect(closed, isTrue);
      expect(openedFull, isTrue);
    });
  });
}
