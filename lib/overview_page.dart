import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _midnightTimer;

  String get _todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _scheduleMidnightReset();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel(); // Nililinis ang timer kapag umalis sa page para walang memory leak
    super.dispose();
  }

  // --- AUTOMATIC MIDNIGHT RESET TIMER ---
  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    // Mag-ti-trigger eksakto pagpatak ng 12:00 AM para i-clear ang counter kahit walang user interaction
    _midnightTimer = Timer(timeUntilMidnight, () {
      if (mounted) {
        setState(() {
          // Rebuilds the UI, which updates _todayDate and resets the visible count to 0
        });
        _scheduleMidnightReset(); // I-set up muli para sa susunod na hatinggabi
      }
    });
  }

  // --- EDIT NAME DIALOG ---
  void _showEditNameDialog(String id, String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Edit Vendo Name", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "New Name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _dbRef.child('vendos/$id/name').set(nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- AUTHORIZED DELETE DIALOG (LOGIN PASSWORD CONFIRMATION) ---
  void _showDeleteDialog(String id, String name) {
    final TextEditingController passwordController = TextEditingController();
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text("Delete $name?", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter your login password to confirm deletion:"),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Admin Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => isPasswordVisible = !isPasswordVisible),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  final user = _auth.currentUser;
                  if (user != null && user.email != null) {
                    try {
                      AuthCredential credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: passwordController.text.trim(),
                      );

                      await user.reauthenticateWithCredential(credential);
                      await _dbRef.child('vendos').child(id).remove();
                      
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showSnackBar("$name deleted successfully.", Colors.red);
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'wrong-password') {
                        _showSnackBar("Incorrect password! Use your login password.", Colors.orange);
                      } else {
                        _showSnackBar("Authentication error. Please try again.", Colors.orange);
                      }
                    } catch (e) {
                      _showSnackBar("Something went wrong.", Colors.red);
                    }
                  }
                },
                child: const Text("Confirm Delete", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Re-usable SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // Custom Confirmation Dialog (Force Dispense / Refill)
  void _showConfirmDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text("Yes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _sendCommand(String commandPath, dynamic value, Color themeColor) {
    _dbRef.child(commandPath).set(value).then((_) {
      _showSnackBar("Command Sent Successfully!", themeColor);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Realtime Vendo Monitoring", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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

  Widget _buildVendoMonitorCard(String id, Map<dynamic, dynamic> data) {
    String name = data['name'] ?? "Unknown Vendo";
    int waterLevel = data['water_level'] ?? 0;
    String status = data['wifi_status'] ?? "Offline";
    bool isOnline = status == "Connected";
    int mlPerPeso = (data['settings'] != null) ? (data['settings']['ml_per_peso'] ?? 200) : 200;

    return Card(
      margin: const EdgeInsets.only(bottom: 25),
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
                        GestureDetector(
                          onTap: () => _showEditNameDialog(id, name),
                          child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                        ),
                      ],
                    ),
                    Text("ID: $id", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    _statusBadge(isOnline, status),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteDialog(id, name),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 40),
            _buildPricingConfig(id, mlPerPeso),
            const SizedBox(height: 20),
            
            // INAYOS NA LAYOUTBUILDER: Nilagyan ng IntrinsicHeight para maging pantay-pantay ang taas ng mga blocks nang walang overflow aror
            LayoutBuilder(
              builder: (context, constraints) {
                bool isCompact = constraints.maxWidth < 550;
                
                if (isCompact) {
                  return Column(
                    children: [
                      _buildQuickStat("Water Level", "$waterLevel%", Icons.opacity, waterLevel > 20 ? Colors.blue : Colors.red),
                      const SizedBox(height: 12),
                      _buildUsersTodayStat(id),
                      const SizedBox(height: 12),
                      _buildQuickStat("Ratio", "₱1:${mlPerPeso}ml", Icons.scale, Colors.teal),
                    ],
                  );
                } else {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildQuickStat("Water Level", "$waterLevel%", Icons.opacity, waterLevel > 20 ? Colors.blue : Colors.red)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildUsersTodayStat(id)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildQuickStat("Ratio", "₱1:${mlPerPeso}ml", Icons.scale, Colors.teal)),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    "Force Dispense", 
                    Icons.play_circle_fill, 
                    Colors.green, 
                    () => _showConfirmDialog(
                      title: "Confirm Force Dispense",
                      content: "Are you sure you want to trigger a force dispense for $name?",
                      onConfirm: () => _sendCommand("vendos/$id/force_dispense", true, Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionButton(
                    "Refill Reset", 
                    Icons.opacity, 
                    Colors.blue, 
                    () => _showConfirmDialog(
                      title: "Confirm Water Refill",
                      content: "This will reset the water level of $name to 100%. Proceed?",
                      onConfirm: () => _sendCommand("vendos/$id/water_level", 100, Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTodayStat(String vendoId) {
    return StreamBuilder(
      stream: _dbRef.child('dispense_logs').onValue,
      builder: (context, snapshot) {
        int uniqueUsersCount = 0;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final dynamic rawLogs = snapshot.data!.snapshot.value;
          Map<dynamic, dynamic> logs = (rawLogs is Map) ? rawLogs : {};
          
          Set<String> uniqueUsers = {};

          logs.forEach((key, log) {
            String currentLogVendoId = log['vendo_id']?.toString() ?? "";
            
            bool isMatchingVendo = (currentLogVendoId == vendoId) || 
                                   (currentLogVendoId.contains(vendoId)) || 
                                   (vendoId.contains(currentLogVendoId));

            if (isMatchingVendo && log['timestamp']?.toString().startsWith(_todayDate) == true) {
              String? uid = log['uid']?.toString();
              if (uid != null) {
                uniqueUsers.add(uid);
              }
            }
          });
          uniqueUsersCount = uniqueUsers.length;
        }
        return _buildQuickStat("Users Today", "$uniqueUsersCount", Icons.people, Colors.orange);
      },
    );
  }

  Widget _statusBadge(bool isOnline, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: isOnline ? Colors.green[100] : Colors.red[100], 
          borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: isOnline ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPricingConfig(String id, int mlPerPeso) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.orange.withOpacity(0.2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Pricing Config", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          
          // INAYOS NA ROW CONTROLS: Nilagyan ng Flexible at FittedBox para hindi mag-overflow sa CP
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.orange), 
                  onPressed: () {
                    if (mlPerPeso > 10) _dbRef.child('vendos/$id/settings/ml_per_peso').set(mlPerPeso - 10);
                  },
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$mlPerPeso ml / ₱1", 
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.orange), 
                  onPressed: () {
                    if (mlPerPeso < 1000) _dbRef.child('vendos/$id/settings/ml_per_peso').set(mlPerPeso + 10);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    // TINANGGAL ANG FIX HEIGHT AT BINIGYAN NG PADDING: Para kusang sumunod ang taas depende sa sukat ng text nang hindi nagkakaroon ng overflow bar
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  } 

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
          backgroundColor: color, 
          foregroundColor: Colors.white, 
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}