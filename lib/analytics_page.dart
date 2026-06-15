import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'student_analytics_section.dart';
import 'weekly_consumption_page.dart'; // Bagong full-page ng Weekly Chart

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference dbLogsRef = FirebaseDatabase.instance.ref('dispense_logs');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder(
          stream: dbLogsRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> logsSnapshot) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER SECTION
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Analytics & Reports",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Real-time campus hydration monitoring and consumption visualization",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 2. STUDENT HYDRATION ANALYTICS (Pangunahing content)
                if (logsSnapshot.hasData && logsSnapshot.data!.snapshot.value != null)
                  StudentAnalyticsSection(
                    logsData: logsSnapshot.data!.snapshot.value as Map<dynamic, dynamic>,
                  ),

                const SizedBox(height: 25),

                // 3. WEEKLY CONSUMPTION PREVIEW CARD (Nag-navigate sa full page)
                _WeeklyConsumptionPreviewCard(logsSnapshot: logsSnapshot),

                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PREVIEW CARD — Summary ng weekly data, click → WeeklyConsumptionPage
// ---------------------------------------------------------------------------
class _WeeklyConsumptionPreviewCard extends StatelessWidget {
  final AsyncSnapshot<DatabaseEvent> logsSnapshot;

  const _WeeklyConsumptionPreviewCard({required this.logsSnapshot});

  /// Kinukuha ang total liters ngayong linggo para sa quick summary
  Map<String, double> _computeDailyTotals() {
    Map<String, double> dailyTotals = {
      "Mon": 0, "Tue": 0, "Wed": 0, "Thu": 0, "Fri": 0, "Sat": 0, "Sun": 0,
    };

    if (logsSnapshot.hasData && logsSnapshot.data!.snapshot.value != null) {
      Map<dynamic, dynamic> logs =
          logsSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;

      DateTime ngayon = DateTime.now();
      DateTime ngayonDito = DateTime(ngayon.year, ngayon.month, ngayon.day);
      int arawMulaLunes = ngayonDito.weekday - DateTime.monday;
      DateTime simulaNgLinggo = ngayonDito.subtract(Duration(days: arawMulaLunes));

      logs.forEach((key, value) {
        if (value is Map &&
            value.containsKey('timestamp') &&
            value.containsKey('amount_ml')) {
          try {
            DateTime logDate = DateTime.parse(value['timestamp'] ?? '');
            if (logDate.isAfter(simulaNgLinggo.subtract(const Duration(seconds: 1)))) {
              double liters = (value['amount_ml'] ?? 0) / 1000.0;
              const dayMap = {1: "Mon", 2: "Tue", 3: "Wed", 4: "Thu", 5: "Fri", 6: "Sat", 7: "Sun"};
              String? dayKey = dayMap[logDate.weekday];
              if (dayKey != null) {
                dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + liters;
              }
            }
          } catch (_) {}
        }
      });
    }

    return dailyTotals;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> dailyTotals = _computeDailyTotals();
    final double weeklyTotal = dailyTotals.values.fold(0.0, (a, b) => a + b);

    // Pinakamataas na araw ngayong linggo
    String peakDay = "—";
    double peakVal = 0;
    dailyTotals.forEach((day, val) {
      if (val > peakVal) {
        peakVal = val;
        peakDay = day;
      }
    });

    final List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WeeklyConsumptionPage()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Card Header ---
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, color: Color(0xFF3B82F6), size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Weekly Water Consumption Volume",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          "This week's total liters dispensed across all units",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF3B82F6), size: 14),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // --- Quick Stats Row ---
              Row(
                children: [
                  _StatChip(
                    label: "Weekly Total",
                    value: "${weeklyTotal.toStringAsFixed(1)} L",
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: "Peak Day",
                    value: peakVal > 0 ? "$peakDay (${peakVal.toStringAsFixed(1)}L)" : "—",
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Mini Bar Indicators (Day breakdown) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: days.map((day) {
                  double val = dailyTotals[day] ?? 0;
                  double maxVal = dailyTotals.values.fold(0.0, (a, b) => a > b ? a : b);
                  double barHeight = maxVal > 0 ? (val / maxVal) * 48 : 4;

                  bool isToday = days[DateTime.now().weekday - 1] == day;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 28,
                        height: barHeight.clamp(4.0, 48.0),
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF3B82F6).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? const Color(0xFF1E293B) : Colors.grey,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // --- View Full Chart CTA ---
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "View Full Chart",
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF3B82F6), size: 13),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HELPER WIDGET — Quick stat chip
// ---------------------------------------------------------------------------
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}