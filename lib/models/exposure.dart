import 'package:hive_ce/hive.dart';

part 'exposure.g.dart';

@HiveType(typeId: 6)
class Exposure extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String filmRollId;

  @HiveField(2)
  int order; // 1-based frame number

  @HiveField(3)
  String imagePath;

  @HiveField(4)
  DateTime capturedAt;

  @HiveField(5)
  String? filmEffect; // serialized FilmEffect, e.g. "lightLeak:2"

  /// Whether this photo's Shiny foil is shown. The album has its own switch
  /// ([FilmRoll.foilEnabled]); the foil shows only when both are on, so one
  /// photo can be turned plain without touching the rest of the roll.
  /// Defaults to on for photos saved before the switch existed.
  @HiveField(6, defaultValue: true)
  bool foilEnabled;

  Exposure({
    required this.id,
    required this.filmRollId,
    required this.order,
    required this.imagePath,
    required this.capturedAt,
    this.filmEffect,
    this.foilEnabled = true,
  });
}
