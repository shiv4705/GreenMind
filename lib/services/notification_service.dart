import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  static Future<void> requestIOSPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> showImmediateNotification(String plantName) async {
    const androidDetails = AndroidNotificationDetails(
      'immediate_channel',
      'Immediate Reminders',
      channelDescription: 'Notification shown immediately after adding a plant',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'Plant Added 🌱',
      'Don\'t forget to water $plantName!',
      notificationDetails,
    );
  }

  static Future<void> scheduleRecurringReminder({
    required String plantName,
    required String frequency,
  }) async {
    int intervalDays;
    switch (frequency) {
      case 'Once a Week':
        intervalDays = 7;
        break;
      case 'Twice a Week':
        intervalDays = 3;
        break;
      case 'Every Other Day':
        intervalDays = 2;
        break;
      case 'Everyday':
        intervalDays = 1;
        break;
      default:
        intervalDays = 7;
    }

    final now = tz.TZDateTime.now(tz.local);
    final firstTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    ).add(Duration(days: intervalDays));

    const androidDetails = AndroidNotificationDetails(
      'recurring_channel',
      'Recurring Watering Reminders',
      channelDescription: 'Recurring reminder to water your plant',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      plantName.hashCode,
      'Water Reminder 🌿',
      'Time to water your $plantName!',
      firstTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
