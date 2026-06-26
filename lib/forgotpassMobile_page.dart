import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPassMobilePage extends StatefulWidget {
  const ForgotPassMobilePage({super.key});

  @override
  State<ForgotPassMobilePage> createState() => _ForgotPassMobilePageState();
}

class _ForgotPassMobilePageState extends State<ForgotPassMobilePage> {
  // Binago natin ang pangalan ng controller para malinaw na ID ang kinukuha natin
  final _idController = TextEditingController();

  Future<void> _resetPassword() async {
    // 1. Kuhanin ang tinype na PSU ID ng estudyante
    String psuId = _idController.text.trim();

    if (psuId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your PSU ID Number."), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      // 2. 🔥 DITO NATIN ISINAKSAK YUNG CODE, BOSS:
      // Awtomatikong dinala sa format ng school email niyo
      String fullSchoolEmail = "$psuId@pampangastateu.edu.ph"; 

      // 3. Ipadala kay Firebase gamit ang binuong school email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: fullSchoolEmail);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reset link sent to $fullSchoolEmail! Please check your Inbox or Spam folder."),
            backgroundColor: Colors.green,
          ),
        );
        
        // Babalik sa Login Page pagkaraan ng 2 segundo
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = "System Error: ${e.message}";
      if (e.code == 'user-not-found') {
        message = "The PSU ID you entered is not registered in the system.";
      } else if (e.code == 'invalid-email') {
        message = "There is an issue with the format of your school email.";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail_lock, size: 80, color: Color(0xFF0D47A1)),
            const SizedBox(height: 15),
            const Text(
              "Reset your Password",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter your PSU ID Number. We will automatically send a reset link to your official school email.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // DITO MAG-TITAPE NG ID NUMBER ANG ESTUDYANTE
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number, // Number pad para sa ID
              decoration: const InputDecoration(
                labelText: "PSU ID Number",
                hintText: "e.g. 2023311060",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 25),

            // BUTTON PARA MAG-SEND
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _resetPassword, // Kapag kinlik, tatakbo yung function sa itaas
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  "SEND RESET LINK",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}