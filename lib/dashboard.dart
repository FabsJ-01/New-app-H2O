import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart'; 
import 'package:qr_flutter/qr_flutter.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'main.dart'; 
import 'profile_page.dart';
//import 'dart:io' show Platform; 

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  double intakeDisplay = 0;
  double dailyGoal = 2000; 
  String gender = "Male";
  int age = 19;
  bool _isMachineReady = false; 
  String? localUid;
  bool _reminderSentToday = false; 

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://h2o-project-e83d9-default-rtdb.firebaseio.com',
  ).ref();

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
    _activateListeners();
  }

  // --- FIX: UPDATED NOTIFICATION LOGIC ---
  Future<void> _sendNotification(String title, String body) async {
    // 1. Android Specifics
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'h2o_hydration_channel',
      'Hydration Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    // 2. Darwin (iOS/macOS) Specifics
    const DarwinNotificationDetails darwinPlatformChannelSpecifics = 
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // 3. Combined Notification Details
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics, // Subukan mo 'iOS' muna, kung ayaw, palitan mo ng 'darwin'
    );

    // 4. THE FIX: Explicitly name the notificationDetails parameter
    // BURAHIN MO YUNG LUMANG .show() AT IPALIT ITO:
    await flutterLocalNotificationsPlugin.show(
      id: 0,                                 // Dapat may 'id:'
      title: title,                          // Dapat may 'title:'
      body: body,                            // Dapat may 'body:'
      notificationDetails: platformChannelSpecifics, 
    );
  }

  Future<void> _loadOfflineData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      intakeDisplay = prefs.getDouble('last_intake') ?? 0.0;
      localUid = prefs.getString('user_uid') ?? FirebaseAuth.instance.currentUser?.uid;
      age = prefs.getInt('last_age') ?? 19;
      gender = prefs.getString('last_gender') ?? "Male";
      dailyGoal = calculateDOHGoal(age, gender);
    });
  }

  void _showQRDialog() {
    final displayUid = FirebaseAuth.instance.currentUser?.uid ?? localUid;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scan to Start", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: displayUid ?? "No UID Saved",
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 10),
            const Text("Itapat ang QR sa scanner ng machine", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  void _triggerWaterDispense() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? localUid;
    if (currentUid != null) {
      await _dbRef.child('users/$currentUid').update({'coin_trigger': true});
      _sendNotification("Vending Started! 💧", "Nagsisimula na ang pag-dispense. Pakihanda ang bote!");
    }
  }

  double calculateDOHGoal(int age, String gender) {
    if (age >= 19 && age <= 59) return (gender == "Male") ? 3000.0 : 2300.0;
    if (age >= 16 && age <= 18) return (gender == "Male") ? 2600.0 : 2200.0;
    if (age >= 13 && age <= 15) return (gender == "Male") ? 2400.0 : 2100.0;
    return 2000.0; 
  }

  void _checkAndResetDailyIntake(String uid, Map data) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String lastUpdate = data['last_update']?.toString() ?? "";
    if (today != lastUpdate) {
      await _dbRef.child('users/$uid').update({
        'intake': 0,
        'last_update': today,
      });
      _reminderSentToday = false; 
    }
  }

  void _activateListeners() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? localUid;
    if (currentUid != null) {
      _dbRef.child('users/$currentUid').onValue.listen((event) async {
        if (mounted && event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          _checkAndResetDailyIntake(currentUid, data);

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          double oldIntake = intakeDisplay;
          bool wasReady = _isMachineReady;

          setState(() {
            intakeDisplay = double.tryParse(data['intake']?.toString() ?? "0") ?? 0;
            age = int.tryParse(data['age']?.toString() ?? "19") ?? 19;
            gender = data['gender']?.toString() ?? "Male";
            dailyGoal = calculateDOHGoal(age, gender);
            _isMachineReady = data['coin_trigger'] == false && data['is_scanning'] == true;
          });

          if (intakeDisplay > oldIntake && oldIntake != 0) {
             _sendNotification("H2O Success! ✨", "Thank you for using PSU H2O. Stay Hydrated!");
          }

          double remaining = dailyGoal - intakeDisplay;
          if (remaining > 0 && intakeDisplay > 0 && !_reminderSentToday) {
            _sendNotification("Hydration Goal", "You have ${remaining.toInt()}ml left to complete your daily goal!");
            _reminderSentToday = true; 
          }

          if (!wasReady && _isMachineReady) {
            _sendNotification("Credits Received! ✅", "Pindutin ang DISPENSE WATER button.");
          }

          await prefs.setDouble('last_intake', intakeDisplay);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double percent = (dailyGoal > 0) ? (intakeDisplay / dailyGoal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("H2O Dashboard"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _activateListeners(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const Text("Daily Hydration Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  CircularPercentIndicator(
                    radius: 110.0,
                    lineWidth: 18.0,
                    percent: percent,
                    animation: true,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: (percent >= 1.0) ? Colors.greenAccent : Colors.blueAccent,
                    backgroundColor: Colors.blue.shade50,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
                        Text("${intakeDisplay.toInt()}ml / ${dailyGoal.toInt()}ml", style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _isMachineReady 
                      ? Column( 
                          key: const ValueKey("dispense"),
                          children: [
                            const Text("Credits Received!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 65,
                              child: ElevatedButton.icon(
                                onPressed: _triggerWaterDispense,
                                icon: const Icon(Icons.water_drop, size: 28),
                                label: const Text("DISPENSE WATER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 10,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column( 
                          key: const ValueKey("qr"),
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: _showQRDialog,
                                icon: const Icon(Icons.qr_code_2),
                                label: const Text("SHOW MY QR CODE"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[800],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
                    child: Text(
                      "Goal: ${dailyGoal.toInt()}ml (DOH for $age yo $gender).",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}