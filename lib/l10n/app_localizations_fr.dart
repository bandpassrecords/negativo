// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Négatif';

  @override
  String get navRolls => 'Pellicules';

  @override
  String get navAlbums => 'Albums';

  @override
  String get navRewards => 'Récompenses';

  @override
  String get navSettings => 'Réglages';

  @override
  String get rollsEmpty => 'Aucune pellicule chargée';

  @override
  String get rollsEmptySub =>
      'Chargez une pellicule pour commencer à photographier.';

  @override
  String get rollsLoadFilmRoll => 'Charger une pellicule';

  @override
  String get rollsLoadFilmFab => 'Charger';

  @override
  String get rollsDevelopingSection => 'En développement';

  @override
  String get rollsStatusLoaded => 'CHARGÉ';

  @override
  String get rollsShoot => 'Photographier';

  @override
  String get rollsDevelop => 'Développer';

  @override
  String get rollsAlmostReady => 'Presque prêt…';

  @override
  String get rollsDevNow => 'DEV. MAINTENANT';

  @override
  String rollsFramesUsed(int used, int total) {
    return '$used / $total poses utilisées';
  }

  @override
  String rollsDaysHoursRemaining(int days, int hours) {
    return '${days}j ${hours}h restants';
  }

  @override
  String rollsHoursMinutesRemaining(int hours, int minutes) {
    return '${hours}h ${minutes}m restants';
  }

  @override
  String rollsMinutesRemaining(int minutes) {
    return '${minutes}m restants';
  }

  @override
  String get albumsTitle => 'Albums';

  @override
  String get albumsEmpty => 'Aucune pellicule développée';

  @override
  String get albumsEmptySub =>
      'Photographiez une pellicule et envoyez-la au développement.';

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
  String get newRollTitle => 'Charger une pellicule';

  @override
  String get newRollChooseStock => 'Choisir la pellicule';

  @override
  String get newRollChooseStockSub =>
      'Chaque pellicule donne un rendu unique à vos photos.';

  @override
  String get newRollChooseCapacity => 'Choisir la capacité';

  @override
  String get newRollChooseCapacitySub => 'Combien de poses a cette pellicule ?';

  @override
  String get newRollNameTitle => 'Nommer cette pellicule';

  @override
  String get newRollNameSub =>
      'Pour quel moment ou voyage est cette pellicule ?';

  @override
  String get newRollNameHint => 'Voyage à Paris, Été 2024, Road Trip…';

  @override
  String get newRollLoadButton => 'Charger';

  @override
  String get newRollNameRequired => 'Donnez d\'abord un nom à votre pellicule';

  @override
  String get newRollFrames => 'poses';

  @override
  String newRollPtsToUnlock(int cost) {
    return '$cost pts pour débloquer';
  }

  @override
  String get detailSendToDevelop => 'Envoyer au développement ?';

  @override
  String detailSendFullBody(int capacity, String duration) {
    return 'Votre pellicule de $capacity poses est prête. Elle sera développée en $duration.';
  }

  @override
  String detailSendPartialBody(int used, int total, String duration) {
    return 'Vous avez utilisé $used sur $total poses. Rembobiner et développer maintenant ?\n\nLe développement prend $duration.';
  }

  @override
  String get detailCancel => 'Annuler';

  @override
  String get detailDevelop => 'Développer';

  @override
  String get detailDeleteTitle => 'Supprimer cette pellicule ?';

  @override
  String detailDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Les $count photos seront supprimées définitivement. Cette action est irréversible.',
      one:
          '1 photo sera supprimée définitivement. Cette action est irréversible.',
    );
    return '$_temp0';
  }

  @override
  String get detailDeleteTooltip => 'Supprimer la pellicule';

  @override
  String get detailDelete => 'Supprimer';

  @override
  String get detailStatusActive => 'Active';

  @override
  String get detailStatusDeveloping => 'En développement';

  @override
  String get detailStatusDeveloped => 'Développée';

  @override
  String get detailStatusUnknown => 'Inconnu';

  @override
  String get detailInfoCreated => 'Créée';

  @override
  String get detailInfoCapacity => 'Capacité';

  @override
  String detailInfoFramesCount(int count) {
    return '$count poses';
  }

  @override
  String get detailInfoExposed => 'Exposées';

  @override
  String get detailInfoSentToDevelop => 'Envoyée au développement';

  @override
  String get detailInfoDevelopedOn => 'Développée le';

  @override
  String get detailInfoReadyOn => 'Prête le';

  @override
  String detailFramesUsedOf(int used, int total) {
    return '$used / $total poses';
  }

  @override
  String detailFramesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count poses restantes',
      one: '1 pose restante',
    );
    return '$_temp0';
  }

  @override
  String get detailAlmostReady => 'Presque prêt…';

  @override
  String detailDevelopingBody(int count) {
    return '$count poses sont en cours de développement. Vous serez notifié quand elles seront prêtes.';
  }

  @override
  String get detailOpenCamera => 'Ouvrir l\'appareil';

  @override
  String get detailDevelopRoll => 'Développer la pellicule';

  @override
  String get detailRewindDevelop => 'Rembobiner et développer';

  @override
  String get detailViewPhotos => 'Voir les photos';

  @override
  String detailDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String detailDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
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
  String get galleryNoPhotos => 'Aucune photo dans cette pellicule';

  @override
  String get galleryShare => 'Partager';

  @override
  String galleryFrameLabel(int order) {
    return 'Pose $order';
  }

  @override
  String galleryFrameOf(int current, int total) {
    return 'Pose $current / $total';
  }

  @override
  String get progressTitle => 'Progression';

  @override
  String get progressAvailablePoints => 'points disponibles';

  @override
  String progressTowardNext(int percent, String feature) {
    return '$percent% vers $feature';
  }

  @override
  String get progressAllUnlocked =>
      '🏆 Toutes les fonctionnalités débloquées !';

  @override
  String progressLifetimePoints(int points) {
    return '$points pts gagnés au total';
  }

  @override
  String get progressHowToEarn => 'COMMENT GAGNER';

  @override
  String get progressEarnPhoto => 'Prendre une photo';

  @override
  String get progressEarnFullRoll =>
      'Utiliser toutes les poses d\'une pellicule';

  @override
  String get progressEarnStartDev => 'Envoyer une pellicule au développement';

  @override
  String get progressEarnCompleteDev => 'Pellicule entièrement développée';

  @override
  String get progressEarnWind => 'Avancer le film en exactement 0,8 s';

  @override
  String get progressWindPrecision =>
      'Précision : ±0,05 s = 25 pts · ±0,15 s = 15 pts · ±0,30 s = 8 pts · ±0,50 s = 3 pts';

  @override
  String get progressFilmStocks => 'PELLICULES';

  @override
  String get progressFilmStocksFree =>
      'Kodak Gold 200 et Portra 400 sont gratuits. Débloquez les autres avec des points.';

  @override
  String get progressUpgrades => 'AMÉLIORATIONS';

  @override
  String get progressDevBoost => 'ACCÉLÉRER LE DÉVELOPPEMENT';

  @override
  String get progressDevBoostSub =>
      'Dépensez des points pour accélérer le développement.';

  @override
  String progressNotEnoughPoints(int cost, int have) {
    return 'Pas assez de points (besoin de $cost, vous avez $have)';
  }

  @override
  String progressNotEnoughPointsSimple(int cost) {
    return 'Pas assez de points (besoin de $cost)';
  }

  @override
  String progressUnlockedFeature(String name) {
    return '🎉 Débloqué : $name !';
  }

  @override
  String get progressDevComplete => '⚡ Développement terminé !';

  @override
  String get progressHalfTime => '⏩ Temps réduit de moitié !';

  @override
  String get progressAlmostReady => 'Presque prêt';

  @override
  String progressDaysHoursLeft(int days, int hours) {
    return '${days}j ${hours}h restants';
  }

  @override
  String progressHoursMinutesLeft(int hours, int minutes) {
    return '${hours}h ${minutes}m restants';
  }

  @override
  String progressMinutesLeft(int minutes) {
    return '${minutes}m restants';
  }

  @override
  String progressHalfTimeBtn(int cost) {
    return '⏩ Moitié du temps\n$cost pts';
  }

  @override
  String progressInstantBtn(int cost) {
    return '⚡ Instantané\n$cost pts';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsFilmDev => 'Développement';

  @override
  String get settingsFilmDevSub =>
      'Combien de temps faut-il pour développer votre film ?';

  @override
  String get settingsDev1Day => '1 jour';

  @override
  String get settingsDev2Days => '2 jours';

  @override
  String get settingsDev3Days => '3 jours';

  @override
  String get settingsDev1Week => '1 semaine';

  @override
  String get settingsNotifyDev => 'Notifier quand c\'est prêt';

  @override
  String get settingsNotifyDevSub =>
      'Recevez une notification quand votre film est prêt';

  @override
  String get settingsStatistics => 'Statistiques';

  @override
  String get settingsRollsDeveloped => 'Pellicules développées';

  @override
  String get settingsTotalPhotos => 'Total de photos prises';

  @override
  String get settingsTotalRolls => 'Total de pellicules';

  @override
  String get notifDevReadyTitle => 'Film développé !';

  @override
  String notifDevReadyBody(String name) {
    return 'Votre pellicule \"$name\" est prête à être récupérée.';
  }
}
