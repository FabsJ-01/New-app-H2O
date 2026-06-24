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
import 'weekly_progress_page.dart';

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

  // Placeholder para sa stats function
  void _showWeeklyStats() {
  // Bubuksan nito ang buong bagong screen
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const WeeklyProgressPage()),
  );
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

  Future<void> _checkAndResetDailyIntake(String uid, Map data) async {
   //String today = "2026-06-18";
    
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String lastUpdate = data['update']?.toString() ?? "";

    if (today != lastUpdate) {
      int lastIntake = int.tryParse(data['intake']?.toString() ?? "0") ?? 0;

       await _dbRef.child('history/$uid/$lastUpdate').set(lastIntake);
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

          // NOTE: Tinanggal ang "Credits Received" notification dito dahil
          // duplicate na sa BackgroundService (main.dart onStart()), na siyang
          // nananatiling tumatakbo kahit closed ang app. Iisang source na lang
          // ng notification para hindi na mag-double.

          await prefs.setDouble('last_intake', intakeDisplay);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double percent = (dailyGoal > 0) ? (intakeDisplay / dailyGoal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "H2O HUB",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade800, Colors.blue.shade600],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, size: 20),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Soft gradient header background — gumagana kasabay ng extendBodyBehindAppBar
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade800, Colors.blue.shade600],
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _activateListeners(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      "Hydration Monitoring",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Soft card na naglalaman ng progress ring — "floats" sa ibabaw ng gradient
                    // Soft card na naglalaman ng progress ring
Container(
  margin: const EdgeInsets.symmetric(horizontal: 50), // Ibalik sa 24 para maganda ang width ng card
  padding: const EdgeInsets.symmetric(vertical: 30),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.shade100.withOpacity(0.6),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  ),
  child: LayoutBuilder(
    builder: (context, constraints) {
      // Kalkulahin ang radius: kumuha ng 40% ng width ng card para laging perfect fit
      double calculatedRadius = constraints.maxWidth * 0.40;
      
      return Center(
        child: CircularPercentIndicator(
          radius: calculatedRadius, 
          lineWidth: 20.0, // Medyo taasan natin ulit kasi may space na
          percent: percent,
          animation: true,
          animationDuration: 800,
          circularStrokeCap: CircularStrokeCap.round,
          linearGradient: (percent >= 1.0)
              ? LinearGradient(colors: [Colors.green.shade400, Colors.teal.shade300])
              : LinearGradient(colors: [Colors.blue.shade400, Colors.lightBlue.shade300]),
          backgroundColor: Colors.blue.shade50,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${(percent * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 40, // Ibalik sa 40 para malinaw
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${intakeDisplay.toInt()}ml / ${dailyGoal.toInt()}ml",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    },
  ),
),

                    const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _isMachineReady 
                    ? Column( 
                        key: const ValueKey("dispense"),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  "System Ready",
                                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.blue.shade500, Colors.blue.shade700],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade300.withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _triggerWaterDispense,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.water_drop, size: 26, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      "DISPENSE WATER",
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        key: const ValueKey("qr"),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue.shade700, Colors.blue.shade900],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade200.withOpacity(0.6),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _showQRDialog,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.qr_code_2, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  "SHOW MY QR CODE",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ),
                ),
                const SizedBox(height: 28),

                // Pinalit na DOH Goal design — softer pill style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "Goal: ${dailyGoal.toInt()}ml (DOH Guidelines for Age $age)",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Bagong Stats Button (Navigation Type)
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 28),
  child: Container(
    width: double.infinity,
    height: 52,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.blue.shade100, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.shade50.withOpacity(0.4),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
                    child: Material(
                      color: Colors.transparent,
                      // Hanapin ang parteng ito sa iyong Dashboard.dart
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        
                        // DITO MO SIYA ILALAGAY:
                        onTap: _showWeeklyStats, 
                        
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart_rounded, color: Colors.blue.shade800),
                            const SizedBox(width: 10),
                            Text(
                              "VIEW WEEKLY PROGRESS",
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                                
                const SizedBox(height: 18),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: _notificationsEnabled ? Colors.white : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.shade100.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      _notificationsEnabled ? "Campus Alerts Active" : "Alerts Paused (At Home)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                        color: _notificationsEnabled ? Colors.blue.shade900 : Colors.grey.shade700
                      ),
                    ),
                    subtitle: Text(
                      "Turn off if you are away from the campus hub",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    value: _notificationsEnabled,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _notificationsEnabled ? Colors.blue.shade50 : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                        color: _notificationsEnabled ? Colors.blue.shade700 : Colors.grey,
                        size: 20,
                      ),
                    ),
                    activeColor: Colors.blue.shade700,
                    onChanged: _toggleNotifications,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}