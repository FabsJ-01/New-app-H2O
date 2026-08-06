import 'dart:async';
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
  StreamSubscription? _userListener;

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

  @override
  void dispose() {
    _userListener?.cancel();
    super.dispose();
  }

  void _showWeeklyStats() {
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
    setState(() => _notificationsEnabled = value);
    await prefs.setBool('notifications_enabled', value);

    if (value) {
      NotificationScheduler.scheduleDailyReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("H2O Reminders: ON 💧"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await NotificationScheduler.cancelAllReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("H2O Reminders: OFF 🔕 (Notifications paused)"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    _activateListeners();
  }

  void _showQRDialog() {
    final displayUid = FirebaseAuth.instance.currentUser?.uid ?? localUid;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Your Personal QR",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: displayUid ?? "No UID Saved",
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 10),
            const Text(
              "Scan at the PSU H2O Hub",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  // --- LOG WATER INTAKE DIALOG ---
  void _showLogWaterDialog() {
    final TextEditingController customController = TextEditingController();
    int? selectedMl;
    bool isCustom = false;

    final List<Map<String, dynamic>> presets = [
      {'label': '250ml', 'value': 250, 'icon': '🥤'},
      {'label': '500ml', 'value': 500, 'icon': '🍶'},
      {'label': '750ml', 'value': 750, 'icon': '🫗'},
      {'label': '1000ml', 'value': 1000, 'icon': '🧴'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Log Water Intake",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Away from campus? Log manually!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preset buttons
                  Text(
                    "Quick Select:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    physics: const NeverScrollableScrollPhysics(),
                    children: presets.map((preset) {
                      bool isSelected =
                          selectedMl == preset['value'] && !isCustom;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedMl = preset['value'];
                            isCustom = false;
                            customController.clear();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.blue.shade100,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  preset['icon'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  preset['label'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Custom input
                  Text(
                    "Or enter custom amount:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setDialogState(() {
                        isCustom = val.isNotEmpty;
                        if (isCustom) selectedMl = null;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "e.g. 350",
                      suffixText: "ml",
                      suffixStyle: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade700,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.blue.shade50,
                    ),
                  ),

                  // Current intake info
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Current: ${intakeDisplay.toInt()}ml / ${dailyGoal.toInt()}ml",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  int mlToAdd = 0;

                  if (isCustom && customController.text.isNotEmpty) {
                    mlToAdd =
                        int.tryParse(customController.text.trim()) ?? 0;
                  } else if (selectedMl != null) {
                    mlToAdd = selectedMl!;
                  }

                  if (mlToAdd <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select or enter a valid amount!"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  if (mlToAdd > 2000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Maximum single log is 2000ml!"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  await _saveManualIntake(mlToAdd);
                },
                child: const Text(
                  "SAVE",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Save manual intake to Firebase
  Future<void> _saveManualIntake(int mlToAdd) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? localUid;
    if (currentUid == null) return;

    try {
      // Get current intake
      final snapshot =
          await _dbRef.child('users/$currentUid/intake').get();
      double currentIntake =
          double.tryParse(snapshot.value?.toString() ?? "0") ?? 0.0;

      double newIntake = currentIntake + mlToAdd;
      String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Update intake sa Firebase
      await _dbRef.child('users/$currentUid').update({
        'intake': newIntake,
        'last_drink_time': now,
      });

      // Save sa manual_logs para may history
      await _dbRef
          .child('users/$currentUid/manual_logs')
          .push()
          .set({
        'amount_ml': mlToAdd,
        'logged_at': now,
        'type': 'manual',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "+${mlToAdd}ml logged successfully! 💧",
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        _sendNotification(
          "Water Intake Logged! 💧",
          "+${mlToAdd}ml added. Keep it up! Total: ${(currentIntake + mlToAdd).toInt()}ml",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving intake: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _triggerWaterDispense() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? localUid;
    if (currentUid != null) {
      await _dbRef.child('users/$currentUid').update({'coin_trigger': true});
      _sendNotification(
        "Dispensing Initiated 💧",
        "System active. Please ensure your container is properly positioned.",
      );
    }
  }

  double calculateDOHGoal(int age, String gender) {
    bool isMale = gender == "Male";
    if (age >= 18) return isMale ? 2900.0 : 2200.0;
    if (age >= 16) return isMale ? 2600.0 : 2000.0;
    if (age >= 13) return isMale ? 2400.0 : 2000.0;
    return 1500.0;
  }

  Future<void> _checkAndResetDailyIntake(String uid, Map data) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String lastUpdate = data['update']?.toString() ?? "";

    if (today != lastUpdate) {
      int lastIntake = int.tryParse(data['intake']?.toString() ?? "0") ?? 0;

      if (lastUpdate.isNotEmpty && lastIntake > 0) {
        await _dbRef.child('history/$uid/$lastUpdate').set(lastIntake);
      }

      await _dbRef.child('users/$uid').update({
        'intake': 0,
        'update': today,
      });
    }
  }

  void _activateListeners() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? localUid;
    if (currentUid != null) {
      _userListener?.cancel();
      _userListener = _dbRef
          .child('users/$currentUid')
          .onValue
          .listen((event) async {
        if (mounted && event.snapshot.value != null) {
          final data =
              Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          _checkAndResetDailyIntake(currentUid, data);

          final SharedPreferences prefs =
              await SharedPreferences.getInstance();
          double oldIntake = intakeDisplay;
          bool wasReady = _isMachineReady;

          setState(() {
            intakeDisplay =
                double.tryParse(data['intake']?.toString() ?? "0") ?? 0;
            age = int.tryParse(data['age']?.toString() ?? "19") ?? 19;
            gender = data['gender']?.toString() ?? "Male";
            dailyGoal = calculateDOHGoal(age, gender);
            _isMachineReady = data['coin_trigger'] == false &&
                data['is_scanning'] == true;
          });

          if (intakeDisplay > oldIntake) {
            _sendNotification(
              "H2O Success! ✨",
              "Thank you for using PSU H2O. Stay Hydrated!",
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      "Thank you for using PSU H2O. Stay Hydrated! 💧"),
                  backgroundColor: Colors.blue[900],
                ),
              );
            }
          }

          bool isScanning = data['is_scanning'] == true;
          bool coinTrigger = data['coin_trigger'] == true;

          if (wasReady && !isScanning && !coinTrigger) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      "Session ended. Device is ready for the next user. 📇"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }

          await prefs.setDouble('last_intake', intakeDisplay);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double percent = (dailyGoal > 0)
        ? (intakeDisplay / dailyGoal).clamp(0.0, 1.0)
        : 0.0;

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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfilePage()),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
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

                    // Circular Progress
                    Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 50),
                      padding:
                          const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.blue.shade100.withOpacity(0.6),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double calculatedRadius =
                              constraints.maxWidth * 0.40;
                          return Center(
                            child: CircularPercentIndicator(
                              radius: calculatedRadius,
                              lineWidth: 20.0,
                              percent: percent,
                              animation: true,
                              animationDuration: 800,
                              circularStrokeCap:
                                  CircularStrokeCap.round,
                              linearGradient: (percent >= 1.0)
                                  ? LinearGradient(colors: [
                                      Colors.green.shade400,
                                      Colors.teal.shade300,
                                    ])
                                  : LinearGradient(colors: [
                                      Colors.blue.shade400,
                                      Colors.lightBlue.shade300,
                                    ]),
                              backgroundColor: Colors.blue.shade50,
                              center: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${(percent * 100).toInt()}%",
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${intakeDisplay.toInt()}ml / ${dailyGoal.toInt()}ml",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // QR or Dispense Button
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _isMachineReady
                            ? Column(
                                key: const ValueKey("dispense"),
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle,
                                            size: 16,
                                            color:
                                                Colors.green.shade600),
                                        const SizedBox(width: 6),
                                        Text(
                                          "System Ready",
                                          style: TextStyle(
                                            color:
                                                Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.blue.shade500,
                                          Colors.blue.shade700,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.shade300
                                              .withOpacity(0.5),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        onTap: _triggerWaterDispense,
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.water_drop,
                                                size: 26,
                                                color: Colors.white),
                                            SizedBox(width: 10),
                                            Text(
                                              "DISPENSE WATER",
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
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
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade700,
                                      Colors.blue.shade900,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade200
                                          .withOpacity(0.6),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(18),
                                    onTap: _showQRDialog,
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.qr_code_2,
                                            color: Colors.white),
                                        SizedBox(width: 10),
                                        Text(
                                          "SHOW MY QR CODE",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- LOG WATER INTAKE BUTTON ---
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.teal.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.teal.shade50.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _showLogWaterDialog,
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: Colors.teal.shade700,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "LOG WATER INTAKE",
                                  style: TextStyle(
                                    color: Colors.teal.shade800,
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

                    const SizedBox(height: 14),

                    // DOH Goal Info
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "Goal: ${dailyGoal.toInt()}ml (DOH Guidelines for Age $age)",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Track Progress Button
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.blue.shade100, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade50
                                  .withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _showWeeklyStats,
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart_rounded,
                                    color: Colors.blue.shade800),
                                const SizedBox(width: 10),
                                Text(
                                  "TRACK MY PROGRESS",
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

                    // Notifications Toggle
                    Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 28),
                      decoration: BoxDecoration(
                        color: _notificationsEnabled
                            ? Colors.white
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.shade100
                                .withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          _notificationsEnabled
                              ? "Campus Alerts Active"
                              : "Alerts Paused (At Home)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _notificationsEnabled
                                ? Colors.blue.shade900
                                : Colors.grey.shade700,
                          ),
                        ),
                        subtitle: Text(
                          "Turn off if you are away from the campus hub",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        value: _notificationsEnabled,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _notificationsEnabled
                                ? Colors.blue.shade50
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _notificationsEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            color: _notificationsEnabled
                                ? Colors.blue.shade700
                                : Colors.grey,
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