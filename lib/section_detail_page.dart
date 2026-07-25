import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class SectionDetailPage extends StatefulWidget {
  final String sectionName;
  final String courseCode;
  final Color courseColor;

  const SectionDetailPage({
    super.key,
    required this.sectionName,
    required this.courseCode,
    required this.courseColor,
  });

  @override
  State<SectionDetailPage> createState() => _SectionDetailPageState();
}

class _SectionDetailPageState extends State<SectionDetailPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Last 7 days
  List<DateTime> last7Days = List.generate(
    7, (i) => DateTime.now().subtract(Duration(days: 6 - i))
  );

  @override
  Widget build(BuildContext context) {
    List<String> formattedDays = last7Days
        .map((d) => DateFormat('yyyy-MM-dd').format(d))
        .toList();
    List<String> labelDays = last7Days
        .map((d) => DateFormat('E').format(d))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: Text(
          "${widget.sectionName} - Details",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      // OUTER StreamBuilder: Fetch users para makuha ang year per psu_id
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.child('users').onValue,
        builder: (context, usersSnapshot) {

          // Build map: { psu_id: year }
          Map<String, String> usersYearMap = {};
          if (usersSnapshot.hasData && usersSnapshot.data!.snapshot.value != null) {
            final usersData = usersSnapshot.data!.snapshot.value as Map;
            usersData.forEach((uid, userData) {
              if (userData is Map) {
                String psuId = userData['psu_id']?.toString() ?? "";
                String year = userData['year']?.toString() ?? "";
                if (psuId.isNotEmpty) {
                  usersYearMap[psuId] = year;
                }
              }
            });
          }

          // INNER StreamBuilder: Fetch dispense_logs
          return StreamBuilder<DatabaseEvent>(
            stream: _dbRef.child('dispense_logs').onValue,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Center(child: CircularProgressIndicator());
              }

              // Data holders
              Map<String, double> dailyData = {for (var d in formattedDays) d: 0.0};
              Map<String, int> dailyCount = {for (var d in formattedDays) d: 0};
              Set<String> uniqueUsers = {};
              double totalLiters = 0.0;
              int totalDispenses = 0;

              // Key: psu_id, Value: {liters, year}
              Map<String, Map<String, dynamic>> userIntake = {};

              final dynamic rawData = snapshot.data!.snapshot.value;
              if (rawData is Map) {
                rawData.forEach((key, value) {
                  if (value is Map) {
                    String timestamp = value['timestamp']?.toString() ?? "";
                    String fullCourse = value['course']?.toString() ?? "";
                    String section = value['section']?.toString() ?? "";
                    String year = value['year']?.toString() ?? "";
                    String psuId = value['psu_id']?.toString() ?? "Unknown";

                    // FIX: Kunin ang year sa users node gamit ang psu_id
                    String studentYear = usersYearMap[psuId] ?? year;

                    String courseCode = _getCourseCode(fullCourse);
                    String sectionKey = "$courseCode ${year.replaceAll(' Year', '')} - $section".trim();

                    if (sectionKey == widget.sectionName) {
                      double ml = double.tryParse(
                        value['amount_ml']?.toString() ??
                        value['amount']?.toString() ?? "0"
                      ) ?? 0.0;
                      double liters = ml / 1000.0;

                      // Daily data for line chart
                      String dateKey = timestamp.split(' ').first;
                      if (dailyData.containsKey(dateKey)) {
                        dailyData[dateKey] = (dailyData[dateKey] ?? 0) + liters;
                        dailyCount[dateKey] = (dailyCount[dateKey] ?? 0) + 1;
                      }

                      totalLiters += liters;
                      totalDispenses++;
                      uniqueUsers.add(psuId);

                      // Store intake with year info
                      if (!userIntake.containsKey(psuId)) {
                        userIntake[psuId] = {'liters': 0.0, 'year': studentYear};
                      }
                      userIntake[psuId]!['liters'] = 
                          (userIntake[psuId]!['liters'] as double) + liters;
                    }
                  }
                });
              }

              // Sort by liters (highest first)
              var sortedUsers = userIntake.entries.toList()
                ..sort((a, b) => (b.value['liters'] as double)
                    .compareTo(a.value['liters'] as double));

              // Build line chart spots
              List<FlSpot> spots = [];
              double maxY = 1.0;
              for (int i = 0; i < formattedDays.length; i++) {
                double val = dailyData[formattedDays[i]] ?? 0.0;
                spots.add(FlSpot(i.toDouble(), val));
                if (val > maxY) maxY = val;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // --- SUMMARY CARDS ---
                    Row(
                      children: [
                        _buildSummaryCard(
                          "Total Dispensed",
                          "${totalLiters.toStringAsFixed(2)} L",
                          Icons.water_drop,
                          Colors.blue,
                        ),
                        const SizedBox(width: 15),
                        _buildSummaryCard(
                          "Total Dispenses",
                          "$totalDispenses times",
                          Icons.repeat,
                          Colors.green,
                        ),
                        const SizedBox(width: 15),
                        _buildSummaryCard(
                          "Unique Students",
                          "${uniqueUsers.length} students",
                          Icons.people,
                          Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- WEEKLY LINE CHART ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.sectionName} - Weekly Tracker",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Text(
                            "Water volume (Liters) consumed for the last 7 days",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey.withOpacity(0.15),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) => Text(
                                        '${value.toStringAsFixed(1)}L',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        int index = value.toInt();
                                        if (index >= 0 && index < labelDays.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              labelDays[index],
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: 6,
                                minY: 0,
                                maxY: maxY + 0.5,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    color: widget.courseColor,
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: widget.courseColor.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Daily count below chart
                          const SizedBox(height: 16),
                          const Divider(),
                          const Text(
                            "Daily Dispense Count",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(7, (i) {
                              int count = dailyCount[formattedDays[i]] ?? 0;
                              return Column(
                                children: [
                                  Text(
                                    "$count",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: count > 0
                                          ? widget.courseColor
                                          : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    labelDays[i],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- STUDENT LEADERBOARD ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Student Hydration Leaderboard",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Text(
                            "Ranked by total water intake this month",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),

                          if (sortedUsers.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  "No student data available.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedUsers.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                String psuId = sortedUsers[index].key;
                                double liters = sortedUsers[index].value['liters'] as double;
                                String studentYear = sortedUsers[index].value['year'] as String;

                                // Rank icons
                                Widget rankWidget;
                                if (index == 0) {
                                  rankWidget = const Text("🥇", style: TextStyle(fontSize: 20));
                                } else if (index == 1) {
                                  rankWidget = const Text("🥈", style: TextStyle(fontSize: 20));
                                } else if (index == 2) {
                                  rankWidget = const Text("🥉", style: TextStyle(fontSize: 20));
                                } else {
                                  rankWidget = Text(
                                    "${index + 1}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  );
                                }

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: SizedBox(
                                    width: 30,
                                    child: Center(child: rankWidget),
                                  ),
                                  title: Text(
                                    psuId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    studentYear.isNotEmpty
                                        ? studentYear
                                        : "Year not available",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: Text(
                                    "${liters.toStringAsFixed(2)} L",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.courseColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ); // end dispense_logs StreamBuilder
        },
      ), // end users StreamBuilder
    );
  }

  // Summary Card Widget
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Course code helper
  String _getCourseCode(String fullCourse) {
    if (fullCourse.contains("Information Technology")) return "BSIT";
    if (fullCourse.contains("Business Administration")) return "BSBA";
    if (fullCourse.contains("Hospitality Management")) return "BSHM";
    if (fullCourse.contains("Education")) return "BSED";
    if (fullCourse.contains("Civil Engineering")) return "BSCE";
    if (fullCourse.contains("Tourism Management")) return "BSTM";
    if (fullCourse.contains("Elementary Education")) return "BEED";
    if (fullCourse.contains("Psychology")) return "BSPSY";
    if (fullCourse.contains("Entrepreneurship")) return "BSENT";
    if (fullCourse.isEmpty) return "Others";
    return fullCourse;
  }
}