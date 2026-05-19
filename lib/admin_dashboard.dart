import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; 
import 'overview_page.dart'; 
import 'user_management.dart';
import 'dispense_logs_page.dart'; 

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _activeScreen = "Overview";
  bool _isSidebarExpanded = true; 
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _showAddVendoDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Add New Vendo Unit", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: "Vendo ID (e.g., vendo_003)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Vendo Name (e.g., PLC Vendo 3)", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (idController.text.isNotEmpty && nameController.text.isNotEmpty) {
                _dbRef.child('vendos/${idController.text}').set({
                  "name": nameController.text,
                  "water_level": 100,
                  "wifi_status": "Offline",
                  "force_dispense": false,
                  "settings": {"ml_per_peso": 200}
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("New Unit Added Successfully!")),
                );
              }
            },
            child: const Text("Add Unit", style: TextStyle(color: Colors.white)),
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
        // TIGNAN KUNG MALIIT ANG SCREEN (Mobile / CP View)
        bool isMobile = constraints.maxWidth < 600;

        return Scaffold(
          // 1. MOBILE APP BAR: Lalabas lang sa CP para may pindutan ng menu drawer
          appBar: isMobile
              ? AppBar(
                  title: Text(_activeScreen, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  backgroundColor: const Color.fromARGB(255, 141, 193, 252),
                  foregroundColor: Colors.white,
                )
              : null,

          // 2. MOBILE DRAWER: Sliding menu para sa CP portrait view
          drawer: isMobile
              ? Drawer(
                  child: Container(
                    color: const Color.fromARGB(255, 141, 193, 252),
                    child: _buildSidebarContent(forceExpand: true, isDrawer: true),
                  ),
                )
              : null,

          // 3. MAIN BODY LAYOUT
          body: Stack(
            children: [
              Row(
                children: [
                  // --- SIDEBAR Component (Para sa PC/Tablet; hidden kapag CP) ---
                  if (!isMobile)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: currentSidebarWidth,
                      color: const Color.fromARGB(255, 141, 193, 252), 
                      child: _buildSidebarContent(forceExpand: _isSidebarExpanded),
                    ),

                  // --- MAIN DYNAMIC CONTENT SCREEN (Overview, Logs, etc.) ---
                  Expanded(
                    child: Container(
                      color: Colors.blueGrey[50],
                      padding: EdgeInsets.all(isMobile ? 15 : 30), // Mas maliit na padding sa mobile
                      child: _buildBodyContent(),
                    ),
                  ),
                ],
              ),

              // --- FLOATING TOGGLE BUTTON (Nakalutang sa line ng Blue/White; hidden sa CP) ---
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
                          _isSidebarExpanded ? Icons.arrow_back_ios_new : Icons.menu,
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

  // --- REUSABLE SIDEBAR CONTENT (Ginagamit ng Sidebar sa PC at Drawer sa Mobile) ---
  Widget _buildSidebarContent({required bool forceExpand, bool isDrawer = false}) {
    return Column(
      children: [
        Container(
          height: 160,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: forceExpand
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue, size: 45),
                    SizedBox(height: 10),
                    Text("H2O HUB ADMIN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("PSU Lubao Campus", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                )
              : const Center(
                  child: Icon(Icons.water_drop, color: Colors.blue, size: 30),
                ),
        ),
        
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 15),

        _buildSidebarItem(Icons.dashboard, "Overview", forceExpand, isDrawer),
        _buildSidebarItem(Icons.assignment, "Dispense Logs", forceExpand, isDrawer),
        _buildSidebarItem(Icons.people, "User Management", forceExpand, isDrawer),
        
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Divider(color: Colors.white24),
        ),

        ListTile(
          horizontalTitleGap: 10,
          leading: const Icon(Icons.add_circle, color: Color.fromARGB(255, 0, 93, 150)),
          title: forceExpand 
              ? const Text("Add New Unit", style: TextStyle(color: Color.fromARGB(255, 0, 93, 150), fontWeight: FontWeight.bold))
              : null,
          onTap: () {
            if (isDrawer) Navigator.pop(context); // Isasara ang drawer sa CP bago lumabas ang dialog
            _showAddVendoDialog();
          },
        ),

        const Spacer(),
        
        ListTile(
          horizontalTitleGap: 10,
          leading: const Icon(Icons.logout, color: Color.fromARGB(179, 219, 33, 33)),
          title: forceExpand ? const Text("Logout", style: TextStyle(color: Color.fromARGB(179, 159, 26, 26))) : null,
          onTap: _logout,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBodyContent() {
    switch (_activeScreen) {
      case "Overview":
        return const OverviewPage();
      case "Dispense Logs":
        return const DispenseLogsPage(); 
      case "User Management":
        return const UserManagement();
      default:
        return const OverviewPage();
    }
  }

  Widget _buildSidebarItem(IconData icon, String title, bool expandText, bool isDrawer) {
    bool isSelected = _activeScreen == title;
    return ListTile(
      horizontalTitleGap: 10,
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.white70),
      title: expandText 
          ? Text(
              title, 
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              ),
            )
          : null,
      onTap: () {
        setState(() => _activeScreen = title);
        if (isDrawer) Navigator.pop(context); // Automatic isasara ang drawer sa mobile pagkapili ng screen
      },
    );
  }
}