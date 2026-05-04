import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationScheduler {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    
    // Tama ito: 'initializationSettings' o 'settings' depende sa version, 
    // pero base sa error mo kanina, ito ang hinihingi.
    await _notifications.initialize(settings: settings); 
  }

  // --- PARA SA INSTANT UPDATES (Credits & Barya) ---
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'h2o_notif_channel', // BINAGO: Dapat match sa main.dart
      'H2O Service Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: DateTime.now().millisecond, 
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  // --- SCHEDULED REMINDER (Daily Goal) ---
  static Future<void> scheduleDailyReminders() async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      // Gawin nating 14:00 (2 PM) para match sa logic ng main.dart
      tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 14, 0);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        id: 101, 
        title: 'H2O HUB Reminder 💧',
        body: 'Oras na para uminom! Wag kalimutan ang iyong daily goal.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'h2o_notif_channel', // BINAGO: Consistent channel para sa lahat
            'H2O Notifications',
            channelDescription: 'Reminders for student hydration',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint("Status: Scheduled successfully for 2:00 PM!");
    } catch (e) {
      debugPrint("Error sa Scheduler: $e");
    }
  }
}