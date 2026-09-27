import 'package:flutter_test/flutter_test.dart';

import 'package:negativo/models/exposure.dart';
import 'package:negativo/models/film_roll.dart';
import 'package:negativo/services/camera_shortcut_service.dart';

FilmRoll _roll(
  String id, {
  String status = 'active',
  int capacity = 24,
  int shot = 0,
  DateTime? createdAt,
}) =>
    FilmRoll(
      id: id,
      name: 'Roll $id',
      capacity: capacity,
      status: status,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      exposureIds: [for (var i = 0; i < shot; i++) '$id-$i'],
    );

Exposure _shot(String rollId, DateTime at) => Exposure(
      id: '$rollId-$at',
      filmRollId: rollId,
      order: 1,
      imagePath: '/x.jpg',
      capturedAt: at,
    );

List<CameraShortcut> _plan(List<FilmRoll> rolls,
        [List<Exposure> exposures = const []]) =>
    planCameraShortcuts(
      rolls: rolls,
      exposures: exposures,
      shootOnRollTitle: (name) => 'Shoot on $name',
      chooseRollTitle: 'Choose a roll',
    );

void main() {
  group('shootableRolls', () {
    test('only loaded rolls with frames left', () {
      final rolls = [
        _roll('a'),
        _roll('full', capacity: 12, shot: 12),
        _roll('dev', status: 'developing'),
        _roll('done', status: 'developed'),
      ];
      expect(shootableRolls(rolls).map((r) => r.id), ['a']);
    });
  });

  group('lastUsedRoll', () {
    test('is the roll shot on most recently', () {
      final rolls = [_roll('a'), _roll('b')];
      final exposures = [
        _shot('a', DateTime(2026, 3, 1)),
        _shot('b', DateTime(2026, 3, 5)),
        _shot('a', DateTime(2026, 3, 2)),
      ];
      expect(lastUsedRoll(rolls, exposures)!.id, 'b');
    });

    test('a roll not shot on yet counts from when it was loaded', () {
      final rolls = [
        _roll('old', createdAt: DateTime(2026, 1, 1)),
        _roll('fresh', createdAt: DateTime(2026, 4, 1)),
      ];
      final exposures = [_shot('old', DateTime(2026, 2, 1))];
      expect(lastUsedRoll(rolls, exposures)!.id, 'fresh');
    });

    test('ignores a roll that has since filled up or gone to develop', () {
      final rolls = [
        _roll('a'),
        _roll('full', capacity: 1, shot: 1),
        _roll('dev', status: 'developing'),
      ];
      final exposures = [
        _shot('full', DateTime(2026, 5, 1)),
        _shot('dev', DateTime(2026, 6, 1)),
      ];
      expect(lastUsedRoll(rolls, exposures)!.id, 'a');
    });

    test('is null with nothing to shoot on', () {
      expect(lastUsedRoll([_roll('d', status: 'developed')], const []),
          isNull);
    });
  });

  group('planCameraShortcuts', () {
    test('no loaded roll: no shortcuts', () {
      expect(_plan([_roll('d', status: 'developing')]), isEmpty);
    });

    test('one roll: a single "take a photo" shortcut on it', () {
      expect(_plan([_roll('a')]), [
        const CameraShortcut(CameraShortcutKind.shootLastRoll, 'Shoot on Roll a'),
      ]);
    });

    test('several rolls: the last-used one, plus "choose a roll"', () {
      final plan = _plan(
        [_roll('a'), _roll('b')],
        [_shot('a', DateTime(2026, 3, 9))],
      );
      expect(plan, [
        const CameraShortcut(CameraShortcutKind.shootLastRoll, 'Shoot on Roll a'),
        const CameraShortcut(CameraShortcutKind.chooseRoll, 'Choose a roll'),
      ]);
    });

    test('a full roll does not count towards offering a choice', () {
      final plan = _plan([_roll('a'), _roll('full', capacity: 1, shot: 1)]);
      expect(plan.map((s) => s.kind), [CameraShortcutKind.shootLastRoll]);
    });
  });

  group('CameraShortcutKind', () {
    test('round-trips through the platform type id', () {
      for (final kind in CameraShortcutKind.values) {
        expect(CameraShortcutKind.fromType(kind.type), kind);
      }
      expect(CameraShortcutKind.fromType('something_else'), isNull);
    });
  });
}
