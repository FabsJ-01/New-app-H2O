import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Para sa pag-add ng unit
import 'overview_page.dart'; 
import 'user_management.dart';
import 'dispense_logs_page.dart'; // Eto ang bagong import para sa Dispense Logs page

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _activeScreen = "Overview";
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // --- POPUP PARA SA PAG-ADD NG BAGONG UNIT ---
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
                // Initial data para sa bagong vendo
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
    return Scaffold(
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 260,
            color: const Color.fromARGB(255, 141, 193, 252), // PSU Maroon (Note: Base sa hex na 'to, ito yung asul mo sa photo)
            child: Column(
              children: [
                const DrawerHeader(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.water_drop, color: Colors.blue, size: 50),
                      SizedBox(height: 10),
                      Text("H2O HUB ADMIN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("PSU Lubao Campus", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                _buildSidebarItem(Icons.dashboard, "Overview"),
                _buildSidebarItem(Icons.assignment, "Dispense Logs"),
                _buildSidebarItem(Icons.people, "User Management"),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Colors.white24),
                ),

                // --- ETO YUNG DINAGDAG NA ADD UNIT BUTTON ---
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.greenAccent),
                  title: const Text("Add New Unit", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  onTap: _showAddVendoDialog,
                ),

                const Spacer(),
                
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text("Logout", style: TextStyle(color: Colors.white70)),
                  onTap: _logout,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // --- DYNAMIC CONTENT (UPDATED SWITCH LOGIC) ---
          Expanded(
            child: Container(
              color: Colors.blueGrey[50],
              padding: const EdgeInsets.all(30),
              child: _buildBodyContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Ginawa nating malinis na Method Switch para madaling basahin ang pagpapalit ng Screens
  Widget _buildBodyContent() {
    switch (_activeScreen) {
      case "Overview":
        return const OverviewPage();
      case "Dispense Logs":
        return const DispenseLogsPage(); // Eto na yung tinatawag nitong bagong gawa mong page!
      case "User Management":
        return const UserManagement();
      default:
        return const OverviewPage();
    }
  }

  Widget _buildSidebarItem(IconData icon, String title) {
    bool isSelected = _activeScreen == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.white70),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () => setState(() => _activeScreen = title),
    );
  }
}