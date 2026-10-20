import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

// Firebase & Storage
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Notifications & Background Tasks
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as t;
import 'notification_scheduler.dart';
import 'package:permission_handler/permission_handler.dart';

// Pages
import 'login_page.dart';
import 'dashboard.dart';
import 'admin_login.dart';
import 'admin_dashboard.dart';

// --- SHARED CONSTANTS: gamitin ito lahat ng file na kailangan mag-refer
// sa parehong Workmanager task (main.dart at dashboard.dart) ---
const String kHydrationTaskName = "h2o_hydration_task";

// FIX: bagong flag sa SharedPreferences para malaman kung may naka-schedule
// na talaga tayong reminder task. Ito ang gagamitin para hindi na basta
// mag-reset (initialDelay: zero) ang schedule tuwing binubuksan lang ang
// app — dating dahilan kung bakit paulit-ulit na lumalabas ang "H2O HUB
// Reminder" sa bawat pag-swipe/pagbukas ng app.
const String kHydrationScheduledFlagKey = "hydration_reminders_scheduled";

// --- 1. HELPER: Time Restriction ---
bool _isWithinActiveHours() {
  final now = DateTime.now();
  return now.hour >= 7 && now.hour < 19;
}

int _minutesUntilActiveHours() {
  final now = DateTime.now();
  if (now.hour < 7) {
    return DateTime(now.year, now.month, now.day, 7, 0, 0)
        .difference(now)
        .inMinutes
        .clamp(1, 24 * 60);
  }
  final tomorrow7am = DateTime(now.year, now.month, now.day + 1, 7, 0, 0);
  return tomorrow7am.difference(now).inMinutes.clamp(1, 24 * 60);
}

double _calculateWorkmanagerDOHGoal(int age, String gender) {
  bool isMale = gender == "Male";
  if (age >= 18) return isMale ? 2900.0 : 2200.0;
  if (age >= 16) return isMale ? 2600.0 : 2000.0;
  if (age >= 13) return isMale ? 2400.0 : 2000.0;
  return 1500.0;
}

