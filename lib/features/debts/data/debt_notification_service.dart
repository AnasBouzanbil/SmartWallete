import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import 'debt_repository.dart';

/// Schedules local reminders for open debts on their due date at 09:00.
class DebtNotificationService {
  DebtNotificationService._();

  static final DebtNotificationService instance = DebtNotificationService._();

  static const String _channelId = 'debt_due';
  static const String _channelName = 'Debt due dates';
  static const int _hour = 9;
  static const int _minute = 0;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) {
      return;
    }

    try {
      tzdata.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fall back to UTC scheduling if timezone lookup fails.
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Reminders when a debt is due.',
          importance: Importance.high,
        ),
      );
      await android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _ready = true;
  }

  Future<void> syncDebts(List<DebtSummary> debts) async {
    if (!_ready || kIsWeb) {
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    for (final DebtSummary item in debts) {
      if (item.isSettled) {
        await _cancel(item.debt.id);
        continue;
      }
      final DateTime? due = item.debt.dueDate;
      if (due == null) {
        await _cancel(item.debt.id);
        continue;
      }
      final DateTime dueDay = DateTime(due.year, due.month, due.day);
      if (dueDay.isBefore(today)) {
        await _cancel(item.debt.id);
        continue;
      }

      await _schedule(item, dueDay);
    }
  }

  Future<void> _schedule(DebtSummary item, DateTime dueDay) async {
    final tz.TZDateTime when = tz.TZDateTime(
      tz.local,
      dueDay.year,
      dueDay.month,
      dueDay.day,
      _hour,
      _minute,
    );
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    if (!when.isAfter(now)) {
      // Due today but past 09:00 — fire in one minute so it still reminds.
      final tz.TZDateTime soon = now.add(const Duration(minutes: 1));
      await _zoned(item, soon);
      return;
    }
    await _zoned(item, when);
  }

  Future<void> _zoned(DebtSummary item, tz.TZDateTime when) async {
    final bool isOwed = item.debt.direction == DebtDirection.owed;
    final String title = isOwed ? 'Debt due today' : 'Money owed to you is due';
    final String body =
        '${item.debt.person} · ${formatMinor(item.outstandingMinor)} left';

    try {
      await _plugin.zonedSchedule(
        item.debt.id,
        title,
        body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Reminders when a debt is due.',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Scheduling can fail on restricted devices; never break the app.
    }
  }

  Future<void> _cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}
