import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Add this
import 'profile_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  double intakeDisplay = 0;
  double dailyGoal = 2000; // Default goal
  String gender = "Male";
  int age = 19;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://h2o-project-e83d9-default-rtdb.firebaseio.com',
  ).ref();

  @override
  void initState() {
    super.initState();
    _activateListeners();
  }

  // --- DOH LOGIC FUNCTION ---
  double calculateDOHGoal(int age, String gender) {
    if (age >= 19 && age <= 59) {
      return (gender == "Male") ? 3000.0 : 2300.0;
    } else if (age >= 16 && age <= 18) {
      return (gender == "Male") ? 2600.0 : 2200.0;
    } else if (age >= 13 && age <= 15) {
      return (gender == "Male") ? 2400.0 : 2100.0;
    }
    return 2000.0; // Fallback default
  }

  void _activateListeners() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      // Makinig sa buong User object para makuha pati age at gender
      _dbRef.child('users/$uid').onValue.listen((event) {
        if (mounted && event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          
          setState(() {
            intakeDisplay = double.tryParse(data['intake']?.toString() ?? "0") ?? 0;
            age = int.tryParse(data['age']?.toString() ?? "19") ?? 19;
            gender = data['gender']?.toString() ?? "Male";
            
            // Auto-compute ng goal base sa DOH Table mo
            dailyGoal = calculateDOHGoal(age, gender);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute percentage for the progress circle
    double percent = intakeDisplay / dailyGoal;
    if (percent > 1.0) percent = 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("H2O Dashboard"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView( // Para iwas overflow sa maliit na screen
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Daily Hydration Progress",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),

              // --- CIRCULAR PROGRESS INDICATOR ---
              CircularPercentIndicator(
                radius: 130.0,
                lineWidth: 20.0,
                percent: percent,
                animation: true,
                animateFromLastPercent: true,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.blueAccent,
                backgroundColor: Colors.blue.shade50,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.water_drop, size: 40, color: Colors.blue),
                    Text(
                      "${(percent * 100).toInt()}%",
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${intakeDisplay.toInt()} / ${dailyGoal.toInt()} ml",
                      style: TextStyle(fontSize: 16, color: Colors.blueGrey[600]),
                    ),
                  ],
                ),
              ),
              // -----------------------------------

              const SizedBox(height: 40),
              
              // Info Card para sa DOH Goal
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Based on DOH guidelines for a $age year old $gender, your daily goal is ${dailyGoal.toInt()}ml.",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}