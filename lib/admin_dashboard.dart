import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; 
import 'overview_page.dart'; 
import 'user_management.dart';
import 'dispense_logs_page.dart'; 
import 'analytics_page.dart';
import 'admin_login.dart'; 
import 'revenue_report_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _activeScreen = "Overview";
  bool _isSidebarExpanded = true; 
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Logout Function with Confirmation Dialog
  void _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Confirm Logout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginPage()),
        (route) => false,
      );
    }
  }

  // Add New Vendo Dialog
  void _showAddVendoDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Add New Vendo Unit",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: "Vendo ID (e.g., vendo_003)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Vendo Name (e.g., PLC Vendo 3)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (idController.text.isNotEmpty && nameController.text.isNotEmpty) {
                _dbRef.child('vendos/${idController.text}').set({
                  "name": nameController.text,
                  "water_level": 100,
                  "wifi_status": "Offline",
                  "force_dispense": false,
                  "settings": {
                    "ml_per_peso": 100,
                    "ms_per_ml": 25.0 // ✅ ISINAMA ANG HARDWARE CALIBRATION DEFAULT RATE
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("New Unit Added Successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              "Add Unit",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double currentSidebarWidth = _isSidebarExpanded ? 260 : 70;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return Scaffold(
          appBar: isMobile
              ? AppBar(
                  title: Text(
                    _activeScreen,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  backgroundColor: const Color.fromARGB(255, 141, 193, 252),
                  foregroundColor: Colors.white,
                )
              : null,

          drawer: isMobile
              ? Drawer(
                  child: Container(
                    color: const Color.fromARGB(255, 141, 193, 252),
                    child: _buildSidebarContent(
                      forceExpand: true,
                      isDrawer: true,
                    ),
                  ),
                )
              : null,

          body: Stack(
            children: [
              Row(
                children: [
                  // Sidebar for Desktop
                  if (!isMobile)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: currentSidebarWidth,
                      color: const Color.fromARGB(255, 141, 193, 252),
                      child: _buildSidebarContent(
                        forceExpand: _isSidebarExpanded,
                      ),
                    ),

                  // Main Content Area
                  Expanded(
                    child: Container(
                      color: Colors.blueGrey[50],
                      padding: EdgeInsets.all(isMobile ? 15 : 30),
                      child: _buildBodyContent(),
                    ),
                  ),
                ],
              ),

              // Sidebar Toggle Button (Desktop only)
              if (!isMobile)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  left: currentSidebarWidth - 18,
                  top: 30,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSidebarExpanded = !_isSidebarExpanded;
                      });
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: const Color.fromARGB(255, 141, 193, 252),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _isSidebarExpanded
                              ? Icons.arrow_back_ios_new
                              : Icons.menu,
                          color: Colors.blue[800],
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Sidebar Content
  Widget _buildSidebarContent({required bool forceExpand, bool isDrawer = false}) {
    return Column(
      children: [
        // Sidebar Header
        Container(
          height: 160,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: forceExpand
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue, size: 45),
                    SizedBox(height: 10),
                    Text(
                      "H2O HUB ADMIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "PSU Lubao Campus",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                )
              : const Center(
                  child: Icon(Icons.water_drop, color: Colors.blue, size: 30),
                ),
        ),

        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 15),

        // Sidebar Menu Items
        _buildSidebarItem(Icons.dashboard, "Overview", forceExpand, isDrawer),
        _buildSidebarItem(Icons.bar_chart, "Analytics & Reports", forceExpand, isDrawer),
        _buildSidebarItem(Icons.assignment, "Dispense Logs", forceExpand, isDrawer),
        _buildSidebarItem(Icons.people, "User Management", forceExpand, isDrawer),
        _buildSidebarItem(Icons.monetization_on_rounded, "Revenue Report", forceExpand, isDrawer),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Divider(color: Colors.white24),
        ),

        // Add New Unit Button
        Tooltip(
          message: forceExpand ? "" : "Add New Unit",
          child: ListTile(
            horizontalTitleGap: 10,
            leading: const Icon(
              Icons.add_circle,
              color: Color.fromARGB(255, 0, 93, 150),
            ),
            title: forceExpand
                ? const Text(
                    "Add New Unit",
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 93, 150),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            onTap: () {
              if (isDrawer) Navigator.pop(context);
              _showAddVendoDialog();
            },
          ),
        ),

        const Spacer(),

        // Logout Button
        Tooltip(
          message: forceExpand ? "" : "Logout",
          child: ListTile(
            horizontalTitleGap: 10,
            leading: const Icon(
              Icons.logout,
              color: Color.fromARGB(179, 219, 33, 33),
            ),
            title: forceExpand
                ? const Text(
                    "Logout",
                    style: TextStyle(
                      color: Color.fromARGB(179, 159, 26, 26),
                    ),
                  )
                : null,
            onTap: _logout,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Body Content Switch
  Widget _buildBodyContent() {
    switch (_activeScreen) {
      case "Overview":
        return const OverviewPage();
      case "Analytics & Reports":
        return const AnalyticsPage();
      case "Dispense Logs":
        return const DispenseLogsPage();
      case "User Management":
        return const UserManagement();
      case "Revenue Report":
        return const RevenueReportPage();
      default:
        return const OverviewPage();
    }
  }

  // Sidebar Item Builder with Tooltip Support
  Widget _buildSidebarItem(
    IconData icon,
    String title,
    bool expandText,
    bool isDrawer,
  ) {
    bool isSelected = _activeScreen == title;
    return Tooltip(
      message: expandText ? "" : title,
      child: ListTile(
        horizontalTitleGap: 10,
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.white70,
        ),
        title: expandText
            ? Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              )
            : null,
        onTap: () {
          setState(() => _activeScreen = title);
          if (isDrawer) Navigator.pop(context);
        },
      ),
    );
  }
}