import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:negativo/l10n/app_localizations.dart';
import 'package:negativo/models/exposure.dart';
import 'package:negativo/models/film_roll.dart';
import 'package:negativo/services/roll_widget_service.dart';

final _now = DateTime(2026, 5, 10, 12);

FilmRoll _roll(
  String id, {
  String status = 'active',
  int capacity = 24,
  int shot = 0,
  DateTime? createdAt,
  DateTime? devStarted,
  int devHours = 48,
  List<String> revealed = const [],
  String? stock,
}) =>
    FilmRoll(
      id: id,
      name: 'Roll $id',
      capacity: capacity,
      status: status,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      developmentStartedAt: devStarted,
      developmentDurationHours: devHours,
      exposureIds: [for (var i = 0; i < shot; i++) '$id-$i'],
      revealedExposureIds: List.of(revealed),
      filmStockId: stock,
    );

Exposure _shot(String rollId, int n, DateTime at) => Exposure(
      id: '$rollId-$n',
      filmRollId: rollId,
      order: n + 1,
      imagePath: '/x.jpg',
      capturedAt: at,
    );

List<Map<String, Object?>> _entries(
  List<FilmRoll> rolls, [
  List<Exposure> exposures = const [],
  bool revealEnabled = true,
]) =>
    rollWidgetEntries(
      rolls: rolls,
      exposures: exposures,
      revealEnabled: revealEnabled,
      now: _now,
    );

