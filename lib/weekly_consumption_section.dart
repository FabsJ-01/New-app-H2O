import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';

class WaterConsumptionChartSection extends StatefulWidget {
  final List<String> activeVendoList;
  final String selectedVendo;

  const WaterConsumptionChartSection({
    super.key,
    required this.activeVendoList,
    required this.selectedVendo,
  });

  @override
  State<WaterConsumptionChartSection> createState() => _WaterConsumptionChartSectionState();
}

class _WaterConsumptionChartSectionState extends State<WaterConsumptionChartSection> {
  final DatabaseReference _dbLogsRef = FirebaseDatabase.instance.ref('dispense_logs');
  String _selectedTimeframe = 'Weekly';

  final List<Color> _vendoColors = const [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
  ];

  Color _generateVendoColor(String vendoId) {
    if (vendoId.isEmpty || vendoId == "All Units") {
      return const Color(0xFF3B82F6);
    }
    final match = RegExp(r'\d+').firstMatch(vendoId);
    int index = match != null ? (int.tryParse(match.group(0)!) ?? 1) - 1 : vendoId.length;
    return _vendoColors[index.abs() % _vendoColors.length];
  }

  List<String> _getPeriodKeys() {
    if (_selectedTimeframe == 'Weekly') {
      return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    } else if (_selectedTimeframe == 'Monthly') {
      return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    } else {
      int currentYear = DateTime.now().year;
      return ["${currentYear - 2}", "${currentYear - 1}", "$currentYear"];
    }
  }

  Map<String, Map<String, double>> _processConsumptionData(Map<dynamic, dynamic> logs) {
  List<String> periodKeys = _getPeriodKeys();
  Map<String, Map<String, double>> stackedData = {
    for (var key in periodKeys) key: {},
  };

  debugPrint("--- START PROCESSING LOGS ---");
  debugPrint("Selected Vendo in Dropdown: '${widget.selectedVendo}'");
  debugPrint("Selected Timeframe: '$_selectedTimeframe'");

  logs.forEach((key, value) {
    if (value is Map) {
      // 1. Kunin ang amount_ml
      int amountMl = 0;
      if (value['amount_ml'] is num) {
        amountMl = (value['amount_ml'] as num).toInt();
      } else if (value['amount_ml'] != null) {
        amountMl = int.tryParse(value['amount_ml'].toString()) ?? 0;
      }

      // 2. Kunin ang vendo_id mula sa database record
      String logVendoId = value['vendo_id']?.toString() ?? 'Unknown';

      // 3. Kunin at i-parse ang timestamp
      dynamic rawTimestamp = value['timestamp'];
      DateTime? logDate;
      if (rawTimestamp is int) {
        logDate = DateTime.fromMillisecondsSinceEpoch(rawTimestamp).toLocal();
      } else if (rawTimestamp is String) {
        logDate = DateTime.tryParse(rawTimestamp)?.toLocal();
        if (logDate == null) {
          int? parsedInt = int.tryParse(rawTimestamp);
          if (parsedInt != null) {
            logDate = DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
          }
        }
      }

      // PRINT DEBUG FOR EACH LOG ENTRY
      debugPrint("LOG ENTRY -> VendoID in DB: '$logVendoId' | Amount: ${amountMl}ml | Date: $logDate");

      if (logDate == null) return;

      // Clean string comparison para iwas sa spaces, underscores, at zeros mismatch
      String cleanSelected = widget.selectedVendo.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
      String cleanLogVendo = logVendoId.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');

      bool isVendoMatch = (widget.selectedVendo == "All Units") || 
                          (cleanSelected == cleanLogVendo) ||
                          (cleanSelected.replaceAll('0', '') == cleanLogVendo.replaceAll('0', ''));

      if (isVendoMatch) {
        String targetKey = "";

        if (_selectedTimeframe == 'Weekly') {
          const dayMap = {1: "Mon", 2: "Tue", 3: "Wed", 4: "Thu", 5: "Fri", 6: "Sat", 7: "Sun"};
          targetKey = dayMap[logDate.weekday] ?? "";
        } else if (_selectedTimeframe == 'Monthly') {
          const monthMap = {
            1: "Jan", 2: "Feb", 3: "Mar", 4: "Apr", 5: "May", 6: "Jun",
            7: "Jul", 8: "Aug", 9: "Sep", 10: "Oct", 11: "Nov", 12: "Dec"
          };
          targetKey = monthMap[logDate.month] ?? "";
        } else if (_selectedTimeframe == 'Yearly') {
          targetKey = logDate.year.toString();
        }

        if (targetKey.isNotEmpty && stackedData.containsKey(targetKey)) {
          double liters = amountMl / 1000.0;
          stackedData[targetKey]![logVendoId] =
              (stackedData[targetKey]![logVendoId] ?? 0.0) + liters;
          
          debugPrint(" MATCH FOUND! Added ${liters}L to $targetKey for $logVendoId");
        }
      } else {
        debugPrint(" NO MATCH: DB '$logVendoId' vs Dropdown '${widget.selectedVendo}'");
      }
    }
  });

  debugPrint("--- END PROCESSING LOGS ---");
  return stackedData;
}
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    List<String> legendVendos = widget.activeVendoList.length > 1
        ? widget.activeVendoList.sublist(1)
        : [];

