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

class _RevenueReportPageState extends State<RevenueReportPage>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String _selectedFilter = "This Month";
  bool _isGeneratingPdf = false;
  bool _isDeletingLogs = false;
  final Set<int> _downloadedYears = {};
  String? _adminName;
  String? _adminEmail;

  late TabController _tabController;

  final List<String> _filters = ["This Week", "This Month", "All Time"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load Admin Info
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
      days.add(DateFormat('yyyy-MM-dd')
          .format(now.subtract(Duration(days: i))));
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

  // Check kung may data na 1 year old
  bool _hasYearOldData(Map<dynamic, dynamic> logsData) {
    int currentYear = DateTime.now().year;
    for (var value in logsData.values) {
      if (value is Map) {
        String timestamp = value['timestamp']?.toString() ?? "";
        if (timestamp.isNotEmpty) {
          try {
            int logYear = int.parse(timestamp.substring(0, 4));
            if (logYear < currentYear) return true;
          } catch (_) {}
        }
      }
    }
    return false;
  }

  // Get available years from logs
  List<int> _getAvailableYears(Map<dynamic, dynamic> logsData) {
    Set<int> years = {};
    int currentYear = DateTime.now().year;
    for (var value in logsData.values) {
      if (value is Map) {
        String timestamp = value['timestamp']?.toString() ?? "";
        if (timestamp.isNotEmpty) {
          try {
            int logYear = int.parse(timestamp.substring(0, 4));
            if (logYear < currentYear) years.add(logYear);
          } catch (_) {}
        }
      }
    }
    List<int> sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
    return sortedYears;
  }

  // Compute yearly data per year
  Map<String, dynamic> _computeYearlyData(
      Map<dynamic, dynamic> logsData,
      int year,
      Map<String, String> vendoNames,
      Map<String, double> vendoMlPerPeso) {
    Map<String, double> vendoRevenue = {};
    Map<String, double> vendoLiters = {};
    Map<String, int> vendoDispenses = {};
    double grandTotal = 0.0;

    logsData.forEach((key, value) {
      if (value is Map) {
        String timestamp = value['timestamp']?.toString() ?? "";
        if (timestamp.startsWith(year.toString())) {
          String vendoId = value['vendo_id']?.toString() ?? "Unknown";
          double ml = double.tryParse(
                value['amount_ml']?.toString() ??
                    value['amount']?.toString() ??
                    "0",
              ) ??
              0.0;
          double mlPerPeso = vendoMlPerPeso[vendoId] ?? 100.0;
          double revenue = ml / mlPerPeso;
          double liters = ml / 1000.0;

          vendoRevenue[vendoId] = (vendoRevenue[vendoId] ?? 0) + revenue;
          vendoLiters[vendoId] = (vendoLiters[vendoId] ?? 0) + liters;
          vendoDispenses[vendoId] = (vendoDispenses[vendoId] ?? 0) + 1;
          grandTotal += revenue;
        }
      }
    });

    return {
      'vendoRevenue': vendoRevenue,
      'vendoLiters': vendoLiters,
      'vendoDispenses': vendoDispenses,
      'grandTotal': grandTotal,
    };
  }

  // Generate PDF Receipt
  Future<void> _generateReceipt({
    required double grandTotal,
    required double totalLiters,
    required int totalDispenses,
    required List<Map<String, dynamic>> vendoBreakdown,
    String? customPeriod,
    bool isYearly = false,
    int? year,
  }) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final now = DateTime.now();

      // Use a push() key to guarantee a unique receipt id — avoids collisions
      // when receipts are deleted/re-counted or generated concurrently.
      final String pushKey = _dbRef.child('receipts').push().key!;
      String receiptNumber = "RCP-${now.year}-$pushKey";

      String period = customPeriod ?? _selectedFilter;

      await _dbRef.child('receipts/$receiptNumber').set({
        'receipt_number': receiptNumber,
        'admin_name': _adminName ?? "Admin",
        'admin_email': _adminEmail ?? "",
        'period': period,
        'grand_total': grandTotal,
        'total_liters': totalLiters,
        'total_dispenses': totalDispenses,
        'generated_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
        'status': 'Generated',
        'type': isYearly ? 'annual' : 'regular',
      });

      await RevenueReceiptService.generateAndPrint(
        receiptNumber: receiptNumber,
        adminName: _adminName ?? "Admin",
        adminEmail: _adminEmail ?? "",
        period: period,
        grandTotal: grandTotal,
        totalLiters: totalLiters,
        totalDispenses: totalDispenses,
        vendoBreakdown: vendoBreakdown,
      );

      if (isYearly && year != null) {
        setState(() => _downloadedYears.add(year));
      }

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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    "Dispenses: $totalDispenses times",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                Text("₱${grandTotal.toStringAsFixed(2)} marked as collected!"),
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

  // Delete Yearly Logs with Admin Password Confirmation
  Future<void> _deleteYearlyLogs(
      int year, Map<dynamic, dynamic> logsData) async {
    final TextEditingController passwordController =
        TextEditingController();
    bool isPasswordVisible = false;
    String? errorText;

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Delete Logs",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "⚠️ You are about to delete:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "All $year dispense logs",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "This action CANNOT be undone!",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // What will NOT be deleted
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "✅ These will NOT be deleted:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "• Student hydration history\n• Receipt records\n• Collection records\n• Vendo settings",
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Admin password field
                Text(
                  "Enter your admin password to confirm:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: "Admin password",
                    errorText: errorText,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.red[700]!,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (passwordController.text.trim().isEmpty) {
                    setDialogState(() {
                      errorText = "Please enter your password";
                    });
                    return;
                  }

                  // Verify admin password via Firebase Auth
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null || user.email == null) return;

                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text.trim(),
                    );

                    await user.reauthenticateWithCredential(credential);
                    Navigator.pop(context, true);
                  } catch (e) {
                    setDialogState(() {
                      errorText = "Incorrect password. Please try again.";
                    });
                  }
                },
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text(
                  "Delete",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeletingLogs = true);

      try {
        // Delete all dispense logs for the selected year in a single
        // multi-path update instead of one request per key.
        Map<String, dynamic> updates = {};
        logsData.forEach((key, value) {
          if (value is Map) {
            String timestamp = value['timestamp']?.toString() ?? "";
            if (timestamp.startsWith(year.toString())) {
              updates['dispense_logs/$key'] = null;
            }
          }
        });

        int deletedCount = updates.length;

        if (updates.isNotEmpty) {
          await _dbRef.update(updates);
        }

        // Reset download flag for this year only
        setState(() {
          _downloadedYears.remove(year);
          _isDeletingLogs = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                      "$deletedCount logs from $year deleted successfully!"),
                ],
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() => _isDeletingLogs = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting logs: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
                        value['settings']?['ml_per_peso']?.toString() ??
                            "100",
                      ) ??
                      100.0;
                  vendoMlPerPeso[key.toString()] = mlPerPeso;
                }
              });
            }

            // Current filter data
            Map<String, double> vendoRevenue = {};
            Map<String, double> vendoLiters = {};
            Map<String, int> vendoDispenses = {};
            double grandTotal = 0.0;

            Map<dynamic, dynamic> allLogsData = {};

            if (logsSnapshot.hasData &&
                logsSnapshot.data!.snapshot.value != null) {
              allLogsData = logsSnapshot.data!.snapshot.value
                  as Map<dynamic, dynamic>;

              allLogsData.forEach((key, value) {
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

            // Check available years
            bool hasYearOldData = allLogsData.isNotEmpty
                ? _hasYearOldData(allLogsData)
                : false;
            List<int> availableYears = allLogsData.isNotEmpty
                ? _getAvailableYears(allLogsData)
                : [];

            return Column(
              children: [
                // Tab Bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue[800],
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue[800],
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: "Current Reports"),
                      Tab(text: "Annual Archive"),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // =============================================
                      // TAB 1 — CURRENT REPORTS (existing design)
                      // =============================================
                      SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            isMobile
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildFilterDropdown(),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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

                            // Grand Total Card
                            Container(
                              width: double.infinity,
                              padding:
                                  EdgeInsets.all(isMobile ? 18 : 24),
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
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

                            // PDF + Mark as Collected Buttons
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
                                        child:
                                            _buildMarkAsCollectedButton(
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

                            // Summary Cards
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

                            // Per Vendo Breakdown
                            _buildVendoBreakdown(
                              sortedVendos: sortedVendos,
                              vendoNames: vendoNames,
                              vendoMlPerPeso: vendoMlPerPeso,
                              vendoLiters: vendoLiters,
                              vendoDispenses: vendoDispenses,
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                      ),

                      // =============================================
                      // TAB 2 — ANNUAL ARCHIVE
                      // =============================================
                      SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            const Text(
                              "Annual Archive",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Text(
                              "Download and manage yearly dispense records",
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),

                            const SizedBox(height: 20),

                            // Check kung may available years
                            if (!hasYearOldData) ...[
                              // Walang 1 year old data pa
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty_rounded,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Not Yet Available",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Annual reports will be available once you have\ncomplete data from a previous year.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "Available after ${DateTime.now().year + 1}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // May available years — ipakita ang bawat taon
                              ...availableYears.map((year) {
                                final yearData = _computeYearlyData(
                                  allLogsData,
                                  year,
                                  vendoNames,
                                  vendoMlPerPeso,
                                );

                                double yearGrandTotal =
                                    yearData['grandTotal'] as double;
                                Map<String, double> yearVendoRevenue =
                                    yearData['vendoRevenue']
                                        as Map<String, double>;
                                Map<String, double> yearVendoLiters =
                                    yearData['vendoLiters']
                                        as Map<String, double>;
                                Map<String, int> yearVendoDispenses =
                                    yearData['vendoDispenses']
                                        as Map<String, int>;

                                int yearTotalDispenses = yearVendoDispenses
                                    .values
                                    .fold(0, (a, b) => a + b);
                                double yearTotalLiters = yearVendoLiters
                                    .values
                                    .fold(0.0, (a, b) => a + b);

                                var yearSortedVendos =
                                    yearVendoRevenue.entries.toList()
                                      ..sort((a, b) =>
                                          b.value.compareTo(a.value));

                                List<Map<String, dynamic>>
                                    yearVendoBreakdown =
                                    yearSortedVendos.map((e) => {
                                          'id': e.key,
                                          'name': vendoNames[e.key] ??
                                              e.key,
                                          'revenue': e.value,
                                          'liters':
                                              yearVendoLiters[e.key] ??
                                                  0.0,
                                          'dispenses':
                                              yearVendoDispenses[e.key] ??
                                                  0,
                                          'mlPerPeso':
                                              vendoMlPerPeso[e.key] ??
                                                  100.0,
                                        }).toList();

                                bool isYearDownloaded =
                                    _downloadedYears.contains(year);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.grey[200]!),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey
                                            .withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Year Header
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.indigo.shade700,
                                              Colors.indigo.shade500,
                                            ],
                                          ),
                                          borderRadius:
                                              const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                              ),
                                              child: const Icon(
                                                Icons.calendar_month_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    "Annual Report $year",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    "$yearTotalDispenses dispenses • ${yearTotalLiters.toStringAsFixed(2)}L",
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              "₱${yearGrandTotal.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Summary per vendo
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            // Summary Cards
                                            Row(
                                              children: [
                                                _buildSummaryCard(
                                                  "Total Revenue",
                                                  "₱${yearGrandTotal.toStringAsFixed(2)}",
                                                  Icons
                                                      .monetization_on_rounded,
                                                  Colors.indigo,
                                                ),
                                                const SizedBox(width: 12),
                                                _buildSummaryCard(
                                                  "Total Liters",
                                                  "${yearTotalLiters.toStringAsFixed(2)} L",
                                                  Icons.water_drop_rounded,
                                                  Colors.blue,
                                                ),
                                                const SizedBox(width: 12),
                                                _buildSummaryCard(
                                                  "Total Dispenses",
                                                  "$yearTotalDispenses times",
                                                  Icons.repeat_rounded,
                                                  Colors.green,
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 16),

                                            // Download Annual Receipt Button
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                      Colors.indigo[700],
                                                  foregroundColor:
                                                      Colors.white,
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    vertical: 14,
                                                    horizontal: 20,
                                                  ),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(10),
                                                  ),
                                                ),
                                                onPressed: _isGeneratingPdf
                                                    ? null
                                                    : () =>
                                                        _generateReceipt(
                                                          grandTotal:
                                                              yearGrandTotal,
                                                          totalLiters:
                                                              yearTotalLiters,
                                                          totalDispenses:
                                                              yearTotalDispenses,
                                                          vendoBreakdown:
                                                              yearVendoBreakdown,
                                                          customPeriod:
                                                              "Annual Report $year",
                                                          isYearly: true,
                                                          year: year,
                                                        ),
                                                icon: _isGeneratingPdf
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              Colors.white,
                                                        ),
                                                      )
                                                    : const Icon(Icons
                                                        .download_rounded),
                                                label: Text(
                                                  _isGeneratingPdf
                                                      ? "Generating..."
                                                      : "Download $year Annual Receipt",
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Delete Button — lalabas ONLY after ma-download itong specific year
                                            if (isYearDownloaded) ...[
                                              const SizedBox(height: 10),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton.icon(
                                                  style: OutlinedButton
                                                      .styleFrom(
                                                    foregroundColor:
                                                        Colors.red[700],
                                                    side: BorderSide(
                                                      color:
                                                          Colors.red[700]!,
                                                    ),
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      vertical: 14,
                                                      horizontal: 20,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(10),
                                                    ),
                                                  ),
                                                  onPressed: _isDeletingLogs
                                                      ? null
                                                      : () =>
                                                          _deleteYearlyLogs(
                                                            year,
                                                            allLogsData,
                                                          ),
                                                  icon: _isDeletingLogs
                                                      ? SizedBox(
                                                          width: 18,
                                                          height: 18,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors
                                                                .red[700],
                                                          ),
                                                        )
                                                      : const Icon(Icons
                                                          .delete_forever_rounded),
                                                  label: Text(
                                                    _isDeletingLogs
                                                        ? "Deleting..."
                                                        : "Delete $year Logs",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Vendo Breakdown Widget
  Widget _buildVendoBreakdown({
    required List<MapEntry<String, double>> sortedVendos,
    required Map<String, String> vendoNames,
    required Map<String, double> vendoMlPerPeso,
    required Map<String, double> vendoLiters,
    required Map<String, int> vendoDispenses,
    required bool isMobile,
  }) {
    return Container(
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
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
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
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                String vendoId = sortedVendos[index].key;
                double revenue = sortedVendos[index].value;
                String name = vendoNames[vendoId] ?? vendoId;
                double mlPerPeso = vendoMlPerPeso[vendoId] ?? 100.0;

                double maxRevenue = sortedVendos.first.value;
                double progress =
                    maxRevenue > 0 ? revenue / maxRevenue : 0;

                Color rankColor = index == 0
                    ? Colors.amber
                    : index == 1
                        ? Colors.grey
                        : index == 2
                            ? Colors.brown
                            : Colors.blue;

                return Padding(
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: rankColor.withOpacity(0.15),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(rankColor),
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
    );
  }

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
        label:
            Text(_isGeneratingPdf ? "Generating..." : "Export PDF Receipt"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
}