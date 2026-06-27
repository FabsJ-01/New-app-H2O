import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class WeeklyProgressPage extends StatefulWidget {
  const WeeklyProgressPage({super.key});

  @override
  State<WeeklyProgressPage> createState() => _WeeklyProgressPageState();
}

class _WeeklyProgressPageState extends State<WeeklyProgressPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Mga araw ng current week (Mon–Sun), computed sa initState
  late List<String> _weekDates;

  // ml consumed per day — key: 'yyyy-MM-dd', value: ml
  Map<String, double> _historyData = {};

  // Daily goal ng user (mula Firebase users/$uid)
  double _dailyGoal = 2200.0;

  bool _isLoading = true;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _weekDates = _getCurrentWeekDates();
    _fetchData();
  }

  // Kumuha ng Mon–Sun dates ng current week
  List<String> _getCurrentWeekDates() {
    final now = DateTime.now();
    // Monday = weekday 1
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return DateFormat('yyyy-MM-dd').format(day);
    });
  }

  // Kumuha ng DOH goal base sa age at gender (consistent sa dashboard.dart)
  double _calculateDOHGoal(int age, String gender) {
    bool isMale = gender == "Male";
    if (age >= 18) return isMale ? 2900.0 : 2200.0;
    if (age >= 16) return isMale ? 2600.0 : 2000.0;
    if (age >= 13) return isMale ? 2400.0 : 2000.0;
    return 1500.0;
  }

  Future<void> _fetchData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Kunin ang user data para sa daily goal
      final userSnapshot = await _dbRef.child('users/$uid').get();
      if (userSnapshot.exists) {
        final userData = Map<dynamic, dynamic>.from(userSnapshot.value as Map);
        int age = int.tryParse(userData['age']?.toString() ?? "19") ?? 19;
        String gender = userData['gender']?.toString() ?? "Male";
        _dailyGoal = _calculateDOHGoal(age, gender);
      }

      // 2. Kunin ang history ng current week
      final historySnapshot = await _dbRef.child('history/$uid').get();
      Map<String, double> tempHistory = {};

      if (historySnapshot.exists) {
        final Map<dynamic, dynamic> allHistory =
            Map<dynamic, dynamic>.from(historySnapshot.value as Map);

        for (String date in _weekDates) {
          if (allHistory.containsKey(date)) {
            tempHistory[date] =
                double.tryParse(allHistory[date].toString()) ?? 0.0;
          } else {
            tempHistory[date] = 0.0;
          }
        }
      } else {
        // Walang history — lahat zero
        for (String date in _weekDates) {
          tempHistory[date] = 0.0;
        }
      }

      setState(() {
        _historyData = tempHistory;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching weekly data: $e");
      setState(() => _isLoading = false);
    }
  }

  // I-convert ang ml sa percentage ng daily goal
  double _toPercent(double ml) {
    if (_dailyGoal <= 0) return 0;
    return (ml / _dailyGoal * 100).clamp(0.0, 120.0); // Max 120% para may room
  }

  // Short day labels para sa X-axis
  String _shortDayLabel(String date) {
    final d = DateTime.parse(date);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[d.weekday - 1];
  }

  // Summary stats
  double get _weeklyTotal =>
      _historyData.values.fold(0.0, (a, b) => a + b);

  double get _weeklyAverage {
    final nonZero = _historyData.values.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return 0;
    return nonZero.reduce((a, b) => a + b) / nonZero.length;
  }

  int get _daysGoalReached =>
      _historyData.values.where((ml) => ml >= _dailyGoal).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Weekly Progress",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade800, Colors.blue.shade600],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Gradient header background
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade800, Colors.blue.shade600],
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // --- Subtitle ---
                        Center(
                          child: Text(
                            "Hydration Goal: ${_dailyGoal.toInt()}ml/day",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Summary Stats Row ---
                        Row(
                          children: [
                            _buildStatCard(
                              label: "Weekly Total",
                              value: "${(_weeklyTotal / 1000).toStringAsFixed(1)}L",
                              icon: Icons.water_drop_rounded,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              label: "Daily Average",
                              value: "${_weeklyAverage.toInt()}ml",
                              icon: Icons.show_chart_rounded,
                              color: Colors.teal.shade600,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              label: "Goal Reached",
                              value: "$_daysGoalReached/7 days",
                              icon: Icons.emoji_events_rounded,
                              color: Colors.orange.shade700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- Chart Card ---
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade100.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bar_chart_rounded,
                                      color: Colors.blue.shade700, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    "This Week's Intake",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "% of daily hydration goal per day",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                              const SizedBox(height: 24),

                              SizedBox(
                                height: 260,
                                child: _weeklyTotal == 0
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.water_drop_outlined,
                                                size: 48,
                                                color: Colors.blue.shade200),
                                            const SizedBox(height: 12),
                                            Text(
                                              "No data recorded this week yet.",
                                              style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      )
                                    : BarChart(
                                        BarChartData(
                                          maxY: 120,
                                          minY: 0,
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false,
                                            horizontalInterval: 25,
                                            getDrawingHorizontalLine: (value) =>
                                                FlLine(
                                              color: value == 100
                                                  ? Colors.green.shade300
                                                  : Colors.grey.shade200,
                                              strokeWidth: value == 100 ? 1.5 : 1,
                                              dashArray:
                                                  value == 100 ? [6, 4] : null,
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          barTouchData: BarTouchData(
                                            touchTooltipData:
                                                BarTouchTooltipData(
                                              getTooltipColor: (group) =>
                                                  Colors.blue.shade800,
                                              getTooltipItem: (group,
                                                  groupIndex, rod, rodIndex) {
                                                String date =
                                                    _weekDates[group.x];
                                                double ml =
                                                    _historyData[date] ?? 0;
                                                double pct =
                                                    _toPercent(ml);
                                                return BarTooltipItem(
                                                  "${_shortDayLabel(date)}\n${ml.toInt()}ml\n${pct.toStringAsFixed(0)}%",
                                                  const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                );
                                              },
                                            ),
                                            touchCallback: (event, response) {
                                              setState(() {
                                                _touchedIndex = response
                                                        ?.spot?.touchedBarGroupIndex;
                                              });
                                            },
                                          ),
                                          titlesData: FlTitlesData(
                                            topTitles: const AxisTitles(
                                                sideTitles: SideTitles(
                                                    showTitles: false)),
                                            rightTitles: const AxisTitles(
                                                sideTitles: SideTitles(
                                                    showTitles: false)),
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 42,
                                                interval: 25,
                                                getTitlesWidget: (value, meta) =>
                                                    Text(
                                                  "${value.toInt()}%",
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade500),
                                                ),
                                              ),
                                            ),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 32,
                                                getTitlesWidget: (value, meta) {
                                                  int idx = value.toInt();
                                                  if (idx < 0 ||
                                                      idx >= _weekDates.length) {
                                                    return const SizedBox();
                                                  }
                                                  String label =
                                                      _shortDayLabel(
                                                          _weekDates[idx]);
                                                  bool isToday = _weekDates[
                                                          idx] ==
                                                      DateFormat('yyyy-MM-dd')
                                                          .format(DateTime.now());
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8),
                                                    child: Text(
                                                      label,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: isToday
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: isToday
                                                            ? Colors.blue.shade700
                                                            : Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          barGroups: List.generate(
                                            _weekDates.length,
                                            (i) {
                                              String date = _weekDates[i];
                                              double ml =
                                                  _historyData[date] ?? 0;
                                              double pct = _toPercent(ml);
                                              bool isToday = date ==
                                                  DateFormat('yyyy-MM-dd')
                                                      .format(DateTime.now());
                                              bool isTouched =
                                                  _touchedIndex == i;
                                              bool goalReached =
                                                  ml >= _dailyGoal;

                                              return BarChartGroupData(
                                                x: i,
                                                barRods: [
                                                  BarChartRodData(
                                                    toY: pct,
                                                    width: isTouched ? 26 : 22,
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    gradient: LinearGradient(
                                                      begin: Alignment.bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: goalReached
                                                          ? [
                                                              Colors.green.shade400,
                                                              Colors.teal.shade300,
                                                            ]
                                                          : isToday
                                                              ? [
                                                                  Colors.blue.shade600,
                                                                  Colors.lightBlue.shade300,
                                                                ]
                                                              : [
                                                                  Colors.blue.shade300,
                                                                  Colors.blue.shade200,
                                                                ],
                                                    ),
                                                    backDrawRodData:
                                                        BackgroundBarChartRodData(
                                                      show: true,
                                                      toY: 120,
                                                      color: Colors.grey.shade100,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                              ),

                              const SizedBox(height: 16),

                              // Legend
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLegendItem(
                                      Colors.blue.shade400, "Current Day"),
                                  const SizedBox(width: 16),
                                  _buildLegendItem(
                                      Colors.teal.shade300, "Goal Reached"),
                                  const SizedBox(width: 16),
                                  _buildLegendItem(
                                      Colors.grey.shade300, "No Data"),
                                ],
                              ),

                              // 100% goal line label
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 2,
                                    color: Colors.green.shade300,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "100% = Daily Goal (${_dailyGoal.toInt()}ml)",
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- Daily Breakdown List ---
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade50.withOpacity(0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Daily Breakdown",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(_weekDates.length, (i) {
                                String date = _weekDates[i];
                                double ml = _historyData[date] ?? 0;
                                double pct = _toPercent(ml);
                                bool goalReached = ml >= _dailyGoal;
                                bool isToday = date ==
                                    DateFormat('yyyy-MM-dd')
                                        .format(DateTime.now());
                                String dayLabel = _shortDayLabel(date);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 36,
                                        child: Text(
                                          dayLabel,
                                          style: TextStyle(
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isToday
                                                ? Colors.blue.shade700
                                                : Colors.grey.shade700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: (pct / 100).clamp(0.0, 1.0),
                                            minHeight: 10,
                                            backgroundColor:
                                                Colors.grey.shade100,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              goalReached
                                                  ? Colors.teal.shade400
                                                  : Colors.blue.shade400,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          ml > 0
                                              ? "${ml.toInt()}ml"
                                              : "—",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: goalReached
                                                ? Colors.teal.shade600
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      goalReached
                                          ? Icon(Icons.check_circle_rounded,
                                              color: Colors.teal.shade400,
                                              size: 18)
                                          : const SizedBox(width: 18),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
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

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}