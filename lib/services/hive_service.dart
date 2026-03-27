import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../hive_registrar.g.dart';
import '../models/film_roll.dart';
import '../models/exposure.dart';
import '../models/app_settings.dart';

class HiveService {
  static const String _filmRollsBoxName = 'film_rolls';
  static const String _exposuresBoxName = 'exposures';
  static const String _settingsBoxName = 'app_settings';
  static const String _settingsKey = 'settings';

  static Box<FilmRoll>? _filmRollsBox;
  static Box<Exposure>? _exposuresBox;
  static Box<AppSettings>? _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapters();

    _filmRollsBox = await Hive.openBox<FilmRoll>(_filmRollsBoxName);
    _exposuresBox = await Hive.openBox<Exposure>(_exposuresBoxName);
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);

    if (_settingsBox!.isEmpty) {
      await saveSettings(AppSettings());
    }
  }

  // ========== Film Rolls ==========

  static Future<void> saveFilmRoll(FilmRoll roll) async {
    await _filmRollsBox!.put(roll.id, roll);
  }

  static FilmRoll? getFilmRoll(String id) {
    return _filmRollsBox!.get(id);
  }

  static List<FilmRoll> getAllFilmRolls() {
    return _filmRollsBox!.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static FilmRoll? getActiveRoll() {
    final rolls = _filmRollsBox!.values.where((r) => r.status == 'active').toList();
    return rolls.isEmpty ? null : rolls.first;
  }

  static List<FilmRoll> getFilmRollsByStatus(String status) {
    return _filmRollsBox!.values
        .where((r) => r.status == status)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> deleteFilmRoll(String id) async {
    await _filmRollsBox!.delete(id);
  }

  static int getTotalRolls() => _filmRollsBox!.length;

  static int getTotalDevelopedRolls() =>
      _filmRollsBox!.values.where((r) => r.status == 'developed').length;

  // ========== Exposures ==========

  static Future<void> saveExposure(Exposure exposure) async {
    await _exposuresBox!.put(exposure.id, exposure);
  }

  static Exposure? getExposure(String id) {
    return _exposuresBox!.get(id);
  }

  static List<Exposure> getExposuresForRoll(String rollId) {
    return _exposuresBox!.values
        .where((e) => e.filmRollId == rollId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  static Future<void> deleteExposure(String id) async {
    await _exposuresBox!.delete(id);
  }

  static int getTotalExposures() => _exposuresBox!.length;

  // ========== Settings ==========

  static AppSettings getSettings() {
    return _settingsBox!.get(_settingsKey) ?? AppSettings();
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox!.put(_settingsKey, settings);
  }

  // ========== Cleanup ==========

  static Future<void> close() async {
    await _filmRollsBox?.close();
    await _exposuresBox?.close();
    await _settingsBox?.close();
  }
}
