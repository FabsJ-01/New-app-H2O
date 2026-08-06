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

class _WeeklyProgressPageState extends State<WeeklyProgressPage>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  late TabController _tabController;

  // Weekly
  late List<String> _weekDates;
  Map<String, double> _weeklyData = {};

  // Monthly
  Map<int, double> _monthlyData = {}; // key: week number (1-5), value: total ml

  // Yearly
  Map<int, double> _yearlyData = {}; // key: month (1-12), value: total ml

  double _dailyGoal = 2200.0;
  bool _isLoading = true;
  int? _touchedIndex;

  // FIX: Real-time today's intake
  double _todayIntake = 0.0;
  String _todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _weekDates = _getCurrentWeekDates();
    _fetchData();
    _listenToTodayIntake(); // FIX: Real-time listener
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // FIX: Real-time listener para sa today's intake
  void _listenToTodayIntake() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _dbRef.child('users/$uid/intake').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        double intake = double.tryParse(
              event.snapshot.value.toString(),
            ) ??
            0.0;
        setState(() {
          _todayIntake = intake;
          // FIX: I-update ang today sa weeklyData para real-time
          _weeklyData[_todayDate] = intake;
        });
      }
    });
  }

  List<String> _getCurrentWeekDates() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return DateFormat('yyyy-MM-dd').format(day);
    });
  }

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
      // 1. User data para sa daily goal
      final userSnapshot = await _dbRef.child('users/$uid').get();
      if (userSnapshot.exists) {
        final userData =
            Map<dynamic, dynamic>.from(userSnapshot.value as Map);
        int age = int.tryParse(userData['age']?.toString() ?? "19") ?? 19;
        String gender = userData['gender']?.toString() ?? "Male";
        _dailyGoal = _calculateDOHGoal(age, gender);

        // FIX: Kunin ang today's intake mula sa users node
        _todayIntake =
            double.tryParse(userData['intake']?.toString() ?? "0") ?? 0.0;
      }

      // 2. History data
      final historySnapshot = await _dbRef.child('history/$uid').get();
      Map<String, double> allHistory = {};

      if (historySnapshot.exists) {
        final raw =
            Map<dynamic, dynamic>.from(historySnapshot.value as Map);
        raw.forEach((key, value) {
          allHistory[key.toString()] =
              double.tryParse(value.toString()) ?? 0.0;
        });
      }

      // FIX: I-include ang today's intake sa history map
      allHistory[_todayDate] = _todayIntake;

      // --- WEEKLY DATA ---
      Map<String, double> tempWeekly = {};
      for (String date in _weekDates) {
        tempWeekly[date] = allHistory[date] ?? 0.0;
      }

      // --- MONTHLY DATA (per week summary) ---
      final now = DateTime.now();
      Map<int, double> tempMonthly = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      allHistory.forEach((dateStr, ml) {
        try {
          final date = DateTime.parse(dateStr);
          if (date.year == now.year && date.month == now.month) {
            // Compute week number within the month (1-5)
            int weekNum = ((date.day - 1) ~/ 7) + 1;
            tempMonthly[weekNum] = (tempMonthly[weekNum] ?? 0) + ml;
          }
        } catch (_) {}
      });

      // --- YEARLY DATA (per month summary) ---
      Map<int, double> tempYearly = {};
      for (int m = 1; m <= 12; m++) {
        tempYearly[m] = 0.0;
      }

      allHistory.forEach((dateStr, ml) {
        try {
          final date = DateTime.parse(dateStr);
          if (date.year == now.year) {
            tempYearly[date.month] = (tempYearly[date.month] ?? 0) + ml;
          }
        } catch (_) {}
      });

      setState(() {
        _weeklyData = tempWeekly;
        _monthlyData = tempMonthly;
        _yearlyData = tempYearly;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  double _toPercent(double ml) {
    if (_dailyGoal <= 0) return 0;
    return (ml / _dailyGoal * 100).clamp(0.0, 120.0);
  }

  String _shortDayLabel(String date) {
    final d = DateTime.parse(date);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[d.weekday - 1];
  }

  // Weekly stats
  double get _weeklyTotal =>
      _weeklyData.values.fold(0.0, (a, b) => a + b);

  double get _weeklyAverage {
    final nonZero = _weeklyData.values.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return 0;
    return nonZero.reduce((a, b) => a + b) / nonZero.length;
  }

  int get _daysGoalReached =>
      _weeklyData.values.where((ml) => ml >= _dailyGoal).length;

  // Monthly stats
  double get _monthlyTotal =>
      _monthlyData.values.fold(0.0, (a, b) => a + b);

  int get _weeksGoalReached => _monthlyData.values
      .where((ml) => ml >= _dailyGoal * 7)
      .length;

  // Yearly stats
  double get _yearlyTotal =>
      _yearlyData.values.fold(0.0, (a, b) => a + b);

  int get _monthsGoalReached => _yearlyData.values
      .where((ml) => ml >= _dailyGoal * 30)
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Hydration Progress",
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: "Weekly"),
            Tab(text: "Monthly"),
            Tab(text: "Yearly"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade800,
                        Colors.blue.shade600,
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWeeklyTab(),
                      _buildMonthlyTab(),
                      _buildYearlyTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // WEEKLY TAB
  // ============================================================
  Widget _buildWeeklyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // FIX: Today's real-time intake banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Today: ${_todayIntake.toInt()}ml / ${_dailyGoal.toInt()}ml",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "(${_toPercent(_todayIntake).toStringAsFixed(0)}%)",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stat Cards
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

          // Bar Chart
          _buildChartCard(
            title: "This Week's Intake",
            subtitle: "% of daily hydration goal per day",
            chart: _buildWeeklyBarChart(),
            legend: _buildLegendRow(),
            goalLabel:
                "100% = Daily Goal (${_dailyGoal.toInt()}ml)",
          ),

          const SizedBox(height: 20),

          // Daily Breakdown
          _buildWeeklyBreakdown(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================================================
  // MONTHLY TAB
  // ============================================================
  Widget _buildMonthlyTab() {
    String monthName =
        DateFormat('MMMM yyyy').format(DateTime.now());
    double weeklyGoal = _dailyGoal * 7;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          Center(
            child: Text(
              monthName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stat Cards
          Row(
            children: [
              _buildStatCard(
                label: "Monthly Total",
                value:
                    "${(_monthlyTotal / 1000).toStringAsFixed(1)}L",
                icon: Icons.water_drop_rounded,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                label: "Weekly Avg",
                value: _monthlyData.values.where((v) => v > 0).isEmpty
                    ? "0ml"
                    : "${(_monthlyTotal / _monthlyData.values.where((v) => v > 0).length / 1000).toStringAsFixed(1)}L",
                icon: Icons.show_chart_rounded,
                color: Colors.teal.shade600,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                label: "Goal Weeks",
                value: "$_weeksGoalReached/5 wks",
                icon: Icons.emoji_events_rounded,
                color: Colors.orange.shade700,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Monthly Bar Chart
          _buildChartCard(
            title: "Monthly Summary",
            subtitle: "Total water intake per week",
            chart: _buildMonthlyBarChart(weeklyGoal),
            legend: _buildLegendRow(),
            goalLabel:
                "Weekly Goal = ${(weeklyGoal / 1000).toStringAsFixed(1)}L",
          ),

          const SizedBox(height: 20),

          // Weekly Breakdown
          _buildMonthlyBreakdown(weeklyGoal),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================================================
  // YEARLY TAB
  // ============================================================
  Widget _buildYearlyTab() {
    String year = DateTime.now().year.toString();
    double monthlyGoal = _dailyGoal * 30;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          Center(
            child: Text(
              "Year $year",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stat Cards
          Row(
            children: [
              _buildStatCard(
                label: "Yearly Total",
                value:
                    "${(_yearlyTotal / 1000).toStringAsFixed(1)}L",
                icon: Icons.water_drop_rounded,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                label: "Monthly Avg",
                value: _yearlyData.values.where((v) => v > 0).isEmpty
                    ? "0L"
                    : "${(_yearlyTotal / _yearlyData.values.where((v) => v > 0).length / 1000).toStringAsFixed(1)}L",
                icon: Icons.show_chart_rounded,
                color: Colors.teal.shade600,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                label: "Goal Months",
                value: "$_monthsGoalReached/12 mo",
                icon: Icons.emoji_events_rounded,
                color: Colors.orange.shade700,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Yearly Bar Chart
          _buildChartCard(
            title: "Yearly Summary",
            subtitle: "Total water intake per month",
            chart: _buildYearlyBarChart(monthlyGoal),
            legend: _buildLegendRow(),
            goalLabel:
                "Monthly Goal ≈ ${(monthlyGoal / 1000).toStringAsFixed(1)}L",
          ),

          const SizedBox(height: 20),

          // Monthly Breakdown
          _buildYearlyBreakdown(monthlyGoal),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================================================
  // CHART BUILDERS
  // ============================================================

  Widget _buildWeeklyBarChart() {
    if (_weeklyTotal == 0) return _buildEmptyChart("No data recorded this week yet.");

    return BarChart(
      BarChartData(
        maxY: 120,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: value == 100
                ? Colors.green.shade300
                : Colors.grey.shade200,
            strokeWidth: value == 100 ? 1.5 : 1,
            dashArray: value == 100 ? [6, 4] : null,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blue.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String date = _weekDates[group.x];
              double ml = _weeklyData[date] ?? 0;
              bool isToday = date == _todayDate;
              return BarTooltipItem(
                "${_shortDayLabel(date)}${isToday ? ' (Today)' : ''}\n${ml.toInt()}ml\n${_toPercent(ml).toStringAsFixed(0)}%",
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
              _touchedIndex =
                  response?.spot?.touchedBarGroupIndex;
            });
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                "${value.toInt()}%",
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx < 0 || idx >= _weekDates.length) {
                  return const SizedBox();
                }
                String label = _shortDayLabel(_weekDates[idx]);
                bool isToday = _weekDates[idx] == _todayDate;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
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
        barGroups: List.generate(_weekDates.length, (i) {
          String date = _weekDates[i];
          double ml = _weeklyData[date] ?? 0;
          double pct = _toPercent(ml);
          bool isToday = date == _todayDate;
          bool isTouched = _touchedIndex == i;
          bool goalReached = ml >= _dailyGoal;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: pct,
                width: isTouched ? 26 : 22,
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: goalReached
                      ? [Colors.green.shade400, Colors.teal.shade300]
                      : isToday
                          ? [Colors.blue.shade600, Colors.lightBlue.shade300]
                          : [Colors.blue.shade300, Colors.blue.shade200],
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 120,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyBarChart(double weeklyGoal) {
    if (_monthlyTotal == 0) return _buildEmptyChart("No data recorded this month yet.");

    double maxVal = _monthlyData.values.isEmpty
        ? weeklyGoal * 1.2
        : (_monthlyData.values.reduce((a, b) => a > b ? a : b) * 1.2)
            .clamp(weeklyGoal * 1.2, double.infinity);

    return BarChart(
      BarChartData(
        maxY: maxVal,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: weeklyGoal / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: (value - weeklyGoal).abs() < 1
                ? Colors.green.shade300
                : Colors.grey.shade200,
            strokeWidth: (value - weeklyGoal).abs() < 1 ? 1.5 : 1,
            dashArray: (value - weeklyGoal).abs() < 1 ? [6, 4] : null,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blue.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              int week = group.x + 1;
              double ml = _monthlyData[week] ?? 0;
              return BarTooltipItem(
                "Week $week\n${(ml / 1000).toStringAsFixed(2)}L",
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
              _touchedIndex =
                  response?.spot?.touchedBarGroupIndex;
            });
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(
                "${(value / 1000).toStringAsFixed(1)}L",
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade500),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                int week = value.toInt() + 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Wk $week",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(5, (i) {
          int week = i + 1;
          double ml = _monthlyData[week] ?? 0;
          bool goalReached = ml >= weeklyGoal;
          bool isTouched = _touchedIndex == i;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: ml,
                width: isTouched ? 26 : 22,
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: goalReached
                      ? [Colors.green.shade400, Colors.teal.shade300]
                      : [Colors.blue.shade300, Colors.blue.shade200],
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildYearlyBarChart(double monthlyGoal) {
    if (_yearlyTotal == 0) return _buildEmptyChart("No data recorded this year yet.");

    const monthLabels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    double maxVal = _yearlyData.values.isEmpty
        ? monthlyGoal * 1.2
        : (_yearlyData.values.reduce((a, b) => a > b ? a : b) * 1.2)
            .clamp(monthlyGoal * 1.2, double.infinity);

    return BarChart(
      BarChartData(
        maxY: maxVal,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blue.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              int month = group.x + 1;
              double ml = _yearlyData[month] ?? 0;
              return BarTooltipItem(
                "${monthLabels[group.x]}\n${(ml / 1000).toStringAsFixed(2)}L",
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
              _touchedIndex =
                  response?.spot?.touchedBarGroupIndex;
            });
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(
                "${(value / 1000).toStringAsFixed(1)}L",
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade500),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx < 0 || idx >= 12) return const SizedBox();
                bool isCurrentMonth = idx + 1 == DateTime.now().month;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    monthLabels[idx],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrentMonth
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrentMonth
                          ? Colors.blue.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(12, (i) {
          int month = i + 1;
          double ml = _yearlyData[month] ?? 0;
          bool goalReached = ml >= monthlyGoal;
          bool isCurrent = month == DateTime.now().month;
          bool isTouched = _touchedIndex == i;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: ml,
                width: isTouched ? 18 : 14,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: goalReached
                      ? [Colors.green.shade400, Colors.teal.shade300]
                      : isCurrent
                          ? [Colors.blue.shade600, Colors.lightBlue.shade300]
                          : [Colors.blue.shade300, Colors.blue.shade200],
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ============================================================
  // BREAKDOWN LISTS
  // ============================================================

  Widget _buildWeeklyBreakdown() {
    return _buildBreakdownCard(
      title: "Daily Breakdown",
      children: List.generate(_weekDates.length, (i) {
        String date = _weekDates[i];
        double ml = _weeklyData[date] ?? 0;
        double pct = _toPercent(ml);
        bool goalReached = ml >= _dailyGoal;
        bool isToday = date == _todayDate;
        String dayLabel = _shortDayLabel(date);

        return _buildBreakdownRow(
          label: dayLabel + (isToday ? " •" : ""),
          ml: ml,
          percent: pct / 100,
          goalReached: goalReached,
          isHighlight: isToday,
          trailing: isToday ? "(Live)" : null,
        );
      }),
    );
  }

  Widget _buildMonthlyBreakdown(double weeklyGoal) {
    return _buildBreakdownCard(
      title: "Weekly Breakdown",
      children: List.generate(5, (i) {
        int week = i + 1;
        double ml = _monthlyData[week] ?? 0;
        bool goalReached = ml >= weeklyGoal;
        double percent = weeklyGoal > 0
            ? (ml / weeklyGoal).clamp(0.0, 1.0)
            : 0.0;

        return _buildBreakdownRow(
          label: "Week $week",
          ml: ml,
          percent: percent,
          goalReached: goalReached,
          isHighlight: false,
          isLiters: true,
        );
      }),
    );
  }

  Widget _buildYearlyBreakdown(double monthlyGoal) {
    const monthNames = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];

    return _buildBreakdownCard(
      title: "Monthly Breakdown",
      children: List.generate(12, (i) {
        int month = i + 1;
        double ml = _yearlyData[month] ?? 0;
        bool goalReached = ml >= monthlyGoal;
        double percent = monthlyGoal > 0
            ? (ml / monthlyGoal).clamp(0.0, 1.0)
            : 0.0;
        bool isCurrent = month == DateTime.now().month;

        return _buildBreakdownRow(
          label: monthNames[i],
          ml: ml,
          percent: percent,
          goalReached: goalReached,
          isHighlight: isCurrent,
          isLiters: true,
        );
      }),
    );
  }

  // ============================================================
  // REUSABLE WIDGETS
  // ============================================================

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget chart,
    required Widget legend,
    required String goalLabel,
  }) {
    return Container(
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
                title,
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
            subtitle,
            style:
                TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 260, child: chart),
          const SizedBox(height: 16),
          legend,
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
                goalLabel,
                style: TextStyle(
                    fontSize: 11, color: Colors.green.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required double ml,
    required double percent,
    required bool goalReached,
    required bool isHighlight,
    String? trailing,
    bool isLiters = false,
  }) {
    String valueText = ml > 0
        ? isLiters
            ? "${(ml / 1000).toStringAsFixed(2)}L"
            : "${ml.toInt()}ml"
        : "—";

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: isLiters ? 70 : 46,
            child: Text(
              label,
              style: TextStyle(
                fontWeight:
                    isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight
                    ? Colors.blue.shade700
                    : Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 10,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
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
              valueText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: goalReached
                    ? Colors.teal.shade600
                    : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade400,
                fontStyle: FontStyle.italic,
              ),
            )
          else if (goalReached)
            Icon(Icons.check_circle_rounded,
                color: Colors.teal.shade400, size: 18)
          else
            const SizedBox(width: 18),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop_outlined,
              size: 48, color: Colors.blue.shade200),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
                color: Colors.grey.shade400, fontSize: 13),
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
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blue.shade400, "Current"),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.teal.shade300, "Goal Reached"),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.grey.shade300, "No Data"),
      ],
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
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}