    return Container(
      width: screenWidth > 1100 ? screenWidth * 0.75 : screenWidth * 0.92,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER AND TIMEFRAME SELECTOR
          Wrap(
            spacing: 20,
            runSpacing: 15,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
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
                  const SizedBox(height: 4),
                  Text(
                    "Total liters (L) dispensed per ${_selectedTimeframe == 'Weekly' ? 'day' : (_selectedTimeframe == 'Monthly' ? 'month' : 'year')} (${widget.selectedVendo} Breakdown)",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: ValueKey('tf_select_$_selectedTimeframe'),
                        value: _selectedTimeframe,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF3B82F6)),
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue != _selectedTimeframe) {
                            setState(() {
                              _selectedTimeframe = newValue;
                            });
                          }
                        },
                        items: const ['Weekly', 'Monthly', 'Yearly']
                            .map((String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  if (widget.selectedVendo == "All Units" && legendVendos.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: legendVendos.map((vName) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _generateVendoColor(vName),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                vName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 35),

          // GRAPH STREAM AREA
          SizedBox(
            height: 380,
            child: StreamBuilder(
              stream: _dbLogsRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> logsSnapshot) {
                List<String> periodKeys = _getPeriodKeys();
                Map<String, Map<String, double>> stackedData = {
                  for (var key in periodKeys) key: {},
                };

                int dataHash = 0;

                if (logsSnapshot.hasData && logsSnapshot.data!.snapshot.value != null) {
                  final rawLogs = logsSnapshot.data!.snapshot.value;
                  if (rawLogs is Map) {
                    stackedData = _processConsumptionData(rawLogs);
                    dataHash = rawLogs.length; // Triggers fresh rebuild on new entry
                  }
                }

                List<BarChartGroupData> barGroups = [];
                double globalMaxY = 0.0;

                for (int i = 0; i < periodKeys.length; i++) {
                  String pKey = periodKeys[i];
                  Map<String, double> vendosInPeriod = stackedData[pKey] ?? {};

                  List<BarChartRodStackItem> stackItems = [];
                  double currentSum = 0.0;
                  List<String> sortedVendosInPeriod = vendosInPeriod.keys.toList()..sort();

                  for (String vId in sortedVendosInPeriod) {
                    double vVolume = vendosInPeriod[vId] ?? 0.0;
                    if (vVolume > 0) {
                      Color rodColor = (widget.selectedVendo != "All Units")
                          ? const Color(0xFF3B82F6)
                          : _generateVendoColor(vId);

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
                          width: _selectedTimeframe == 'Monthly' ? 14 : 22,
                          borderRadius: BorderRadius.circular(4),
                          rodStackItems: stackItems.isEmpty
                              ? [BarChartRodStackItem(0, 0, Colors.transparent)]
                              : stackItems,
                        )
                      ],
                    ),
                  );
                }

                double chartMaxY = (globalMaxY <= 0) ? 10.0 : (globalMaxY * 1.25);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0, right: 10.0),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.basic,
                    child: BarChart(
                      // Nagdaragdag ng unique key batay sa timeframe, vendo, at data size para ma-clear ang lumang Mouse Tracker states sa Web
                      key: ValueKey('barchart_${_selectedTimeframe}_${widget.selectedVendo}_$dataHash'),
                      BarChartData(
                        maxY: chartMaxY,
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        barTouchData: BarTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => const Color(0xFF1E293B),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              int xIdx = group.x.toInt();
                              if (xIdx < 0 || xIdx >= periodKeys.length) return null;

                              String periodName = periodKeys[xIdx];
                              Map<String, double>? periodData = stackedData[periodName];
                              if (periodData == null) return null;

                              List<String> sortedVendos = periodData.keys.toList()..sort();
                              String tooltipContent = "$periodName Summary\n";
                              bool hasDataInBar = false;

                              for (String vid in sortedVendos) {
                                double vol = periodData[vid] ?? 0.0;
                                if (vol > 0) {
                                  tooltipContent += "• $vid: ${vol.toStringAsFixed(1)}L\n";
                                  hasDataInBar = true;
                                }
                              }

                              if (!hasDataInBar) return null;

                              return BarTooltipItem(
                                tooltipContent.trim(),
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              getTitlesWidget: (value, meta) => Text(
                                "${value.toStringAsFixed(1)}L",
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (value == index.toDouble() && index >= 0 && index < periodKeys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Text(
                                      periodKeys[index],
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        barGroups: barGroups,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}