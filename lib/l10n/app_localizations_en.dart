// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Negativo';

  @override
  String get navRolls => 'Rolls';

  @override
  String get navAlbums => 'Albums';

  @override
  String get navRewards => 'Rewards';

  @override
  String get navSettings => 'Settings';

  @override
  String get rollsEmpty => 'No film loaded';

  @override
  String get rollsEmptySub => 'Load a film roll to start shooting.';

  @override
  String get rollsLoadFilmRoll => 'Load Film Roll';

  @override
  String get rollsLoadFilmFab => 'Load Film';

  @override
  String get rollsDevelopingSection => 'Developing';

  @override
  String get rollsStatusLoaded => 'LOADED';

  @override
  String get rollsShoot => 'Shoot';

  @override
  String get rollsDevelop => 'Develop';

  @override
  String get rollsAlmostReady => 'Almost ready…';

  @override
  String get rollsDevNow => 'DEV NOW';

  @override
  String rollsFramesUsed(int used, int total) {
    return '$used / $total frames used';
  }

  @override
  String rollsDaysHoursRemaining(int days, int hours) {
    return '${days}d ${hours}h remaining';
  }

  @override
  String rollsHoursMinutesRemaining(int hours, int minutes) {
    return '${hours}h ${minutes}m remaining';
  }

  @override
  String rollsMinutesRemaining(int minutes) {
    return '${minutes}m remaining';
  }

  @override
  String get albumsTitle => 'Albums';

  @override
  String get albumsEmpty => 'No developed rolls yet';

  @override
  String get albumsEmptySub => 'Shoot a roll and send it for development.';

  @override
  String albumsPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '$count photo',
    );
    return '$_temp0';
  }

  @override
  String get newRollTitle => 'Load Film Roll';

  @override
  String get newRollChooseStock => 'Choose film stock';

  @override
  String get newRollChooseStockSub =>
      'Each stock gives your photos a distinct look.';

  @override
  String get newRollChooseCapacity => 'Choose capacity';

  @override
  String get newRollChooseCapacitySub => 'How many frames does this roll have?';

  @override
  String get newRollNameTitle => 'Name this roll';

  @override
  String get newRollNameSub => 'What moment or trip is this roll for?';

  @override
  String get newRollNameHint => 'Paris Trip, Summer 2024, Road Trip…';

  @override
  String get newRollLoadButton => 'Load Roll';

  @override
  String get newRollNameRequired => 'Give your roll a name first';

  @override
  String get newRollFrames => 'frames';

  @override
  String newRollPtsToUnlock(int cost) {
    return '$cost pts to unlock';
  }

  @override
  String get detailSendToDevelop => 'Send for development?';

  @override
  String detailSendFullBody(int capacity, String duration) {
    return 'Your roll of $capacity frames is ready. It will be developed in $duration.';
  }

  @override
  String detailSendPartialBody(int used, int total, String duration) {
    return 'You\'ve used $used of $total frames. Rewind early and develop now?\n\nDevelopment takes $duration.';
  }

  @override
  String get detailCancel => 'Cancel';

  @override
  String get detailDevelop => 'Develop';

  @override
  String get detailDeleteTitle => 'Delete this roll?';

  @override
  String detailDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'All $count photos will be permanently deleted. This cannot be undone.',
      one: 'All 1 photo will be permanently deleted. This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get detailDeleteTooltip => 'Delete roll';

  @override
  String get detailDelete => 'Delete';

  @override
  String get detailStatusActive => 'Active';

  @override
  String get detailStatusDeveloping => 'Developing';

  @override
  String get detailStatusDeveloped => 'Developed';

  @override
  String get detailStatusUnknown => 'Unknown';

  @override
  String get detailInfoCreated => 'Created';

  @override
  String get detailInfoCapacity => 'Capacity';

  @override
  String detailInfoFramesCount(int count) {
    return '$count frames';
  }

  @override
  String get detailInfoExposed => 'Exposed';

  @override
  String get detailInfoSentToDevelop => 'Sent to develop';

  @override
  String get detailInfoDevelopedOn => 'Developed on';

  @override
  String get detailInfoReadyOn => 'Ready on';

  @override
  String detailFramesUsedOf(int used, int total) {
    return '$used / $total frames';
  }

  @override
  String detailFramesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frames remaining',
      one: '1 frame remaining',
    );
    return '$_temp0';
  }

  @override
  String get detailAlmostReady => 'Almost ready…';

  @override
  String detailDevelopingBody(int count) {
    return '$count frames are being developed. You\'ll get a notification when they\'re ready.';
  }

  @override
  String get detailOpenCamera => 'Open Camera';

  @override
  String get detailDevelopRoll => 'Develop Roll';

  @override
  String get detailRewindDevelop => 'Rewind & Develop Early';

  @override
  String get detailViewPhotos => 'View Photos';

  @override
  String detailDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String detailDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String galleryPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get galleryNoPhotos => 'No photos in this roll';

  @override
  String get galleryShare => 'Share';

  @override
  String galleryFrameLabel(int order) {
    return 'Frame $order';
  }

  @override
  String galleryFrameOf(int current, int total) {
    return 'Frame $current / $total';
  }

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressAvailablePoints => 'available points';

  @override
  String progressTowardNext(int percent, String feature) {
    return '$percent% toward $feature';
  }

  @override
  String get progressAllUnlocked => '🏆 All features unlocked!';

  @override
  String progressLifetimePoints(int points) {
    return '$points pts earned all-time';
  }

  @override
  String get progressHowToEarn => 'HOW TO EARN';

  @override
  String get progressEarnPhoto => 'Take a photo';

  @override
  String get progressEarnFullRoll => 'Use every frame on a roll';

  @override
  String get progressEarnStartDev => 'Send roll to develop';

  @override
  String get progressEarnCompleteDev => 'Roll fully developed';

  @override
  String get progressEarnWind => 'Wind at exactly 0.8 s';

  @override
  String get progressWindPrecision =>
      'Wind precision: ±0.05 s = 25 pts · ±0.15 s = 15 pts · ±0.30 s = 8 pts · ±0.50 s = 3 pts';

  @override
  String get progressFilmStocks => 'FILM STOCKS';

  @override
  String get progressFilmStocksFree =>
      'Kodak Portra 400 is free. Unlock the rest with points.';

  @override
  String get progressUpgrades => 'UPGRADES';

  @override
  String get progressDevBoost => 'DEVELOPMENT BOOST';

  @override
  String get progressDevBoostSub =>
      'Spend points to speed up a developing roll.';

  @override
  String progressNotEnoughPoints(int cost, int have) {
    return 'Not enough points (need $cost, have $have)';
  }

  @override
  String progressNotEnoughPointsSimple(int cost) {
    return 'Not enough points (need $cost)';
  }

  @override
  String progressUnlockedFeature(String name) {
    return '🎉 Unlocked: $name!';
  }

  @override
  String get progressDevComplete => '⚡ Development complete!';

  @override
  String get progressHalfTime => '⏩ Cut remaining time in half!';

  @override
  String get progressAlmostReady => 'Almost ready';

  @override
  String progressDaysHoursLeft(int days, int hours) {
    return '${days}d ${hours}h left';
  }

  @override
  String progressHoursMinutesLeft(int hours, int minutes) {
    return '${hours}h ${minutes}m left';
  }

  @override
  String progressMinutesLeft(int minutes) {
    return '${minutes}m left';
  }

  @override
  String progressHalfTimeBtn(int cost) {
    return '⏩ Half time\n$cost pts';
  }

  @override
  String progressInstantBtn(int cost) {
    return '⚡ Instant\n$cost pts';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsFilmDev => 'Film Development';

  @override
  String get settingsFilmDevSub =>
      'How long should it take to develop your film?';

  @override
  String get settingsDev1Day => '1 day';

  @override
  String get settingsDev2Days => '2 days';

  @override
  String get settingsDev3Days => '3 days';

  @override
  String get settingsDev1Week => '1 week';

  @override
  String get settingsNotifyDev => 'Notify when developed';

  @override
  String get settingsNotifyDevSub =>
      'Get a notification when your film is ready';

  @override
  String get settingsStatistics => 'Statistics';

  @override
  String get settingsRollsDeveloped => 'Rolls developed';

  @override
  String get settingsTotalPhotos => 'Total photos taken';

  @override
  String get settingsTotalRolls => 'Total rolls';

  @override
  String get notifDevReadyTitle => 'Film developed!';

  @override
  String notifDevReadyBody(String name) {
    return 'Your roll \"$name\" is ready to be picked up.';
  }
}
