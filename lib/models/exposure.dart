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

  Exposure({
    required this.id,
    required this.filmRollId,
    required this.order,
    required this.imagePath,
    required this.capturedAt,
  });
}
