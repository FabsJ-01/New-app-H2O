import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart'; 
import 'dashboard.dart';    
import 'package:firebase_database/firebase_database.dart'; 
import 'change_password_page.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;

  Future<void> _login() async {
    String psuId = idController.text.trim();
    String inputPassword = passwordController.text.trim();

    if (psuId.isEmpty || inputPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pakisulat ang PSU ID at Password."), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      // 1. SILIPIN ANG BUONG USERS NODE PARA HANAPIN KUNG NASAAN ANG PSU ID
      final databaseRef = FirebaseDatabase.instance.ref().child('users');
      final snapshot = await databaseRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> allUsers = snapshot.value as Map<dynamic, dynamic>;
        Map<dynamic, dynamic>? targetUserData;

        // Iikutin ang bawat mahabang UID folder para hanapin ang tumutugmang psu_id
        allUsers.forEach((key, value) {
          if (value is Map && value['psu_id'].toString() == psuId) {
            targetUserData = value;
          }
        });

        // Kung nahanap ang account ng estudyante sa database
        if (targetUserData != null) {
          // KUNG ANG ACCOUNT AY NI-RESET NG ADMIN AT TUGMA ANG INPUT PASSWORD
          if (targetUserData!['status'] == 'Password Reset by Admin' && 
              (targetUserData!['password'] == inputPassword || inputPassword == "PsulubaoH2o" || inputPassword == "${psuId}H2o")) {
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Admin Reset Detected! Pakisulat ang iyong bagong password."), 
                  backgroundColor: Colors.blue
                ),
              );

              // DIRETSO SA CHANGE PASSWORD PAGE 
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
              );
            }
            return; // Hihinto na rito, ligtas sa Auth block!
          }
        }
      }

      // 2. NORMAL LOGIN: Kung hindi naman ni-reset o normal ang status
      String psuEmail = "$psuId@psu.edu.ph";
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: psuEmail,
        password: inputPassword,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Wrong PSU ID or Password.";
      if (e.code == 'user-not-found') {
        errorMessage = "Not registered PSU ID.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password. Please try again.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Email format error.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("System Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop, size: 80, color: Colors.blue),
              const SizedBox(height: 10),
              const Text(
                "PSU H2O LOGIN", 
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))
              ),
              const SizedBox(height: 30),

              // PSU ID FIELD
              TextField(
                controller: idController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "PSU ID Number", 
                  hintText: "e.g. 2023311060",
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.badge)
                ),
              ),
              const SizedBox(height: 15),

              // PASSWORD FIELD
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: const Text(
                    "LOGIN", 
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // GO TO REGISTER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No account?"),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const RegisterPage())
                    ),
                    child: const Text(
                      "Register here", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}