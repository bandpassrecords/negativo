import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/film_roll.dart';
import '../models/exposure.dart';
import 'hive_service.dart';
import 'notification_service.dart';

class FilmService {
  static const _uuid = Uuid();

  /// Returns the currently active (loaded) film roll, or null if none.
  static FilmRoll? getActiveRoll() {
    return HiveService.getActiveRoll();
  }

  /// Creates a new film roll and sets it as active.
  static Future<FilmRoll> loadNewRoll(String name, int capacity) async {
    final settings = HiveService.getSettings();
    final roll = FilmRoll(
      id: _uuid.v4(),
      name: name,
      capacity: capacity,
      createdAt: DateTime.now(),
      developmentDurationHours: settings.developmentDurationHours,
    );
    await HiveService.saveFilmRoll(roll);
    return roll;
  }

  /// Adds an exposure (photo) to the given film roll.
  static Future<Exposure> addExposure(FilmRoll roll, String imagePath) async {
    final savedPath = await _copyToFilmsDirectory(imagePath);
    final exposure = Exposure(
      id: _uuid.v4(),
      filmRollId: roll.id,
      order: roll.exposureCount + 1,
      imagePath: savedPath,
      capturedAt: DateTime.now(),
    );
    await HiveService.saveExposure(exposure);
    roll.exposureIds.add(exposure.id);
    await HiveService.saveFilmRoll(roll);
    return exposure;
  }

  /// Sends the roll for development (starts the development timer).
  static Future<void> startDevelopment(FilmRoll roll) async {
    roll.status = 'developing';
    roll.developmentStartedAt = DateTime.now();
    await HiveService.saveFilmRoll(roll);

    final settings = HiveService.getSettings();
    if (settings.developmentNotificationsEnabled) {
      await NotificationService.scheduleDevelopmentNotification(roll);
    }
  }

  /// Instantly marks a developing roll as developed (for testing only).
  static Future<void> instantDevelop(FilmRoll roll) async {
    roll.status = 'developed';
    await HiveService.saveFilmRoll(roll);
    await NotificationService.cancelDevelopmentNotification(roll.id);
  }

  /// Checks all developing rolls and marks any completed ones as 'developed'.
  static Future<List<FilmRoll>> checkDevelopmentCompletions() async {
    final developing = HiveService.getFilmRollsByStatus('developing');
    final completed = <FilmRoll>[];
    for (final roll in developing) {
      if (roll.isDevelopmentComplete) {
        roll.status = 'developed';
        await HiveService.saveFilmRoll(roll);
        await NotificationService.cancelDevelopmentNotification(roll.id);
        completed.add(roll);
      }
    }
    return completed;
  }

  /// Deletes a film roll and all its exposures (and image files).
  static Future<void> deleteRoll(FilmRoll roll) async {
    final exposures = HiveService.getExposuresForRoll(roll.id);
    for (final exposure in exposures) {
      await _deleteFile(exposure.imagePath);
      await HiveService.deleteExposure(exposure.id);
    }
    await NotificationService.cancelDevelopmentNotification(roll.id);
    await HiveService.deleteFilmRoll(roll.id);
  }

  static Future<String> _copyToFilmsDirectory(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final filmsDir = Directory(path.join(appDir.path, 'films'));
    if (!await filmsDir.exists()) {
      await filmsDir.create(recursive: true);
    }
    final ext = path.extension(sourcePath);
    final destPath = path.join(filmsDir.path, '${_uuid.v4()}$ext');
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  static Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
