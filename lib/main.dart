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

// --- 1. WORKMANAGER CALLBACK ---
double _calculateWorkmanagerDOHGoal(int age, String gender) {
  if (age >= 19 && age <= 59) return (gender == "Male") ? 3000.0 : 2300.0;
  if (age >= 16 && age <= 18) return (gender == "Male") ? 2600.0 : 2200.0;
  if (age >= 13 && age <= 15) return (gender == "Male") ? 2400.0 : 2100.0;
  return 2000.0;
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // 🔥 SOLID GUARD 1: Para sa dynamic OneOffTask loop
      bool isNotifEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!isNotifEnabled) {
        debugPrint("Workmanager skipped: Notifications are disabled by user.");
        return Future.value(true);
      }

      final String? uid = prefs.getString('user_uid'); 

      if (uid == null) {
        debugPrint("Workmanager skipped: No saved user_uid found in SharedPreferences.");
        return Future.value(true);
      }

      final ref = FirebaseDatabase.instance.ref('users/$uid');
      final snapshot = await ref.get();
      
      int nextDelayMinutes = 60; 

      if (snapshot.exists) {  
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        
        double intake = double.tryParse(data['intake']?.toString() ?? "0") ?? 0;
        double lastSavedIntake = prefs.getDouble('last_background_intake') ?? 0;
        
        int userAge = int.tryParse(data['age']?.toString() ?? "19") ?? 19;
        String userGender = data['gender']?.toString() ?? "Male";
        
        int dailyGoal = _calculateWorkmanagerDOHGoal(userAge, userGender).toInt(); 

        if (intake <= lastSavedIntake) {  
          if (intake < dailyGoal) {
            int kulang = dailyGoal - intake.toInt();
            await NotificationScheduler.showInstantNotification(
              title: "H2O HUB Reminder 💧",
              body: "Student, you have $kulang ml left to reach your ${dailyGoal}ml goal! Dispense now at the nearest campus hub.",
            );
          }
          nextDelayMinutes = 30; 
        } else {
          await prefs.setDouble('last_background_intake', intake); 
          nextDelayMinutes = 60; 
        }
      }

      await Workmanager().registerOneOffTask(
        "h2o_dynamic_task_${DateTime.now().millisecondsSinceEpoch}", 
        "h2o_hydration_task",
        initialDelay: Duration(minutes: nextDelayMinutes), 
        constraints: Constraints(
          networkType: NetworkType.connected, 
        ),
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
    if (uid == null) {
      uid = prefs.getString('user_uid'); 
    }

    if (uid != null) {
      DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('users/$uid');

      dbRef.onValue.listen((event) async {
        // 🔥 SOLID GUARD 2: Bago mag-trigger ang popup ng barya, i-reload at tingnan muna kung naka-ON ang switch
        await prefs.reload();
        bool isNotifEnabled = prefs.getBool('notifications_enabled') ?? true;
        if (!isNotifEnabled) return; // 🛑 Kapag naka-OFF ang switch, block agad ang alert.

        if (event.snapshot.value != null) {
          final userData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          
          bool isScanning = userData['is_scanning'] == true;
          bool coinTrigger = userData['coin_trigger'] == true;
          int amount = int.tryParse(userData['last_credits']?.toString() ?? "0") ?? 0;

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
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isNotifEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (isNotifEnabled) {
      await Workmanager().registerPeriodicTask(
        "h2o_hydration_periodic_id", 
        "h2o_periodic_task",          
        frequency: const Duration(hours: 1), 
        initialDelay: const Duration(minutes: 2), 
        constraints: Constraints(
          networkType: NetworkType.connected, 
        ),
      );
    } else {
      // Kung naka-OFF na nung huling sara ng app, siguraduhing burado ang nakasalang na task
      await Workmanager().cancelAll();
    }
    
    await initializeBackgroundService();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      String psuId = user.email!.split('@')[0];
      await prefs.setString('user_psu_id', psuId); 
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
            if (kIsWeb) return const AdminDashboard();

            String uid = snapshot.data!.uid;
            
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('user_uid', uid); 
            });
            
            return FutureBuilder<DataSnapshot>(
              future: FirebaseDatabase.instance.ref().child('users/$uid/status').get(),
              builder: (context, statusSnapshot) {
                if (statusSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                
                if (statusSnapshot.hasData && statusSnapshot.data!.value == 'Password Reset by Admin') {
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