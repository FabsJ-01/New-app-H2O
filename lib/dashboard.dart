import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart'; 
import 'package:qr_flutter/qr_flutter.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; // 1. Added this
import 'profile_page.dart';

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
  String? localUid; // 2. Added local UID for offline QR

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://h2o-project-e83d9-default-rtdb.firebaseio.com',
  ).ref();

  @override
  void initState() {
    super.initState();
    _loadOfflineData(); // 3. Load saved data first
    _activateListeners();
  }

  // 4. Function to load data from Phone Storage
  _loadOfflineData() async {
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
    // Gamitin ang localUid kung null ang Firebase UID (Offline mode)
    final displayUid = FirebaseAuth.instance.currentUser?.uid ?? localUid;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scan to Start", textAlign: TextAlign.center),
        content: SizedBox(
          width: 250, 
          height: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: displayUid ?? "No UID Saved", // Reliable offline
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 10),
              const Text("Itapat ang QR sa scanner ng machine", textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  void _triggerCoinSlot() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? localUid;
    if (currentUid != null) {
      await _dbRef.child('users/$currentUid').update({
        'coin_trigger': true,
        'is_scanning': false, 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Coin slot activated! Please insert coin."),
          backgroundColor: Colors.orange,
        ),
      );
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
          
          setState(() {
            intakeDisplay = double.tryParse(data['intake']?.toString() ?? "0") ?? 0;
            age = int.tryParse(data['age']?.toString() ?? "19") ?? 19;
            gender = data['gender']?.toString() ?? "Male";
            dailyGoal = calculateDOHGoal(age, gender);
            _isMachineReady = data['is_scanning'] == true;
          });

          // 5. Always save to SharedPreferences when data changes
          await prefs.setDouble('last_intake', intakeDisplay);
          await prefs.setString('user_uid', currentUid);
          await prefs.setInt('last_age', age);
          await prefs.setString('last_gender', gender);
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
      body: RefreshIndicator( // Added for manual sync if online
        onRefresh: () async => _activateListeners(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text("Daily Hydration Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                SizedBox(
                  height: 230,
                  child: CircularPercentIndicator(
                    radius: 110.0,
                    lineWidth: 18.0,
                    percent: percent,
                    animation: true,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: Colors.blueAccent,
                    backgroundColor: Colors.blue.shade50,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
                        Text("${intakeDisplay.toInt()}ml / ${dailyGoal.toInt()}ml", style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showQRDialog,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text("SHOW MY QR CODE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                if (_isMachineReady)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          const Text("Machine Verified! Proceed to pay?", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _triggerCoinSlot,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                              child: const Text("ACTIVATE COIN SLOT"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Text("Waiting for machine scan...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

                const SizedBox(height: 30),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
                  child: Text(
                    "Goal: ${dailyGoal.toInt()}ml (DOH guidelines for a $age year old $gender).",
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
    );
  }
}