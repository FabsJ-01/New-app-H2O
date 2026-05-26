import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
  
class NotificationScheduler {
    static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

    static const int _dailyGoalNotifId = 101;

    // --- INITIALIZATION SETTINGS ---
    static Future<void> init() async {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);    
      await _notifications.initialize(settings: settings); 
    }

    // --- PARA SA INSTANT UPDATES (Credits & Barya) ---
    static Future<void> showInstantNotification({
      required String title,
      required String body,
    }) async {
      const androidDetails = AndroidNotificationDetails(
        'h2o_notif_channel', 
        'H2O Service Alerts',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        id: DateTime.now().millisecond % 100000, 
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    }

    // --- SCHEDULED REMINDER (TEST MODE: Every 2 Minutes / 7:00 AM - 7:00 PM School Time Only) ---
    static Future<void> scheduleDailyReminders() async {
    try {
      await _notifications.cancel(id: _dailyGoalNotifId);

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime targetScheduledTime = now.add(const Duration(minutes: 2));

      if (targetScheduledTime.hour < 7) {
        targetScheduledTime = tz.TZDateTime(
          tz.local, 
          targetScheduledTime.year, 
          targetScheduledTime.month, 
          targetScheduledTime.day, 
          7, 0, 0,
        );
      } else if (targetScheduledTime.hour >= 19) {
        targetScheduledTime = tz.TZDateTime(
          tz.local, 
          targetScheduledTime.year, 
          targetScheduledTime.month, 
          targetScheduledTime.day + 1, 
          7, 0, 0,
        );
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'h2o_local_reminder_channel',
        'H2O Offline Reminders',
        channelDescription: 'Periodic local hydration alerts for students',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.zonedSchedule(
        id: _dailyGoalNotifId,                      
        title: "H2O HUB Reminder 💧",                  
        body: "Don't forget to check your hydration level at the nearest vending hub!", 
        scheduledDate: targetScheduledTime,                    
        notificationDetails: platformDetails,                        
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
        matchDateTimeComponents: DateTimeComponents.time, 
      );

      debugPrint("Local Notification Looping successfully scheduled at: $targetScheduledTime");
    } catch (e) {
      debugPrint("Error scheduling local reminders: $e");
    }
  }

  // 🔥 SAKTONG LAPAG: Dito mo siya ilalagay pre sa ilalim ng schedule function!
  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
    debugPrint("All scheduled local notifications have been cleared.");
  }
  
} // <--- Ito ang pinakahuling bracket ng buong file mo