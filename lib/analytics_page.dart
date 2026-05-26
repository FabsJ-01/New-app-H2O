import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'student_analytics_section.dart'; // Bagong file natin

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final DatabaseReference _dbLogsRef = FirebaseDatabase.instance.ref('dispense_logs'); 
  final DatabaseReference _dbVendosRef = FirebaseDatabase.instance.ref('vendos'); 

  String _selectedVendo = "All Units"; 

  // Auto-generate ng Kulay gamit ang String Hash ng Vendo ID (Para laging consistent)
  final List<Color> _vendoColors = [
    const Color(0xFF3B82F6), // Premium Blue (Vendo 1)
    const Color(0xFF10B981), // Emerald Green (Vendo 2)
    const Color(0xFFF59E0B), // Warm Amber (Vendo 3)
    const Color(0xFF6366F1), // Indigo (Vendo 4)
    const Color(0xFF14B8A6), // Teal (Vendo 5)
    const Color(0xFFEC4899), // Soft Pink (Vendo 6)
    const Color(0xFFF97316), // Muted Orange (Vendo 7)
    const Color(0xFF8B5CF6), // Soft Violet (Vendo 8)
  ];

  Color _generateVendoColor(String vendoId) {
    if (vendoId.isEmpty || vendoId == "All Units") {
      return const Color(0xFF3B82F6); // Default Corporate Blue
    }
    
    RegExp regExp = RegExp(r'\d+');
    Match? match = regExp.firstMatch(vendoId);
    
    int index = match != null ? int.parse(match.group(0)!) - 1 : vendoId.length;

    return _vendoColors[index % _vendoColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0), // Bahagyang nilakihan ang padding para mas malinis sa web
        child: StreamBuilder(
          stream: _dbVendosRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> vendosSnapshot) {
            List<String> activeVendoList = ["All Units"];
            
            if (vendosSnapshot.hasData && vendosSnapshot.data!.snapshot.value != null) {
              Map<dynamic, dynamic> vendosData = vendosSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              vendosData.forEach((key, value) {
                String vId = key.toString().trim();
                if (vId.isNotEmpty) activeVendoList.add(vId);
              });
              activeVendoList.sort();

              if (!activeVendoList.contains(_selectedVendo)) {
                _selectedVendo = "All Units";
              }
            }

            return StreamBuilder(
              stream: _dbLogsRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> logsSnapshot) {
                
                Map<String, Map<String, double>> stackedWeeklyData = {
                  "Mon": {}, "Tue": {}, "Wed": {}, "Thu": {}, "Fri": {}, "Sat": {}, "Sun": {},
                };

                DateTime ngayon = DateTime.now();
                DateTime ngayonDito = DateTime(ngayon.year, ngayon.month, ngayon.day);
                int arawMulaLunes = ngayonDito.weekday - DateTime.monday;
                DateTime simulaNgLinggo = ngayonDito.subtract(Duration(days: arawMulaLunes));

                if (logsSnapshot.hasData && logsSnapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic> logs = logsSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  logs.forEach((key, value) {
                    if (value is Map && value.containsKey('timestamp') && value.containsKey('amount_ml')) {
                      int amountMl = value['amount_ml'] ?? 0;
                      String timestampStr = value['timestamp'] ?? ''; 
                      String logVendoId = value['vendo_id'] ?? 'Unknown';

                      try {
                        DateTime logDate = DateTime.parse(timestampStr);

                        if (logDate.isAfter(simulaNgLinggo.subtract(const Duration(seconds: 1)))) {
                          
                          bool isVendoMatch = (_selectedVendo == "All Units") || (logVendoId == _selectedVendo);

                          if (isVendoMatch) {
                            int dayOfWeek = logDate.weekday; 
                            String dayKey = "";
                            if (dayOfWeek == DateTime.monday) dayKey = "Mon";
                            else if (dayOfWeek == DateTime.tuesday) dayKey = "Tue";
                            else if (dayOfWeek == DateTime.wednesday) dayKey = "Wed";
                            else if (dayOfWeek == DateTime.thursday) dayKey = "Thu";
                            else if (dayOfWeek == DateTime.friday) dayKey = "Fri";
                            else if (dayOfWeek == DateTime.saturday) dayKey = "Sat"; 
                            else if (dayOfWeek == DateTime.sunday) dayKey = "Sun";   

                            double liters = amountMl / 1000.0;
                            
                            if (stackedWeeklyData.containsKey(dayKey)) {
                              stackedWeeklyData[dayKey]![logVendoId] = 
                                  (stackedWeeklyData[dayKey]![logVendoId] ?? 0.0) + liters;
                            }
                          }
                        }
                      } catch (e) {
                        print("Error parsing timestamp: $e");
                      }
                    }
                  });
                }

                List<String> mgaAraw = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                List<BarChartGroupData> barGroups = [];
                double globalMaxY = 5.0; 

                for (int i = 0; i < mgaAraw.length; i++) {
                  String day = mgaAraw[i];
                  Map<String, double> vendosInDay = stackedWeeklyData[day]!;
                  
                  List<BarChartRodStackItem> stackItems = [];
                  double currentSum = 0.0;

                  List<String> sortedVendosInDay = vendosInDay.keys.toList()..sort();

                  for (String vId in sortedVendosInDay) {
                    double vVolume = vendosInDay[vId]!;
                    if (vVolume > 0) {
                      Color rodColor = _generateVendoColor(vId);
                      
                      if (_selectedVendo != "All Units") {
                        rodColor = const Color(0xFF3B82F6);
                      }

                      stackItems.add(
                        BarChartRodStackItem(currentSum, currentSum + vVolume, rodColor),
                      );
                      currentSum += vVolume;
                    }
                  }

                  if (currentSum > globalMaxY) {
                    globalMaxY = currentSum;
                  }

                  barGroups.add(
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: currentSum,
                          width: 22,
                          borderRadius: BorderRadius.circular(4),
                          rodStackItems: stackItems.isEmpty ? [BarChartRodStackItem(0, 0, const Color(0xFF3B82F6))] : stackItems,
                        )
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER SECTION (Row ng Titles at Dropdown Filter)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Analytics & Reports", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              SizedBox(height: 4),
                              Text("Real-time campus hydration monitoring and consumption visualization", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedVendo,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E293B)),
                            underline: const SizedBox(),
                            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                            items: activeVendoList.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedVendo = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // 2. WEEKLY WATER CONSUMPTION GRAPH CONTAINER
                    Container(
                      width: screenWidth > 1100 ? screenWidth * 0.75 : screenWidth * 0.92, 
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 20, runSpacing: 15, 
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Weekly Water Consumption Volume", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 4),
                                  Text("Total liters (L) dispensed per day ($_selectedVendo Breakdown)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              
                              if (_selectedVendo == "All Units")
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(activeVendoList.length - 1, (index) {
                                    String vName = activeVendoList[index + 1];
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: Row(
                                        children: [
                                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _generateVendoColor(vName), shape: BoxShape.circle)),
                                          const SizedBox(width: 4),
                                          Text(vName, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    );
                                  }),
                                )
                            ],
                          ),
                          const SizedBox(height: 35),
                          
                          SizedBox(
                            height: 380, 
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0, right: 10.0), 
                              child: BarChart(
                                BarChartData(
                                  maxY: globalMaxY + 1.5,
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                                  
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (group) => const Color(0xFF1E293B),
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        String dayName = mgaAraw[group.x.toInt()];
                                        Map<String, double> dayData = stackedWeeklyData[dayName]!;
                                        
                                        List<String> sortedVendos = dayData.keys.toList()..sort();
                                        String tooltipContent = "$dayName Summary\n";

                                        for (String vid in sortedVendos) {
                                          double vol = dayData[vid] ?? 0.0;
                                          if (vol > 0) {
                                            tooltipContent += "• $vid: ${vol.toStringAsFixed(1)}L\n";
                                          }
                                        }

                                        return BarTooltipItem(
                                          tooltipContent.trim(),
                                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                        );
                                      },
                                    ),
                                  ),

                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true, reservedSize: 45,
                                        getTitlesWidget: (value, meta) => Text("${value.toStringAsFixed(1)}L", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true, reservedSize: 32, 
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() >= 0 && value.toInt() < mgaAraw.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 10.0),
                                              child: Text(mgaAraw[value.toInt()], style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.bold)),
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
                    ),
                    
                    // 3. PAGITAN PAPUNTA SA STUDENT HYDRO-ANALYTICS CARD
                    const SizedBox(height: 35),

                    // 4. DITO NA TATAWAGIN ANG HIWALAY NA STUDENT ANALYTICS FILE (Nasa tamang baba na siya)
                    if (logsSnapshot.hasData && logsSnapshot.data!.snapshot.value != null)
                      StudentAnalyticsSection(
                        logsData: logsSnapshot.data!.snapshot.value as Map<dynamic, dynamic>
                      ),
                      
                    // Ekstrang space sa dulo para swabe ang pag-scroll
                    const SizedBox(height: 40),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}