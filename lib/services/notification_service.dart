import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/film_roll.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    tz.initializeTimeZones();
    _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(initSettings);
    await _requestPermissions();
  }

  static void _configureLocalTimezone() {
    try {
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      final timezoneMap = {
        0: 'UTC',
        1: 'Europe/Paris',
        -1: 'Atlantic/Azores',
        2: 'Europe/Berlin',
        -2: 'Atlantic/South_Georgia',
        3: 'Europe/Moscow',
        -3: 'America/Sao_Paulo',
        4: 'Asia/Dubai',
        -4: 'America/New_York',
        5: 'Asia/Karachi',
        -5: 'America/Chicago',
        -6: 'America/Denver',
        -7: 'America/Los_Angeles',
        8: 'Asia/Shanghai',
        -8: 'Pacific/Pitcairn',
        9: 'Asia/Tokyo',
        -9: 'Pacific/Gambier',
        10: 'Australia/Sydney',
        -10: 'Pacific/Honolulu',
      };

      final tzName = timezoneMap[offsetHours];
      if (tzName != null) {
        tz.setLocalLocation(tz.getLocation(tzName));
      } else {
        _setTimezoneByOffset(offsetHours);
      }
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
  }

  static void _setTimezoneByOffset(int offsetHours) {
    try {
      final name = offsetHours == 0
          ? 'UTC'
          : offsetHours > 0
              ? 'Etc/GMT-$offsetHours'
              : 'Etc/GMT+${-offsetHours}';
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final plugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await plugin?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Schedule a notification for when the film roll finishes developing.
  static Future<void> scheduleDevelopmentNotification(FilmRoll roll) async {
    final completesAt = roll.developmentCompletesAt;
    if (completesAt == null) return;

    final scheduledDate = tz.TZDateTime.from(completesAt, tz.local);
    // Skip if already in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final notificationId = roll.id.hashCode.abs() % 100000;

    const androidDetails = AndroidNotificationDetails(
      'film_development',
      'Film Development',
      channelDescription: 'Notifications when your film roll is ready to view',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notifications.zonedSchedule(
        notificationId,
        'Your film is ready! 📷',
        '"${roll.name}" has been developed. Tap to view your photos.',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        payload: 'developed_${roll.id}',
      );
    } catch (_) {}
  }

  /// Cancel the development notification for a given roll ID.
  static Future<void> cancelDevelopmentNotification(String rollId) async {
    final notificationId = rollId.hashCode.abs() % 100000;
    await _notifications.cancel(notificationId);
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
