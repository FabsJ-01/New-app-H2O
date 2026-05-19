import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// GLOBAL INITIALIZATION
final DatabaseReference globalUserRef = FirebaseDatabase.instance.ref('users');

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  void _showDeleteUserDialog(String uid, String psuId) {
    TextEditingController adminPassController = TextEditingController();
    bool obscureAdminPass = true; // State para sa pagpapakita o pagtatago ng password

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Confirm Delete Account"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Sigurado ka bang buburahin ang account ni $psuId?"),
                const SizedBox(height: 15),
                TextField(
                  controller: adminPassController,
                  obscureText: obscureAdminPass, // Nakatali sa state variable
                  decoration: InputDecoration(
                    labelText: "Admin Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureAdminPass ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        // setDialogState ang mag-a-update ng UI sa loob lang ng dialog
                        setDialogState(() {
                          obscureAdminPass = !obscureAdminPass;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("Cancel")
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    User? admin = FirebaseAuth.instance.currentUser;
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: admin!.email!,
                      password: adminPassController.text.trim(),
                    );
                    
                    await admin.reauthenticateWithCredential(credential);
                    await globalUserRef.child(uid).remove(); 
                    if (context.mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User Deleted"), backgroundColor: Colors.red)
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mali ang Admin Password!"))
                    );
                  }
                },
                child: const Text("Delete", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "User Management", 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search PSU ID...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), 
                borderSide: BorderSide.none
              ),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: StreamBuilder(
                stream: globalUserRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text("No users found."));
                  }

                  Map<String, dynamic> users = {};
                  final rawData = snapshot.data!.snapshot.value;

                  if (rawData is Map) {
                    rawData.forEach((key, value) {
                      users[key.toString()] = Map<String, dynamic>.from(value as Map);
                    });
                  } else if (rawData is List) {
                    for (int i = 0; i < rawData.length; i++) {
                      if (rawData[i] != null) {
                        users[i.toString()] = Map<String, dynamic>.from(rawData[i] as Map);
                      }
                    }
                  }

                  var filteredEntries = users.entries.where((e) {
                    String psuId = (e.value['psu_id'] ?? "").toString().toLowerCase();
                    return psuId.contains(searchQuery.toLowerCase());
                  }).toList();

                  if (filteredEntries.isEmpty) {
                    return const Center(child: Text("No matching PSU ID found."));
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              columnSpacing: (constraints.maxWidth < 600) ? 20 : 40, 
                              headingRowHeight: 50,
                              dataRowHeight: 60,
                              columns: const [
                                DataColumn(label: Text("PSU ID", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Intake", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Update", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredEntries.map((entry) {
                                String uid = entry.key;
                                var data = entry.value;
                                String psuId = (data['psu_id'] ?? "-").toString();
                                String intake = (data['intake'] ?? "0").toString();
                                String lastUpdate = (data['last_update'] ?? "-").toString();

                                return DataRow(cells: [
                                  DataCell(Text(psuId, style: const TextStyle(fontSize: 13))),
                                  DataCell(Text("$intake ml", style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(lastUpdate, style: const TextStyle(fontSize: 11, color: Colors.blue))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                                          onPressed: () => _showDeleteUserDialog(uid, psuId),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    }
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}