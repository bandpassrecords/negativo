import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Negativo'**
  String get appTitle;

  /// No description provided for @navRolls.
  ///
  /// In en, this message translates to:
  /// **'Rolls'**
  String get navRolls;

  /// No description provided for @navAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get navAlbums;

  /// No description provided for @navRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get navRewards;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @rollsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No film loaded'**
  String get rollsEmpty;

  /// No description provided for @rollsEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Load a film roll to start shooting.'**
  String get rollsEmptySub;

  /// No description provided for @rollsLoadFilmRoll.
  ///
  /// In en, this message translates to:
  /// **'Load Film Roll'**
  String get rollsLoadFilmRoll;

  /// No description provided for @rollsLoadFilmFab.
  ///
  /// In en, this message translates to:
  /// **'Load Film'**
  String get rollsLoadFilmFab;

  /// No description provided for @rollsDevelopingSection.
  ///
  /// In en, this message translates to:
  /// **'Developing'**
  String get rollsDevelopingSection;

  /// No description provided for @rollsStatusLoaded.
  ///
  /// In en, this message translates to:
  /// **'LOADED'**
  String get rollsStatusLoaded;

  /// No description provided for @rollsShoot.
  ///
  /// In en, this message translates to:
  /// **'Shoot'**
  String get rollsShoot;

  /// No description provided for @rollsDevelop.
  ///
  /// In en, this message translates to:
  /// **'Develop'**
  String get rollsDevelop;

  /// No description provided for @rollsAlmostReady.
  ///
  /// In en, this message translates to:
  /// **'Almost ready…'**
  String get rollsAlmostReady;

  /// No description provided for @rollsDevNow.
  ///
  /// In en, this message translates to:
  /// **'DEV NOW'**
  String get rollsDevNow;

  /// No description provided for @rollsFramesUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total} frames used'**
  String rollsFramesUsed(int used, int total);

  /// No description provided for @rollsDaysHoursRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h remaining'**
  String rollsDaysHoursRemaining(int days, int hours);

  /// No description provided for @rollsHoursMinutesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m remaining'**
  String rollsHoursMinutesRemaining(int hours, int minutes);

  /// No description provided for @rollsMinutesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m remaining'**
  String rollsMinutesRemaining(int minutes);

  /// No description provided for @albumsTitle.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albumsTitle;

  /// No description provided for @albumsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No developed rolls yet'**
  String get albumsEmpty;

  /// No description provided for @albumsEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Shoot a roll and send it for development.'**
  String get albumsEmptySub;

  /// No description provided for @albumsPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} photo} other{{count} photos}}'**
  String albumsPhotoCount(int count);

  /// No description provided for @newRollTitle.
  ///
  /// In en, this message translates to:
  /// **'Load Film Roll'**
  String get newRollTitle;

  /// No description provided for @newRollChooseStock.
  ///
  /// In en, this message translates to:
  /// **'Choose film stock'**
  String get newRollChooseStock;

  /// No description provided for @newRollChooseStockSub.
  ///
  /// In en, this message translates to:
  /// **'Each stock gives your photos a distinct look.'**
  String get newRollChooseStockSub;

  /// No description provided for @newRollChooseCapacity.
  ///
  /// In en, this message translates to:
  /// **'Choose capacity'**
  String get newRollChooseCapacity;

  /// No description provided for @newRollChooseCapacitySub.
  ///
  /// In en, this message translates to:
  /// **'How many frames does this roll have?'**
  String get newRollChooseCapacitySub;

  /// No description provided for @newRollNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this roll'**
  String get newRollNameTitle;

  /// No description provided for @newRollNameSub.
  ///
  /// In en, this message translates to:
  /// **'What moment or trip is this roll for?'**
  String get newRollNameSub;

  /// No description provided for @newRollNameHint.
  ///
  /// In en, this message translates to:
  /// **'Paris Trip, Summer 2024, Road Trip…'**
  String get newRollNameHint;

  /// No description provided for @newRollLoadButton.
  ///
  /// In en, this message translates to:
  /// **'Load Roll'**
  String get newRollLoadButton;

  /// No description provided for @newRollNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give your roll a name first'**
  String get newRollNameRequired;

  /// No description provided for @newRollFrames.
  ///
  /// In en, this message translates to:
  /// **'frames'**
  String get newRollFrames;

  /// No description provided for @newRollPtsToUnlock.
  ///
  /// In en, this message translates to:
  /// **'{cost} pts to unlock'**
  String newRollPtsToUnlock(int cost);

  /// No description provided for @detailSendToDevelop.
  ///
  /// In en, this message translates to:
  /// **'Send for development?'**
  String get detailSendToDevelop;

  /// No description provided for @detailSendFullBody.
  ///
  /// In en, this message translates to:
  /// **'Your roll of {capacity} frames is ready. It will be developed in {duration}.'**
  String detailSendFullBody(int capacity, String duration);

  /// No description provided for @detailSendPartialBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used {used} of {total} frames. Rewind early and develop now?\n\nDevelopment takes {duration}.'**
  String detailSendPartialBody(int used, int total, String duration);

  /// No description provided for @detailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get detailCancel;

  /// No description provided for @detailDevelop.
  ///
  /// In en, this message translates to:
  /// **'Develop'**
  String get detailDevelop;

  /// No description provided for @detailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this roll?'**
  String get detailDeleteTitle;

  /// No description provided for @detailDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{All 1 photo will be permanently deleted. This cannot be undone.} other{All {count} photos will be permanently deleted. This cannot be undone.}}'**
  String detailDeleteBody(int count);

  /// No description provided for @detailDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete roll'**
  String get detailDeleteTooltip;

  /// No description provided for @detailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get detailDelete;

  /// No description provided for @detailStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get detailStatusActive;

  /// No description provided for @detailStatusDeveloping.
  ///
  /// In en, this message translates to:
  /// **'Developing'**
  String get detailStatusDeveloping;

  /// No description provided for @detailStatusDeveloped.
  ///
  /// In en, this message translates to:
  /// **'Developed'**
  String get detailStatusDeveloped;

  /// No description provided for @detailStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get detailStatusUnknown;

  /// No description provided for @detailInfoCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get detailInfoCreated;

  /// No description provided for @detailInfoCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get detailInfoCapacity;

  /// No description provided for @detailInfoFramesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} frames'**
  String detailInfoFramesCount(int count);

  /// No description provided for @detailInfoExposed.
  ///
  /// In en, this message translates to:
  /// **'Exposed'**
  String get detailInfoExposed;

  /// No description provided for @detailInfoSentToDevelop.
  ///
  /// In en, this message translates to:
  /// **'Sent to develop'**
  String get detailInfoSentToDevelop;

  /// No description provided for @detailInfoDevelopedOn.
  ///
  /// In en, this message translates to:
  /// **'Developed on'**
  String get detailInfoDevelopedOn;

  /// No description provided for @detailInfoReadyOn.
  ///
  /// In en, this message translates to:
  /// **'Ready on'**
  String get detailInfoReadyOn;

  /// No description provided for @detailFramesUsedOf.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total} frames'**
  String detailFramesUsedOf(int used, int total);

  /// No description provided for @detailFramesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 frame remaining} other{{count} frames remaining}}'**
  String detailFramesRemaining(int count);

  /// No description provided for @detailAlmostReady.
  ///
  /// In en, this message translates to:
  /// **'Almost ready…'**
  String get detailAlmostReady;

  /// No description provided for @detailDevelopingBody.
  ///
  /// In en, this message translates to:
  /// **'{count} frames are being developed. You\'ll get a notification when they\'re ready.'**
  String detailDevelopingBody(int count);

  /// No description provided for @detailOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Open Camera'**
  String get detailOpenCamera;

  /// No description provided for @detailDevelopRoll.
  ///
  /// In en, this message translates to:
  /// **'Develop Roll'**
  String get detailDevelopRoll;

  /// No description provided for @detailRewindDevelop.
  ///
  /// In en, this message translates to:
  /// **'Rewind & Develop Early'**
  String get detailRewindDevelop;

  /// No description provided for @detailViewPhotos.
  ///
  /// In en, this message translates to:
  /// **'View Photos'**
  String get detailViewPhotos;

  /// No description provided for @detailDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour} other{{count} hours}}'**
  String detailDurationHours(int count);

  /// No description provided for @detailDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}}'**
  String detailDurationDays(int count);

  /// No description provided for @galleryPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 photo} other{{count} photos}}'**
  String galleryPhotoCount(int count);

  /// No description provided for @galleryNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos in this roll'**
  String get galleryNoPhotos;

  /// No description provided for @galleryShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get galleryShare;

  /// No description provided for @galleryFrameLabel.
  ///
  /// In en, this message translates to:
  /// **'Frame {order}'**
  String galleryFrameLabel(int order);

  /// No description provided for @galleryFrameOf.
  ///
  /// In en, this message translates to:
  /// **'Frame {current} / {total}'**
  String galleryFrameOf(int current, int total);

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressAvailablePoints.
  ///
  /// In en, this message translates to:
  /// **'available points'**
  String get progressAvailablePoints;

  /// No description provided for @progressTowardNext.
  ///
  /// In en, this message translates to:
  /// **'{percent}% toward {feature}'**
  String progressTowardNext(int percent, String feature);

  /// No description provided for @progressAllUnlocked.
  ///
  /// In en, this message translates to:
  /// **'🏆 All features unlocked!'**
  String get progressAllUnlocked;

  /// No description provided for @progressLifetimePoints.
  ///
  /// In en, this message translates to:
  /// **'{points} pts earned all-time'**
  String progressLifetimePoints(int points);

  /// No description provided for @progressHowToEarn.
  ///
  /// In en, this message translates to:
  /// **'HOW TO EARN'**
  String get progressHowToEarn;

  /// No description provided for @progressEarnPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get progressEarnPhoto;

  /// No description provided for @progressEarnFullRoll.
  ///
  /// In en, this message translates to:
  /// **'Use every frame on a roll'**
  String get progressEarnFullRoll;

  /// No description provided for @progressEarnStartDev.
  ///
  /// In en, this message translates to:
  /// **'Send roll to develop'**
  String get progressEarnStartDev;

  /// No description provided for @progressEarnCompleteDev.
  ///
  /// In en, this message translates to:
  /// **'Roll fully developed'**
  String get progressEarnCompleteDev;

  /// No description provided for @progressEarnWind.
  ///
  /// In en, this message translates to:
  /// **'Wind at exactly 0.8 s'**
  String get progressEarnWind;

  /// No description provided for @progressWindPrecision.
  ///
  /// In en, this message translates to:
  /// **'Wind precision: ±0.05 s = 25 pts · ±0.15 s = 15 pts · ±0.30 s = 8 pts · ±0.50 s = 3 pts'**
  String get progressWindPrecision;

  /// No description provided for @progressFilmStocks.
  ///
  /// In en, this message translates to:
  /// **'FILM STOCKS'**
  String get progressFilmStocks;

  /// No description provided for @progressFilmStocksFree.
  ///
  /// In en, this message translates to:
  /// **'Kodak Gold 200 and Portra 400 are free. Unlock the rest with points.'**
  String get progressFilmStocksFree;

  /// No description provided for @progressUpgrades.
  ///
  /// In en, this message translates to:
  /// **'UPGRADES'**
  String get progressUpgrades;

  /// No description provided for @progressDevBoost.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPMENT BOOST'**
  String get progressDevBoost;

  /// No description provided for @progressDevBoostSub.
  ///
  /// In en, this message translates to:
  /// **'Spend points to speed up a developing roll.'**
  String get progressDevBoostSub;

  /// No description provided for @progressNotEnoughPoints.
  ///
  /// In en, this message translates to:
  /// **'Not enough points (need {cost}, have {have})'**
  String progressNotEnoughPoints(int cost, int have);

  /// No description provided for @progressNotEnoughPointsSimple.
  ///
  /// In en, this message translates to:
  /// **'Not enough points (need {cost})'**
  String progressNotEnoughPointsSimple(int cost);

  /// No description provided for @progressUnlockedFeature.
  ///
  /// In en, this message translates to:
  /// **'🎉 Unlocked: {name}!'**
  String progressUnlockedFeature(String name);

  /// No description provided for @progressDevComplete.
  ///
  /// In en, this message translates to:
  /// **'⚡ Development complete!'**
  String get progressDevComplete;

  /// No description provided for @progressHalfTime.
  ///
  /// In en, this message translates to:
  /// **'⏩ Cut remaining time in half!'**
  String get progressHalfTime;

  /// No description provided for @progressAlmostReady.
  ///
  /// In en, this message translates to:
  /// **'Almost ready'**
  String get progressAlmostReady;

  /// No description provided for @progressDaysHoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h left'**
  String progressDaysHoursLeft(int days, int hours);

  /// No description provided for @progressHoursMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m left'**
  String progressHoursMinutesLeft(int hours, int minutes);

  /// No description provided for @progressMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m left'**
  String progressMinutesLeft(int minutes);

  /// No description provided for @progressHalfTimeBtn.
  ///
  /// In en, this message translates to:
  /// **'⏩ Half time\n{cost} pts'**
  String progressHalfTimeBtn(int cost);

  /// No description provided for @progressInstantBtn.
  ///
  /// In en, this message translates to:
  /// **'⚡ Instant\n{cost} pts'**
  String progressInstantBtn(int cost);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsFilmDev.
  ///
  /// In en, this message translates to:
  /// **'Film Development'**
  String get settingsFilmDev;

  /// No description provided for @settingsFilmDevSub.
  ///
  /// In en, this message translates to:
  /// **'How long should it take to develop your film?'**
  String get settingsFilmDevSub;

  /// No description provided for @settingsDev1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get settingsDev1Day;

  /// No description provided for @settingsDev2Days.
  ///
  /// In en, this message translates to:
  /// **'2 days'**
  String get settingsDev2Days;

  /// No description provided for @settingsDev3Days.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get settingsDev3Days;

  /// No description provided for @settingsDev1Week.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get settingsDev1Week;

  /// No description provided for @settingsNotifyDev.
  ///
  /// In en, this message translates to:
  /// **'Notify when developed'**
  String get settingsNotifyDev;

  /// No description provided for @settingsNotifyDevSub.
  ///
  /// In en, this message translates to:
  /// **'Get a notification when your film is ready'**
  String get settingsNotifyDevSub;

  /// No description provided for @settingsStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get settingsStatistics;

  /// No description provided for @settingsRollsDeveloped.
  ///
  /// In en, this message translates to:
  /// **'Rolls developed'**
  String get settingsRollsDeveloped;

  /// No description provided for @settingsTotalPhotos.
  ///
  /// In en, this message translates to:
  /// **'Total photos taken'**
  String get settingsTotalPhotos;

  /// No description provided for @settingsTotalRolls.
  ///
  /// In en, this message translates to:
  /// **'Total rolls'**
  String get settingsTotalRolls;

  /// No description provided for @notifDevReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Film developed!'**
  String get notifDevReadyTitle;

  /// No description provided for @notifDevReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your roll \"{name}\" is ready to be picked up.'**
  String notifDevReadyBody(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'pt'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