void main() {
  group('rollWidgetEntries', () {
    test('loaded rolls first, the one shot on most recently leading', () {
      final entries = _entries(
        [_roll('a'), _roll('b')],
        [
          _shot('a', 0, DateTime(2026, 5, 1)),
          _shot('b', 0, DateTime(2026, 5, 9)),
        ],
      );
      expect(entries.map((e) => e['id']), ['b', 'a']);
      expect(entries.every((e) => e['state'] == 'shoot'), isTrue);
    });

    test('a full roll is shown as needing to go to develop', () {
      final entries = _entries([_roll('full', capacity: 2, shot: 2)]);
      expect(entries.single['state'], 'full');
      expect(entries.single['used'], 2);
      expect(entries.single['capacity'], 2);
    });

    test('a roll at the lab carries when it will be ready', () {
      final started = DateTime(2026, 5, 10, 8);
      final entries = _entries([
        _roll('lab', status: 'developing', devStarted: started, devHours: 24),
      ]);
      expect(entries.single['state'], 'developing');
      expect(entries.single['readyAtMillis'],
          started.add(const Duration(hours: 24)).millisecondsSinceEpoch);
    });

    test('a lab roll whose time is up shows as ready', () {
      final entries = _entries([
        _roll('lab',
            status: 'developing',
            devStarted: DateTime(2026, 5, 1),
            devHours: 24),
      ]);
      expect(entries.single['state'], 'ready');
      expect(entries.single['readyAtMillis'], isNull);
    });

    test(
        'a developed roll with frames to reveal is ready; a revealed one is gone',
        () {
      final entries = _entries(
        [
          _roll('waiting',
              status: 'developed', shot: 2, revealed: ['waiting-0']),
          _roll('done', status: 'developed', shot: 1, revealed: ['done-0']),
        ],
        [
          _shot('waiting', 0, DateTime(2026, 4, 1)),
          _shot('waiting', 1, DateTime(2026, 4, 1)),
          _shot('done', 0, DateTime(2026, 4, 1)),
        ],
      );
      expect(entries.map((e) => e['id']), ['waiting']);
      expect(entries.single['state'], 'ready');
    });

    test('with reveal turned off, developed rolls are not waiting', () {
      final entries = _entries(
        [_roll('d', status: 'developed', shot: 1)],
        [_shot('d', 0, DateTime(2026, 4, 1))],
        false,
      );
      expect(entries, isEmpty);
    });

    test('the arrows go loaded → at the lab (soonest first) → to reveal', () {
      final entries = _entries(
        [
          _roll('late', status: 'developing', devStarted: _now, devHours: 72),
          _roll('reveal', status: 'developed', shot: 1),
          _roll('loaded'),
          _roll('soon', status: 'developing', devStarted: _now, devHours: 2),
        ],
        [_shot('reveal', 0, DateTime(2026, 4, 1))],
      );
      expect(entries.map((e) => e['id']), ['loaded', 'soon', 'late', 'reveal']);
    });

    test('names the film stock when the roll has one', () {
      final stocked = _entries([_roll('s', stock: 'hp5')]).single;
      expect((stocked['stock'] as String), isNotEmpty);
      expect(_entries([_roll('n')]).single['stock'], '');
    });
  });

  test('labels keep the placeholders the widget fills in itself', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final labels = rollWidgetLabels(l);
    expect(labels['framesOf'], contains('{used}'));
    expect(labels['framesOf'], contains('{total}'));
    expect(labels['readyInDays'], allOf(contains('{d}'), contains('{h}')));
    expect(labels['readyInHours'], allOf(contains('{h}'), contains('{m}')));
    for (final key in ['ready', 'full', 'empty', 'load']) {
      expect(labels[key], isNotEmpty, reason: key);
    }
  });

  test('every language keeps the placeholders', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      final labels = rollWidgetLabels(l);
      expect(labels['readyInDays'], allOf(contains('{d}'), contains('{h}')),
          reason: '$locale');
      expect(labels['readyInHours'], allOf(contains('{h}'), contains('{m}')),
          reason: '$locale');
    }
  });

  group('parseRollWidgetUri', () {
    test('reads the links the widgets open', () {
      expect(parseRollWidgetUri(Uri.parse('negativo://widget/shoot?roll=r1')),
          const RollWidgetLink(RollWidgetTap.shoot, 'r1'));
      expect(parseRollWidgetUri(Uri.parse('negativo://widget/roll?roll=r2')),
          const RollWidgetLink(RollWidgetTap.openRoll, 'r2'));
      expect(parseRollWidgetUri(Uri.parse('negativo://widget/new')),
          const RollWidgetLink(RollWidgetTap.newRoll));
      expect(parseRollWidgetUri(Uri.parse('negativo://widget/camera')),
          const RollWidgetLink(RollWidgetTap.camera));
    });

    test('ignores anything that is not a widget link', () {
      expect(parseRollWidgetUri(null), isNull);
      expect(parseRollWidgetUri(Uri.parse('https://widget/shoot?roll=r1')),
          isNull);
      expect(parseRollWidgetUri(Uri.parse('negativo://other/shoot?roll=r1')),
          isNull);
      expect(parseRollWidgetUri(Uri.parse('negativo://widget/shoot')), isNull,
          reason: 'no roll to shoot on');
      expect(
          parseRollWidgetUri(Uri.parse('negativo://widget/unknown')), isNull);
    });
  });

  group('rollWidgetDestination', () {
    RollWidgetDestination where(RollWidgetLink link, FilmRoll? roll,
            [List<Exposure> exposures = const []]) =>
        rollWidgetDestination(link, roll, exposures, revealEnabled: true);

    const shoot = RollWidgetLink(RollWidgetTap.shoot, 'x');
    const open = RollWidgetLink(RollWidgetTap.openRoll, 'x');

    test('the shutter opens the camera on a roll with frames left', () {
      expect(where(shoot, _roll('x')), RollWidgetDestination.viewfinder);
    });

    test('a roll that filled up since goes to its page instead', () {
      expect(where(shoot, _roll('x', capacity: 1, shot: 1)),
          RollWidgetDestination.rollDetail);
    });

    test('a roll at the lab opens its page', () {
      expect(where(open, _roll('x', status: 'developing')),
          RollWidgetDestination.rollDetail);
    });

    test('a developed roll opens the reveal, or the gallery once revealed', () {
      final exposures = [_shot('x', 0, DateTime(2026, 4, 1))];
      expect(where(open, _roll('x', status: 'developed', shot: 1), exposures),
          RollWidgetDestination.reveal);
      expect(
        where(
          open,
          _roll('x', status: 'developed', shot: 1, revealed: ['x-0']),
          exposures,
        ),
        RollWidgetDestination.gallery,
      );
    });

    test('the camera widget shoots on the last-used roll', () {
      const camera = RollWidgetLink(RollWidgetTap.camera);
      expect(where(camera, _roll('x')), RollWidgetDestination.viewfinder);
    });

    test('with no roll to shoot on, the camera widget offers to load one', () {
      const camera = RollWidgetLink(RollWidgetTap.camera);
      expect(where(camera, null), RollWidgetDestination.newRoll);
    });

    test('a deleted roll opens nothing; "load a roll" always works', () {
      expect(where(open, null), RollWidgetDestination.nothing);
      expect(where(const RollWidgetLink(RollWidgetTap.newRoll), null),
          RollWidgetDestination.newRoll);
    });
  });
}
