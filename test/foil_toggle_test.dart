import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:negativo/effects/film_effect.dart';
import 'package:negativo/hive_registrar.g.dart';
import 'package:negativo/models/exposure.dart';
import 'package:negativo/models/film_roll.dart';

Exposure _exposure({String? effect, bool foilEnabled = true}) => Exposure(
      id: 'e1',
      filmRollId: 'r1',
      order: 1,
      imagePath: '/nowhere.jpg',
      capturedAt: DateTime(2026, 1, 1),
      filmEffect: effect,
      foilEnabled: foilEnabled,
    );

FilmRoll _roll({
  bool foilEnabled = true,
  String? effect,
  bool effectEnabled = true,
}) =>
    FilmRoll(
      id: 'r1',
      name: 'Trip',
      capacity: 24,
      createdAt: DateTime(2026, 1, 1),
      foilEnabled: foilEnabled,
      filmEffect: effect,
      effectEnabled: effectEnabled,
    );

void main() {
  const shiny = 'shiny:3';

  group('per-photo foil switch', () {
    test('a new photo shows its foil', () {
      expect(_exposure().foilEnabled, isTrue);
    });

    test('a Shiny photo shows the foil when both switches are on', () {
      final e = _exposure(effect: shiny);
      expect(FilmEffect.forExposure(e, _roll())?.isRare, isTrue);
      expect(FilmEffect.hasFoilShown(e, _roll()), isTrue);
    });

    test('turning it off for one photo hides that photo’s foil', () {
      final e = _exposure(effect: shiny, foilEnabled: false);
      expect(FilmEffect.forExposure(e, _roll())?.isRare ?? false, isFalse);
      expect(FilmEffect.hasFoilShown(e, _roll()), isFalse);
      expect(FilmEffect.hasFoil(e), isTrue,
          reason: 'still has one to switch back on');
    });

    test('the album switch still turns every foil off', () {
      final e = _exposure(effect: shiny);
      expect(FilmEffect.hasFoilShown(e, _roll(foilEnabled: false)), isFalse);
    });

    test('with the foil off, the roll’s own effect shows instead', () {
      final e = _exposure(effect: shiny, foilEnabled: false);
      final roll = _roll(effect: 'lightLeak:2');
      expect(FilmEffect.forExposure(e, roll)?.serialized, 'lightLeak:2');
    });

    test('a photo with no foil has nothing to switch', () {
      expect(FilmEffect.hasFoil(_exposure()), isFalse);
      expect(FilmEffect.hasFoil(_exposure(effect: 'lightLeak:2')), isFalse);
    });

    test('the per-photo switch does not affect non-foil effects', () {
      final e = _exposure(effect: 'lightLeak:1', foilEnabled: false);
      expect(FilmEffect.forExposure(e, _roll())?.serialized, 'lightLeak:1');
    });
  });

  group('storage', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('negativo_foil_');
      Hive.init(dir.path);
      if (!Hive.isAdapterRegistered(6)) Hive.registerAdapters();
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('the switch is saved with the photo', () async {
      final box = await Hive.openBox<Exposure>('exposures');
      await box.put('e1', _exposure(effect: shiny, foilEnabled: false));
      await box.close();

      final reopened = await Hive.openBox<Exposure>('exposures');
      expect(reopened.get('e1')!.foilEnabled, isFalse);
    });
  });
}
