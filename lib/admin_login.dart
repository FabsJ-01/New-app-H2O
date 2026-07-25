import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard.dart'; 
import 'admin_register.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Variable for password visibility toggle
  bool _isObscured = true;
  bool _isLoading = false;

  // Login Function with Loading Indicator
  void _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
        // Redirect to Admin Dashboard upon successful login
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const AdminDashboard())
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Forgot Password Function
  void _forgotPassword() async {
    // Validate email field before sending reset link
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address first.")),
      );
      return;
    }

    try {
      // Send password reset email via Firebase Authentication
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset link has been sent. Please check your email."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Full-screen background container with image and color overlay
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgAdminlgn.jpg'),
            fit: BoxFit.cover,
            // Blue tint overlay applied on top of the background image
            colorFilter: ColorFilter.mode(
              Color.fromARGB(93, 99, 172, 255),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: Center(
          // Scrollable layout to prevent overflow when keyboard appears
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                // Slightly transparent white card
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Title
                  const Text(
                    "H2O ADMIN LOGIN", 
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Color.fromARGB(255, 24, 151, 255)
                    )
                  ),
                  const SizedBox(height: 20),
                  
                  // Email Input Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email", 
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    )
                  ),
                  const SizedBox(height: 15),
                  
                  // Password Input Field with Show/Hide Toggle
                  TextField(
                    controller: _passwordController, 
                    obscureText: _isObscured,
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
                            // Toggle password visibility
                            _isObscured = !_isObscured;
                          });
                        },
                      ),
                    ),
                  ),

                  // Forgot Password Link (aligned to the right)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Login Button with Loading Indicator
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "LOGIN", 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Registration Navigation Link
                  TextButton(
                    onPressed: _isLoading ? null : () {
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