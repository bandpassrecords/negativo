// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Negativo';

  @override
  String get navRolls => 'Rullini';

  @override
  String get navAlbums => 'Album';

  @override
  String get navRewards => 'Ricompense';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get rollsEmpty => 'Nessun rullino caricato';

  @override
  String get rollsEmptySub => 'Carica un rullino per iniziare a fotografare.';

  @override
  String get rollsLoadFilmRoll => 'Carica Rullino';

  @override
  String get rollsLoadFilmFab => 'Carica Film';

  @override
  String get rollsDevelopingSection => 'In Sviluppo';

  @override
  String get rollsStatusLoaded => 'CARICATO';

  @override
  String get rollsShoot => 'Fotografare';

  @override
  String get rollsDevelop => 'Sviluppare';

  @override
  String get rollsAlmostReady => 'Quasi pronto…';

  @override
  String get rollsDevNow => 'SVILUPPA ORA';

  @override
  String rollsFramesUsed(int used, int total) {
    return '$used / $total fotogrammi usati';
  }

  @override
  String rollsDaysHoursRemaining(int days, int hours) {
    return '${days}g ${hours}h rimanenti';
  }

  @override
  String rollsHoursMinutesRemaining(int hours, int minutes) {
    return '${hours}h ${minutes}m rimanenti';
  }

  @override
  String rollsMinutesRemaining(int minutes) {
    return '${minutes}m rimanenti';
  }

  @override
  String get albumsTitle => 'Album';

  @override
  String get albumsEmpty => 'Nessun rullino sviluppato ancora';

  @override
  String get albumsEmptySub => 'Fotografa un rullino e mandalo a sviluppare.';

  @override
  String albumsPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto',
      one: '$count foto',
    );
    return '$_temp0';
  }

  @override
  String get newRollTitle => 'Carica Rullino';

  @override
  String get newRollChooseStock => 'Scegli il film';

  @override
  String get newRollChooseStockSub =>
      'Ogni film dà alle tue foto un aspetto unico.';

  @override
  String get newRollChooseCapacity => 'Scegli la capacità';

  @override
  String get newRollChooseCapacitySub => 'Quanti fotogrammi ha questo rullino?';

  @override
  String get newRollNameTitle => 'Dai un nome al rullino';

  @override
  String get newRollNameSub => 'Per quale momento o viaggio è questo rullino?';

  @override
  String get newRollNameHint => 'Viaggio a Parigi, Estate 2024, Road Trip…';

  @override
  String get newRollLoadButton => 'Carica Rullino';

  @override
  String get newRollNameRequired => 'Prima dai un nome al tuo rullino';

  @override
  String get newRollFrames => 'fotogrammi';

  @override
  String newRollPtsToUnlock(int cost) {
    return '$cost pts per sbloccare';
  }

  @override
  String get detailSendToDevelop => 'Mandare a sviluppare?';

  @override
  String detailSendFullBody(int capacity, String duration) {
    return 'Il tuo rullino da $capacity fotogrammi è pronto. Verrà sviluppato in $duration.';
  }

  @override
  String detailSendPartialBody(int used, int total, String duration) {
    return 'Hai usato $used di $total fotogrammi. Riavvolgi e sviluppa ora?\n\nLo sviluppo richiede $duration.';
  }

  @override
  String get detailCancel => 'Annulla';

  @override
  String get detailDevelop => 'Sviluppa';

  @override
  String get detailDeleteTitle => 'Eliminare questo rullino?';

  @override
  String detailDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tutte le $count foto verranno eliminate definitivamente. Questa azione è irreversibile.',
      one:
          '1 foto verrà eliminata definitivamente. Questa azione è irreversibile.',
    );
    return '$_temp0';
  }

  @override
  String get detailDeleteTooltip => 'Elimina rullino';

  @override
  String get detailDelete => 'Elimina';

  @override
  String get detailStatusActive => 'Attivo';

  @override
  String get detailStatusDeveloping => 'In sviluppo';

  @override
  String get detailStatusDeveloped => 'Sviluppato';

  @override
  String get detailStatusUnknown => 'Sconosciuto';

  @override
  String get detailInfoCreated => 'Creato';

  @override
  String get detailInfoCapacity => 'Capacità';

  @override
  String detailInfoFramesCount(int count) {
    return '$count fotogrammi';
  }

  @override
  String get detailInfoExposed => 'Esposti';

  @override
  String get detailInfoSentToDevelop => 'Inviato a sviluppare';

  @override
  String get detailInfoDevelopedOn => 'Sviluppato il';

  @override
  String get detailInfoReadyOn => 'Pronto il';

  @override
  String detailFramesUsedOf(int used, int total) {
    return '$used / $total fotogrammi';
  }

  @override
  String detailFramesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotogrammi rimanenti',
      one: '1 fotogramma rimanente',
    );
    return '$_temp0';
  }

  @override
  String get detailAlmostReady => 'Quasi pronto…';

  @override
  String detailDevelopingBody(int count) {
    return '$count fotogrammi sono in sviluppo. Riceverai una notifica quando saranno pronti.';
  }

  @override
  String get detailOpenCamera => 'Apri Fotocamera';

  @override
  String get detailDevelopRoll => 'Sviluppa Rullino';

  @override
  String get detailRewindDevelop => 'Riavvolgi e Sviluppa';

  @override
  String get detailViewPhotos => 'Vedi Foto';

  @override
  String detailDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore',
      one: '1 ora',
    );
    return '$_temp0';
  }

  @override
  String detailDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String galleryPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String get galleryNoPhotos => 'Nessuna foto in questo rullino';

  @override
  String get galleryShare => 'Condividi';

  @override
  String galleryFrameLabel(int order) {
    return 'Fotogramma $order';
  }

  @override
  String galleryFrameOf(int current, int total) {
    return 'Fotogramma $current / $total';
  }

  @override
  String get progressTitle => 'Progressi';

  @override
  String get progressAvailablePoints => 'punti disponibili';

  @override
  String progressTowardNext(int percent, String feature) {
    return '$percent% verso $feature';
  }

  @override
  String get progressAllUnlocked => '🏆 Tutte le funzioni sbloccate!';

  @override
  String progressLifetimePoints(int points) {
    return '$points pts guadagnati in totale';
  }

  @override
  String get progressHowToEarn => 'COME GUADAGNARE';

  @override
  String get progressEarnPhoto => 'Scattare una foto';

  @override
  String get progressEarnFullRoll => 'Usare tutti i fotogrammi di un rullino';

  @override
  String get progressEarnStartDev => 'Mandare il rullino a sviluppare';

  @override
  String get progressEarnCompleteDev => 'Rullino completamente sviluppato';

  @override
  String get progressEarnWind => 'Avanzare il film in esattamente 0,8 s';

  @override
  String get progressWindPrecision =>
      'Precisione: ±0,05 s = 25 pts · ±0,15 s = 15 pts · ±0,30 s = 8 pts · ±0,50 s = 3 pts';

  @override
  String get progressFilmStocks => 'TIPI DI PELLICOLA';

  @override
  String get progressFilmStocksFree =>
      'Kodak Portra 400 è gratuito. Sblocca gli altri con i punti.';

  @override
  String get progressUpgrades => 'AGGIORNAMENTI';

  @override
  String get progressDevBoost => 'ACCELERA SVILUPPO';

  @override
  String get progressDevBoostSub =>
      'Spendi punti per accelerare lo sviluppo di un rullino.';

  @override
  String progressNotEnoughPoints(int cost, int have) {
    return 'Punti insufficienti (servono $cost, hai $have)';
  }

  @override
  String progressNotEnoughPointsSimple(int cost) {
    return 'Punti insufficienti (servono $cost)';
  }

  @override
  String progressUnlockedFeature(String name) {
    return '🎉 Sbloccato: $name!';
  }

  @override
  String get progressDevComplete => '⚡ Sviluppo completato!';

  @override
  String get progressHalfTime => '⏩ Tempo dimezzato!';

  @override
  String get progressAlmostReady => 'Quasi pronto';

  @override
  String progressDaysHoursLeft(int days, int hours) {
    return '${days}g ${hours}h rimanenti';
  }

  @override
  String progressHoursMinutesLeft(int hours, int minutes) {
    return '${hours}h ${minutes}m rimanenti';
  }

  @override
  String progressMinutesLeft(int minutes) {
    return '${minutes}m rimanenti';
  }

  @override
  String progressHalfTimeBtn(int cost) {
    return '⏩ Metà del tempo\n$cost pts';
  }

  @override
  String progressInstantBtn(int cost) {
    return '⚡ Istantaneo\n$cost pts';
  }

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsFilmDev => 'Sviluppo Pellicola';

  @override
  String get settingsFilmDevSub => 'Quanto tempo deve richiedere lo sviluppo?';

  @override
  String get settingsDev1Day => '1 giorno';

  @override
  String get settingsDev2Days => '2 giorni';

  @override
  String get settingsDev3Days => '3 giorni';

  @override
  String get settingsDev1Week => '1 settimana';

  @override
  String get settingsNotifyDev => 'Notifica quando sviluppato';

  @override
  String get settingsNotifyDevSub =>
      'Ricevi una notifica quando la tua pellicola è pronta';

  @override
  String get settingsStatistics => 'Statistiche';

  @override
  String get settingsRollsDeveloped => 'Rullini sviluppati';

  @override
  String get settingsTotalPhotos => 'Totale foto scattate';

  @override
  String get settingsTotalRolls => 'Totale rullini';

  @override
  String get notifDevReadyTitle => 'Pellicola sviluppata!';

  @override
  String notifDevReadyBody(String name) {
    return 'Il tuo rullino \"$name\" è pronto da ritirare.';
  }
}
