import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'weekly_consumption_section.dart';

class WeeklyConsumptionPage extends StatefulWidget {
  const WeeklyConsumptionPage({super.key});

  @override
  State<WeeklyConsumptionPage> createState() => _WeeklyConsumptionPageState();
}

class _WeeklyConsumptionPageState extends State<WeeklyConsumptionPage> {
  final DatabaseReference _dbVendosRef = FirebaseDatabase.instance.ref('vendos');
  String _selectedVendo = "All Units";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _dbVendosRef.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> vendosSnapshot) {
        List<String> activeVendoList = ["All Units"];

        if (vendosSnapshot.hasData && vendosSnapshot.data!.snapshot.value != null) {
          final rawData = vendosSnapshot.data!.snapshot.value;
          if (rawData is Map) {
            List<String> tempVendos = [];
            rawData.forEach((key, value) {
              String vId = key.toString().trim();
              if (vId.isNotEmpty) tempVendos.add(vId);
            });
            tempVendos.sort();
            activeVendoList.addAll(tempVendos);
          }
        }

        // Siguraduhing valid ang selected vendo nang hindi sinisira ang state sa build logic
        final currentSelected = activeVendoList.contains(_selectedVendo) 
            ? _selectedVendo 
            : "All Units";

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Water Consumption Analytics",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "Volume breakdown & metrics",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        // MAGLAGAY NG UNIQUE KEY DITO PARA HINDI MAG-CRASH ANG MOUSE TRACKER
                        key: ValueKey('vendo_dropdown_$currentSelected'),
                        value: currentSelected,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E293B)),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        items: activeVendoList
                            .map((v) => DropdownMenuItem<String>(
                                  value: v,
                                  child: Text(v),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          if (newValue != null && newValue != _selectedVendo) {
                            setState(() {
                              _selectedVendo = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: WaterConsumptionChartSection(
                activeVendoList: activeVendoList,
                selectedVendo: currentSelected,
              ),
            ),
          ),
        );
      },
    );
  }
}