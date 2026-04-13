import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'change_password_page.dart';
import 'login_page.dart'; // Siguraduhing tama ang path ng login page mo

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    // Logic para makuha ang PSU ID mula sa email (e.g., 2023311060 mula sa 2023311060@psu.edu.ph)
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Center(
              child: Icon(Icons.account_circle, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Pinalitan ang User ID label ng PSU ID
            Text("PSU ID: $psuId", 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("${user?.email}", style: const TextStyle(color: Colors.grey)),
            
            const Spacer(),
            
            // Change Password Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  );
                },
                child: const Text("Change Password", style: TextStyle(color: Colors.white)),
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
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    // Tatanggalin lahat ng nasa stack para malinis ang pagbalik sa Login
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                child: Text("Logout", style: TextStyle(color: Colors.red[700])),
              ),
            ),
            const SizedBox(height: 20), // Padding sa pinakababa
          ],
        ),
      ),
    );
  }
}