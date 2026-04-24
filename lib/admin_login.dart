import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard.dart'; 
import 'admin_register.dart'; // Idinagdag para sa navigation

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Variable para sa eye icon (Show/Hide password)
  bool _isObscured = true;

  void _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (mounted) {
        // Redirection sa AdminDashboard
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const AdminDashboard())
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("H2O ADMIN LOGIN", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 20),
              
              // Email Field
              TextField(
                controller: _emailController, 
                decoration: const InputDecoration(
                  labelText: "Email", 
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                )
              ),
              const SizedBox(height: 15),
              
              // Password Field with Eye Icon
              TextField(
                controller: _passwordController, 
                obscureText: _isObscured, // Eto yung magha-hide/show ng text
                decoration: InputDecoration(
                  labelText: "Password", 
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured; // Pag click ng eye, magpapalit ang state
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _login, 
                  child: const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 15),
              
              // Register Link
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const AdminRegisterPage())
                  );
                },
                child: const Text("Don't have an account? Register here"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}