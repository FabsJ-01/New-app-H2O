import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Dagdag para makabasa sa Firestore
import 'change_password_page.dart';
import 'login_page.dart'; 

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String userRole = "";
  String userCourse = "";
  String userYear = "";
  String userSection = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // HAKBANG PARA HILAHIN ANG MGA DAGDAG NA INFO MULA SA FIRESTORE
  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            userRole = data['role'] ?? 'Student';
            userCourse = data['course'] ?? 'N/A';
            userYear = data['year'] ?? 'N/A';
            userSection = data['section'] ?? 'N/A';
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print("Error fetching profile data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    String psuId = "Guest";
    if (user?.email != null) {
      psuId = user!.email!.split('@')[0]; 
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Loading screen habang kinukuha ang data
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Center(
                    child: Icon(Icons.account_circle, size: 100, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  
                  // PSU ID Number
                  Text("PSU ID: $psuId", 
                       style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  
                  // Email Address
                  Text("${user?.email}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 15),

                  // ROLE BADGE (Lalabas para sa lahat ng uri ng User)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      userRole.toUpperCase(),
                      style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 10),

                  // --- DYNAMIC INFRASTRUCTURE: LALABAS LANG KAPAG STUDENT ANG ACCOUNT ---
                  if (userRole == "Student" && userCourse != "N/A") ...[
                    _buildProfileInfoRow(Icons.school, "Course", userCourse),
                    const SizedBox(height: 15),
                    _buildProfileInfoRow(Icons.layers, "Year Level", userYear),
                    const SizedBox(height: 15),
                    _buildProfileInfoRow(Icons.class_, "Section", userSection),
                  ],

                  const Spacer(),
                  
                  // Change Password Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                        );
                      },
                      child: const Text("Change Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await _auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                      child: Text("Logout", style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20), 
                ],
              ),
            ),
    );
  }

  // REUSABLE ROW COMPONENT PARA SA IMPORMASYON (Malinis at pantay tingnan)
  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[800], size: 22),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}