import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'student_analytics_section.dart';
import 'weekly_consumption_page.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference dbLogsRef = FirebaseDatabase.instance.ref('dispense_logs');
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: StreamBuilder(
          stream: dbLogsRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> logsSnapshot) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER SECTION
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Analytics & Reports",
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Real-time campus hydration monitoring and consumption visualization",
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. STUDENT HYDRATION ANALYTICS
                if (logsSnapshot.hasData && logsSnapshot.data!.snapshot.value != null)
                  StudentAnalyticsSection(
                    logsData: logsSnapshot.data!.snapshot.value as Map<dynamic, dynamic>,
                  ),

                const SizedBox(height: 24),

                // 3. RESPONSIVE CONSUMPTION PREVIEW CARD
                _ConsumptionPreviewCard(logsSnapshot: logsSnapshot),

                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DYNAMIC PREVIEW CARD — Fully Responsive & Type-Safe
// ---------------------------------------------------------------------------
class _ConsumptionPreviewCard extends StatefulWidget {
  final AsyncSnapshot<DatabaseEvent> logsSnapshot;

  const _ConsumptionPreviewCard({required this.logsSnapshot});

  @override
  State<_ConsumptionPreviewCard> createState() => _ConsumptionPreviewCardState();
}

class _ConsumptionPreviewCardState extends State<_ConsumptionPreviewCard> {
  String _selectedTimeframe = 'Weekly';

