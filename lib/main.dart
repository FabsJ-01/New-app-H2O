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
  return now.hour >= 7 && now.hour < 19; // 7am to 7pm (19:00)
}

double _calculateWorkmanagerDOHGoal(int age, String gender) {
  if (age >= 19 && age <= 59) return (gender == "Male") ? 3000.0 : 2300.0;
  if (age >= 16 && age <= 18) return (gender == "Male") ? 2600.0 : 2200.0;
  if (age >= 13 && age <= 15) return (gender == "Male") ? 2400.0 : 2100.0;
  return 2000.0;
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (!_isWithinActiveHours()) return Future.value(true);

    try {
      await Firebase.initializeApp();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      bool isNotifEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!isNotifEnabled) return Future.value(true);

      final String? uid = prefs.getString('user_uid'); 
      if (uid == null) return Future.value(true);

      final ref = FirebaseDatabase.instance.ref('users/$uid');
      final snapshot = await ref.get();
      
      int nextDelayMinutes = 20; // Default interval

      if (snapshot.exists) {  
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        double intake = double.tryParse(data['intake']?.toString() ?? "0") ?? 0;
        double lastSavedIntake = prefs.getDouble('last_background_intake') ?? 0;
        int userAge = int.tryParse(data['age']?.toString() ?? "19") ?? 19;
        String userGender = data['gender']?.toString() ?? "Male";
        int dailyGoal = _calculateWorkmanagerDOHGoal(userAge, userGender).toInt(); 
        
        // LOGIC: Kung hindi nagbago ang intake, ibig sabihin hindi nag-dispense
        if (intake <= lastSavedIntake) {
          // Hindi nag-dispense: Bilisan ang reminder (30 minutes)
          nextDelayMinutes = 15;
          
          if (intake < dailyGoal) {
            int kulang = dailyGoal - intake.toInt();
            await NotificationScheduler.showInstantNotification(
              title: "H2O HUB Reminder 💧",
              body: "Student, you have $kulang ml left! Dispense now at the nearest campus hub.",
            );
          }
        } else {
          // Nag-dispense: Reset sa 60 minutes
          nextDelayMinutes=20;
          await prefs.setDouble('last_background_intake', intake);
        }
      }

      await Workmanager().registerOneOffTask(
        "h2o_hydration_task", 
        "h2o_hydration_task",
        initialDelay: Duration(minutes: nextDelayMinutes), 
        constraints: Constraints(networkType: NetworkType.connected),
      );
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) => service.setAsForegroundService());
    service.on('setAsBackground').listen((event) => service.setAsBackgroundService());
  }

  service.on('stopService').listen((event) => service.stopSelf());

  try {
    final user = FirebaseAuth.instance.currentUser;
    String? uid = user?.uid;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (uid == null) uid = prefs.getString('user_uid'); 

    if (uid != null) {
      DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('users/$uid');
      dbRef.onValue.listen((event) async {
        if (event.snapshot.value == null) return;
        final userData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        
        // 1. INSTANT GOAL REACHED CHECK
        double intake = double.tryParse(userData['intake']?.toString() ?? "0") ?? 0;
        int age = int.tryParse(userData['age']?.toString() ?? "19") ?? 19;
        String gender = userData['gender']?.toString() ?? "Male";
        int dailyGoal = _calculateWorkmanagerDOHGoal(age, gender).toInt();

        // Mag-check lang kung bago mag 6:00 PM (18:00)
        final now = DateTime.now();
        if (now.hour < 18) { 
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
        }
      }
        // 2. INSTANT CREDITS CHECK
        bool isScanning = userData['is_scanning'] == true;
        int amount = int.tryParse(userData['last_credits']?.toString() ?? "0") ?? 0;
        if (isScanning && amount > 0) {
          await NotificationScheduler.showInstantNotification(
            title: "Credits Received! ✅",
            body: "PHP $amount.00 detected. Click DISPENSE in the app.",
          );
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
    'h2o_notif_channel', 'H2O Service',
    description: 'Monitoring vending station...',
    importance: Importance.max, 
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ilabas natin ito sa 'if (!kIsWeb)' para hindi mag-error kung sakaling mag-restart
  try {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  } catch (e) {
    debugPrint("Persistence already enabled or not supported: $e");
  }

  if (!kIsWeb) {
    if (await Permission.notification.isDenied) await Permission.notification.request();

    t.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    
    await NotificationScheduler.init(); 

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    await Workmanager().cancelAll();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notifications_enabled') ?? true) {
      await Workmanager().registerOneOffTask(
        "h2o_hydration_task", 
        "h2o_hydration_task",
        initialDelay: const Duration(minutes: 16), 
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }
    
    await initializeBackgroundService();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await prefs.setString('user_psu_id', user.email!.split('@')[0]); 
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
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (snapshot.hasData) {
            if (kIsWeb) return const AdminDashboard();
            String uid = snapshot.data!.uid;
            SharedPreferences.getInstance().then((prefs) => prefs.setString('user_uid', uid));
            return FutureBuilder<DataSnapshot>(
              future: FirebaseDatabase.instance.ref().child('users/$uid/status').get(),
              builder: (context, statusSnapshot) {
                if (statusSnapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                if (statusSnapshot.hasData && statusSnapshot.data!.value == 'Password Reset by Admin') {
                  FirebaseAuth.instance.signOut();
                  return const LoginPage();
                }
                return const Dashboard();
              },
            );
          } else return kIsWeb ? const AdminLoginPage() : const LoginPage();
        },
      ),
    );
  }
}