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

        // Siguraduhing valid ang selected vendo
        final currentSelected = activeVendoList.contains(_selectedVendo) 
            ? _selectedVendo 
            : "All Units";

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: const Color(0xFFE2E8F0),
                height: 1.0,
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: IconButton(
                  hoverColor: const Color(0xFFF1F5F9),
                  splashRadius: 22,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Water Consumption Analytics",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Volume breakdown & metrics",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: ValueKey('vendo_dropdown_$currentSelected'),
                        value: currentSelected,
                        borderRadius: BorderRadius.circular(12),
                        dropdownColor: Colors.white,
                        elevation: 3,
                        icon: const Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        items: activeVendoList.map((v) {
                          return DropdownMenuItem<String>(
                            value: v,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  v == "All Units" ? Icons.tune_rounded : Icons.water_drop_rounded,
                                  size: 15,
                                  color: const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 8),
                                Text(v),
                              ],
                            ),
                          );
                        }).toList(),
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bool isMobile = constraints.maxWidth < 600;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: WaterConsumptionChartSection(
                      activeVendoList: activeVendoList,
                      selectedVendo: currentSelected,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}