  Map<String, double> _computeTotals() {
    Map<String, double> totals = {};

    if (_selectedTimeframe == 'Weekly') {
      totals = {"Mon": 0.0, "Tue": 0.0, "Wed": 0.0, "Thu": 0.0, "Fri": 0.0, "Sat": 0.0, "Sun": 0.0};
    } else if (_selectedTimeframe == 'Monthly') {
      totals = {
        "Jan": 0.0, "Feb": 0.0, "Mar": 0.0, "Apr": 0.0, "May": 0.0, "Jun": 0.0,
        "Jul": 0.0, "Aug": 0.0, "Sep": 0.0, "Oct": 0.0, "Nov": 0.0, "Dec": 0.0
      };
    } else {
      int currentYear = DateTime.now().year;
      totals = {
        "${currentYear - 2}": 0.0,
        "${currentYear - 1}": 0.0,
        "$currentYear": 0.0,
      };
    }

    if (widget.logsSnapshot.hasData && widget.logsSnapshot.data!.snapshot.value != null) {
      final rawData = widget.logsSnapshot.data!.snapshot.value;

      if (rawData is Map) {
        DateTime ngayon = DateTime.now();

        rawData.forEach((key, value) {
          if (value is Map) {
            // SAFE AMOUNT_ML PARSING
            double amountMl = 0.0;
            dynamic rawAmount = value['amount_ml'];
            if (rawAmount is num) {
              amountMl = rawAmount.toDouble();
            } else if (rawAmount != null) {
              amountMl = double.tryParse(rawAmount.toString()) ?? 0.0;
            }

            // SAFE TIMESTAMP PARSING
            dynamic rawTimestamp = value['timestamp'];
            DateTime? logDate;
            if (rawTimestamp is int) {
              logDate = DateTime.fromMillisecondsSinceEpoch(rawTimestamp).toLocal();
            } else if (rawTimestamp is num) {
              logDate = DateTime.fromMillisecondsSinceEpoch(rawTimestamp.toInt()).toLocal();
            } else if (rawTimestamp is String) {
              logDate = DateTime.tryParse(rawTimestamp)?.toLocal();
              if (logDate == null) {
                int? parsedInt = int.tryParse(rawTimestamp);
                if (parsedInt != null) {
                  logDate = DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
                }
              }
            }

            if (logDate == null) return;

            double liters = amountMl / 1000.0;

            if (_selectedTimeframe == 'Weekly') {
              DateTime ngayonDito = DateTime(ngayon.year, ngayon.month, ngayon.day);
              int arawMulaLunes = ngayonDito.weekday - DateTime.monday;
              DateTime simulaNgLinggo = ngayonDito.subtract(Duration(days: arawMulaLunes));
              DateTime katapusanNgLinggo = simulaNgLinggo.add(const Duration(days: 7));

              if (logDate.isAfter(simulaNgLinggo.subtract(const Duration(seconds: 1))) &&
                  logDate.isBefore(katapusanNgLinggo)) {
                const dayMap = {1: "Mon", 2: "Tue", 3: "Wed", 4: "Thu", 5: "Fri", 6: "Sat", 7: "Sun"};
                String? dayKey = dayMap[logDate.weekday];
                if (dayKey != null && totals.containsKey(dayKey)) {
                  totals[dayKey] = (totals[dayKey] ?? 0.0) + liters;
                }
              }
            } else if (_selectedTimeframe == 'Monthly') {
              if (logDate.year == ngayon.year) {
                const monthMap = {
                  1: "Jan", 2: "Feb", 3: "Mar", 4: "Apr", 5: "May", 6: "Jun",
                  7: "Jul", 8: "Aug", 9: "Sep", 10: "Oct", 11: "Nov", 12: "Dec"
                };
                String? monthKey = monthMap[logDate.month];
                if (monthKey != null && totals.containsKey(monthKey)) {
                  totals[monthKey] = (totals[monthKey] ?? 0.0) + liters;
                }
              }
            } else if (_selectedTimeframe == 'Yearly') {
              String yearKey = logDate.year.toString();
              if (totals.containsKey(yearKey)) {
                totals[yearKey] = (totals[yearKey] ?? 0.0) + liters;
              }
            }
          }
        });
      }
    }

    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = _computeTotals();
    final double totalLiters = totals.values.fold(0.0, (a, b) => a + b);

    String peakPeriod = "—";
    double peakVal = 0.0;
    totals.forEach((key, val) {
      if (val > peakVal) {
        peakVal = val;
        peakPeriod = key;
      }
    });

    String peakLabel = _selectedTimeframe == 'Weekly'
        ? 'Peak Day'
        : (_selectedTimeframe == 'Monthly' ? 'Peak Month' : 'Peak Year');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeeklyConsumptionPage()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isCompact = constraints.maxWidth < 600;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- RESPONSIVE HEADER ---
                    if (isCompact) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "$_selectedTimeframe Water Consumption Volume",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Liters dispensed across all units",
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildTimeframeDropdown(),
                        ],
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$_selectedTimeframe Water Consumption Volume",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  "This ${_selectedTimeframe.toLowerCase()}'s total liters dispensed across all units",
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          _buildTimeframeDropdown(),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // --- RESPONSIVE QUICK STATS ROW ---
                    LayoutBuilder(
                      builder: (context, chipConstraints) {
                        double availableWidth = chipConstraints.maxWidth;
                        double chipWidth = availableWidth < 480
                            ? (availableWidth - 12) / 2
                            : 180;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: chipWidth,
                              child: _StatChip(
                                label: "$_selectedTimeframe Total",
                                value: "${totalLiters.toStringAsFixed(1)} L",
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            SizedBox(
                              width: chipWidth,
                              child: _StatChip(
                                label: peakLabel,
                                value: peakVal > 0 ? "$peakPeriod (${peakVal.toStringAsFixed(1)}L)" : "—",
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- DYNAMIC MINI BAR INDICATORS ---
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: totals.keys.map((key) {
                            double val = totals[key] ?? 0.0;
                            double maxVal = totals.values.fold(0.0, (a, b) => a > b ? a : b);
                            double barHeight = maxVal > 0 ? (val / maxVal) * 44 : 4;

                            bool isCurrent = false;
                            if (_selectedTimeframe == 'Weekly') {
                              isCurrent = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][DateTime.now().weekday - 1] == key;
                            } else if (_selectedTimeframe == 'Monthly') {
                              isCurrent = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][DateTime.now().month - 1] == key;
                            } else {
                              isCurrent = DateTime.now().year.toString() == key;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: _selectedTimeframe == 'Monthly' ? 14 : 22,
                                    height: barHeight.clamp(4.0, 44.0),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF2563EB).withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    key,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      color: isCurrent ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- VIEW FULL CHART CTA ---
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "View Full Chart",
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF2563EB), size: 12),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeframe,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB), size: 16),
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
            fontSize: 11,
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
    );
  }
}

// ---------------------------------------------------------------------------
// HELPER WIDGET — Stat chip
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}