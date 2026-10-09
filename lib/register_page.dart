import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final ageController = TextEditingController();
  final sectionController = TextEditingController();

  String? selectedCourse;
  String? selectedYear;
  String? selectedGender;
  String? selectedRole;
  bool isPasswordVisible = false;

  final List<String> genders = ['Male', 'Female'];
  final List<String> roles = ['Student', 'Faculty Member', 'Utility'];
  final List<String> years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> courses = [
    'Bachelor of Science in Information Technology',
    'Bachelor of Science in Entrepreneurship',
    'Bachelor of Science in Civil Engineering',
    'Bachelor of Elementary Education',
    'Bachelor of Science in Tourism Management',
    'Bachelor of Science in Business Administration Major in Marketing',
    'Bachelor of Science in Psychology',
  ];

@override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    ageController.dispose();
    sectionController.dispose();
    super.dispose();
  }

  String? validatePassword(String value) {
    if (value.length < 8) return "At least 8 characters required";
    if (!value.contains(RegExp(r'[a-z]'))) return "Must have at least 1 lowercase letter";
    return null;
  }

  Future<void> _register() async {
    final String trimmedId = idController.text.trim();
    final String trimmedAge = ageController.text.trim();

    // 1. Basic Empty Validation check
    if (trimmedId.isEmpty ||
        trimmedAge.isEmpty ||
        selectedGender == null ||
        selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out all required fields."), backgroundColor: Colors.orange),
      );
      return;
    }

    // 2. RESTRICTION CHECK: Numbers Only Validation para sa PSU ID at Age
    final RegExp numericRegex = RegExp(r'^[0-9]+$');

    if (!numericRegex.hasMatch(trimmedId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PSU ID must contain numbers only (no spaces, letters, or special characters like . , / -)."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!numericRegex.hasMatch(trimmedAge)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Age must contain numbers only."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Student Validation
    if (selectedRole == 'Student') {
      if (selectedCourse == null || selectedYear == null || sectionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill out all student profile fields."), backgroundColor: Colors.orange),
        );
        return;
      }
    }

    final passwordError = validatePassword(passwordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String psuEmail = "$trimmedId@pampangastateu.edu.ph";
      int userAge = int.tryParse(trimmedAge) ?? 0;

      // A. Create User sa Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: psuEmail,
        password: passwordController.text.trim(),
      );

      final String uid = userCredential.user!.uid;
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      String courseValue = selectedRole == 'Student' ? selectedCourse! : 'N/A';
      String yearValue = selectedRole == 'Student' ? selectedYear! : 'N/A';
      String sectionValue = selectedRole == 'Student' ? sectionController.text.trim().toUpperCase() : 'N/A';

      // B. Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'psu_id': trimmedId,
        'age': userAge,
        'gender': selectedGender,
        'role': selectedRole,
        'course': courseValue,
        'year': yearValue,
        'section': sectionValue,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // C. Save to Realtime Database
      await FirebaseDatabase.instance.ref("users/$uid").set({
        'intake': 0,
        'age': userAge,
        'gender': selectedGender,
        'psu_id': trimmedId,
        'role': selectedRole,
        'course': courseValue,
        'year': yearValue,
        'section': sectionValue,
        'last_update': today,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close Dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account Created Successfully! Redirecting..."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context); // Back to Login Screen
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      String errorMessage = "Registration failed. Please check your details.";
      if (e.code == 'email-already-in-use') errorMessage = "This PSU ID is already registered.";
      if (e.code == 'weak-password') errorMessage = "Password should be at least 8 characters.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Check your connection or Database rules."), backgroundColor: Colors.red),
      );
    }
  }
  // Helper Widget para sa Section Headers
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[900], size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Input Decoration para sa uniform style
  InputDecoration _customInputDecoration(String labelText, IconData icon, {String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.blue[900]),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade900, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Banner
            Card(
              elevation: 0,
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[900],
                      child: const Icon(Icons.water_drop, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PSU H2O Registration",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900]),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Fill in your official details to register.",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // CARD 1: Basic Information
            Card(
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSectionHeader("Personal Info", Icons.person_outline),
                    
                    // PSU ID Field
                    TextField(
                      controller: idController,
                      keyboardType: TextInputType.number,
                      decoration: _customInputDecoration("PSU ID Number", Icons.badge_outlined, hintText: "e.g. 2023311060"),
                    ),
                    const SizedBox(height: 15),

                    // Age Field
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: _customInputDecoration("Age", Icons.calendar_today_outlined),
                    ),
                    const SizedBox(height: 15),

                    // Gender Field
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: _customInputDecoration("Gender", Icons.wc_outlined),
                      items: genders.map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) => setState(() => selectedGender = newValue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // CARD 2: Role Selection & Academic Details
            Card(
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSectionHeader("Role & Classification", Icons.work_outline),
                    
                    // Role Field
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: _customInputDecoration("Role", Icons.badge_outlined),
                      items: roles.map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRole = newValue;
                          if (selectedRole != 'Student') {
                            selectedCourse = null;
                            selectedYear = null;
                            sectionController.clear();
                          }
                        });
                      },
                    ),

                    // DYNAMIC STUDENT FIELDS
                    if (selectedRole == 'Student') ...[
                      const Divider(height: 30),
                      _buildSectionHeader("Student Details", Icons.school_outlined),
                      
                      // Course Field
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedCourse,
                        decoration: _customInputDecoration("Course", Icons.menu_book_outlined),
                        selectedItemBuilder: (BuildContext context) {
                          return courses.map<Widget>((String item) {
                            return Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            );
                          }).toList();
                        },
                        items: courses.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) => setState(() => selectedCourse = newValue),
                      ),
                      const SizedBox(height: 15),

                      // Year Level Field
                      DropdownButtonFormField<String>(
                        value: selectedYear,
                        decoration: _customInputDecoration("Year Level", Icons.layers_outlined),
                        items: years.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (String? newValue) => setState(() => selectedYear = newValue),
                      ),
                      const SizedBox(height: 15),

                      // Section Field
                      TextField(
                        controller: sectionController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _customInputDecoration("Section", Icons.class_outlined, hintText: "A, B, C, etc."),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // CARD 3: Account Security
            Card(
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSectionHeader("Security", Icons.lock_outline),
                    
                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: _customInputDecoration(
                        "Password",
                        Icons.lock_clock_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "CREATE ACCOUNT",
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}