import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DispenseLogsPage extends StatefulWidget {
  const DispenseLogsPage({super.key});

  @override
  State<DispenseLogsPage> createState() => _DispenseLogsPageState();
}

class _DispenseLogsPageState extends State<DispenseLogsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Timer? _midnightTimer;

  // Kinukuha ang kasalukuyang petsa sa format na yyyy-MM-dd (hal. 2026-05-17)
  String get _todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _scheduleMidnightReset();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel(); // Nililinis ang timer para maiwasan ang memory leaks
    super.dispose();
  }

  // --- AUTOMATIC MIDNIGHT RESET TIMER ---
  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    // Pagpatak ng eksaktong 12:00 AM, awtomatikong magre-refresh ang UI
    _midnightTimer = Timer(timeUntilMidnight, () {
      if (mounted) {
        setState(() {});
        _scheduleMidnightReset(); // I-set up muli para sa susunod na hatinggabi
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dispense Transactions Today",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              "Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            
            // Unang Stream: Kukunin ang listahan ng mga Vendos para makagawa ng Card kada isa
            StreamBuilder(
              stream: _dbRef.child('vendos').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> vendoSnapshot) {
                if (vendoSnapshot.hasData && vendoSnapshot.data!.snapshot.value != null) {
                  final dynamic rawVendos = vendoSnapshot.data!.snapshot.value;
                  List<Widget> clusterCards = [];

                  // FIXED: Tinanggal ang maling `if` wrapper dito para hindi na mag-void error
                  rawDataToMap(rawVendos, (id, data) {
                    clusterCards.add(_buildVendoLogsCard(id, data['name'] ?? "Unknown Vendo"));
                  });

                  return Column(children: clusterCards);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD KADA VENDO AT ANG LOGS NITO ---
  Widget _buildVendoLogsCard(String vendoId, String vendoName) {
    return Card(
      margin: const EdgeInsets.only(bottom: 25),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header ng Card (Pangalan at ID ng Vendo)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vendoName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "ID: $vendoId",
                    style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // Ikalawang Stream: Pakikinggan ang 'dispense_logs' node sa Firebase
            StreamBuilder(
              stream: _dbRef.child('dispense_logs').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> logSnapshot) {
                if (logSnapshot.hasData && logSnapshot.data!.snapshot.value != null) {
                  final dynamic rawLogs = logSnapshot.data!.snapshot.value;
                  Map<dynamic, dynamic> logsMap = (rawLogs is Map) ? rawLogs : {};

                  List<Map<String, dynamic>> filteredLogs = [];

                  logsMap.forEach((key, value) {
                    if (value is Map) {
                      String currentLogVendoId = value['vendo_id']?.toString() ?? "";
                      String timestamp = value['timestamp']?.toString() ?? "";

                      // Sinasala ang vendo_id at tinitiyak na ngayong araw lang ang logs (12 AM reset logic)
                      bool isMatchingVendo = (currentLogVendoId == vendoId) || 
                                             (currentLogVendoId.contains(vendoId)) || 
                                             (vendoId.contains(currentLogVendoId));

                      if (isMatchingVendo && timestamp.startsWith(_todayDate)) {
                        filteredLogs.add({
                          'psu_id': value['psu_id'] ?? "N/A",
                          'amount_ml': value['amount_ml'] ?? 0,
                          'timestamp': timestamp,
                        });
                      }
                    }
                  });

                  // Inaayos ang listahan para ang pinakabagong dispense ang nasa itaas
                  filteredLogs.sort((a, b) => b['timestamp'].toString().compareTo(a['timestamp'].toString()));

                  if (filteredLogs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "No water dispensed today for this unit.",
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    );
                  }

                  // Table Layout para sa malinis at pantay-pantay na listahan ng logs
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2), // PSU ID
                          1: FlexColumnWidth(1.5), // Amount (ML)
                          2: FlexColumnWidth(2.5), // Time
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                        ),
                        children: [
                          // Table Header
                          const TableRow(
                            children: [
                              Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("PSU ID", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Volume", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Time Dispensed", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                            ],
                          ),
                          // Table Body Rows
                          ...filteredLogs.map((log) {
                            String formatTime = log['timestamp'];
                            if (formatTime.length >= 19) {
                              formatTime = formatTime.substring(11, 19); // HH:mm:ss lang ang kukunin
                            }

                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(log['psu_id'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text("${log['amount_ml']} ml", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(formatTime, style: const TextStyle(color: Colors.black87)),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }
                return const Center(child: LinearProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper function para basahin ang parehong Map at List structure mula sa Firebase vendos node
  void rawDataToMap(dynamic rawData, Function(String id, Map<dynamic, dynamic> data) action) {
    if (rawData is Map) {
      rawData.forEach((key, value) {
        if (value is Map) action(key.toString(), value);
      });
    } else if (rawData is List) {
      for (int i = 0; i < rawData.length; i++) {
        if (rawData[i] != null && rawData[i] is Map) {
          action(i.toString(), rawData[i]);
        }
      }
    }
  }
}