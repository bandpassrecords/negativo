import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';

import '../l10n/app_localizations.dart';
import '../models/exposure.dart';
import '../models/film_roll.dart';
import '../screens/new_roll_screen.dart';
import '../screens/roll_picker_screen.dart';
import '../screens/viewfinder_screen.dart';
import 'app_navigator.dart';
import 'hive_service.dart';

/// What a camera shortcut does when tapped.
enum CameraShortcutKind {
  /// Straight into the viewfinder for the roll shot on most recently.
  shootLastRoll('shoot_last_roll'),

  /// A list of the loaded rolls to pick one from, then the viewfinder.
  chooseRoll('choose_roll'),

  /// "Camera", always there (Android): the last-used roll, or "load a roll"
  /// when there is nothing to shoot on. Its fixed id and title make it the
  /// one to drag onto the home screen as an icon, like Instagram's camera.
  camera('camera');

  const CameraShortcutKind(this.type);

  /// The id the platform hands back when the shortcut is tapped.
  final String type;

  static CameraShortcutKind? fromType(String type) {
    for (final kind in values) {
      if (kind.type == type) return kind;
    }
    return null;
  }
}

/// One home-screen shortcut, before it is handed to the platform.
class CameraShortcut {
  const CameraShortcut(this.kind, this.title);

  final CameraShortcutKind kind;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is CameraShortcut && other.kind == kind && other.title == title;

  @override
  int get hashCode => Object.hash(kind, title);

  @override
  String toString() => 'CameraShortcut(${kind.type}, $title)';
}

/// The rolls a shortcut can open the camera on: loaded and not yet full.
List<FilmRoll> shootableRolls(Iterable<FilmRoll> rolls) => [
      for (final r in rolls)
        if (r.status == 'active' && !r.isFull) r
    ];

/// The roll someone most likely wants to keep shooting: the one with the most
/// recent exposure, or — for rolls not shot on yet — the most recently loaded.
/// Null when there is nothing to shoot on.
FilmRoll? lastUsedRoll(Iterable<FilmRoll> rolls, Iterable<Exposure> exposures) {
  final shootable = shootableRolls(rolls);
  if (shootable.isEmpty) return null;
  final lastShot = <String, DateTime>{};
  for (final e in exposures) {
    final seen = lastShot[e.filmRollId];
    if (seen == null || e.capturedAt.isAfter(seen)) {
      lastShot[e.filmRollId] = e.capturedAt;
    }
  }
  DateTime usedAt(FilmRoll r) => lastShot[r.id] ?? r.createdAt;
  return shootable.reduce((a, b) => usedAt(b).isAfter(usedAt(a)) ? b : a);
}

/// Which shortcuts to offer:
///
/// - with [cameraTitle] (Android) → "Camera" always, in place of "take a
///   photo on <roll>", so an icon dragged onto the home screen keeps working;
/// - otherwise, one or more rolls to shoot on → "take a photo" on the
///   last-used roll, and none without (the app icon alone is the way in);
/// - more than one → also "choose a roll".
List<CameraShortcut> planCameraShortcuts({
  required Iterable<FilmRoll> rolls,
  required Iterable<Exposure> exposures,
  required String Function(String rollName) shootOnRollTitle,
  required String chooseRollTitle,
  String? cameraTitle,
}) {
  final last = lastUsedRoll(rolls, exposures);
  return [
    if (cameraTitle != null)
      CameraShortcut(CameraShortcutKind.camera, cameraTitle)
    else if (last != null)
      CameraShortcut(
          CameraShortcutKind.shootLastRoll, shootOnRollTitle(last.name)),
    if (shootableRolls(rolls).length > 1)
      CameraShortcut(CameraShortcutKind.chooseRoll, chooseRollTitle),
  ];
}

/// Keeps the app icon's shortcuts (long-press on iOS and Android; on Android
/// a shortcut can also be dragged onto the home screen as its own icon) in
/// step with the rolls, and opens the camera when one is tapped.
class CameraShortcutService {
  CameraShortcutService._();

  static const _quickActions = QuickActions();
  static List<CameraShortcut>? _published;
  static final _subscriptions = <StreamSubscription<dynamic>>[];
  static Timer? _debounce;

  /// Starts listening for taps and keeps the shortcuts current as rolls are
  /// loaded, shot, sent to develop or deleted.
  static Future<void> init() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    await _quickActions.initialize(_onTapped);
    await refresh();
    _subscriptions
      ..add(HiveService.watchFilmRolls().listen((_) => _scheduleRefresh()))
      ..add(HiveService.watchExposures().listen((_) => _scheduleRefresh()));
  }

  static void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), refresh);
  }

  /// Re-publishes the shortcuts — also after a language change, since their
  /// titles are localised.
  static Future<void> refresh() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    final l = lookupAppLocalizations(
      Locale(HiveService.getSettings().language),
    );
    final plan = planCameraShortcuts(
      rolls: HiveService.getAllFilmRolls(),
      exposures: HiveService.getAllExposures(),
      shootOnRollTitle: l.shortcutShootOnRoll,
      chooseRollTitle: l.shortcutChooseRoll,
      cameraTitle: Platform.isAndroid ? l.shortcutCamera : null,
    );
    if (_listEquals(plan, _published)) return;
    _published = plan;
    await _quickActions.setShortcutItems([
      for (final s in plan)
        ShortcutItem(
          type: s.kind.type,
          localizedTitle: s.title,
          // Android drawables in res/drawable; iOS falls back to no icon.
          icon: Platform.isAndroid
              ? (s.kind == CameraShortcutKind.chooseRoll
                  ? 'ic_shortcut_rolls'
                  : 'ic_shortcut_camera')
              : null,
        ),
    ]);
  }

  static void _onTapped(String type) {
    final kind = CameraShortcutKind.fromType(type);
    if (kind == null) return;
    // A cold start delivers the tap before the first screen exists;
    // AppNavigator holds it until the app can navigate.
    AppNavigator.run((nav) => _open(kind, nav));
  }

  static void _open(CameraShortcutKind kind, NavigatorState nav) {
    // Decide at tap time: the roll may have filled up or been sent off since
    // the shortcut was published.
    final rolls = HiveService.getAllFilmRolls();
    final shootable = shootableRolls(rolls);
    if (shootable.isEmpty) {
      // "Camera" with nothing to shoot on: offer to load a roll. The others
      // just open the app.
      if (kind == CameraShortcutKind.camera) {
        nav.push(MaterialPageRoute(builder: (_) => const NewRollScreen()));
      }
      return;
    }

    if (kind == CameraShortcutKind.chooseRoll && shootable.length > 1) {
      nav.push(MaterialPageRoute(builder: (_) => const RollPickerScreen()));
      return;
    }
    final roll = kind == CameraShortcutKind.chooseRoll
        ? shootable.single
        : lastUsedRoll(rolls, HiveService.getAllExposures())!;
    nav.push(
      MaterialPageRoute(builder: (_) => ViewfinderScreen(filmRoll: roll)),
    );
  }

  static bool _listEquals(List<CameraShortcut> a, List<CameraShortcut>? b) {
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
