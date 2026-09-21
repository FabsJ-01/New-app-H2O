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

                // 3. DYNAMIC CONSUMPTION PREVIEW CARD (Weekly / Monthly / Yearly)
                _ConsumptionPreviewCard(logsSnapshot: logsSnapshot),

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
// DYNAMIC PREVIEW CARD — Weekly / Monthly / Yearly Toggle
// ---------------------------------------------------------------------------
class _ConsumptionPreviewCard extends StatefulWidget {
  final AsyncSnapshot<DatabaseEvent> logsSnapshot;

  const _ConsumptionPreviewCard({required this.logsSnapshot});

  @override
  State<_ConsumptionPreviewCard> createState() => _ConsumptionPreviewCardState();
}

class _ConsumptionPreviewCardState extends State<_ConsumptionPreviewCard> {
  String _selectedTimeframe = 'Weekly'; // Options: 'Weekly', 'Monthly', 'Yearly'

  /// Compute totals base sa napiling timeframe
  Map<String, double> _computeTotals() {
    Map<String, double> totals = {};

    if (_selectedTimeframe == 'Weekly') {
      totals = {"Mon": 0, "Tue": 0, "Wed": 0, "Thu": 0, "Fri": 0, "Sat": 0, "Sun": 0};
    } else if (_selectedTimeframe == 'Monthly') {
      totals = {
        "Jan": 0, "Feb": 0, "Mar": 0, "Apr": 0, "May": 0, "Jun": 0,
        "Jul": 0, "Aug": 0, "Sep": 0, "Oct": 0, "Nov": 0, "Dec": 0
      };
    } else {
      // Yearly defaults (3 latest years)
      int currentYear = DateTime.now().year;
      totals = {
        "${currentYear - 2}": 0,
        "${currentYear - 1}": 0,
        "$currentYear": 0,
      };
    }

    if (widget.logsSnapshot.hasData && widget.logsSnapshot.data!.snapshot.value != null) {
      Map<dynamic, dynamic> logs =
          widget.logsSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;

      DateTime ngayon = DateTime.now();

      logs.forEach((key, value) {
        if (value is Map &&
            value.containsKey('timestamp') &&
            value.containsKey('amount_ml')) {
          try {
            DateTime logDate = DateTime.parse(value['timestamp'] ?? '');
            double liters = (value['amount_ml'] ?? 0) / 1000.0;

            if (_selectedTimeframe == 'Weekly') {
              DateTime ngayonDito = DateTime(ngayon.year, ngayon.month, ngayon.day);
              int arawMulaLunes = ngayonDito.weekday - DateTime.monday;
              DateTime simulaNgLinggo = ngayonDito.subtract(Duration(days: arawMulaLunes));

              if (logDate.isAfter(simulaNgLinggo.subtract(const Duration(seconds: 1)))) {
                const dayMap = {1: "Mon", 2: "Tue", 3: "Wed", 4: "Thu", 5: "Fri", 6: "Sat", 7: "Sun"};
                String? dayKey = dayMap[logDate.weekday];
                if (dayKey != null) {
                  totals[dayKey] = (totals[dayKey] ?? 0) + liters;
                }
              }
            } else if (_selectedTimeframe == 'Monthly') {
              if (logDate.year == ngayon.year) {
                const monthMap = {
                  1: "Jan", 2: "Feb", 3: "Mar", 4: "Apr", 5: "May", 6: "Jun",
                  7: "Jul", 8: "Aug", 9: "Sep", 10: "Oct", 11: "Nov", 12: "Dec"
                };
                String? monthKey = monthMap[logDate.month];
                if (monthKey != null) {
                  totals[monthKey] = (totals[monthKey] ?? 0) + liters;
                }
              }
            } else if (_selectedTimeframe == 'Yearly') {
              String yearKey = logDate.year.toString();
              if (totals.containsKey(yearKey)) {
                totals[yearKey] = (totals[yearKey] ?? 0) + liters;
              }
            }
          } catch (_) {}
        }
      });
    }

    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = _computeTotals();
    final double totalLiters = totals.values.fold(0.0, (a, b) => a + b);

    // Peak computation
    String peakPeriod = "—";
    double peakVal = 0;
    totals.forEach((key, val) {
      if (val > peakVal) {
        peakVal = val;
        peakPeriod = key;
      }
    });

    String peakLabel = _selectedTimeframe == 'Weekly'
        ? 'Peak Day'
        : (_selectedTimeframe == 'Monthly' ? 'Peak Month' : 'Peak Year');

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
              // --- Card Header + Timeframe Toggle ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.bar_chart_rounded, color: Color(0xFF3B82F6), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$_selectedTimeframe Water Consumption Volume",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          "This ${_selectedTimeframe.toLowerCase()}'s total liters dispensed across all units",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Timeframe Switcher Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTimeframe,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF3B82F6)),
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedTimeframe = newValue;
                            });
                          }
                        },
                        items: <String>['Weekly', 'Monthly', 'Yearly']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // --- Quick Stats Row ---
              Row(
                children: [
                  _StatChip(
                    label: "$_selectedTimeframe Total",
                    value: "${totalLiters.toStringAsFixed(1)} L",
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: peakLabel,
                    value: peakVal > 0 ? "$peakPeriod (${peakVal.toStringAsFixed(1)}L)" : "—",
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Dynamic Mini Bar Indicators ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: totals.keys.map((key) {
                    double val = totals[key] ?? 0;
                    double maxVal = totals.values.fold(0.0, (a, b) => a > b ? a : b);
                    double barHeight = maxVal > 0 ? (val / maxVal) * 48 : 4;

                    bool isCurrent = false;
                    if (_selectedTimeframe == 'Weekly') {
                      isCurrent = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][DateTime.now().weekday - 1] == key;
                    } else if (_selectedTimeframe == 'Monthly') {
                      isCurrent = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][DateTime.now().month - 1] == key;
                    } else {
                      isCurrent = DateTime.now().year.toString() == key;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: _selectedTimeframe == 'Monthly' ? 18 : 28,
                            height: barHeight.clamp(4.0, 48.0),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF3B82F6).withOpacity(0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            key,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? const Color(0xFF1E293B) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
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