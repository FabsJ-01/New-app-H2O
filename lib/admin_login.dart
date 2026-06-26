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
      // Ginamit ang Container sa body para ma-apply ang background image sa buong screen
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgAdminlgn.jpg'), // <-- Dito nakalagay yung imahe mo boss
            fit: BoxFit.cover, // Para sakop nito ang buong screen kahit i-resize ang browser o phone
            
            // 🔥 DITO PUMASOK ANG BLUE OVERLAY BLEND:
            colorFilter: ColorFilter.mode(
              Color.fromARGB(93, 99, 172, 255), // Tint na blue na may kontroladong opacity/transparency
              BlendMode.srcOver,  // Blend mode para pumatong ang kulay sa imahe
            ),
          ),
        ),
        child: Center(
          // SingleChildScrollView para hindi mag-overflow kapag lumabas ang keyboard sa mobile
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // Bahagyang transparent para lumutang ang card sa background
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2), // Medyo pinaitim ang anino para mas lutang ang card
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("H2O ADMIN LOGIN", 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 24, 151, 255))),
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
        ),
      ),
    );
  }
}