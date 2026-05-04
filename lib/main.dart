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
import 'package:timezone/data/latest.dart' as t;
import 'package:timezone/timezone.dart' as tz;
import 'notification_scheduler.dart';

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
      // Initialize Firebase inside the task isolate
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseDatabase.instance.ref('users/${user.uid}');
        final snapshot = await ref.get();
        if (snapshot.exists) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          double intake = double.tryParse(data['intake']?.toString() ?? "0") ?? 0;
          final now = DateTime.now();
          
          // pwede ito sa tester sa panel mwah mwah
          if (now.hour >= 14 && intake < 2000) {
             int kulang = 2000 - intake.toInt();
             await NotificationScheduler.showInstantNotification(
                title: "H2O HUB Reminder 💧",
                body: "Student, may $kulang ml ka pa na kailangang inumin today!",
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
  // CRITICAL FIX: Ensure background isolate can use plugins
  DartPluginRegistrant.ensureInitialized();

  // Initialize Firebase for this isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) => service.setAsForegroundService());
    service.on('setAsBackground').listen((event) => service.setAsBackgroundService());
  }

  service.on('stopService').listen((event) => service.stopSelf());

  // Background Logic for Coin/Credits Monitoring
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Kunin ang UID mula sa storage dahil ang Isolate ay walang access sa main Auth state agad
    String? uid = prefs.getString('user_uid');

    if (uid != null) {
      DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('users/$uid');
      dbRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          
          bool isScanning = data['is_scanning'] == true;
          bool coinTrigger = data['coin_trigger'] == true;
          int amount = int.tryParse(data['last_credits']?.toString() ?? "0") ?? 0;

          // Notification Trigger
          if (isScanning && !coinTrigger && amount > 0) {
            NotificationScheduler.showInstantNotification(
              title: "Credits Received! ✅",
              body: "PHP $amount.00 detected. Click DISPENSE in the app.",
            );
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
  
  // Create Notification Channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'h2o_notif_channel',
    'H2O Service',
    description: 'Monitoring vending station...',
    importance: Importance.low,
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

  // 1. Firebase Core Initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    // 2. Timezones
    t.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    
    // 3. Database Persistence (Offline Mode support)
    FirebaseDatabase.instance.setPersistenceEnabled(true);

    // 4. Notifications Initialization
    await NotificationScheduler.init(); 

    // 5. Workmanager Initialization
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    
    // 6. Background Service Initialization
    await initializeBackgroundService();

    // 7. Store UID for Background Isolate use
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