// --- WORKMANAGER CALLBACK ---
// FIX: ngayon, ISANG lugar lang (sa dulo, sa `finally`-style na daan) ang
// nagre-reschedule ng susunod na task. Hindi na ito namamatay kahit:
//  - disabled ang notifications habang naka-schedule na (edge case)
//  - labas sa active hours
//  - nag-error sa Firebase fetch
// --- WORKMANAGER CALLBACK ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    int nextDelayMinutes = 30; // Default fallback kapag paulit-ulit na ang reminder

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isNotifEnabled = prefs.getBool('notifications_enabled') ?? true;

      if (!isNotifEnabled) {
        await prefs.setBool(kHydrationScheduledFlagKey, false);
        return Future.value(true);
      }

      if (!_isWithinActiveHours()) {
        nextDelayMinutes = _minutesUntilActiveHours();
      } else {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform);
        }

        final String? uid = prefs.getString('user_uid');
        if (uid != null) {
          final ref = FirebaseDatabase.instance.ref('users/$uid');
          final snapshot = await ref.get();

          if (snapshot.exists) {
            final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
            double intake = double.tryParse(data['intake']?.toString() ?? "0") ?? 0;
            int userAge = int.tryParse(data['age']?.toString() ?? "19") ?? 19;
            String userGender = data['gender']?.toString() ?? "Male";
            int dailyGoal = _calculateWorkmanagerDOHGoal(userAge, userGender).toInt();

            // 1. Check kung naabot na ang Goal
            if (intake >= dailyGoal) {
              String todayKey = 'congrats_sent_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
              bool hasCongratulated = prefs.getBool(todayKey) ?? false;
              if (!hasCongratulated) {
                await NotificationScheduler.showInstantNotification(
                  title: "Goal Reached! 🎉",
                  body: "Congratulations! You have reached your hydration goal for today.",
                );
                await prefs.setBool(todayKey, true);
              }
            } else {
              // 2. Basahin ang huling ininom o log mula sa Firebase (`last_drink_time`)
              String lastDrinkStr = data['last_drink_time']?.toString() ?? "";
              DateTime? lastDrinkTime = DateTime.tryParse(lastDrinkStr);

              // Kung may huling inom, tingnan natin kung wala pang 1 hour (60 minutes) ang nakakalipas
              if (lastDrinkTime != null) {
                final differenceMinutes = DateTime.now().difference(lastDrinkTime).inMinutes;
                
                if (differenceMinutes < 60) {
                  // Kung wala pang 1 hour mula nang huling uminom/mag-log, i-reschedule natin ang susunod na check 
                  // para eksaktong matapos ang 1 hour na window!
                  nextDelayMinutes = (60 - differenceMinutes).clamp(1, 60);
                  debugPrint("Workmanager: Bago pa ang huling inom ($differenceMinutes mins ago). Rescheduling in $nextDelayMinutes mins.");
                  
                  await Workmanager().registerOneOffTask(
                    kHydrationTaskName,
                    kHydrationTaskName,
                    initialDelay: Duration(minutes: nextDelayMinutes),
                    constraints: Constraints(networkType: NetworkType.connected),
                    existingWorkPolicy: ExistingWorkPolicy.replace,
                  );
                  return Future.value(true);
                }
              }

              // Kung lumagpas na ng 60 minutes mula sa huling inom/log (o walang nakitang last_drink_time), 
              // magpapadala na tayo ng reminder at gagawin na itong 30 mins para sa susunod.
              int kulang = dailyGoal - intake.toInt();
              int streak = (prefs.getInt('reminder_streak_count') ?? 0) + 1;
              await prefs.setInt('reminder_streak_count', streak);

              final List<String> reminderMessages = [
                "Student, you have $kulang ml left! Dispense now at the nearest H2O hub.",
                "Hey, you haven't dispensed yet! You still need ${kulang}ml to reach today's goal.",
                "Reminder: you're still ${kulang}ml short. Hydrate now before you get dehydrated!",
                "You might have forgotten — you still need to drink ${kulang}ml today. Do it now!",
              ];

              int messageIndex = (streak - 1).clamp(0, reminderMessages.length - 1);
              await NotificationScheduler.showInstantNotification(
                title: "H2O HUB Reminder 💧",
                body: reminderMessages[messageIndex],
              );

              // Pagkalipas ng unang reminder, 30 minutes na ang susunod na agwat kung hindi pa rin nag-didispense
              nextDelayMinutes = 30;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Workmanager Error: $e");
    }

    await Workmanager().registerOneOffTask(
      kHydrationTaskName,
      kHydrationTaskName,
      initialDelay: Duration(minutes: nextDelayMinutes),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    debugPrint("Workmanager: Rescheduled in $nextDelayMinutes minutes.");
    return Future.value(true);
  });
}
  // --- 2. BACKGROUND SERVICE (Real-time Monitoring) ---
  @pragma('vm:entry-point')
  void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen(
          (event) => service.setAsForegroundService());
      service.on('setAsBackground').listen(
          (event) => service.setAsBackgroundService());
    }

    service.on('stopService').listen((event) => service.stopSelf());

    try {
      final ref = FirebaseDatabase.instance.ref();
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('user_uid');

      if (uid != null) {
        ref.child('users/$uid').onValue.listen((event) async {
          if (event.snapshot.value == null) return;
          final userData =
              Map<dynamic, dynamic>.from(event.snapshot.value as Map);

          await prefs.reload();

          // ============================================
          // 1. CREDITS RECEIVED NOTIFICATION
          // ============================================
          bool isScanning = userData['is_scanning'] == true;
          int amount =
              int.tryParse(userData['last_credits']?.toString() ?? "0") ?? 0;

          final lastNotifiedAmount =
              prefs.getInt('last_notified_credit_amount') ?? -1;
          final lastNotifiedScanState =
              prefs.getBool('last_notified_scan_state') ?? false;

          bool isNewCreditEvent = isScanning &&
              amount > 0 &&
              (amount != lastNotifiedAmount || !lastNotifiedScanState);

          if (isNewCreditEvent) {
            await NotificationScheduler.showInstantNotification(
              title: "Credits Received! ✅",
              body: "PHP $amount.00 detected. Click DISPENSE in the app.",
            );
            await prefs.setInt('last_notified_credit_amount', amount);
            await prefs.setBool('last_notified_scan_state', true);
          }

          if (!isScanning) {
            await prefs.setBool('last_notified_scan_state', false);
          }

        // ============================================
        // 2. THANK YOU NOTIFICATION — BACKGROUND SERVICE
        // Lalabas AFTER mag-dispense — hindi kapag binuksan lang ang app!
        // ============================================
        bool isNotifEnabled = prefs.getBool('notifications_enabled') ?? true;

        if (isNotifEnabled) {
          double currentIntake =
              double.tryParse(userData['intake']?.toString() ?? "0") ?? 0.0;
          double lastSavedIntake =
              prefs.getDouble('last_bg_intake_thankyou') ?? -1.0;

          if (lastSavedIntake == -1.0) {
            await prefs.setDouble('last_bg_intake_thankyou', currentIntake);
            debugPrint(
                "Background: First load — saving intake: $currentIntake ml. No notification.");
          } else if (currentIntake > lastSavedIntake) {
            double dispensedNow = currentIntake - lastSavedIntake;

            int lastThankYouTime =
                prefs.getInt('last_thankyou_timestamp') ?? 0;
            int nowMs = DateTime.now().millisecondsSinceEpoch;
            bool cooldownPassed = (nowMs - lastThankYouTime) > 30000;

            if (cooldownPassed && dispensedNow >= 50) {
              await NotificationScheduler.showInstantNotification(
                title: "H2O Success! ✨",
                body:
                    "Thank you for using PSU H2O! +${dispensedNow.toInt()}ml added. Stay Hydrated! 💧",
              );

              await prefs.setInt('last_thankyou_timestamp', nowMs);
              await prefs.setDouble('last_bg_intake_thankyou', currentIntake);

              debugPrint(
                  "Background: Thank You sent! +${dispensedNow.toInt()}ml");
            } else {
              await prefs.setDouble('last_bg_intake_thankyou', currentIntake);
            }
          }

          if (currentIntake == 0 && lastSavedIntake > 0) {
            await prefs.setDouble('last_bg_intake_thankyou', -1.0);
            debugPrint(
                "Background: Daily reset detected. Resetting saved intake.");
          }
        }
      });
    }
  } catch (e) {
    debugPrint("Background Service Error: $e");
  }
}

