import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Idinagdag para ma-update ang status sa database
import 'login_page.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Variables para sa eye icon toggle
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

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
    String currentPass = _currentPasswordController.text.trim();
    String newPass = _newPasswordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
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

    setState(() => _isLoading = true);

    try {
      // 1. Kunin ang kasalukuyang user na dinala rito ng login page bypass logic
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null && user.email != null) {
        // 1a. RE-AUTHENTICATE muna bago payagan ng Firebase ang sensitive operation
        //     (kailangan ito dahil sa "requires-recent-login" error ng Firebase Auth)
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPass,
        );
        await user.reauthenticateWithCredential(credential);

        // 2. I-update ang password sa Firebase Authentication para opisyal na silang makalogin sa susunod
        await user.updatePassword(newPass);

        // 3. I-update ang Realtime Database: Baguhin ang password at ibalik sa 'Active' ang status
        await FirebaseDatabase.instance.ref().child('users/${user.uid}').update({
          'password': newPass,
          'status': 'Active', // Tinanggal na ang 'Password Reset by Admin' tag
        });
      }

      // I-sign out muna para pilitin silang mag-login gamit ang bago nilang gawang password
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        _showSnackBar("Password updated! Please login again.");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Specific na error handling para malinaw sa user kung mali ang current password
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showSnackBar("Current password is incorrect.");
      } else if (e.code == 'too-many-requests') {
        _showSnackBar("Too many attempts. Please try again later.");
      } else {
        _showSnackBar("Error: ${e.message}");
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            // Current Password Field (kailangan para sa reauthentication)
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPass,
              decoration: InputDecoration(
                labelText: "Current Password",
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
                ),
              ),
            ),
            const SizedBox(height: 15),
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
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Submit", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}