import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../features/routine/domain/class_entry.dart';

/// Every reminder is scheduled entirely on-device via Android's AlarmManager
/// (through flutter_local_notifications) and repeats weekly on its own.
/// There is no server, no Firebase project, and no internet connection
/// involved anywhere in this class.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      // NOTE: getLocalTimezone() is flutter_timezone's current method name
      // as of writing. If `flutter pub get` resolves a version that renamed
      // it, this is the other spot to check against the package's README.
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (e) {
      developer.log(
        'Could not resolve device timezone, defaulting to UTC: $e',
        name: 'NotificationService',
      );
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: initSettings);

    _initialized = true;
  }

  /// Requests the Android 13+ POST_NOTIFICATIONS runtime permission and the
  /// Android 12+ "Alarms & reminders" exact-alarm access. Both are needed
  /// for reminders to fire at the exact scheduled minute.
  ///
  /// NOTE: `requestExactAlarmsPermission()` was added to
  /// flutter_local_notifications a few versions back. If this fails to
  /// compile against whatever version `flutter pub get` resolves, check
  /// the package's current AndroidFlutterLocalNotificationsPlugin API —
  /// the method name is the most likely thing to have shifted.
  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;

    final notificationsGranted =
        await androidPlugin.requestNotificationsPermission() ?? false;
    final exactAlarmGranted =
        await androidPlugin.requestExactAlarmsPermission() ?? false;
    return notificationsGranted && exactAlarmGranted;
  }

  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.areNotificationsEnabled() ?? false;
  }

  /// Schedules (or reschedules) a reminder that repeats every week at the
  /// same day/time, [ClassEntry.reminderMinutesBefore] minutes before the
  /// class starts.
  Future<void> scheduleWeeklyReminder(ClassEntry entry) async {
    await cancelReminder(entry);

    // Auto-request permissions if needed
    try {
      await requestPermissions();
    } catch (_) {}

    final classStart = _nextOccurrence(
      dayOfWeek: entry.dayOfWeek,
      hour: entry.startHour,
      minute: entry.startMinute,
    );
    final reminderTime = _asFutureOccurrence(
      classStart.subtract(Duration(minutes: entry.reminderMinutesBefore)),
    );

    const androidDetails = AndroidNotificationDetails(
      'classping_reminders',
      'Class reminders',
      channelDescription: 'Reminders before each scheduled class',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    try {
      await _plugin.zonedSchedule(
        id: entry.notificationId,
        title: '${entry.subject} starts soon',
        body: _reminderBody(entry),
        scheduledDate: reminderTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      developer.log(
        'Exact alarm failed, falling back to inexact schedule: $e',
        name: 'NotificationService',
      );
      try {
        await _plugin.zonedSchedule(
          id: entry.notificationId,
          title: '${entry.subject} starts soon',
          body: _reminderBody(entry),
          scheduledDate: reminderTime,
          notificationDetails: const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (err, st) {
        developer.log(
          'Failed to schedule notification: $err',
          name: 'NotificationService',
          error: err,
          stackTrace: st,
        );
      }
    }
  }

  Future<void> cancelReminder(ClassEntry entry) async {
    try {
      await _plugin.cancel(id: entry.notificationId);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Called whenever the routine list loads (app start, or right after the
  /// semester-break dates are changed in Settings). If a break is currently
  /// active, every reminder is cancelled so nothing fires during vacation;
  /// otherwise every entry is (re)scheduled normally. This is a simple,
  /// app-open-time sync rather than exact-date OS scheduling, so it only
  /// takes effect the next time ClassPing is opened while a break starts
  /// or ends \u2014 acceptable for a student project, but worth noting as a
  /// known limitation rather than true background pausing.
  Future<void> syncWithSemesterBreak({
    required List<ClassEntry> entries,
    required bool breakIsActive,
  }) async {
    for (final entry in entries) {
      if (breakIsActive) {
        await cancelReminder(entry);
      } else {
        await scheduleWeeklyReminder(entry);
      }
    }
  }

  String _reminderBody(ClassEntry entry) {
    final parts = <String>[entry.startTimeLabel];
    if (entry.room.isNotEmpty) parts.add('Room ${entry.room}');
    if (entry.instructor.isNotEmpty) parts.add(entry.instructor);
    return parts.join(' \u2022 ');
  }

  /// The next upcoming date/time for [dayOfWeek] (0=Sunday..6=Saturday) at
  /// [hour]:[minute].
  tz.TZDateTime _nextOccurrence({
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    final targetWeekday = dayOfWeek == 0 ? DateTime.sunday : dayOfWeek;
    while (scheduled.weekday != targetWeekday || scheduled.isBefore(now.subtract(const Duration(seconds: 30)))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _asFutureOccurrence(tz.TZDateTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var result = time;
    while (result.isBefore(now.subtract(const Duration(seconds: 30)))) {
      result = result.add(const Duration(days: 7));
    }
    return result;
  }
}
