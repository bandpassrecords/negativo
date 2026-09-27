import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../l10n/app_localizations.dart';
import '../models/exposure.dart';
import '../models/film_roll.dart';
import '../models/film_stock.dart';
import '../screens/developed_gallery_screen.dart';
import '../screens/film_roll_detail_screen.dart';
import '../screens/new_roll_screen.dart';
import '../screens/reveal_gallery_screen.dart';
import '../screens/viewfinder_screen.dart';
import 'app_navigator.dart';
import 'camera_shortcut_service.dart';
import 'film_service.dart';
import 'hive_service.dart';

/// Key the rolls are stored under for the Android widget
/// (RollWidgetProvider.DATA_KEY — keep the two in step).
const kRollWidgetDataKey = 'roll_widget_v1';
const _androidProvider = 'com.bandpassrecords.negativo.RollWidgetProvider';

/// What the widget shows for a roll — the "state" RollWidgetProvider reads.
enum RollWidgetState {
  /// Loaded, frames left: the shutter shows.
  shoot,

  /// Loaded but every frame used: it needs sending off to develop.
  full,

  /// At the lab: a countdown to when it's ready.
  developing,

  /// Developed with frames still to reveal.
  ready,
}

/// Whether opening [roll] should go to the reveal rather than the gallery —
/// the albums tab's rule: frames left to develop, unless reveal is turned off.
bool needsReveal(
  FilmRoll roll,
  Iterable<Exposure> rollExposures, {
  required bool revealEnabled,
}) {
  if (!revealEnabled) return false;
  final revealed = roll.revealedExposureIds.toSet();
  return rollExposures.any((e) => !revealed.contains(e.id));
}

/// The rolls the widget can show, in the order its arrows go through them:
/// loaded rolls, the one shot on most recently first; then rolls at the lab,
/// soonest ready first; then developed rolls still waiting to be revealed.
List<Map<String, Object?>> rollWidgetEntries({
  required Iterable<FilmRoll> rolls,
  required Iterable<Exposure> exposures,
  required bool revealEnabled,
  required DateTime now,
}) {
  final byRoll = <String, List<Exposure>>{};
  final lastShot = <String, DateTime>{};
  for (final e in exposures) {
    (byRoll[e.filmRollId] ??= []).add(e);
    final seen = lastShot[e.filmRollId];
    if (seen == null || e.capturedAt.isAfter(seen)) {
      lastShot[e.filmRollId] = e.capturedAt;
    }
  }
  DateTime usedAt(FilmRoll r) => lastShot[r.id] ?? r.createdAt;

  final loaded = [
    for (final r in rolls)
      if (r.status == 'active') r
  ]..sort((a, b) => usedAt(b).compareTo(usedAt(a)));
  final developing = [
    for (final r in rolls)
      if (r.status == 'developing') r
  ]..sort((a, b) => (a.developmentCompletesAt ?? now)
      .compareTo(b.developmentCompletesAt ?? now));
  final waiting = [
    for (final r in rolls)
      if (r.status == 'developed' &&
          needsReveal(r, byRoll[r.id] ?? const [],
              revealEnabled: revealEnabled))
        r,
  ];

  Map<String, Object?> entry(FilmRoll r, RollWidgetState state) {
    final stock = FilmStock.fromId(r.filmStockId);
    return {
      'id': r.id,
      'name': r.name,
      'stock': stock == null ? '' : '${stock.brand} ${stock.name}',
      'used': r.exposureCount,
      'capacity': r.capacity,
      'state': state.name,
      'readyAtMillis': state == RollWidgetState.developing
          ? r.developmentCompletesAt?.millisecondsSinceEpoch
          : null,
    };
  }

  return [
    for (final r in loaded)
      entry(r, r.isFull ? RollWidgetState.full : RollWidgetState.shoot),
    for (final r in developing)
      entry(
        r,
        (r.developmentCompletesAt?.isAfter(now) ?? false)
            ? RollWidgetState.developing
            : RollWidgetState.ready,
      ),
    for (final r in waiting) entry(r, RollWidgetState.ready),
  ];
}

/// Wording for the widget, in the app's language. Placeholders in braces are
/// filled in by the widget itself when it draws (the countdown changes
/// between app launches).
Map<String, String> rollWidgetLabels(AppLocalizations l) => {
      'framesOf': l.widgetFramesOf('{used}', '{total}'),
      'readyInDays': l.widgetReadyInDays('{d}', '{h}'),
      'readyInHours': l.widgetReadyInHours('{h}', '{m}'),
      'ready': l.widgetReady,
      'full': l.widgetFull,
      'empty': l.rollsEmpty,
      'load': l.rollsLoadFilmRoll,
    };

/// A tap on a widget, read from the link it opened the app with.
enum RollWidgetTap {
  shoot,
  openRoll,
  newRoll,

  /// The camera widget: shoot on whichever roll was used last.
  camera,
}

class RollWidgetLink {
  const RollWidgetLink(this.tap, [this.rollId]);

  final RollWidgetTap tap;
  final String? rollId;

  @override
  bool operator ==(Object other) =>
      other is RollWidgetLink && other.tap == tap && other.rollId == rollId;

  @override
  int get hashCode => Object.hash(tap, rollId);

  @override
  String toString() => 'RollWidgetLink($tap, $rollId)';
}

