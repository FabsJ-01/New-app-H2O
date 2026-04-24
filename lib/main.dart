import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as t;
import 'package:flutter/foundation.dart' show kIsWeb;

// Import your files
import 'login_page.dart';        
import 'dashboard.dart';         
import 'admin_login.dart';       
import 'admin_dashboard.dart';   
import 'firebase_options.dart';

// Import Platform safely
import 'dart:io' show Platform;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase connected successfully!");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  // 2. Mobile-Only Setup (Android & iOS)
  if (!kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    t.initializeTimeZones();

    // Android Notification Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // NEW: iOS (Darwin) Notification Settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combine settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS, // Isama ang iOS settings dito
    );

    await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint("Notification Clicked!");
    },
  );

    // Request Permissions based on platform
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      // NEW: iOS specific permission request
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  runApp(const H2OApp());
}

class H2OApp extends StatelessWidget {
  const H2OApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'H2O Smart Vending',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Inalis ko ang useMaterial3: false para mas maging modern ang itsura sa iOS
        useMaterial3: true, 
      ),
      
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            // Naka-login: Check if Web (Admin) or Mobile (User)
            return kIsWeb ? const AdminDashboard() : const Dashboard();
          } else {
            // Hindi naka-login
            return kIsWeb ? const AdminLoginPage() : const LoginPage();
          }
        },
      ),
    );
  }
}