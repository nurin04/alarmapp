import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmProvider {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleNotification(
      int id, String title, DateTime dateTime, String repeatType) async {
    final tz.TZDateTime scheduledDate =
        _getFutureDate(tz.TZDateTime.from(dateTime, tz.local));

    final formattedTime =
        DateFormat.jm().format(dateTime); // Format time as 02:30 AM

    final notificationMessage = 'Alarm is set at $formattedTime';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      sound: RawResourceAndroidNotificationSound("alaram"),
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Schedule initial notification if today is a valid day for the repeat type
    if (_isValidDayForRepeatType(dateTime, repeatType)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        notificationMessage,
        scheduledDate,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Handle repeat logic based on selected repeatType
    if (repeatType == 'Daily') {
      await _scheduleDailyNotification(
          id, title, notificationMessage, dateTime, platformChannelSpecifics);
    } else if (repeatType == 'Weekday') {
      _scheduleWeekdayNotifications(
          id, title, notificationMessage, dateTime, platformChannelSpecifics);
    } else if (repeatType == 'Weekend') {
      _scheduleWeekendNotifications(
          id, title, notificationMessage, dateTime, platformChannelSpecifics);
    }
  }

  static bool _isValidDayForRepeatType(DateTime dateTime, String repeatType) {
    if (repeatType == 'Weekday') {
      return dateTime.weekday >= DateTime.monday &&
          dateTime.weekday <= DateTime.friday;
    } else if (repeatType == 'Weekend') {
      return dateTime.weekday == DateTime.saturday ||
          dateTime.weekday == DateTime.sunday;
    }
    return true; // For 'None' and 'Daily', any day is valid
  }

  static Future<void> _scheduleDailyNotification(
      int id,
      String title,
      String notificationMessage,
      DateTime dateTime,
      NotificationDetails platformChannelSpecifics) async {
    // Ensure the scheduledDate is in the future
    final tz.TZDateTime scheduledDate =
        _getFutureDate(tz.TZDateTime.from(dateTime, tz.local));
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      notificationMessage,
      scheduledDate,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleWeekdayNotifications(
      int id,
      String title,
      String notificationMessage,
      DateTime dateTime,
      NotificationDetails platformChannelSpecifics) async {
    // Schedule the first notification if it falls on a weekday
    final tz.TZDateTime firstScheduledDate =
        _getFutureDate(tz.TZDateTime.from(dateTime, tz.local));
    if (firstScheduledDate.weekday >= DateTime.monday &&
        firstScheduledDate.weekday <= DateTime.friday) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        notificationMessage,
        firstScheduledDate,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }

    // Schedule notifications for the next weekdays
    DateTime nextDateTime = dateTime.add(Duration(days: 1));
    int nextId = id + 1;
    for (int i = 1; i < 7; i++) {
      // Skip weekends
      if (nextDateTime.weekday >= DateTime.monday &&
          nextDateTime.weekday <= DateTime.friday) {
        final tz.TZDateTime nextScheduledDate =
            _getFutureDate(tz.TZDateTime.from(nextDateTime, tz.local));
        await flutterLocalNotificationsPlugin.zonedSchedule(
          nextId,
          title,
          notificationMessage,
          nextScheduledDate,
          platformChannelSpecifics,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        nextId++;
      }
      nextDateTime = nextDateTime.add(Duration(days: 1));
    }
  }

  static Future<void> _scheduleWeekendNotifications(
      int id,
      String title,
      String notificationMessage,
      DateTime dateTime,
      NotificationDetails platformChannelSpecifics) async {
    for (int i = 1; i < 7; i++) {
      final nextDateTime = dateTime.add(Duration(days: i));
      if (nextDateTime.weekday == DateTime.saturday ||
          nextDateTime.weekday == DateTime.sunday) {
        final tz.TZDateTime nextScheduledDate =
            _getFutureDate(tz.TZDateTime.from(nextDateTime, tz.local));
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + i,
          title,
          notificationMessage,
          nextScheduledDate,
          platformChannelSpecifics,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Helper function to ensure the date is in the future
  static tz.TZDateTime _getFutureDate(tz.TZDateTime scheduledDate) {
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledDate.isBefore(now)) {
      return scheduledDate.add(Duration(days: 1));
    }
    return scheduledDate;
  }
}
