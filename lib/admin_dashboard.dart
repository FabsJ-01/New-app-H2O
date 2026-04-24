import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Function para sa Logout
  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // Function para mag-send ng command sa Raspberry Pi
  void _sendCommand(String commandPath, dynamic value) {
    _dbRef.child(commandPath).set(value).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Command Sent: $commandPath = $value")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 260,
            color: Colors.blueGrey[900],
            child: Column(
              children: [
                const DrawerHeader(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.water_drop, color: Colors.blue, size: 50),
                      SizedBox(height: 10),
                      Text("H2O ADMIN", 
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _buildSidebarItem(Icons.dashboard, "Overview", true),
                _buildSidebarItem(Icons.people, "User Management", false),
                _buildSidebarItem(Icons.history, "Dispense Logs", false),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
                  onTap: _logout,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // MAIN CONTENT AREA
          Expanded(
            child: Container(
              color: Colors.blueGrey[50],
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("System Overview", 
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),

                  // STATS CARDS (Realtime Data)
                  Row(
                    children: [
                      _buildStatCard("Hardware Status", "ONLINE", Icons.memory, Colors.green),
                      _buildStatCard("Total Users", "24", Icons.group, Colors.blue),
                      _buildStatCard("Water Level", "85%", Icons.waves, Colors.cyan),
                    ],
                  ),

                  const SizedBox(height: 40),
                  const Text("Quick Actions", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // CONTROL PANEL
                  Wrap(
                    spacing: 20,
                    children: [
                      _buildActionButton(
                        "Reset Daily Goals", 
                        Icons.refresh, 
                        Colors.orange, 
                        () => _sendCommand("commands/reset_all", true)
                      ),
                      _buildActionButton(
                        "Force Dispense", 
                        Icons.play_arrow, 
                        Colors.green, 
                        () => _sendCommand("commands/force_pump", true)
                      ),
                      _buildActionButton(
                        "System Maintenance", 
                        Icons.build, 
                        Colors.red, 
                        () => _sendCommand("status/mode", "maintenance")
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar Item Helper
  Widget _buildSidebarItem(IconData icon, String title, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.white70),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
      onTap: () {},
      selected: isSelected,
    );
  }

  // Stat Card Helper
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey)),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // Action Button Helper
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        side: BorderSide(color: color),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}