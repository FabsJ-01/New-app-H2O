import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyProgressPage extends StatefulWidget {
  const WeeklyProgressPage({super.key});

  @override
  State<WeeklyProgressPage> createState() => _WeeklyProgressPageState();
}

class _WeeklyProgressPageState extends State<WeeklyProgressPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> weeklyData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _dbRef.child('history/$uid').limitToLast(7).get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        List<Map<String, dynamic>> temp = [];

        data.forEach((key, value) {
          temp.add({
            'date': key,
            'amount': double.tryParse(value.toString()) ?? 0.0
          });
        });

        // I-sort ang dates para maayos ang pagkakasunod-sunod sa chart
        temp.sort((a, b) => a['date'].compareTo(b['date']));

        setState(() {
          weeklyData = temp;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Progress")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weeklyData.isEmpty
              ? const Center(child: Text("Wala pang history na naitala."))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text("Water Consumption (ml)",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      Expanded(
                        child:LineChart(
  LineChartData(
    minY: 0,
    maxY: 100, // 100% ang limit
    minX: 0,
    maxX: 6, // 0=Mon, 6=Sun
    gridData: FlGridData(show: true, horizontalInterval: 25), // Grid kada 25%
    
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) => Text("${value.toInt()}%"),
        ),
      ),
    ),
    
    lineBarsData: [
      LineChartBarData(
        spots: [
          // Halimbawa: FlSpot(index, percentage)
          const FlSpot(0, 20), // Mon: 20%
          const FlSpot(1, 50), // Tue: 50%
          const FlSpot(2, 30), // Wed: 30%
          const FlSpot(3, 80), // Thu: 80%
          const FlSpot(4, 90), // Fri: 90%
          const FlSpot(5, 40), // Sat: 40%
          const FlSpot(6, 10), // Sun: 10%
        ],
        isCurved: true, // Para maging smooth ang curve
        color: Colors.blueAccent,
        barWidth: 4,
        belowBarData: BarAreaData(
          show: true, 
          color: Colors.blueAccent.withOpacity(0.2) // Shading sa ilalim
        ),
        dotData: FlDotData(show: true),
      ),
    ],
  ),
)
                      ),
                    ],
                  ),
                ),
    );
  }
}