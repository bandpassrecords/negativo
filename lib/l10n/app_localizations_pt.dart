// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Negativo';

  @override
  String get navRolls => 'Filmes';

  @override
  String get navAlbums => 'Álbuns';

  @override
  String get navRewards => 'Recompensas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get rollsEmpty => 'Nenhum filme carregado';

  @override
  String get rollsEmptySub => 'Carregue um rolo para começar a fotografar.';

  @override
  String get rollsLoadFilmRoll => 'Carregar Rolo';

  @override
  String get rollsLoadFilmFab => 'Carregar Filme';

  @override
  String get rollsDevelopingSection => 'Em Revelação';

  @override
  String get rollsStatusLoaded => 'CARREGADO';

  @override
  String get rollsShoot => 'Fotografar';

  @override
  String get rollsDevelop => 'Revelar';

  @override
  String get rollsAlmostReady => 'Quase pronto…';

  @override
  String get rollsDevNow => 'REVELAR JÁ';

  @override
  String rollsFramesUsed(int used, int total) {
    return '$used / $total frames usados';
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
  String get albumsTitle => 'Álbuns';

  @override
  String get albumsEmpty => 'Nenhum rolo revelado ainda';

  @override
  String get albumsEmptySub => 'Fotografe um rolo e envie para revelação.';

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
  String get newRollTitle => 'Carregar Rolo de Filme';

  @override
  String get newRollChooseStock => 'Escolha o filme';

  @override
  String get newRollChooseStockSub =>
      'Cada filme dá às suas fotos um visual distinto.';

  @override
  String get newRollChooseCapacity => 'Escolha a capacidade';

  @override
  String get newRollChooseCapacitySub => 'Quantos frames tem esse rolo?';

  @override
  String get newRollNameTitle => 'Dê um nome ao rolo';

  @override
  String get newRollNameSub => 'Qual momento ou viagem é para esse rolo?';

  @override
  String get newRollNameHint => 'Viagem a Paris, Verão 2024, Road Trip…';

  @override
  String get newRollLoadButton => 'Carregar Rolo';

  @override
  String get newRollNameRequired => 'Dê um nome ao seu rolo primeiro';

  @override
  String get newRollFrames => 'frames';

  @override
  String newRollPtsToUnlock(int cost) {
    return '$cost pts para desbloquear';
  }

  @override
  String get detailSendToDevelop => 'Enviar para revelação?';

  @override
  String detailSendFullBody(int capacity, String duration) {
    return 'Seu rolo de $capacity frames está pronto. Será revelado em $duration.';
  }

  @override
  String detailSendPartialBody(int used, int total, String duration) {
    return 'Você usou $used de $total frames. Rebobinar e revelar agora?\n\nA revelação leva $duration.';
  }

  @override
  String get detailCancel => 'Cancelar';

  @override
  String get detailDevelop => 'Revelar';

  @override
  String get detailDeleteTitle => 'Excluir este rolo?';

  @override
  String detailDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Todas as $count fotos serão excluídas permanentemente. Isso não pode ser desfeito.',
      one: '1 foto será excluída permanentemente. Isso não pode ser desfeito.',
    );
    return '$_temp0';
  }

  @override
  String get detailDeleteTooltip => 'Excluir rolo';

  @override
  String get detailDelete => 'Excluir';

  @override
  String get detailStatusActive => 'Ativo';

  @override
  String get detailStatusDeveloping => 'Revelando';

  @override
  String get detailStatusDeveloped => 'Revelado';

  @override
  String get detailStatusUnknown => 'Desconhecido';

  @override
  String get detailInfoCreated => 'Criado';

  @override
  String get detailInfoCapacity => 'Capacidade';

  @override
  String detailInfoFramesCount(int count) {
    return '$count frames';
  }

  @override
  String get detailInfoExposed => 'Expostos';

  @override
  String get detailInfoSentToDevelop => 'Enviado para revelar';

  @override
  String get detailInfoDevelopedOn => 'Revelado em';

  @override
  String get detailInfoReadyOn => 'Pronto em';

  @override
  String detailFramesUsedOf(int used, int total) {
    return '$used / $total frames';
  }

  @override
  String detailFramesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frames restantes',
      one: '1 frame restante',
    );
    return '$_temp0';
  }

  @override
  String get detailAlmostReady => 'Quase pronto…';

  @override
  String detailDevelopingBody(int count) {
    return '$count frames estão sendo revelados. Você receberá uma notificação quando estiverem prontos.';
  }

  @override
  String get detailOpenCamera => 'Abrir Câmera';

  @override
  String get detailDevelopRoll => 'Revelar Rolo';

  @override
  String get detailRewindDevelop => 'Rebobinar e Revelar';

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
      other: '$count dias',
      one: '1 dia',
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
  String get galleryNoPhotos => 'Nenhuma foto neste rolo';

  @override
  String get galleryShare => 'Compartilhar';

  @override
  String galleryFrameLabel(int order) {
    return 'Frame $order';
  }

  @override
  String galleryFrameOf(int current, int total) {
    return 'Frame $current / $total';
  }

  @override
  String get progressTitle => 'Progresso';

  @override
  String get progressAvailablePoints => 'pontos disponíveis';

  @override
  String progressTowardNext(int percent, String feature) {
    return '$percent% para $feature';
  }

  @override
  String get progressAllUnlocked => '🏆 Todos os recursos desbloqueados!';

  @override
  String progressLifetimePoints(int points) {
    return '$points pts ganhos no total';
  }

  @override
  String get progressHowToEarn => 'COMO GANHAR';

  @override
  String get progressEarnPhoto => 'Tirar uma foto';

  @override
  String get progressEarnFullRoll => 'Usar todos os frames de um rolo';

  @override
  String get progressEarnStartDev => 'Enviar rolo para revelar';

  @override
  String get progressEarnCompleteDev => 'Rolo totalmente revelado';

  @override
  String get progressEarnWind => 'Avançar filme em exatamente 0,8 s';

  @override
  String get progressWindPrecision =>
      'Precisão: ±0,05 s = 25 pts · ±0,15 s = 15 pts · ±0,30 s = 8 pts · ±0,50 s = 3 pts';

  @override
  String get progressFilmStocks => 'TIPOS DE FILME';

  @override
  String get progressFilmStocksFree =>
      'Kodak Gold 200 e Portra 400 são gratuitos. Desbloqueie os outros com pontos.';

  @override
  String get progressUpgrades => 'MELHORIAS';

  @override
  String get progressDevBoost => 'ACELERAR REVELAÇÃO';

  @override
  String get progressDevBoostSub =>
      'Use pontos para acelerar a revelação de um rolo.';

  @override
  String progressNotEnoughPoints(int cost, int have) {
    return 'Pontos insuficientes (precisa de $cost, tem $have)';
  }

  @override
  String progressNotEnoughPointsSimple(int cost) {
    return 'Pontos insuficientes (precisa de $cost)';
  }

  @override
  String progressUnlockedFeature(String name) {
    return '🎉 Desbloqueado: $name!';
  }

  @override
  String get progressDevComplete => '⚡ Revelação concluída!';

  @override
  String get progressHalfTime => '⏩ Tempo reduzido à metade!';

  @override
  String get progressAlmostReady => 'Quase pronto';

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
    return '⏩ Metade do tempo\n$cost pts';
  }

  @override
  String progressInstantBtn(int cost) {
    return '⚡ Instantâneo\n$cost pts';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsFilmDev => 'Revelação de Filme';

  @override
  String get settingsFilmDevSub =>
      'Quanto tempo deve levar para revelar seu filme?';

  @override
  String get settingsDev1Day => '1 dia';

  @override
  String get settingsDev2Days => '2 dias';

  @override
  String get settingsDev3Days => '3 dias';

  @override
  String get settingsDev1Week => '1 semana';

  @override
  String get settingsNotifyDev => 'Notificar quando revelado';

  @override
  String get settingsNotifyDevSub =>
      'Receba uma notificação quando seu filme estiver pronto';

  @override
  String get settingsStatistics => 'Estatísticas';

  @override
  String get settingsRollsDeveloped => 'Rolos revelados';

  @override
  String get settingsTotalPhotos => 'Total de fotos tiradas';

  @override
  String get settingsTotalRolls => 'Total de rolos';

  @override
  String get notifDevReadyTitle => 'Filme revelado!';

  @override
  String notifDevReadyBody(String name) {
    return 'Seu rolo \"$name\" está pronto para ser retirado.';
  }
}
