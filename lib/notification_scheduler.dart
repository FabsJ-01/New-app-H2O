import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// FIX: Tinanggal na ang `scheduleDailyReminders()` at `cancelAllReminders()`
// na gumagamit ng `zonedSchedule` + `DateTimeComponents.time`. Ang method
// na iyon ay hindi umuulit "every N minutes" kahit anong comment ang
// nakalagay dati — isang beses lang siya papasok bawat 24 oras, at
// nagdu-duplicate pa siya ng function sa Workmanager loop (main.dart)
// na parehong nagpapadala ng "H2O HUB Reminder" text.
//
// Ang Workmanager loop na lang (startHydrationReminders / 
// stopHydrationReminders sa main.dart) ang SATANGING nagpapadala ng
// periodic hydration reminders ngayon. Ang class na ito ay para na lang
// sa instant, one-off na notifications (credits, thank you, goal reached,
// atbp.) na tinatawag mula sa ibang parte ng app.
class NotificationScheduler {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // --- INITIALIZATION SETTINGS ---
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/launcher_icon.png');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings: settings);
  }

  // --- PARA SA INSTANT UPDATES (Credits, Barya, Thank You, Goal Reached) ---
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

    const notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  // --- Kanselahin ang lahat ng naka-schedule/naka-show na LOCAL
  // notifications (hindi kasama ang Workmanager task — gamitin
  // ang stopHydrationReminders() sa main.dart para doon). ---
  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
    debugPrint("All local notifications have been cleared.");
  }
} 