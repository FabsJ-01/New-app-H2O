import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('dispense_logs'); 

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PAGE HEADER
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Analytics & Reports", 
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
                ),
                SizedBox(height: 4),
                Text(
                  "Real-time campus hydration monitoring and consumption visualization", 
                  style: TextStyle(color: Colors.grey, fontSize: 13)
                ),
              ],
            ),
            const SizedBox(height: 25),

            // DYNAMIC RESPONSIVE BAR CHART CARD
            StreamBuilder(
              stream: _dbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                Map<String, double> weeklyLiters = {
                  "Mon": 0.0,
                  "Tue": 0.0,
                  "Wed": 0.0,
                  "Thu": 0.0,
                  "Fri": 0.0,
                  "Sat": 0.0,
                  "Sun": 0.0,
                };

                // ─── ALGORITMO PARA SA AUTO-RESET (DATE FILTER) ───
                // 1. Kukunin ang petsa ngayon at oras na 00:00:00
                DateTime ngayon = DateTime.now();
                DateTime ngayonDito = DateTime(ngayon.year, ngayon.month, ngayon.day);
                
                // 2. Hahanapin kung kailan ang Lunes ng kasalukuyang linggong ito
                int arawMulaLunes = ngayonDito.weekday - DateTime.monday;
                DateTime simulaNgLinggo = ngayonDito.subtract(Duration(days: arawMulaLunes));

                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic> logs = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  logs.forEach((key, value) {
                    if (value is Map && value.containsKey('timestamp') && value.containsKey('amount_ml')) {
                      int amountMl = value['amount_ml'] ?? 0;
                      String timestampStr = value['timestamp'] ?? ''; 

                      try {
                        DateTime logDate = DateTime.parse(timestampStr);

                        // 3. FILTER CHECK: Dapat ang logDate ay mas bago o katumbas ng Lunes ng linggong ito
                        if (logDate.isAfter(simulaNgLinggo.subtract(const Duration(seconds: 1)))) {
                          int dayOfWeek = logDate.weekday; 

                          String dayKey = "";
                          if (dayOfWeek == DateTime.monday) dayKey = "Mon";
                          else if (dayOfWeek == DateTime.tuesday) dayKey = "Tue";
                          else if (dayOfWeek == DateTime.wednesday) dayKey = "Wed";
                          else if (dayOfWeek == DateTime.thursday) dayKey = "Thu";
                          else if (dayOfWeek == DateTime.friday) dayKey = "Fri";
                          else if (dayOfWeek == DateTime.saturday) dayKey = "Sat"; 
                          else if (dayOfWeek == DateTime.sunday) dayKey = "Sun";   

                          if (weeklyLiters.containsKey(dayKey)) {
                            weeklyLiters[dayKey] = weeklyLiters[dayKey]! + (amountMl / 1000.0);
                          }
                        }
                      } catch (e) {
                        print("Skipping configuration entry: $key");
                      }
                    }
                  });
                }

                List<BarChartGroupData> barGroups = [
                  _buildBarGroup(0, weeklyLiters["Mon"]!, Colors.blue[400]!),
                  _buildBarGroup(1, weeklyLiters["Tue"]!, Colors.blue[400]!),
                  _buildBarGroup(2, weeklyLiters["Wed"]!, Colors.blue[400]!), 
                  _buildBarGroup(3, weeklyLiters["Thu"]!, Colors.blue[400]!),
                  _buildBarGroup(4, weeklyLiters["Fri"]!, Colors.blue[400]!),
                  _buildBarGroup(5, weeklyLiters["Sat"]!, Colors.orange[400]!), 
                  _buildBarGroup(6, weeklyLiters["Sun"]!, Colors.orange[400]!), 
                ];

                double maxLiters = weeklyLiters.values.reduce((a, b) => a > b ? a : b);
                if (maxLiters < 5.0) maxLiters = 5.0; 

                return Container(
                  width: screenWidth > 1100 ? screenWidth * 0.75 : screenWidth * 0.92, 
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 20, 
                        runSpacing: 15, 
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: screenWidth > 600 ? 400 : double.infinity),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Weekly Water Consumption Volume", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                SizedBox(height: 4),
                                Text("Total liters (L) dispensed per day (Current Week Only)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              const Text("Weekdays", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                              const SizedBox(width: 16),
                              Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              const Text("Weekends", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 35),
                      
                      SizedBox(
                        height: 360, 
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0, right: 10.0), 
                          child: BarChart(
                            BarChartData(
                              maxY: maxLiters + 1.5,
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: true, drawVerticalLine: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 45,
                                    getTitlesWidget: (value, meta) => Text("${value.toStringAsFixed(1)}L", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32, 
                                    getTitlesWidget: (value, meta) {
                                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                                        return SideTitleWidget(
                                          meta: meta, 
                                          space: 10, 
                                          child: Text(
                                            days[value.toInt()], 
                                            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.bold)
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              barGroups: barGroups,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18, 
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        )
      ],
    );
  }
}