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
import 'main.dart';
import 'weekly_progress_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  double intakeDisplay = 0;
  double dailyGoal = 2000;
  String gender = "Male";
  int age = 19;
  bool _isMachineReady = false;
  String? localUid;
  bool _notificationsEnabled = true;
  StreamSubscription? _userListener;
  bool _isFirstLoad = true;

  // Animation controller para sa water wave effect
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://h2o-project-e83d9-default-rtdb.firebaseio.com',
  ).ref();

  @override
  void initState() {
    super.initState();

    // Wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _loadOfflineData();
    _activateListeners();
  }

  @override
  void dispose() {
    _userListener?.cancel();
    _waveController.dispose();
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
      await ensureHydrationRemindersRunning();
    } else {
      await stopHydrationReminders();
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _notificationsEnabled = value);
    await prefs.setBool('notifications_enabled', value);

    if (value) {
      await startHydrationReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("H2O Reminders: ON 💧"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await stopHydrationReminders();
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          "Current: ${intakeDisplay.toInt()}ml / ${dailyGoal.toInt()}ml",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
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
                child: Text("Cancel",
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
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
                        content:
                            Text("Please select or enter a valid amount!"),
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
                child: const Text("SAVE",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveManualIntake(int mlToAdd) async {
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? localUid;
    if (currentUid == null) return;

    try {
      final snapshot =
          await _dbRef.child('users/$currentUid/intake').get();
      double currentIntake =
          double.tryParse(snapshot.value?.toString() ?? "0") ?? 0.0;

      double newIntake = currentIntake + mlToAdd;
      String now =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      await _dbRef.child('users/$currentUid').update({
        'intake': newIntake,
        'last_drink_time': now,
      });

      await _dbRef
          .child('users/$currentUid/manual_logs')
          .push()
          .set({'amount_ml': mlToAdd, 'logged_at': now, 'type': 'manual'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text("+${mlToAdd}ml logged successfully! 💧"),
              ],
            ),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
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
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _triggerWaterDispense() async {
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? localUid;
    if (currentUid != null) {
      await _dbRef.child('users/$currentUid').update({
        'coin_trigger': true,
        'is_dispensing': true,
      });
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
      int lastIntake =
          int.tryParse(data['intake']?.toString() ?? "0") ?? 0;
      if (lastUpdate.isNotEmpty && lastIntake > 0) {
        await _dbRef.child('history/$uid/$lastUpdate').set(lastIntake);
      }
      await _dbRef
          .child('users/$uid')
          .update({'intake': 0, 'update': today});
    }
  }

  void _activateListeners() {
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? localUid;
    if (currentUid != null) {
      _userListener?.cancel();
      _userListener = _dbRef
          .child('users/$currentUid')
          .onValue
          .listen((event) async {
        if (mounted && event.snapshot.value != null) {
          final data =
              Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          await _checkAndResetDailyIntake(currentUid, data);

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

          if (!_isFirstLoad && intakeDisplay > oldIntake) {
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

          if (_isFirstLoad) _isFirstLoad = false;

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
    double percent =
        (dailyGoal > 0) ? (intakeDisplay / dailyGoal).clamp(0.0, 1.0) : 0.0;
    bool goalReached = percent >= 1.0;

    // Dynamic colors base sa progress
    Color primaryColor = goalReached
        ? const Color(0xFF00C853)
        : percent > 0.6
            ? const Color(0xFF0288D1)
            : const Color(0xFF1565C0);

    Color secondaryColor = goalReached
        ? const Color(0xFF00E676)
        : percent > 0.6
            ? const Color(0xFF29B6F6)
            : const Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _waveAnimation.value * 0.3),
                  
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              "H2O HUB",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 18,
              ),
            ),
          ],
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
              colors: [primaryColor, secondaryColor],
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
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1),
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
          // Gradient background
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
            ),
          ),

          // Bubbles decoration
          Positioned(
            top: 80,
            right: 20,
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _waveAnimation.value),
                  child: _buildBubble(40, 0.1),
                );
              },
            ),
          ),
          Positioned(
            top: 120,
            left: 15,
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_waveAnimation.value),
                  child: _buildBubble(24, 0.15),
                );
              },
            ),
          ),
          Positioned(
            top: 160,
            right: 60,
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_waveAnimation.value * 0.5, 0),
                  child: _buildBubble(16, 0.12),
                );
              },
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _activateListeners(),
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      goalReached
                          ? "🎉 Daily Goal Reached!"
                          : "Stay Hydrated, Stay Healthy!",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Main circular progress card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              double radius = constraints.maxWidth * 0.38;
                              return CircularPercentIndicator(
                                radius: radius,
                                lineWidth: 18.0,
                                percent: percent,
                                animation: true,
                                animationDuration: 1000,
                                circularStrokeCap: CircularStrokeCap.round,
                                linearGradient: goalReached
                                    ? const LinearGradient(colors: [
                                        Color(0xFF00C853),
                                        Color(0xFF69F0AE),
                                      ])
                                    : LinearGradient(colors: [
                                        primaryColor,
                                        secondaryColor,
                                      ]),
                                backgroundColor:
                                    primaryColor.withOpacity(0.08),
                                center: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _waveAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                              0, _waveAnimation.value * 0.2),
                                          child: Text(
                                            goalReached ? "🎉" : "💧",
                                            style: const TextStyle(
                                                fontSize: 28),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${(percent * 100).toInt()}%",
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${intakeDisplay.toInt()}ml",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "of ${dailyGoal.toInt()}ml",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // Progress info bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 14, color: primaryColor),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "DOH Goal for Age $age • ${dailyGoal.toInt()}ml/day",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _buildQuickStat(
                            icon: Icons.local_drink_rounded,
                            label: "Consumed",
                            value: "${intakeDisplay.toInt()}ml",
                            color: primaryColor,
                          ),
                          const SizedBox(width: 12),
                          _buildQuickStat(
                            icon: Icons.flag_rounded,
                            label: "Remaining",
                            value:
                                "${((dailyGoal - intakeDisplay).clamp(0, dailyGoal)).toInt()}ml",
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 12),
                          _buildQuickStat(
                            icon: Icons.emoji_events_rounded,
                            label: "Goal",
                            value: "${dailyGoal.toInt()}ml",
                            color: Colors.purple.shade600,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action buttons section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // QR or Dispense button
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                    scale: animation, child: child),
                              );
                            },
                            child: _isMachineReady
                                ? _buildDispenseButton(primaryColor)
                                : _buildQRButton(),
                          ),

                          const SizedBox(height: 12),

                          // Log Water Intake Button
                          _buildActionButton(
                            icon: Icons.add_circle_rounded,
                            label: "LOG WATER INTAKE",
                            subtitle: "Away from campus? Log manually",
                            color: const Color(0xFF00897B),
                            secondColor: const Color(0xFF26A69A),
                            onTap: _showLogWaterDialog,
                          ),

                          const SizedBox(height: 12),

                          // Track Progress Button
                          _buildActionButton(
                            icon: Icons.bar_chart_rounded,
                            label: "TRACK MY PROGRESS",
                            subtitle: "Weekly • Monthly • Yearly",
                            color: const Color(0xFF5C6BC0),
                            secondColor: const Color(0xFF7986CB),
                            onTap: _showWeeklyStats,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notifications Toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          title: Text(
                            _notificationsEnabled
                                ? "Campus Alerts Active"
                                : "Alerts Paused (At Home)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _notificationsEnabled
                                  ? const Color(0xFF1565C0)
                                  : Colors.grey.shade700,
                            ),
                          ),
                          subtitle: Text(
                            "Turn off if you are away from the campus hub",
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                          ),
                          value: _notificationsEnabled,
                          secondary: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: _notificationsEnabled
                                  ? LinearGradient(colors: [
                                      primaryColor,
                                      secondaryColor,
                                    ])
                                  : LinearGradient(colors: [
                                      Colors.grey.shade400,
                                      Colors.grey.shade300,
                                    ]),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _notificationsEnabled
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_off_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          activeColor: primaryColor,
                          onChanged: _toggleNotifications,
                        ),
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

  // Bubble decoration widget
  Widget _buildBubble(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  // Quick stat card
  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Dispense Water button
  Widget _buildDispenseButton(Color primaryColor) {
    return Column(
      key: const ValueKey("dispense"),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Machine Ready — Tap to Dispense",
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00B0FF),
                Color(0xFF0091EA),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0091EA).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
                children: [
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _waveAnimation.value * 0.5),
                        child: const Icon(Icons.water_drop,
                            size: 28, color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "DISPENSE WATER",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // QR Code button
  Widget _buildQRButton() {
    return Container(
      key: const ValueKey("qr"),
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF0D47A1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _showQRDialog,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_2_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SHOW MY QR CODE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "Scan at the nearest H2O Hub",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action button (Log Water + Track Progress)
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color secondColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, secondColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}