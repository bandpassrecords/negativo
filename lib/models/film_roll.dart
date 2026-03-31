import 'package:hive_ce/hive.dart';

part 'film_roll.g.dart';

@HiveType(typeId: 5)
class FilmRoll extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int capacity; // 12, 24, 36

  @HiveField(3)
  String status; // 'active' | 'developing' | 'developed'

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? developmentStartedAt;

  @HiveField(6)
  int developmentDurationHours;

  @HiveField(7)
  List<String> exposureIds;

  @HiveField(8)
  String? filmStockId;

  FilmRoll({
    required this.id,
    required this.name,
    required this.capacity,
    this.status = 'active',
    required this.createdAt,
    this.developmentStartedAt,
    this.developmentDurationHours = 48,
    List<String>? exposureIds,
    this.filmStockId,
  }) : exposureIds = exposureIds ?? [];

  int get exposureCount => exposureIds.length;
  int get remainingFrames => capacity - exposureIds.length;
  bool get isFull => exposureIds.length >= capacity;

  DateTime? get developmentCompletesAt =>
      developmentStartedAt?.add(Duration(hours: developmentDurationHours));

  bool get isDevelopmentComplete =>
      developmentCompletesAt != null &&
      DateTime.now().isAfter(developmentCompletesAt!);

  Duration? get remainingDevelopmentTime {
    final completesAt = developmentCompletesAt;
    if (completesAt == null) return null;
    final remaining = completesAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
