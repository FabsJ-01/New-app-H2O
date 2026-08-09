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

// --- 1. HELPER: Time Restriction ---
bool _isWithinActiveHours() {
  final now = DateTime.now();
  return now.hour >= 7 && now.hour < 19;
}

double _calculateWorkmanagerDOHGoal(int age, String gender) {
  bool isMale = gender == "Male";
  if (age >= 18) return isMale ? 2900.0 : 2200.0;
  if (age >= 16) return isMale ? 2600.0 : 2000.0;
  if (age >= 13) return isMale ? 2400.0 : 2000.0;
  return 1500.0;
}

// --- WORKMANAGER CALLBACK ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (!_isWithinActiveHours()) {
      debugPrint("Workmanager: Outside active hours, skipping task.");
      return Future.value(true);
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      bool isNotifEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      if (!isNotifEnabled) return Future.value(true);

      final String? uid = prefs.getString('user_uid');
      if (uid == null) {
        debugPrint("Workmanager: No UID found.");
        return Future.value(true);
      }

      final ref = FirebaseDatabase.instance.ref('users/$uid');
      final snapshot = await ref.get();

      int nextDelayMinutes = 17;

      if (snapshot.exists) {
        final data =
            Map<dynamic, dynamic>.from(snapshot.value as Map);
        double intake =
            double.tryParse(data['intake']?.toString() ?? "0") ??
                0;
        double lastSavedIntake =
            prefs.getDouble('last_background_intake') ?? 0;
        int userAge =
            int.tryParse(data['age']?.toString() ?? "19") ?? 19;
        String userGender =
            data['gender']?.toString() ?? "Male";
        int dailyGoal =
            _calculateWorkmanagerDOHGoal(userAge, userGender)
                .toInt();

        // GOAL REACHED
        if (intake >= dailyGoal) {
          String todayKey =
              'congrats_sent_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
          bool hasCongratulated =
              prefs.getBool(todayKey) ?? false;
          if (!hasCongratulated) {
            await NotificationScheduler.showInstantNotification(
              title: "Goal Reached! 🎉",
              body:
                  "Congratulations! You have reached your hydration goal for today.",
            );
            await prefs.setBool(todayKey, true);
          }
        }

        if (intake <= lastSavedIntake) {
          nextDelayMinutes = 30;
          if (intake < dailyGoal) {
            int kulang = dailyGoal - intake.toInt();
            debugPrint(
                "Workmanager: Sending reminder, kulang: $kulang");
            await NotificationScheduler.showInstantNotification(
              title: "H2O HUB Reminder 💧",
              body:
                  "Student, you have $kulang ml left! Dispense now at the nearest H2O hub.",
            );
          }
        } else {
          nextDelayMinutes = 60;
          debugPrint(
              "Workmanager: Intake increased, resetting interval to 60 mins.");
          await prefs.setDouble('last_background_intake', intake);
        }
      }

      await Workmanager().registerOneOffTask(
        "h2o_hydration_task",
        "h2o_hydration_task",
        initialDelay: Duration(minutes: nextDelayMinutes),
        constraints:
            Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      debugPrint(
          "Workmanager: Task scheduled in $nextDelayMinutes minutes.");
    } catch (e) {
      debugPrint("Workmanager Error: $e");
    }
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
        final userData = Map<dynamic, dynamic>.from(
            event.snapshot.value as Map);

        await prefs.reload();

        // ============================================
        // 1. CREDITS RECEIVED NOTIFICATION
        // ============================================
        bool isScanning = userData['is_scanning'] == true;
        int amount = int.tryParse(
                userData['last_credits']?.toString() ?? "0") ??
            0;

        final lastNotifiedAmount =
            prefs.getInt('last_notified_credit_amount') ?? -1;
        final lastNotifiedScanState =
            prefs.getBool('last_notified_scan_state') ?? false;

        bool isNewCreditEvent = isScanning &&
            amount > 0 &&
            (amount != lastNotifiedAmount ||
                !lastNotifiedScanState);

        if (isNewCreditEvent) {
          await NotificationScheduler.showInstantNotification(
            title: "Credits Received! ✅",
            body:
                "PHP $amount.00 detected. Click DISPENSE in the app.",
          );
          await prefs.setInt(
              'last_notified_credit_amount', amount);
          await prefs.setBool('last_notified_scan_state', true);
        }

        if (!isScanning) {
          await prefs.setBool(
              'last_notified_scan_state', false);
        }

        // ============================================
        // 2. THANK YOU NOTIFICATION — BACKGROUND SERVICE
        // FIX: Lalabas AFTER mag-dispense —
        // hindi kapag binuksan lang ang app!
        // ============================================
        bool isNotifEnabled =
            prefs.getBool('notifications_enabled') ?? true;

        if (isNotifEnabled) {
          double currentIntake = double.tryParse(
                  userData['intake']?.toString() ?? "0") ??
              0.0;
          double lastSavedIntake =
              prefs.getDouble('last_bg_intake_thankyou') ?? -1.0;

          // FIX: -1.0 ang default — ibig sabihin first load pa
          // Hindi mag-trigger kapag first load
          if (lastSavedIntake == -1.0) {
            // First time — i-save lang ang current intake
            // pero HINDI mag-send ng notification
            await prefs.setDouble(
                'last_bg_intake_thankyou', currentIntake);
            debugPrint(
                "Background: First load — saving intake: $currentIntake ml. No notification.");
          } else if (currentIntake > lastSavedIntake) {
            // Nag-increase ang intake — ibig sabihin nag-dispense!
            double dispensedNow = currentIntake - lastSavedIntake;

            // Anti-spam — 30 seconds cooldown
            int lastThankYouTime =
                prefs.getInt('last_thankyou_timestamp') ?? 0;
            int nowMs = DateTime.now().millisecondsSinceEpoch;
            bool cooldownPassed =
                (nowMs - lastThankYouTime) > 30000;

            // Minimum 50ml para mag-trigger
            if (cooldownPassed && dispensedNow >= 50) {
              await NotificationScheduler.showInstantNotification(
                title: "H2O Success! ✨",
                body:
                    "Thank you for using PSU H2O! +${dispensedNow.toInt()}ml added. Stay Hydrated! 💧",
              );

              await prefs.setInt(
                  'last_thankyou_timestamp', nowMs);
              await prefs.setDouble(
                  'last_bg_intake_thankyou', currentIntake);

              debugPrint(
                  "Background: Thank You sent! +${dispensedNow.toInt()}ml");
            } else {
              // I-update lang ang saved intake
              await prefs.setDouble(
                  'last_bg_intake_thankyou', currentIntake);
            }
          }

          // FIX: I-reset kapag nag-reset ang daily intake (bagong araw)
          if (currentIntake == 0 && lastSavedIntake > 0) {
            await prefs.setDouble(
                'last_bg_intake_thankyou', -1.0);
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
  const AndroidNotificationChannel channel =
      AndroidNotificationChannel(
    'h2o_notif_channel',
    'H2O Service',
    description: 'Monitoring vending station...',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin
      flutterLocalNotificationsPlugin =
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

// --- 4. MAIN ENTRY POINT ---
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

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    if (prefs.getBool('notifications_enabled') ?? true) {
      await Workmanager().registerOneOffTask(
        "h2o_hydration_task",
        "h2o_hydration_task",
        initialDelay: Duration.zero,
        constraints:
            Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    }

    await initializeBackgroundService();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await prefs.setString(
          'user_psu_id', user.email!.split('@')[0]);
    }
  }

  runApp(const H2OApp());
}

// --- 5. APP ROOT WIDGET ---
class H2OApp extends StatelessWidget {
  const H2OApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'H2O Smart Vending',
      theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body:
                    Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            if (kIsWeb) return const AdminDashboard();
            String uid = snapshot.data!.uid;
            SharedPreferences.getInstance().then(
                (prefs) => prefs.setString('user_uid', uid));
            return FutureBuilder<DataSnapshot>(
              future: FirebaseDatabase.instance
                  .ref()
                  .child('users/$uid/status')
                  .get(),
              builder: (context, statusSnapshot) {
                if (statusSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(
                          child: CircularProgressIndicator()));
                }
                if (statusSnapshot.hasData &&
                    statusSnapshot.data!.value ==
                        'Password Reset by Admin') {
                  FirebaseAuth.instance.signOut();
                  return const LoginPage();
                }
                return const Dashboard();
              },
            );
          } else {
            return kIsWeb
                ? const AdminLoginPage()
                : const LoginPage();
          }
        },
      ),
    );
  }
}