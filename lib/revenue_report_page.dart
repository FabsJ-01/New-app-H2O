import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'revenue_receipt_service.dart';

class RevenueReportPage extends StatefulWidget {
  const RevenueReportPage({super.key});

  @override
  State<RevenueReportPage> createState() => _RevenueReportPageState();
}

class _RevenueReportPageState extends State<RevenueReportPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String _selectedFilter = "This Month";
  bool _isGeneratingPdf = false;
  String? _adminName;
  String? _adminEmail;

  final List<String> _filters = ["This Week", "This Month", "All Time"];

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  // Load Admin Name and Email from Firebase
  Future<void> _loadAdminInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String adminName = "Admin";
      final snapshot = await _dbRef.child('admins/${user.uid}').get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map;
        adminName = data['name']?.toString() ?? "Admin";
      }

      if (mounted) {
        setState(() {
          _adminName = adminName;
          _adminEmail = user.email ?? "";
        });
      }
    }
  }

  String get _currentMonth => DateFormat('yyyy-MM').format(DateTime.now());

  List<String> get _currentWeekDays {
    List<String> days = [];
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      days.add(
        DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i))),
      );
    }
    return days;
  }

  bool _isInFilter(String timestamp) {
    if (timestamp.isEmpty) return false;
    if (_selectedFilter == "All Time") return true;
    if (_selectedFilter == "This Month") {
      return timestamp.startsWith(_currentMonth);
    }
    if (_selectedFilter == "This Week") {
      String dateKey = timestamp.split(' ').first;
      return _currentWeekDays.contains(dateKey);
    }
    return false;
  }

  // Generate PDF Receipt
  Future<void> _generateReceipt({
    required double grandTotal,
    required double totalLiters,
    required int totalDispenses,
    required List<Map<String, dynamic>> vendoBreakdown,
  }) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final now = DateTime.now();
      final snapshot = await _dbRef.child('receipts').get();
      int count = 1;
      if (snapshot.exists && snapshot.value != null) {
        count = (snapshot.value as Map).length + 1;
      }
      String receiptNumber =
          "RCP-${now.year}-${count.toString().padLeft(3, '0')}";

      await _dbRef.child('receipts/$receiptNumber').set({
        'receipt_number': receiptNumber,
        'admin_name': _adminName ?? "Admin",
        'admin_email': _adminEmail ?? "",
        'period': _selectedFilter,
        'grand_total': grandTotal,
        'total_liters': totalLiters,
        'total_dispenses': totalDispenses,
        'generated_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
        'status': 'Generated',
      });

      await RevenueReceiptService.generateAndPrint(
        receiptNumber: receiptNumber,
        adminName: _adminName ?? "Admin",
        adminEmail: _adminEmail ?? "",
        period: _selectedFilter,
        grandTotal: grandTotal,
        totalLiters: totalLiters,
        totalDispenses: totalDispenses,
        vendoBreakdown: vendoBreakdown,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text("Receipt $receiptNumber generated!"),
              ],
            ),
            backgroundColor: Colors.blue[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generating receipt: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // Mark as Collected
  Future<void> _markAsCollected({
    required double grandTotal,
    required double totalLiters,
    required int totalDispenses,
  }) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "Mark as Collected",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Confirm collection of:",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₱${grandTotal.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    "Period: $_selectedFilter",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "Dispenses: $totalDispenses times",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Confirm Collection",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final now = DateTime.now();
      await _dbRef.child('collections').push().set({
        'period': _selectedFilter,
        'amount': grandTotal,
        'total_liters': totalLiters,
        'total_dispenses': totalDispenses,
        'admin_name': _adminName ?? "Admin",
        'admin_email': _adminEmail ?? "",
        'collected_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "₱${grandTotal.toStringAsFixed(2)} marked as collected!",
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // --- HELPER WIDGETS ---

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedFilter = newValue);
            }
          },
          items: _filters.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGeneratePdfButton({
    required double grandTotal,
    required double totalLiters,
    required int totalDispenses,
    required List<Map<String, dynamic>> vendoBreakdown,
    required List<MapEntry<String, double>> sortedVendos,
    required bool fullWidth,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: (_isGeneratingPdf || sortedVendos.isEmpty)
            ? null
            : () => _generateReceipt(
                  grandTotal: grandTotal,
                  totalLiters: totalLiters,
                  totalDispenses: totalDispenses,
                  vendoBreakdown: vendoBreakdown,
                ),
        icon: _isGeneratingPdf
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf_rounded),
        label: Text(_isGeneratingPdf ? "Generating..." : "Export PDF Receipt"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkAsCollectedButton({
    required double grandTotal,
    required double totalLiters,
    required int totalDispenses,
    required List<MapEntry<String, double>> sortedVendos,
    required bool fullWidth,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: sortedVendos.isEmpty
            ? null
            : () => _markAsCollected(
                  grandTotal: grandTotal,
                  totalLiters: totalLiters,
                  totalDispenses: totalDispenses,
                ),
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text("Mark as Collected"),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green.shade700,
          side: BorderSide(color: Colors.green.shade700),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return StreamBuilder<DatabaseEvent>(
      stream: _dbRef.child('dispense_logs').onValue,
      builder: (context, logsSnapshot) {
        return StreamBuilder<DatabaseEvent>(
          stream: _dbRef.child('vendos').onValue,
          builder: (context, vendosSnapshot) {
            Map<String, String> vendoNames = {};
            Map<String, double> vendoMlPerPeso = {};

            if (vendosSnapshot.hasData &&
                vendosSnapshot.data!.snapshot.value != null) {
              final vendosData = vendosSnapshot.data!.snapshot.value
                  as Map<dynamic, dynamic>;
              vendosData.forEach((key, value) {
                if (value is Map) {
                  vendoNames[key.toString()] =
                      value['name']?.toString() ?? key.toString();
                  double mlPerPeso = double.tryParse(
                        value['settings']?['ml_per_peso']?.toString() ?? "100",
                      ) ??
                      100.0;
                  vendoMlPerPeso[key.toString()] = mlPerPeso;
                }
              });
            }

            Map<String, double> vendoRevenue = {};
            Map<String, double> vendoLiters = {};
            Map<String, int> vendoDispenses = {};
            double grandTotal = 0.0;

            if (logsSnapshot.hasData &&
                logsSnapshot.data!.snapshot.value != null) {
              final logsData = logsSnapshot.data!.snapshot.value
                  as Map<dynamic, dynamic>;

              logsData.forEach((key, value) {
                if (value is Map) {
                  String timestamp = value['timestamp']?.toString() ?? "";
                  String vendoId =
                      value['vendo_id']?.toString() ?? "Unknown";

                  if (_isInFilter(timestamp)) {
                    double ml = double.tryParse(
                          value['amount_ml']?.toString() ??
                              value['amount']?.toString() ??
                              "0",
                        ) ??
                        0.0;

                    double mlPerPeso = vendoMlPerPeso[vendoId] ?? 100.0;
                    double revenue = ml / mlPerPeso;
                    double liters = ml / 1000.0;

                    vendoRevenue[vendoId] =
                        (vendoRevenue[vendoId] ?? 0) + revenue;
                    vendoLiters[vendoId] =
                        (vendoLiters[vendoId] ?? 0) + liters;
                    vendoDispenses[vendoId] =
                        (vendoDispenses[vendoId] ?? 0) + 1;
                    grandTotal += revenue;
                  }
                }
              });
            }

            var sortedVendos = vendoRevenue.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            int totalDispenses =
                vendoDispenses.values.fold(0, (a, b) => a + b);
            double totalLiters =
                vendoLiters.values.fold(0.0, (a, b) => a + b);

            List<Map<String, dynamic>> vendoBreakdown =
                sortedVendos.map((e) => {
                      'id': e.key,
                      'name': vendoNames[e.key] ?? e.key,
                      'revenue': e.value,
                      'liters': vendoLiters[e.key] ?? 0.0,
                      'dispenses': vendoDispenses[e.key] ?? 0,
                      'mlPerPeso': vendoMlPerPeso[e.key] ?? 100.0,
                    }).toList();

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Revenue Report",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Text(
                              "Total earnings per vendo unit",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            _buildFilterDropdown(),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Revenue Report",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  "Total earnings per vendo unit",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            _buildFilterDropdown(),
                          ],
                        ),

                  const SizedBox(height: 20),

                  // --- GRAND TOTAL CARD ---
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 18 : 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade700,
                          Colors.blue.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.monetization_on_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                "Total Revenue — $_selectedFilter",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "₱${grandTotal.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 32 : 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "From $totalDispenses dispenses across ${vendoRevenue.length} units",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- PDF + MARK AS COLLECTED BUTTONS ---
                  isMobile
                      ? Column(
                          children: [
                            _buildGeneratePdfButton(
                              grandTotal: grandTotal,
                              totalLiters: totalLiters,
                              totalDispenses: totalDispenses,
                              vendoBreakdown: vendoBreakdown,
                              sortedVendos: sortedVendos,
                              fullWidth: true,
                            ),
                            const SizedBox(height: 10),
                            _buildMarkAsCollectedButton(
                              grandTotal: grandTotal,
                              totalLiters: totalLiters,
                              totalDispenses: totalDispenses,
                              sortedVendos: sortedVendos,
                              fullWidth: true,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildGeneratePdfButton(
                                grandTotal: grandTotal,
                                totalLiters: totalLiters,
                                totalDispenses: totalDispenses,
                                vendoBreakdown: vendoBreakdown,
                                sortedVendos: sortedVendos,
                                fullWidth: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMarkAsCollectedButton(
                                grandTotal: grandTotal,
                                totalLiters: totalLiters,
                                totalDispenses: totalDispenses,
                                sortedVendos: sortedVendos,
                                fullWidth: false,
                              ),
                            ),
                          ],
                        ),

                  const SizedBox(height: 20),

                  // --- SUMMARY CARDS ---
                  isMobile
                      ? Column(
                          children: [
                            Row(
                              children: [
                                _buildSummaryCard(
                                  "Total Liters",
                                  "${totalLiters.toStringAsFixed(2)} L",
                                  Icons.water_drop_rounded,
                                  Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                _buildSummaryCard(
                                  "Total Dispenses",
                                  "$totalDispenses times",
                                  Icons.repeat_rounded,
                                  Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildSummaryCard(
                                  "Active Units",
                                  "${vendoRevenue.length} units",
                                  Icons.local_drink_rounded,
                                  Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            _buildSummaryCard(
                              "Total Liters Dispensed",
                              "${totalLiters.toStringAsFixed(2)} L",
                              Icons.water_drop_rounded,
                              Colors.blue,
                            ),
                            const SizedBox(width: 16),
                            _buildSummaryCard(
                              "Total Dispenses",
                              "$totalDispenses times",
                              Icons.repeat_rounded,
                              Colors.green,
                            ),
                            const SizedBox(width: 16),
                            _buildSummaryCard(
                              "Active Vendo Units",
                              "${vendoRevenue.length} units",
                              Icons.local_drink_rounded,
                              Colors.orange,
                            ),
                          ],
                        ),

                  const SizedBox(height: 20),

                  // --- PER VENDO BREAKDOWN ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(isMobile ? 16 : 20),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Revenue Per Vendo Unit",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                "Breakdown of earnings per machine",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (sortedVendos.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_rounded,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "No revenue data available.",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedVendos.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              String vendoId = sortedVendos[index].key;
                              double revenue = sortedVendos[index].value;
                              String name = vendoNames[vendoId] ?? vendoId;
                              double mlPerPeso =
                                  vendoMlPerPeso[vendoId] ?? 100.0;

                              double maxRevenue = sortedVendos.first.value;
                              double progress = maxRevenue > 0
                                  ? revenue / maxRevenue
                                  : 0;

                              Color rankColor = index == 0
                                  ? Colors.amber
                                  : index == 1
                                      ? Colors.grey
                                      : index == 2
                                          ? Colors.brown
                                          : Colors.blue;

                              return Padding(
                                padding:
                                    EdgeInsets.all(isMobile ? 14 : 20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Rank badge
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color:
                                                rankColor.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "#${index + 1}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: rankColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Vendo info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              Text(
                                                "ID: $vendoId  •  ₱1:${mlPerPeso.toInt()}ml",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Revenue
                                        Text(
                                          "₱${revenue.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 15 : 18,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Progress bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor:
                                            const Color(0xFFF1F5F9),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                rankColor),
                                        minHeight: 6,
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
                ],
              ),
            );
          },
        );
      },
    );
  }
}