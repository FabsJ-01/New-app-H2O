import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class LeaderboardDetailPage extends StatefulWidget {
  const LeaderboardDetailPage({super.key});

  @override
  State<LeaderboardDetailPage> createState() => _LeaderboardDetailPageState();
}

class _LeaderboardDetailPageState extends State<LeaderboardDetailPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  int touchedIndex = -1;
  String? _selectedCourse; 

  // COLOR MAPPING PER COURSE
  Color getCourseColor(String course) {
    switch (course.toUpperCase()) {
      case 'BSIT': 
        return Colors.grey;
      case 'BSPSY':
        return const Color.fromARGB(255, 246, 248, 246);
        case 'BSED': 
        return Colors.red;
      case 'BSBA': 
        return Colors.blue;
      case 'BSCE': 
        return const Color.fromARGB(255, 67, 67, 67);
      case 'BSHM': 
        return Colors.green;
        case 'BSTM': 
        return const Color.fromARGB(255, 178, 69, 167);
      case 'BSEE': 
        return Colors.deepPurple;
      case 'BEED': 
        return Colors.orange;
      default: 
        return const Color.fromARGB(255, 0, 0, 0); 
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    var mediaQuery = MediaQuery.of(context);
    bool isWideScreen = mediaQuery.size.width > 800;

    // Kunin ang mga petsa para sa huling 7 araw (Daily Weekly Tracker)
    List<DateTime> last7Days = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    List<String> formattedDays = last7Days.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();
    List<String> labelDays = last7Days.map((d) => DateFormat('E').format(d)).toList(); // E.g., Mon, Tue...

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: const Text(
          "Monthly Hydration Analytics", 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.child('dispense_logs').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Data holders
          Map<String, double> courseTotals = {};
          Map<String, Map<String, double>> sectionTotalsPerCourse = {};
          
          // Map para sa Line Chart: {'yyyy-MM-dd': totalLiters}
          Map<String, double> dailyWeeklyData = { for (var v in formattedDays) v : 0.0 };

          final dynamic rawData = snapshot.data!.snapshot.value;
          if (rawData is Map) {
            rawData.forEach((key, value) {
              if (value is Map) {
                String timestamp = value['timestamp']?.toString() ?? "";
                
                // 1. Month Check para sa Pie Chart at Section Breakdown
                if (timestamp.startsWith(currentMonth)) {
                  String fullCourse = value['course']?.toString() ?? "Others";
                  String section = value['section']?.toString() ?? "Unknown Section";
                  String year = value['year']?.toString() ?? "";

                  String courseCode = fullCourse;
                  if (fullCourse.contains("Information Technology")) courseCode = "BSIT";
                  else if (fullCourse.contains("Business Administration")) courseCode = "BSBA";
                  else if (fullCourse.contains("Hospitality Management")) courseCode = "BSHM";
                  else if (fullCourse.contains("Education")) courseCode = "BSED";
                  else if (fullCourse.contains("Civil Engineering")) courseCode = "BSCE";
                   else if (fullCourse.contains("Civil Engineering")) courseCode = "BSCE";
                   else if (fullCourse.contains("Tourism Management")) courseCode = "BSTM";
                   else if (fullCourse.contains("Electrical Engineering")) courseCode = "BSEE";
                   else if (fullCourse.contains("Elementary Education")) courseCode = "BEED";
                   else if (fullCourse.contains("Psychology")) courseCode = "BSPSY";
                  else if (fullCourse.isEmpty) courseCode = "Others";

                  double ml = double.tryParse(value['amount_ml']?.toString() ?? 
                              value['amount']?.toString() ?? "0") ?? 0.0;
                  double liters = ml / 1000.0;

                  courseTotals[courseCode] = (courseTotals[courseCode] ?? 0) + liters;

                  String sectionKey = "$courseCode ${year.replaceAll(' Year', '')} - $section".trim();
                  if (!sectionTotalsPerCourse.containsKey(courseCode)) {
                    sectionTotalsPerCourse[courseCode] = {};
                  }
                  sectionTotalsPerCourse[courseCode]![sectionKey] = 
                      (sectionTotalsPerCourse[courseCode]![sectionKey] ?? 0) + liters;
                }

                // 2. Lingguhang Araw Check para sa Line Graph (Filtered sa Selected Course kung mayroon)
                String dateKey = timestamp.split(' ').first; // Kukunin ang 'yyyy-MM-dd' part
                if (dailyWeeklyData.containsKey(dateKey)) {
                  String fullCourse = value['course']?.toString() ?? "Others";
                  String courseCode = fullCourse;
                  if (fullCourse.contains("Information Technology")) courseCode = "BSIT";
                  else if (fullCourse.contains("Business Administration")) courseCode = "BSBA";
                  else if (fullCourse.contains("Hospitality Management")) courseCode = "BSHM";
                  else if (fullCourse.contains("Education")) courseCode = "BSED";
                  else if (fullCourse.contains("Civil Engineering")) courseCode = "BSCE";
                  else if (fullCourse.contains("Civil Engineering")) courseCode = "BSCE";
                  else if (fullCourse.contains("Tourism Management")) courseCode = "BSTM";
                  else if (fullCourse.contains("Electrical Engineering")) courseCode = "BSEE";
                  else if (fullCourse.contains("Elementary Education")) courseCode = "BEED";
                  else if (fullCourse.contains("Psychology")) courseCode = "BSPSY";
                  else if (fullCourse.isEmpty) courseCode = "Others"; 

                  double ml = double.tryParse(value['amount_ml']?.toString() ?? 
                              value['amount']?.toString() ?? "0") ?? 0.0;

                  // Kung walang napiling kurso, ipakita lahat. Kung mayroon, salain ang napili lang.
                  if (_selectedCourse == null || _selectedCourse == courseCode) {
                    dailyWeeklyData[dateKey] = (dailyWeeklyData[dateKey] ?? 0.0) + (ml / 1000.0);
                  }
                }
              }
            });
          }

          courseTotals.removeWhere((key, value) => value <= 0);

          if (courseTotals.isEmpty) {
            return const Center(
              child: Text(
                "No data recorded for this month yet.",
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            );
          }

          final List<String> courseKeys = courseTotals.keys.toList();

          // Responsive Layout Builder
          Widget mainLayout = isWideScreen 
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _buildPieChartCard(courseTotals, courseKeys)),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3, 
                    child: _buildSidePanel(courseTotals, sectionTotalsPerCourse, formattedDays, labelDays, dailyWeeklyData),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildPieChartCard(courseTotals, courseKeys),
                  const SizedBox(height: 20),
                  _buildSidePanel(courseTotals, sectionTotalsPerCourse, formattedDays, labelDays, dailyWeeklyData),
                ],
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Water Consumption Distribution per Course", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 20),
                mainLayout,
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET FOR PIE CHART CARD ---
 Widget _buildPieChartCard(Map<String, double> courseTotals, List<String> courseKeys) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Gamitin ang chartSize dito para maging responsive
        double chartSize = constraints.maxWidth * 0.8; 
        
        return SizedBox(
          width: chartSize,
          height: chartSize,
          child: PieChart(
            PieChartData(
              // ... (panatilihin ang iyong touchCallback logic)
              sectionsSpace: 4, 
              centerSpaceRadius: chartSize * 0.25, // Responsive center space
              sections: courseTotals.entries.map((entry) {
                final int index = courseKeys.indexOf(entry.key);
                final bool isTouched = index == touchedIndex || _selectedCourse == entry.key;
                
                return PieChartSectionData(
                  color: getCourseColor(entry.key),
                  value: entry.value,
                  title: '${entry.key}\n${entry.value.toStringAsFixed(1)}L',
                  radius: isTouched ? 80.0 : 65.0,
                  
                  // Mas malayo sa labas para hindi mag-overlap
                  titlePositionPercentageOffset: 1.7, 
                  
                  titleStyle: const TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.black87,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    ),
  );
}
  // --- WIDGET FOR LEGEND, BREAKDOWN, AND THE NEW DAILY LINE GRAPH ---
  Widget _buildSidePanel(
    Map<String, double> courseTotals, 
    Map<String, Map<String, double>> sectionTotalsPerCourse,
    List<String> formattedDays,
    List<String> labelDays,
    Map<String, double> dailyWeeklyData,
  ) {
    var sectionData = _selectedCourse != null ? sectionTotalsPerCourse[_selectedCourse] : null;
    Color graphColor = _selectedCourse != null ? getCourseColor(_selectedCourse!) : Colors.blue;

    // Pag-convert ng data para sa FlSpot ng Line Chart
    List<FlSpot> spots = [];
    double maxLiters = 5.0; // Default max Y axis ceiling
    for (int i = 0; i < formattedDays.length; i++) {
      double totalLiters = dailyWeeklyData[formattedDays[i]] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), totalLiters));
      if (totalLiters > maxLiters) maxLiters = totalLiters;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Course Indicators Card
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Course Indicators", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 15,
                  runSpacing: 10,
                  children: courseTotals.keys.map((course) {
                    bool isSelected = _selectedCourse == course;
                    return InkWell(
                      onTap: () => setState(() => _selectedCourse = course),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? getCourseColor(course).withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? getCourseColor(course) : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(color: getCourseColor(course), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(course, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),

        // 2. Section Breakdown Panel
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCourse != null ? "$_selectedCourse Section Breakdown" : "Section Analytics",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                ),
                const Divider(),
                if (_selectedCourse == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "Click a course to view its sections.",
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    ),
                  )
                else if (sectionData == null || sectionData.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("No section logs for this course.")),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sectionData.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      String sectionName = sectionData.keys.elementAt(index);
                      double volume = sectionData.values.elementAt(index);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(sectionName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        trailing: Text(
                          "${volume.toStringAsFixed(2)} L",
                          style: TextStyle(fontWeight: FontWeight.bold, color: getCourseColor(_selectedCourse!)),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),

        // 3. DAILY CONSUMPTION LINE GRAPH PER WEEK CARD
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCourse != null ? "$_selectedCourse Weekly Daily Tracker" : "Campus Overall Weekly Tracker",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                ),
                const Text("Water volume (Liters) consumed for the last 7 days", style: TextStyle(fontSize: 11, color: Colors.grey)),
                const Divider(),
                const SizedBox(height: 25),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toStringAsFixed(1)}L', 
                              style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1, // PINUWERSANG 1 INTERVAL PARA HINDI MAG-DUPLICATE ANG ARAL
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < labelDays.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
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
                      maxY: maxLiters + 0.5,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: graphColor,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: graphColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}