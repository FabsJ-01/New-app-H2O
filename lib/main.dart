import 'dart:async';
import 'dart:ui';
//import 'dart:io' show Platform;
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

// --- 1. WORKMANAGER CALLBACK (Daily Reminders) ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseDatabase.instance.ref('users/${user.uid}');
        final snapshot = await ref.get();
        if (snapshot.exists) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          
          double intake = double.tryParse(data['intake']?.toString() ?? "0") ?? 0;
          int dailyGoal = int.tryParse(data['daily_goal']?.toString() ?? "2000") ?? 2000; 
          
          final now = DateTime.now();
          
          if (now.hour >= 14 && intake < dailyGoal) {
             int kulang = dailyGoal - intake.toInt();
             await NotificationScheduler.showInstantNotification(
                title: "H2O HUB Reminder 💧",
                body: "Student, you have $kulang ml left to reach your ${dailyGoal}ml goal!",
             );
          }
        }
      }
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('user_uid');

    if (uid != null) {
      DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('users/$uid');
      dbRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          
          bool isScanning = data['is_scanning'] == true;
          bool coinTrigger = data['coin_trigger'] == true;
          int amount = int.tryParse(data['last_credits']?.toString() ?? "0") ?? 0;

          // 1. ORIGINAL CREDIT NOTIFICATION
          if (isScanning && !coinTrigger && amount > 0) {
            NotificationScheduler.showInstantNotification(
              title: "Credits Received! ✅",
              body: "PHP $amount.00 detected. Click DISPENSE in the app.",
            );
          }

          // 2. SMART HYDRATION LOGIC WITH SCHOOL HOURS
          String? lastDrink = data['last_drink_time'];
          double intake = double.tryParse(data['intake']?.toString() ?? "0") ?? 0;
          int dailyGoal = int.tryParse(data['daily_goal']?.toString() ?? "2000") ?? 2000;

          // STOP: Kapag nakuha na ang goal, hinto na ang reminders
          if (intake >= dailyGoal) return;

          // SCHOOL HOURS CHECK: 7 AM to 7 PM (19:00)
          final now = DateTime.now();
          if (now.hour < 7 || now.hour >= 19) {
            return; // Exit if outside school hours
          }

          if (lastDrink != null) {
            DateTime lastTime = DateTime.parse(lastDrink);
            Duration diff = now.difference(lastTime);

            // A. Initial Reminder (1 Hour / 60 Minutes)
            if (diff.inMinutes == 60) {
              NotificationScheduler.showInstantNotification(
                title: "H2O HUB: Time to Hydrate! 💧",
                body: "It's been 1 hour since your last drink. Stay hydrated, Student!",
              );
            } 
            // B. Nagging Follow-up (Every 30 mins after the first hour)
            else if (diff.inMinutes > 60) {
              int extraMinutes = diff.inMinutes - 60;
              if (extraMinutes % 30 == 0) {
                NotificationScheduler.showInstantNotification(
                  title: "H2O HUB: Still thirsty? 🥤",
                  body: "Stay on track with your goal! Don't forget to refill.",
                );
              }
            }
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

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    t.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    
    FirebaseDatabase.instance.setPersistenceEnabled(true);

    await NotificationScheduler.init(); 

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    
    await initializeBackgroundService();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', user.uid);
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, 
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          if (snapshot.hasData) {
            return kIsWeb ? const AdminDashboard() : const Dashboard();
          } else {
            return kIsWeb ? const AdminLoginPage() : const LoginPage();
          }
        },
      ),
    );
  }
}