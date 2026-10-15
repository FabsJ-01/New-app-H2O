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
    bool obscureAdminPass = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(
                  "Confirm Delete Account",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sigurado ka bang buburahin ang account ni $psuId?",
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: adminPassController,
                  obscureText: obscureAdminPass,
                  decoration: InputDecoration(
                    labelText: "Admin Password",
                    labelStyle: const TextStyle(fontSize: 13),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureAdminPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () {
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
                child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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
                      const SnackBar(
                        content: Text("User Deleted"),
                        backgroundColor: Color(0xFFDC2626),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mali ang Admin Password!")),
                    );
                  }
                },
                child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER SECTION
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "User Management",
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "View, search, and manage registered student accounts and hydration logs",
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // MODERN SEARCH BAR
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search PSU ID...",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = "");
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          const SizedBox(height: 20),

          // USER DATA DISPLAY (RESPONSIVE TABLE OR MOBILE CARDS)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StreamBuilder(
                stream: globalUserRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return _buildEmptyState("No users found in database.");
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
                    return _buildEmptyState("No matching PSU ID found.");
                  }

                  // RESPONSIVE LAYOUT SWITCHING
                  return isMobile
                      ? _buildMobileUserList(filteredEntries)
                      : _buildDesktopDataTable(filteredEntries);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MOBILE LAYOUT: Clean Card-based List
  Widget _buildMobileUserList(List<MapEntry<String, dynamic>> filteredEntries) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: filteredEntries.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        var entry = filteredEntries[index];
        String uid = entry.key;
        var data = entry.value;
        String psuId = (data['psu_id'] ?? "-").toString();
        String intake = (data['intake'] ?? "0").toString();
        String lastUpdate = (data['last_update'] ?? "-").toString();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.08),
                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      psuId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          "Intake: $intake ml",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        const Text("•", style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lastUpdate,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                ),
                onPressed: () => _showDeleteUserDialog(uid, psuId),
              ),
            ],
          ),
        );
      },
    );
  }

  // DESKTOP LAYOUT: Clean & Modern Data Table
  Widget _buildDesktopDataTable(List<MapEntry<String, dynamic>> filteredEntries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
              headingRowHeight: 48,
              dataRowHeight: 56,
              horizontalMargin: 20,
              columnSpacing: 24,
              dividerThickness: 1,
              columns: const [
                DataColumn(
                  label: Text("PSU ID", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13)),
                ),
                DataColumn(
                  label: Text("Intake", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13)),
                ),
                DataColumn(
                  label: Text("Last Update", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13)),
                ),
                DataColumn(
                  label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13)),
                ),
              ],
              rows: filteredEntries.map((entry) {
                String uid = entry.key;
                var data = entry.value;
                String psuId = (data['psu_id'] ?? "-").toString();
                String intake = (data['intake'] ?? "0").toString();
                String lastUpdate = (data['last_update'] ?? "-").toString();

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                            child: const Icon(Icons.person, size: 16, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            psuId,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "$intake ml",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        lastUpdate,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        tooltip: "Delete User",
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        onPressed: () => _showDeleteUserDialog(uid, psuId),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_rounded, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}