/// Reads `negativo://widget/shoot?roll=<id>`, `…/roll?roll=<id>` and
/// `…/new` (see RollWidgetState.tapUri on the Android side), and the camera
/// widget's `…/camera` (CameraWidgetProvider.CAMERA_URI). Anything else is
/// not a widget link.
RollWidgetLink? parseRollWidgetUri(Uri? uri) {
  if (uri == null || uri.scheme != 'negativo' || uri.host != 'widget') {
    return null;
  }
  final path = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
  final roll = uri.queryParameters['roll'];
  return switch (path) {
    'shoot' when roll != null => RollWidgetLink(RollWidgetTap.shoot, roll),
    'roll' when roll != null => RollWidgetLink(RollWidgetTap.openRoll, roll),
    'new' => const RollWidgetLink(RollWidgetTap.newRoll),
    'camera' => const RollWidgetLink(RollWidgetTap.camera),
    _ => null,
  };
}

/// Where a widget tap should land.
enum RollWidgetDestination {
  viewfinder,
  rollDetail,
  reveal,
  gallery,
  newRoll,
  nothing
}

/// Decided at tap time from the roll as it is now — it may have filled up,
/// finished developing or been deleted since the widget was drawn. For the
/// camera widget [roll] is the last-used roll with frames left, if any.
RollWidgetDestination rollWidgetDestination(
  RollWidgetLink link,
  FilmRoll? roll,
  Iterable<Exposure> rollExposures, {
  required bool revealEnabled,
}) {
  if (link.tap == RollWidgetTap.newRoll) return RollWidgetDestination.newRoll;
  // Nothing to shoot on: offer to load a roll rather than do nothing.
  if (link.tap == RollWidgetTap.camera && roll == null) {
    return RollWidgetDestination.newRoll;
  }
  if (roll == null) return RollWidgetDestination.nothing;
  switch (roll.status) {
    case 'active':
      return roll.isFull
          ? RollWidgetDestination.rollDetail
          : RollWidgetDestination.viewfinder;
    case 'developing':
      return RollWidgetDestination.rollDetail;
    default:
      return needsReveal(roll, rollExposures, revealEnabled: revealEnabled)
          ? RollWidgetDestination.reveal
          : RollWidgetDestination.gallery;
  }
}

/// Keeps the Android home-screen roll widget in step with the rolls, and
/// opens the right screen when it or the camera widget is tapped.
class RollWidgetService {
  RollWidgetService._();

  static final _subscriptions = <StreamSubscription<dynamic>>[];
  static Timer? _debounce;
  static String? _published;

  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    await publish();
    _subscriptions
      ..add(HiveService.watchFilmRolls().listen((_) => _schedulePublish()))
      ..add(HiveService.watchExposures().listen((_) => _schedulePublish()))
      ..add(HomeWidget.widgetClicked.listen(_onTapped));
    _onTapped(await HomeWidget.initiallyLaunchedFromHomeWidget());
  }

  static void _schedulePublish() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), publish);
  }

  /// Writes the rolls for the widget and redraws it. Also called after a
  /// language change, since the labels are localised.
  static Future<void> publish() async {
    if (!Platform.isAndroid) return;
    final settings = HiveService.getSettings();
    final l = lookupAppLocalizations(Locale(settings.language));
    final data = jsonEncode({
      'rolls': rollWidgetEntries(
        rolls: HiveService.getAllFilmRolls(),
        exposures: HiveService.getAllExposures(),
        revealEnabled: settings.albumRevealEnabled,
        now: DateTime.now(),
      ),
      'labels': rollWidgetLabels(l),
    });
    if (data == _published) return;
    _published = data;
    await HomeWidget.saveWidgetData<String>(kRollWidgetDataKey, data);
    await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
  }

  static void _onTapped(Uri? uri) {
    final link = parseRollWidgetUri(uri);
    if (link == null) return;
    AppNavigator.run((nav) => _open(link, nav));
  }

  static Future<void> _open(RollWidgetLink link, NavigatorState nav) async {
    // A roll whose lab time has passed is marked developed first, so it
    // opens the reveal rather than the waiting screen.
    await FilmService.checkDevelopmentCompletions();
    final roll = link.tap == RollWidgetTap.camera
        ? lastUsedRoll(
            HiveService.getAllFilmRolls(), HiveService.getAllExposures())
        : link.rollId == null
            ? null
            : HiveService.getFilmRoll(link.rollId!);
    final exposures = roll == null
        ? const <Exposure>[]
        : HiveService.getExposuresForRoll(roll.id);
    final destination = rollWidgetDestination(
      link,
      roll,
      exposures,
      revealEnabled: HiveService.getSettings().albumRevealEnabled,
    );
    final Widget? screen = switch (destination) {
      RollWidgetDestination.viewfinder => ViewfinderScreen(filmRoll: roll!),
      RollWidgetDestination.rollDetail => FilmRollDetailScreen(filmRoll: roll!),
      RollWidgetDestination.reveal => RevealGalleryScreen(filmRoll: roll!),
      RollWidgetDestination.gallery => DevelopedGalleryScreen(filmRoll: roll!),
      RollWidgetDestination.newRoll => const NewRollScreen(),
      RollWidgetDestination.nothing => null,
    };
    if (screen != null) {
      nav.push(MaterialPageRoute(builder: (_) => screen));
    }
  }
}
