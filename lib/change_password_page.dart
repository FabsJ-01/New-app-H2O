import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Variables para sa eye icon toggle
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  // Validation Logic
  bool _isPasswordValid(String password) {
    // Check if length is at least 8
    if (password.length < 8) return false;
    // Check if has uppercase
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    // Check if has lowercase
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    
    return true;
  }

  Future<void> _updatePassword() async {
    String newPass = _newPasswordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar("Please fill all fields");
      return;
    }

    // Check strength requirements
    if (!_isPasswordValid(newPass)) {
      _showSnackBar("Password must be 8+ chars with uppercase & lowercase");
      return;
    }

    if (newPass != confirmPass) {
      _showSnackBar("Passwords do not match!");
      return;
    }

    try {
      await FirebaseAuth.instance.currentUser?.updatePassword(newPass);
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        _showSnackBar("Password updated! Please login again.");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"), 
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // New Password Field
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPass,
              decoration: InputDecoration(
                labelText: "New Password",
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                ),
              ),
            ),
            const SizedBox(height: 15),
            // Re-type Password Field
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPass,
              decoration: InputDecoration(
                labelText: "Re-type New Password",
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "• At least 8 characters\n• Must have Upper and Lowercase letters",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("Submit", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}