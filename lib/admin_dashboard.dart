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
  String _activeScreen = "Overview";

  // --- 1. ADD VENDO LOGIC ---
  void _addNewVendo(String id, String name) {
    if (id.isEmpty || name.isEmpty) return;

    _dbRef.child('vendos/$id').set({
      'name': name,
      'water_level': 100,
      'wifi_status': "Offline",
      'force_dispense': false,
      'last_online': "Never",
      'settings': {
        'ml_per_peso': 200, // Standard PSU H2O Calibration
      }
    }).then((_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New Vendo Added Successfully!"), backgroundColor: Colors.green),
      );
    });
  }

  void _showAddVendoDialog() {
    TextEditingController idController = TextEditingController();
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Vendo Unit"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idController, decoration: const InputDecoration(labelText: "Vendo ID (e.g. vendo_002)")),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Vendo Name (e.g. CCS Building)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => _addNewVendo(idController.text, nameController.text),
            child: const Text("Add Vendo"),
          ),
        ],
      ),
    );
  }

  // --- NEW: EDIT VENDO NAME LOGIC ---
  void _editVendoName(String id, String currentName) {
    TextEditingController nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Vendo Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "New Vendo Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _dbRef.child('vendos/$id/name').set(nameController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Name updated successfully!"), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- 2. DELETE LOGIC WITH AUTHENTICATION ---
  void _deleteVendo(String id, String inputPassword) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && user.email != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: inputPassword,
        );

        await user.reauthenticateWithCredential(credential);
        await _dbRef.child('vendos/$id').remove();
        
        if (!mounted) return;
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vendo $id has been permanently deleted."), backgroundColor: Colors.red),
        );
      } on FirebaseAuthException catch (e) {
        String errorMsg = e.code == 'wrong-password' ? "Mali ang Admin password mo." : "Authentication Error.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.orange),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("May error sa pag-delete. Check connection."), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteDialog(String id, String name) {
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text("Confirm Delete"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sigurado ka bang buburahin mo ang $name ($id)?"),
            const Text("Action cannot be undone.", style: TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Enter Login Password to Confirm",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => _deleteVendo(id, passwordController.text.trim()),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // --- 3. COMMAND LOGIC ---
  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _sendCommand(String commandPath, dynamic value, Color snackColor) {
    _dbRef.child(commandPath).set(value).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: snackColor,
          content: Text("Command Sent: $commandPath = $value"),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 260,
            color: const Color.fromARGB(255, 128, 0, 0), // PSU Maroon
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
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.greenAccent),
                  title: const Text("Add New Vendo", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  onTap: _showAddVendoDialog,
                ),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text("Logout", style: TextStyle(color: Colors.white)),
                  onTap: _logout,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // --- DYNAMIC CONTENT ---
          Expanded(
            child: Container(
              color: Colors.blueGrey[50],
              padding: const EdgeInsets.all(30),
              child: _activeScreen == "Overview" 
                  ? _buildOverviewContent() 
                  : _buildLogsContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Realtime Vendo Monitoring", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          StreamBuilder(
            stream: _dbRef.child('vendos').onValue,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                final dynamic rawData = snapshot.data!.snapshot.value;
                List<Widget> vendoCards = [];

                if (rawData is Map) {
                  rawData.forEach((key, value) {
                    vendoCards.add(_buildVendoMonitorCard(key.toString(), Map<dynamic, dynamic>.from(value)));
                  });
                } else if (rawData is List) {
                  for (int i = 0; i < rawData.length; i++) {
                    if (rawData[i] != null) {
                      vendoCards.add(_buildVendoMonitorCard(i.toString(), Map<dynamic, dynamic>.from(rawData[i])));
                    }
                  }
                }
                return Column(children: vendoCards);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Dispense Logs History", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: StreamBuilder(
              stream: _dbRef.child('dispense_logs').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final dynamic rawLogs = snapshot.data!.snapshot.value;
                  List<dynamic> logsList = [];

                  if (rawLogs is Map) {
                    logsList = rawLogs.values.toList();
                  } else if (rawLogs is List) {
                    logsList = rawLogs.where((element) => element != null).toList();
                  }

                  logsList.sort((a, b) => (b['timestamp'] ?? "").compareTo(a['timestamp'] ?? ""));

                  return ListView.separated(
                    padding: const EdgeInsets.all(15),
                    itemCount: logsList.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      var log = logsList[index];
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                        title: Text("PSU ID: ${log['psu_id'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Time: ${log['timestamp'] ?? 'N/A'} | Vendo: ${log['vendo_id'] ?? 'N/A'}"),
                        trailing: Text("${log['amount_ml'] ?? 0}ml", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      );
                    },
                  );
                }
                return const Center(child: Text("No logs available yet."));
              },
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildVendoMonitorCard(String id, Map<dynamic, dynamic> data) {
    String name = data['name'] ?? "Unknown Vendo";
    int waterLevel = data['water_level'] ?? 0;
    String status = data['wifi_status'] ?? "Offline";
    bool isOnline = status == "Connected";
    int mlPerPeso = (data['settings'] != null) ? (data['settings']['ml_per_peso'] ?? 200) : 200;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                          onPressed: () => _editVendoName(id, name),
                          tooltip: "Edit Name",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text("ID: $id", style: const TextStyle(color: Colors.grey)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => _showDeleteDialog(id, name)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isOnline ? Colors.green[100] : Colors.red[100], borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: isOnline ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 40),
            
            // Pricing Controller
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Water Pricing Config", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle, color: Colors.orange), onPressed: () {
                        if (mlPerPeso > 10) _dbRef.child('vendos/$id/settings/ml_per_peso').set(mlPerPeso - 10);
                      }),
                      Text("$mlPerPeso ml / ₱1", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add_circle, color: Colors.orange), onPressed: () {
                        if (mlPerPeso < 1000) _dbRef.child('vendos/$id/settings/ml_per_peso').set(mlPerPeso + 10);
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildQuickStat("Water Level", "$waterLevel%", Icons.opacity, waterLevel > 20 ? Colors.blue : Colors.red),
                _buildQuickStat("Status", status, Icons.wifi, isOnline ? Colors.green : Colors.red),
                _buildQuickStat("Ratio", "₱1:${mlPerPeso}ml", Icons.scale, Colors.teal),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildActionButton("Force Dispense", Icons.play_circle_fill, Colors.green, () => _sendCommand("vendos/$id/force_dispense", true, Colors.green))),
                const SizedBox(width: 15),
                Expanded(child: _buildActionButton("Refill Reset", Icons.opacity, Colors.blue, () => _sendCommand("vendos/$id/water_level", 100, Colors.blue))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title) {
    bool isSelected = _activeScreen == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.white70),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
      onTap: () => setState(() => _activeScreen = title),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}