// --- 3. BACKGROUND SERVICE CONFIGURATION ---
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'h2o_notif_channel',
    'H2O Service',
    description: 'Monitoring vending station...',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'h2o_notif_channel',
      initialNotificationTitle: 'H2O Hub Active',
      initialNotificationContent: 'Monitoring vending station...',
      foregroundServiceTypes: [AndroidForegroundType.specialUse],
    ),
    iosConfiguration: IosConfiguration(),
  );
}

// --- 4. PUBLIC HELPERS: gamitin ito sa dashboard.dart toggle ---
// FIX: ito ang gagamitin kapag EXPLICIT na aksyon ng user ang nagpapatakbo
// nito (i.e. i-tap ang toggle papuntang ON). Sadyang agad itong tatakbo
// (initialDelay: zero) dahil malinaw na intensyon ng user na simulan ito
// NGAYON DIN. Hindi ito dapat tawagin sa tuwing bubukas lang ang app —
// gamitin sa halip ang ensureHydrationRemindersRunning() sa ibaba.
Future<void> startHydrationReminders() async {
  await Workmanager().registerOneOffTask(
    kHydrationTaskName,
    kHydrationTaskName,
    initialDelay: Duration.zero,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kHydrationScheduledFlagKey, true);
  debugPrint("Workmanager: Hydration reminders started (immediate).");
}

Future<void> stopHydrationReminders() async {
  await Workmanager().cancelByUniqueName(kHydrationTaskName);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kHydrationScheduledFlagKey, false);
  debugPrint("Workmanager: Hydration reminders stopped.");
}

// FIX: BAGONG function — ito ang gagamitin sa dashboard.dart
// `_loadOfflineData()` (ibig sabihin, sa TUWING binubuksan ang app).
// Kaibahan sa startHydrationReminders(): hindi nito basta ini-reset ang
// schedule papuntang "tumakbo agad" kung meron nang tumatakbo — titignan
// muna nito ang naka-save na flag. Kung meron nang naka-schedule,
// hahayaan na lang itong tumakbo sa dati niyang oras — hindi na
// mag-re-register ng bago. Ito ang solusyon sa dating bug kung saan
// paulit-ulit lumalabas ang "H2O HUB Reminder" sa BAWAT pagbukas/swipe
// ng app.
Future<void> ensureHydrationRemindersRunning() async {
  final prefs = await SharedPreferences.getInstance();
  bool alreadyScheduled =
      prefs.getBool(kHydrationScheduledFlagKey) ?? false;

  if (alreadyScheduled) {
    debugPrint(
        "Workmanager: Reminders already scheduled — hindi na re-restart.");
    return;
  }

  // Wala pang naka-schedule (bagong install, o kasunod ng disable→enable
  // na hindi dumaan sa toggle) — dito lang tayo talaga magsi-simula.
  await startHydrationReminders();
}

// --- 5. MAIN ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  try {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  } catch (_) {}

  if (!kIsWeb) {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    t.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    await NotificationScheduler.init();

    await Workmanager()
        .initialize(callbackDispatcher, isInDebugMode: kDebugMode);

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // FIX: gamitin ang ensureHydrationRemindersRunning() dito imbes na
    // startHydrationReminders() — kung may buhay na task pa mula sa
    // nakaraang session (hal. app restart lang, hindi fresh install),
    // hindi na natin ito i-re-reset papuntang "tumakbo agad."
    if (prefs.getBool('notifications_enabled') ?? true) {
      await ensureHydrationRemindersRunning();
    }

    await initializeBackgroundService();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await prefs.setString('user_psu_id', user.email!.split('@')[0]);
    }
  }

  runApp(const H2OApp());
}

// --- 6. APP ROOT WIDGET ---
class H2OApp extends StatelessWidget {
  const H2OApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'H2O Smart Vending',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            if (kIsWeb) return const AdminDashboard();
            String uid = snapshot.data!.uid;
            SharedPreferences.getInstance()
                .then((prefs) => prefs.setString('user_uid', uid));
            return FutureBuilder<DataSnapshot>(
              future: FirebaseDatabase.instance
                  .ref()
                  .child('users/$uid/status')
                  .get(),
              builder: (context, statusSnapshot) {
                if (statusSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }
                if (statusSnapshot.hasData &&
                    statusSnapshot.data!.value == 'Password Reset by Admin') {
                  FirebaseAuth.instance.signOut();
                  return const LoginPage();
                }
                return const Dashboard();
              },
            );
          } else {
            return kIsWeb ? const AdminLoginPage() : const LoginPage();
          }
        },
      ),
    );
  }
}