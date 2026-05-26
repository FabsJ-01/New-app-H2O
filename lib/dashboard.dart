import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart'; 
import 'package:qr_flutter/qr_flutter.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import 'notification_scheduler.dart'; 

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
  bool _notificationsEnabled = true; 

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

  Future<void> _sendNotification(String title, String body) async {
    if (!_notificationsEnabled) return; 
    
    await NotificationScheduler.showInstantNotification(
      title: title,
      body: body,
    );
  }

  Future<void> _loadOfflineData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      await prefs.setString('user_uid', user.uid); 
    }

    setState(() {
      intakeDisplay = prefs.getDouble('last_intake') ?? 0.0;
      localUid = prefs.getString('user_uid') ?? user?.uid;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true; 
    });

    if (_notificationsEnabled) {
      NotificationScheduler.scheduleDailyReminders();
    } else {
      NotificationScheduler.cancelAllReminders(); 
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = value;
    });
    await prefs.setBool('notifications_enabled', value);

    if (value) {
      NotificationScheduler.scheduleDailyReminders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("H2O Reminders: ON 💧"), backgroundColor: Colors.green),
      );
    } else {
      await NotificationScheduler.cancelAllReminders(); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("H2O Reminders: OFF 🔕 (Notifications paused)"), backgroundColor: Colors.orange),
      );
    }
  }

  void _showQRDialog() {
    final displayUid = FirebaseAuth.instance.currentUser?.uid ?? localUid;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Your Personal QR", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: displayUid ?? "No UID Saved",
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 10),
            const Text("Scan at the PSU H2O Hub", textAlign: TextAlign.center),
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
      _sendNotification("Dispensing Initiated 💧", "System active. Please ensure your container is properly positioned.");
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
    String lastUpdate = data['update']?.toString() ?? "";
    
    if (today != lastUpdate) {
      await _dbRef.child('users/$uid').update({
        'intake': 0,
        'update': today, 
      });
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

          if (intakeDisplay > oldIntake) {
              _sendNotification("H2O Success! ✨", "Thank you for using PSU H2O. Stay Hydrated!");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Thank you for using PSU H2O. Stay Hydrated! 💧"),
                  backgroundColor: Colors.blue[900],
                ),
              );
          }

          bool isScanning = data['is_scanning'] == true;
          bool coinTrigger = data['coin_trigger'] == true;
          
          if (wasReady && !isScanning && !coinTrigger) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Session ended. Device is ready for the next user. 📇"),
                backgroundColor: Colors.green,
              ),
            );
          }

          if (!wasReady && _isMachineReady) {
            int amount = int.tryParse(data['last_credits']?.toString() ?? "0") ?? 0;
            _sendNotification(
              "Credits Received! ✅", 
              "PHP $amount.00 has been verified. Click the button to dispense water."
            );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("H2O HUB", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _activateListeners(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 🔥 DAGDAG: "Hydration Monitoring" Title right at the top
                const SizedBox(height: 25),
                Text(
                  "Hydration Monitoring",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                    letterSpacing: 0.5,
                  ),
                ),
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
                          const Text("System Ready ✅", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
                    : SizedBox(
                        key: const ValueKey("qr"),
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
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.blue[50], 
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade100)
                  ),
                  child: Text(
                    "Goal: ${dailyGoal.toInt()}ml Based on DOH guidelines for Age $age ($gender)",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                  ),
                ),
                
                const SizedBox(height: 15),

                // Toggle Switch nananatili sa saktong pwesto sa baba
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: _notificationsEnabled ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _notificationsEnabled ? Colors.blue.shade100 : Colors.grey.shade300)
                  ),
                  child: SwitchListTile(
                    title: Text(
                      _notificationsEnabled ? "Campus Alerts Active" : "Alerts Paused (At Home)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: _notificationsEnabled ? Colors.blue.shade900 : Colors.grey.shade700
                      ),
                    ),
                    subtitle: const Text("Turn off if you are away from the campus hub"),
                    value: _notificationsEnabled,
                    secondary: Icon(
                      _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                      color: _notificationsEnabled ? Colors.blue.shade800 : Colors.grey,
                    ),
                    activeColor: Colors.blue.shade900,
                    onChanged: _toggleNotifications,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}