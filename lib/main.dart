import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importante ito para sa StreamBuilder
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as t;
import 'login_page.dart';
import 'dashboard.dart'; // Naka-uncomment na ito para gumana ang auto-login
import 'dart:io';
// Global instance para matawag natin ang notifications kahit saan
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp();
  
  // 2. Enable Offline Persistence para sa Database
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  
  // 3. Initialize Timezones
  t.initializeTimeZones();

  // 4. Notification Settings for Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint("Notification Clicked!");
    },
  );  
  if (Platform.isAndroid) {
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
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
      theme: ThemeData(primarySwatch: Colors.blue),
      // DITO ANG MAGIC: StreamBuilder ang magbabantay kung logged in ang user
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Habang chine-check pa ng Firebase ang login session
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Kung may "data" (User) sa snapshot, diretso sa Dashboard
          if (snapshot.hasData) {
            return const Dashboard();
          }
          
          // Kung walang user, balik sa LoginPage
          return const LoginPage();
        },
      ),
    );
  }
}