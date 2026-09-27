// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Negativo';

  @override
  String get navRolls => 'Rollos';

  @override
  String get navAlbums => 'Álbumes';

  @override
  String get navRewards => 'Recompensas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get rollsEmpty => 'No hay película cargada';

  @override
  String get rollsEmptySub => 'Carga un rollo para empezar a fotografiar.';

  @override
  String get rollsLoadFilmRoll => 'Cargar Rollo';

  @override
  String get rollsLoadFilmFab => 'Cargar Película';

  @override
  String get rollsDevelopingSection => 'En Revelado';

  @override
  String get rollsStatusLoaded => 'CARGADO';

  @override
  String get rollsShoot => 'Fotografiar';

  @override
  String get rollsDevelop => 'Revelar';

  @override
  String get rollsAlmostReady => 'Casi listo…';

  @override
  String get rollsDevNow => 'REVELAR YA';

  @override
  String rollsFramesUsed(int used, int total) {
    return '$used / $total fotogramas usados';
  }

  @override
  String rollsDaysHoursRemaining(int days, int hours) {
    return '${days}d ${hours}h restantes';
  }

  @override
  String rollsHoursMinutesRemaining(int hours, int minutes) {
    return '${hours}h ${minutes}m restantes';
  }

  @override
  String rollsMinutesRemaining(int minutes) {
    return '${minutes}m restantes';
  }

  @override
  String get albumsTitle => 'Álbumes';

  @override
  String get albumsEmpty => 'Aún no hay rollos revelados';

  @override
  String get albumsEmptySub => 'Fotografía un rollo y envíalo a revelar.';

  @override
  String albumsPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos',
      one: '$count foto',
    );
    return '$_temp0';
  }

  @override
  String get newRollTitle => 'Cargar Rollo de Película';

  @override
  String get newRollChooseStock => 'Elige el tipo de película';

  @override
  String get newRollChooseStockSub =>
      'Cada película da un aspecto único a tus fotos.';

  @override
  String get newRollChooseCapacity => 'Elige la capacidad';

  @override
  String get newRollChooseCapacitySub =>
      '¿Cuántos fotogramas tiene este rollo?';

  @override
  String get newRollNameTitle => 'Nombra este rollo';

  @override
  String get newRollNameSub => '¿Para qué momento o viaje es este rollo?';

  @override
  String get newRollNameHint => 'Viaje a París, Verano 2024, Road Trip…';

  @override
  String get newRollLoadButton => 'Cargar Rollo';

  @override
  String get newRollNameRequired => 'Primero dale un nombre a tu rollo';

  @override
  String get newRollFrames => 'fotogramas';

  @override
  String newRollPtsToUnlock(int cost) {
    return '$cost pts para desbloquear';
  }

  @override
  String get detailSendToDevelop => '¿Enviar a revelar?';

  @override
  String detailSendFullBody(int capacity, String duration) {
    return 'Tu rollo de $capacity fotogramas está listo. Se revelará en $duration.';
  }

  @override
  String detailSendPartialBody(int used, int total, String duration) {
    return 'Has usado $used de $total fotogramas. ¿Rebobinar y revelar ahora?\n\nEl revelado tarda $duration.';
  }

  @override
  String get detailCancel => 'Cancelar';

  @override
  String get detailDevelop => 'Revelar';

  @override
  String get detailDeleteTitle => '¿Eliminar este rollo?';

  @override
  String detailDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Las $count fotos serán eliminadas permanentemente. Esto no se puede deshacer.',
      one: '1 foto será eliminada permanentemente. Esto no se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String get detailDeleteTooltip => 'Eliminar rollo';

  @override
  String get detailDelete => 'Eliminar';

  @override
  String get detailStatusActive => 'Activo';

  @override
  String get detailStatusDeveloping => 'Revelando';

  @override
  String get detailStatusDeveloped => 'Revelado';

  @override
  String get detailStatusUnknown => 'Desconocido';

  @override
  String get detailInfoCreated => 'Creado';

  @override
  String get detailInfoCapacity => 'Capacidad';

  @override
  String detailInfoFramesCount(int count) {
    return '$count fotogramas';
  }

  @override
  String get detailInfoExposed => 'Expuestos';

  @override
  String get detailInfoSentToDevelop => 'Enviado a revelar';

  @override
  String get detailInfoDevelopedOn => 'Revelado el';

  @override
  String get detailInfoReadyOn => 'Listo el';

  @override
  String detailFramesUsedOf(int used, int total) {
    return '$used / $total fotogramas';
  }

  @override
  String detailFramesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotogramas restantes',
      one: '1 fotograma restante',
    );
    return '$_temp0';
  }

  @override
  String get detailAlmostReady => 'Casi listo…';

  @override
  String detailDevelopingBody(int count) {
    return '$count fotogramas se están revelando. Recibirás una notificación cuando estén listos.';
  }

  @override
  String get detailOpenCamera => 'Abrir Cámara';

  @override
  String get detailDevelopRoll => 'Revelar Rollo';

  @override
  String get detailRewindDevelop => 'Rebobinar y Revelar';

  @override
  String get detailViewPhotos => 'Ver Fotos';

  @override
  String detailDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String detailDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String galleryPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String get galleryNoPhotos => 'No hay fotos en este rollo';

  @override
  String get galleryShare => 'Compartir';

  @override
  String galleryFrameLabel(int order) {
    return 'Fotograma $order';
  }

  @override
  String galleryFrameOf(int current, int total) {
    return 'Fotograma $current / $total';
  }

  @override
  String get progressTitle => 'Progreso';

  @override
  String get progressAvailablePoints => 'puntos disponibles';

  @override
  String progressTowardNext(int percent, String feature) {
    return '$percent% hacia $feature';
  }

  @override
  String get progressAllUnlocked => '🏆 ¡Todas las funciones desbloqueadas!';

  @override
  String progressLifetimePoints(int points) {
    return '$points pts ganados en total';
  }

  @override
  String get progressHowToEarn => 'CÓMO GANAR';

  @override
  String get progressEarnPhoto => 'Tomar una foto';

  @override
  String get progressEarnFullRoll => 'Usar todos los fotogramas de un rollo';

  @override
  String get progressEarnStartDev => 'Enviar rollo a revelar';

  @override
  String get progressEarnCompleteDev => 'Rollo completamente revelado';

  @override
  String get progressEarnWind => 'Avanzar película en exactamente 0,8 s';

  @override
  String get progressWindPrecision =>
      'Precisión: ±0,05 s = 25 pts · ±0,15 s = 15 pts · ±0,30 s = 8 pts · ±0,50 s = 3 pts';

  @override
  String get progressFilmStocks => 'TIPOS DE PELÍCULA';

  @override
  String get progressFilmStocksFree =>
      'Kodak Gold 200 y Portra 400 son gratuitos. Desbloquea el resto con puntos.';

  @override
  String get progressUpgrades => 'MEJORAS';

  @override
  String get progressDevBoost => 'ACELERAR REVELADO';

  @override
  String get progressDevBoostSub =>
      'Usa puntos para acelerar el revelado de un rollo.';

  @override
  String progressNotEnoughPoints(int cost, int have) {
    return 'Puntos insuficientes (necesitas $cost, tienes $have)';
  }

  @override
  String progressNotEnoughPointsSimple(int cost) {
    return 'Puntos insuficientes (necesitas $cost)';
  }

  @override
  String progressUnlockedFeature(String name) {
    return '🎉 ¡Desbloqueado: $name!';
  }

  @override
  String get progressDevComplete => '⚡ ¡Revelado completo!';

  @override
  String get progressHalfTime => '⏩ ¡Tiempo reducido a la mitad!';

  @override
  String get progressAlmostReady => 'Casi listo';

  @override
  String progressDaysHoursLeft(int days, int hours) {
    return '${days}d ${hours}h restantes';
  }

  @override
  String progressHoursMinutesLeft(int hours, int minutes) {
    return '${hours}h ${minutes}m restantes';
  }

  @override
  String progressMinutesLeft(int minutes) {
    return '${minutes}m restantes';
  }

  @override
  String progressHalfTimeBtn(int cost) {
    return '⏩ Mitad de tiempo\n$cost pts';
  }

  @override
  String progressInstantBtn(int cost) {
    return '⚡ Instantáneo\n$cost pts';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsFilmDev => 'Revelado de Película';

  @override
  String get settingsFilmDevSub =>
      '¿Cuánto tiempo debe tardar en revelar tu película?';

  @override
  String get settingsDev1Day => '1 día';

  @override
  String get settingsDev2Days => '2 días';

  @override
  String get settingsDev3Days => '3 días';

  @override
  String get settingsDev1Week => '1 semana';

  @override
  String get settingsNotifyDev => 'Notificar cuando esté revelado';

  @override
  String get settingsNotifyDevSub =>
      'Recibe una notificación cuando tu película esté lista';

  @override
  String get settingsStatistics => 'Estadísticas';

  @override
  String get settingsRollsDeveloped => 'Rollos revelados';

  @override
  String get settingsTotalPhotos => 'Total de fotos tomadas';

  @override
  String get settingsTotalRolls => 'Total de rollos';

  @override
  String get revealSkipAll => 'Saltar todo';

  @override
  String get revealTapToDevelop => 'Toca para revelar';

  @override
  String get revealSwipeForNext => 'Desliza al siguiente fotograma';

  @override
  String get revealAllDeveloped => 'Todos los fotogramas revelados';

  @override
  String get revealTapToOpenGallery => 'Toca para abrir la galería';

  @override
  String get albumCustomizeColor => 'Color';

  @override
  String get albumCustomizePattern => 'Patrón';

  @override
  String get albumEditThumbnail => 'Editar fotos de miniatura';

  @override
  String get albumEditThumbnailSub =>
      'Elige hasta 4 fotos para la portada del álbum';

  @override
  String get albumEffectSub =>
      'Mostrar efecto de película en todas las fotos de este álbum';

  @override
  String get galleryEditThumbnail => 'Editar miniatura';

  @override
  String get gallerySharePhotos => 'Compartir fotos';

  @override
  String get gallerySelectThumbnail => 'Seleccionar miniatura';

  @override
  String get galleryMaxThumbnail => 'Máximo 4 fotos para la miniatura';

  @override
  String get galleryThumbnailUpdated => 'Miniatura actualizada';

  @override
  String get gallerySelectPhotos => 'Seleccionar fotos';

  @override
  String gallerySelectedCount(int count) {
    return '$count seleccionado(s)';
  }

  @override
  String get gallerySelectAll => 'Seleccionar todo';

  @override
  String get galleryDeselectAll => 'Deseleccionar todo';

  @override
  String galleryShareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Compartir $count fotos',
      one: 'Compartir 1 foto',
      zero: 'Compartir',
    );
    return '$_temp0';
  }

  @override
  String get galleryGooglePhotos => 'Google Fotos';

  @override
  String get galleryGooglePhotosUploading => 'Subiendo a Google Fotos…';

  @override
  String get galleryGooglePhotosDone =>
      'Álbum creado en Google Fotos. Ábrelo para compartirlo.';

  @override
  String get galleryGooglePhotosOpen => 'Abrir';

  @override
  String galleryGooglePhotosFailed(String error) {
    return 'Error al subir a Google Fotos: $error';
  }

  @override
  String get settingsAlbumReveal => 'Revelado de álbum';

  @override
  String get settingsAlbumRevealSub =>
      'Mostrar negativo de película antes de revelar cada foto';

  @override
  String get photoInfoTitle => 'Info de foto';

  @override
  String get photoInfoDate => 'Fecha';

  @override
  String get photoInfoRoll => 'Rollo';

  @override
  String get photoInfoFilmStock => 'Tipo de película';

  @override
  String get photoInfoSize => 'Tamaño';

  @override
  String get photoInfoFrame => 'Fotograma';

  @override
  String get photoInfoEffect => 'Efecto de Película';

  @override
  String effectFound(String name) {
    return '🎞 ¡Efecto $name en este fotograma!';
  }

  @override
  String get effectShinyFound =>
      '🌈 ¡Fotograma foil! Inclina tu teléfono para verlo brillar.';

  @override
  String get notifDevReadyTitle => '¡Película revelada!';

  @override
  String notifDevReadyBody(String name) {
    return 'Tu rollo \"$name\" está listo para recoger.';
  }

  @override
  String get negativesTitle => 'Negativos';

  @override
  String get negativesHint =>
      'Toca un fotograma para verlo a contraluz. Los fotogramas foil brillan al inclinar el teléfono.';

  @override
  String get negativesSave => 'Guardar negativos en la galería';

  @override
  String get negativesSaved => 'Negativos guardados en tu galería';

  @override
  String negativesSaveFailed(String error) {
    return 'No se pudieron guardar los negativos: $error';
  }

  @override
  String get negativesNegative => 'Negativo';

  @override
  String get negativesPrint => 'Copia';

  @override
  String get negativesFoilHint => '✨ Fotograma foil — inclina tu teléfono';

  @override
  String get albumFoil => 'Fotogramas foil';

  @override
  String get albumFoilSub =>
      'Brillo holográfico en las fotos Shiny, en pantalla y al compartir';

  @override
  String get photoFoilTurnOff => 'Quitar el foil de esta foto';

  @override
  String get photoFoilTurnOn => 'Activar el foil de esta foto';

  @override
  String get photoFoilAlbumOff =>
      'El foil está desactivado en todo el álbum. Actívalo de nuevo en los ajustes del álbum.';

  @override
  String shortcutShootOnRoll(String roll) {
    return 'Fotografiar en $roll';
  }

  @override
  String get shortcutChooseRoll => 'Elegir un rollo';

  @override
  String get shortcutChooseRollTitle => '¿Qué rollo?';

  @override
  String revealProgress(int developed, int total) {
    return '$developed de $total revelados';
  }

  @override
  String get revealStripHint =>
      'Desplázate por la película y toca cada negativo para revelarlo.';

  @override
  String get revealOpenGallery => 'Abrir la galería';

  @override
  String get googlePhotosSignInCanceled =>
      'Se canceló el inicio de sesión de Google.';

  @override
  String get googlePhotosNotConfigured =>
      'El inicio de sesión de Google Fotos no está configurado para esta versión de la app, así que Google lo rechazó.';

  @override
  String get shareAnotherWayTitle => 'Comparte el álbum de otra forma';

  @override
  String get shareAnotherWayBody =>
      'Envía las fotos a cualquier app (Google Fotos incluida) o guárdalas en el teléfono como un álbum del que Google Fotos hace copia y que puede compartir.';

  @override
  String get galleryShareWithApp => 'Compartir con una app';

  @override
  String get gallerySaveToPhoneAlbum => 'Guardar en el teléfono como álbum';

  @override
  String gallerySavedToPhoneAlbum(String album) {
    return 'Guardado en el álbum \"$album\" del teléfono. Google Fotos puede hacer copia y compartirlo desde ahí.';
  }
}
