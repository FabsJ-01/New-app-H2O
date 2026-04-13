import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart'; 
import 'dashboard.dart';    

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
    // 1. Check muna kung may laman ang fields
    if (idController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pakisulat ang PSU ID at Password."), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      // 2. Logic: Ginagawang email ang ID sa background (@psu.edu.ph)
      String psuEmail = "${idController.text.trim()}@psu.edu.ph";

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: psuEmail,
        password: passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 3. Mas specific na error messages
      String errorMessage = "Mali ang PSU ID o Password.";
      
      if (e.code == 'user-not-found') {
        errorMessage = "Hindi rehistrado ang ID na ito.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Maling password. Pakisubukang muli.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Format error sa ID Number.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ginamit ko ang SingleChildScrollView para hindi mag-error ang layout pag lumabas ang keyboard
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder or PSU Title
              const Icon(Icons.water_drop, size: 80, color: Colors.blue),
              const SizedBox(height: 10),
              const Text(
                "PSU H2O LOGIN", 
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)) // Dark Blue PSU Color
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
                    backgroundColor: const Color(0xFF0D47A1), // PSU Dark Blue
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