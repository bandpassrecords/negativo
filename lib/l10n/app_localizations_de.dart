// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Negativ';

  @override
  String get navRolls => 'Filme';

  @override
  String get navAlbums => 'Alben';

  @override
  String get navRewards => 'Belohnungen';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get rollsEmpty => 'Kein Film geladen';

  @override
  String get rollsEmptySub => 'Lade einen Film ein, um zu fotografieren.';

  @override
  String get rollsLoadFilmRoll => 'Film einlegen';

  @override
  String get rollsLoadFilmFab => 'Film laden';

  @override
  String get rollsDevelopingSection => 'In Entwicklung';

  @override
  String get rollsStatusLoaded => 'GELADEN';

  @override
  String get rollsShoot => 'Fotografieren';

  @override
  String get rollsDevelop => 'Entwickeln';

  @override
  String get rollsAlmostReady => 'Fast fertig…';

  @override
  String get rollsDevNow => 'JETZT ENTWICKELN';

  @override
  String rollsFramesUsed(int used, int total) {
    return '$used / $total Aufnahmen verwendet';
  }

  @override
  String rollsDaysHoursRemaining(int days, int hours) {
    return '${days}T ${hours}h verbleibend';
  }

  @override
  String rollsHoursMinutesRemaining(int hours, int minutes) {
    return '${hours}h ${minutes}m verbleibend';
  }

  @override
  String rollsMinutesRemaining(int minutes) {
    return '${minutes}m verbleibend';
  }

  @override
  String get albumsTitle => 'Alben';

  @override
  String get albumsEmpty => 'Noch keine entwickelten Filme';

  @override
  String get albumsEmptySub =>
      'Fotografiere einen Film und schicke ihn zur Entwicklung.';

  @override
  String albumsPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos',
      one: '$count Foto',
    );
    return '$_temp0';
  }

  @override
  String get newRollTitle => 'Film einlegen';

  @override
  String get newRollChooseStock => 'Film auswählen';

  @override
  String get newRollChooseStockSub =>
      'Jeder Film gibt deinen Fotos einen eigenen Look.';

  @override
  String get newRollChooseCapacity => 'Kapazität wählen';

  @override
  String get newRollChooseCapacitySub => 'Wie viele Aufnahmen hat dieser Film?';

  @override
  String get newRollNameTitle => 'Film benennen';

  @override
  String get newRollNameSub =>
      'Für welchen Moment oder welche Reise ist dieser Film?';

  @override
  String get newRollNameHint => 'Paris-Reise, Sommer 2024, Road Trip…';

  @override
  String get newRollLoadButton => 'Film laden';

  @override
  String get newRollNameRequired => 'Gib deinem Film zuerst einen Namen';

  @override
  String get newRollFrames => 'Aufnahmen';

  @override
  String newRollPtsToUnlock(int cost) {
    return '$cost Pkt. zum Freischalten';
  }

  @override
  String get detailSendToDevelop => 'Zur Entwicklung schicken?';

  @override
  String detailSendFullBody(int capacity, String duration) {
    return 'Dein Film mit $capacity Aufnahmen ist bereit. Er wird in $duration entwickelt.';
  }

  @override
  String detailSendPartialBody(int used, int total, String duration) {
    return 'Du hast $used von $total Aufnahmen verwendet. Jetzt zurückspulen und entwickeln?\n\nDie Entwicklung dauert $duration.';
  }

  @override
  String get detailCancel => 'Abbrechen';

  @override
  String get detailDevelop => 'Entwickeln';

  @override
  String get detailDeleteTitle => 'Film löschen?';

  @override
  String detailDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Alle $count Fotos werden dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.',
      one:
          '1 Foto wird dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.',
    );
    return '$_temp0';
  }

  @override
  String get detailDeleteTooltip => 'Film löschen';

  @override
  String get detailDelete => 'Löschen';

  @override
  String get detailStatusActive => 'Aktiv';

  @override
  String get detailStatusDeveloping => 'In Entwicklung';

  @override
  String get detailStatusDeveloped => 'Entwickelt';

  @override
  String get detailStatusUnknown => 'Unbekannt';

  @override
  String get detailInfoCreated => 'Erstellt';

  @override
  String get detailInfoCapacity => 'Kapazität';

  @override
  String detailInfoFramesCount(int count) {
    return '$count Aufnahmen';
  }

  @override
  String get detailInfoExposed => 'Belichtet';

  @override
  String get detailInfoSentToDevelop => 'Zur Entwicklung geschickt';

  @override
  String get detailInfoDevelopedOn => 'Entwickelt am';

  @override
  String get detailInfoReadyOn => 'Fertig am';

  @override
  String detailFramesUsedOf(int used, int total) {
    return '$used / $total Aufnahmen';
  }

  @override
  String detailFramesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufnahmen übrig',
      one: '1 Aufnahme übrig',
    );
    return '$_temp0';
  }

  @override
  String get detailAlmostReady => 'Fast fertig…';

  @override
  String detailDevelopingBody(int count) {
    return '$count Aufnahmen werden entwickelt. Du erhältst eine Benachrichtigung, wenn sie fertig sind.';
  }

  @override
  String get detailOpenCamera => 'Kamera öffnen';

  @override
  String get detailDevelopRoll => 'Film entwickeln';

  @override
  String get detailRewindDevelop => 'Zurückspulen & entwickeln';

  @override
  String get detailViewPhotos => 'Fotos ansehen';

  @override
  String detailDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String detailDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String galleryPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos',
      one: '1 Foto',
    );
    return '$_temp0';
  }

  @override
  String get galleryNoPhotos => 'Keine Fotos in diesem Film';

  @override
  String get galleryShare => 'Teilen';

  @override
  String galleryFrameLabel(int order) {
    return 'Aufnahme $order';
  }

  @override
  String galleryFrameOf(int current, int total) {
    return 'Aufnahme $current / $total';
  }

  @override
  String get progressTitle => 'Fortschritt';

  @override
  String get progressAvailablePoints => 'verfügbare Punkte';

  @override
  String progressTowardNext(int percent, String feature) {
    return '$percent% bis $feature';
  }

  @override
  String get progressAllUnlocked => '🏆 Alle Funktionen freigeschaltet!';

  @override
  String progressLifetimePoints(int points) {
    return '$points Pkt. insgesamt verdient';
  }

  @override
  String get progressHowToEarn => 'WIE VERDIENEN';

  @override
  String get progressEarnPhoto => 'Ein Foto aufnehmen';

  @override
  String get progressEarnFullRoll => 'Alle Aufnahmen eines Films nutzen';

  @override
  String get progressEarnStartDev => 'Film zur Entwicklung schicken';

  @override
  String get progressEarnCompleteDev => 'Film vollständig entwickelt';

  @override
  String get progressEarnWind => 'Film in genau 0,8 s vorspulen';

  @override
  String get progressWindPrecision =>
      'Genauigkeit: ±0,05 s = 25 Pkt. · ±0,15 s = 15 Pkt. · ±0,30 s = 8 Pkt. · ±0,50 s = 3 Pkt.';

  @override
  String get progressFilmStocks => 'FILMSORTEN';

  @override
  String get progressFilmStocksFree =>
      'Kodak Gold 200 und Portra 400 sind kostenlos. Schalte den Rest mit Punkten frei.';

  @override
  String get progressUpgrades => 'UPGRADES';

  @override
  String get progressDevBoost => 'ENTWICKLUNG BESCHLEUNIGEN';

  @override
  String get progressDevBoostSub =>
      'Punkte ausgeben, um die Entwicklung zu beschleunigen.';

  @override
  String progressNotEnoughPoints(int cost, int have) {
    return 'Nicht genug Punkte (benötigt $cost, vorhanden $have)';
  }

  @override
  String progressNotEnoughPointsSimple(int cost) {
    return 'Nicht genug Punkte (benötigt $cost)';
  }

  @override
  String progressUnlockedFeature(String name) {
    return '🎉 Freigeschaltet: $name!';
  }

  @override
  String get progressDevComplete => '⚡ Entwicklung abgeschlossen!';

  @override
  String get progressHalfTime => '⏩ Zeit halbiert!';

  @override
  String get progressAlmostReady => 'Fast fertig';

  @override
  String progressDaysHoursLeft(int days, int hours) {
    return '${days}T ${hours}h übrig';
  }

  @override
  String progressHoursMinutesLeft(int hours, int minutes) {
    return '${hours}h ${minutes}m übrig';
  }

  @override
  String progressMinutesLeft(int minutes) {
    return '${minutes}m übrig';
  }

  @override
  String progressHalfTimeBtn(int cost) {
    return '⏩ Halbe Zeit\n$cost Pkt.';
  }

  @override
  String progressInstantBtn(int cost) {
    return '⚡ Sofort\n$cost Pkt.';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAppearance => 'Erscheinungsbild';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsFilmDev => 'Filmentwicklung';

  @override
  String get settingsFilmDevSub => 'Wie lange soll die Entwicklung dauern?';

  @override
  String get settingsDev1Day => '1 Tag';

  @override
  String get settingsDev2Days => '2 Tage';

  @override
  String get settingsDev3Days => '3 Tage';

  @override
  String get settingsDev1Week => '1 Woche';

  @override
  String get settingsNotifyDev => 'Benachrichtigung bei Fertigstellung';

  @override
  String get settingsNotifyDevSub =>
      'Erhalte eine Benachrichtigung, wenn dein Film fertig ist';

  @override
  String get settingsStatistics => 'Statistiken';

  @override
  String get settingsRollsDeveloped => 'Entwickelte Filme';

  @override
  String get settingsTotalPhotos => 'Aufnahmen insgesamt';

  @override
  String get settingsTotalRolls => 'Filme insgesamt';

  @override
  String get revealSkipAll => 'Alle überspringen';

  @override
  String get revealTapToDevelop => 'Tippen zum Entwickeln';

  @override
  String get revealSwipeForNext => 'Wischen für nächsten Frame';

  @override
  String get revealAllDeveloped => 'Alle Aufnahmen entwickelt';

  @override
  String get revealTapToOpenGallery => 'Tippen zum Öffnen der Galerie';

  @override
  String get albumCustomizeColor => 'Farbe';

  @override
  String get albumCustomizePattern => 'Muster';

  @override
  String get albumEditThumbnail => 'Vorschaubilder bearbeiten';

  @override
  String get albumEditThumbnailSub =>
      'Bis zu 4 Fotos für das Albumcover auswählen';

  @override
  String get albumEffectSub =>
      'Filmeffekt auf allen Fotos dieses Albums anzeigen';

  @override
  String get galleryEditThumbnail => 'Vorschau bearbeiten';

  @override
  String get gallerySharePhotos => 'Fotos teilen';

  @override
  String get gallerySelectThumbnail => 'Vorschau auswählen';

  @override
  String get galleryMaxThumbnail => 'Maximal 4 Fotos für das Vorschaubild';

  @override
  String get galleryThumbnailUpdated => 'Vorschau aktualisiert';

  @override
  String get gallerySelectPhotos => 'Fotos auswählen';

  @override
  String gallerySelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get gallerySelectAll => 'Alle auswählen';

  @override
  String get galleryDeselectAll => 'Auswahl aufheben';

  @override
  String galleryShareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos teilen',
      one: '1 Foto teilen',
      zero: 'Teilen',
    );
    return '$_temp0';
  }

  @override
  String get galleryGooglePhotos => 'Google Fotos';

  @override
  String get galleryGooglePhotosUploading =>
      'Wird zu Google Fotos hochgeladen…';

  @override
  String get galleryGooglePhotosDone =>
      'Album in Google Fotos erstellt. Öffne es, um es zu teilen.';

  @override
  String get galleryGooglePhotosOpen => 'Öffnen';

  @override
  String galleryGooglePhotosFailed(String error) {
    return 'Upload zu Google Fotos fehlgeschlagen: $error';
  }

  @override
  String get settingsAlbumReveal => 'Album-Enthüllung';

  @override
  String get settingsAlbumRevealSub =>
      'Filmnegativ vor dem Enthüllen jedes Fotos anzeigen';

  @override
  String get photoInfoTitle => 'Foto-Info';

  @override
  String get photoInfoDate => 'Datum';

  @override
  String get photoInfoRoll => 'Film';

  @override
  String get photoInfoFilmStock => 'Filmtyp';

  @override
  String get photoInfoSize => 'Größe';

  @override
  String get photoInfoFrame => 'Aufnahme';

  @override
  String get photoInfoEffect => 'Filmeffekt';

  @override
  String effectFound(String name) {
    return '🎞 Effekt $name auf dieser Aufnahme!';
  }

  @override
  String get effectShinyFound =>
      '🌈 Folienbild! Neige dein Handy, um es glänzen zu sehen.';

  @override
  String get notifDevReadyTitle => 'Film entwickelt!';

  @override
  String notifDevReadyBody(String name) {
    return 'Dein Film \"$name\" ist zur Abholung bereit.';
  }

  @override
  String get negativesTitle => 'Negative';

  @override
  String get negativesHint =>
      'Tippe auf ein Bild, um es gegen das Licht zu halten. Folienbilder glänzen, wenn du dein Handy neigst.';

  @override
  String get negativesSave => 'Negative in der Galerie speichern';

  @override
  String get negativesSaved => 'Negative in deiner Galerie gespeichert';

  @override
  String negativesSaveFailed(String error) {
    return 'Negative konnten nicht gespeichert werden: $error';
  }

  @override
  String get negativesNegative => 'Negativ';

  @override
  String get negativesPrint => 'Abzug';

  @override
  String get negativesFoilHint => '✨ Folienbild — neige dein Handy';

  @override
  String get albumFoil => 'Folienbilder';

  @override
  String get albumFoilSub =>
      'Holografischer Glanz auf Shiny-Fotos, am Bildschirm und beim Teilen';

  @override
  String get photoFoilTurnOff => 'Folie für dieses Foto ausschalten';

  @override
  String get photoFoilTurnOn => 'Folie für dieses Foto einschalten';

  @override
  String get photoFoilAlbumOff =>
      'Die Folie ist für das ganze Album aus. Schalte sie in den Albumeinstellungen wieder ein.';

  @override
  String shortcutShootOnRoll(String roll) {
    return 'Auf $roll fotografieren';
  }

  @override
  String get shortcutChooseRoll => 'Film auswählen';

  @override
  String get shortcutChooseRollTitle => 'Welcher Film?';

  @override
  String get shortcutCamera => 'Kamera';

  @override
  String revealProgress(int developed, int total) {
    return '$developed von $total entwickelt';
  }

  @override
  String get revealStripHint =>
      'Scrolle durch deinen Film und tippe auf jedes Negativ, um es zu entwickeln.';

  @override
  String get revealOpenGallery => 'Galerie öffnen';

  @override
  String get googlePhotosSignInCanceled =>
      'Die Google-Anmeldung wurde abgebrochen.';

  @override
  String get googlePhotosNotConfigured =>
      'Die Google-Fotos-Anmeldung ist für diese Version der App nicht eingerichtet, daher hat Google sie abgelehnt.';

  @override
  String get shareAnotherWayTitle => 'Album anders teilen';

  @override
  String get shareAnotherWayBody =>
      'Sende die Fotos an eine beliebige App (auch Google Fotos) oder speichere sie als Album auf dem Handy, das Google Fotos sichert und teilen kann.';

  @override
  String get galleryShareWithApp => 'Mit einer App teilen';

  @override
  String get gallerySaveToPhoneAlbum => 'Als Album aufs Handy speichern';

  @override
  String gallerySavedToPhoneAlbum(String album) {
    return 'Im Album „$album“ auf dem Handy gespeichert. Google Fotos kann es von dort sichern und teilen.';
  }

  @override
  String widgetFramesOf(String used, String total) {
    return '$used / $total';
  }

  @override
  String widgetReadyInDays(String days, String hours) {
    return 'Fertig in $days T. $hours Std.';
  }

  @override
  String widgetReadyInHours(String hours, String minutes) {
    return 'Fertig in $hours Std. $minutes Min.';
  }

  @override
  String get widgetReady => 'Bereit zum Entwickeln';

  @override
  String get widgetFull => 'Rolle voll. Zum Entwickeln schicken';

  @override
  String get developedDialogTitle => 'Film entwickelt';

  @override
  String developedDialogBody(String roll) {
    return '$roll ist fertig. Jetzt öffnen und die Fotos ansehen?';
  }

  @override
  String get developedDialogLater => 'Später';

  @override
  String get developedDialogOpen => 'Öffnen';

  @override
  String get whatsNewTitle => 'Neuigkeiten';

  @override
  String whatsNewTitleWithVersion(String version) {
    return 'Neu in $version';
  }

  @override
  String get whatsNewIntro =>
      'Das hat sich geändert, seit du Negativo zuletzt geöffnet hast.';

  @override
  String get whatsNewGotIt => 'Verstanden';

  @override
  String get changelogFullButton => 'Alle Änderungen';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get changelogTitle => 'Versionsverlauf';

  @override
  String get changelogSub => 'Was sich in jeder Version geändert hat';

  @override
  String get changelogEmpty => 'Dieser Build enthält keinen Versionsverlauf.';

  @override
  String get changelogCurrentVersionBadge => 'Installiert';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsVersionDev => 'Entwicklungs-Build';
}
