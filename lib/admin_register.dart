import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'admin_dashboard.dart';

class AdminRegisterPage extends StatefulWidget {
  const AdminRegisterPage({super.key});

  @override
  State<AdminRegisterPage> createState() => _AdminRegisterPageState();
}

class _AdminRegisterPageState extends State<AdminRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // State for UI
  bool _isObscured = true;
  bool _isConfirmObscured = true;
  bool _isLoading = false;
  String _selectedGender = 'Male';

  // Password Validator
  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters required';
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) return 'Must contain a lowercase letter';
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return 'Must contain an uppercase letter';
    return null;
  }

  // Firebase Register Logic
  Future<void> _registerAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      // Step 2: Save admin details in Realtime Database
      DatabaseReference adminRef = FirebaseDatabase.instance
          .ref("admins/${userCredential.user!.uid}");

      await adminRef.set({
        'psu_id': _idController.text.trim(),
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        'role': 'Admin',
        'email': _emailController.text.trim(),
        'created_at': ServerValue.timestamp,
      });

      if (mounted) {
        setState(() => _isLoading = false);

        // Step 3: Show success message then redirect
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Admin account created successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Step 4: Redirect to Admin Dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors with clear messages
      setState(() => _isLoading = false);

      String errorMessage;

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already registered. Please use a different email.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format. Please enter a valid email.";
          break;
        case 'weak-password':
          errorMessage = "Password is too weak. Please choose a stronger password.";
          break;
        case 'permission-denied':
          errorMessage = "Permission denied. Please contact the system administrator.";
          break;
        default:
          errorMessage = "Registration failed: ${e.message}";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unexpected error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 500,
            margin: const EdgeInsets.symmetric(vertical: 40),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "H2O ADMIN REGISTRATION",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField(_idController, "PSU ID No.", Icons.badge),
                  _buildTextField(_nameController, "Full Name", Icons.person),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _ageController, "Age", Icons.cake, isNumber: true
                        )
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(labelText: "Gender"),
                          items: ['Male', 'Female']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedGender = val!),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),
                  _buildTextField(_emailController, "Admin Email", Icons.email),

                  // Password Field
                  TextFormField(
                    controller: _passController,
                    obscureText: _isObscured,
                    validator: _passwordValidator,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscured ? Icons.visibility_off : Icons.visibility
                        ),
                        onPressed: () => setState(() => _isObscured = !_isObscured),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPassController,
                    obscureText: _isConfirmObscured,
                    validator: (val) =>
                        val != _passController.text ? "Passwords do not match" : null,
                    decoration: InputDecoration(
                      labelText: "Retype Password",
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmObscured ? Icons.visibility_off : Icons.visibility
                        ),
                        onPressed: () => setState(
                          () => _isConfirmObscured = !_isConfirmObscured
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Register Button with Loading Indicator
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _registerAdmin,
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
                              "CREATE ADMIN ACCOUNT",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Back to Login
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text("Back to Login"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: (val) => val!.isEmpty ? "This field is required." : null,
      ),
    );
  }
}