import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final idController = TextEditingController(); 
  final passwordController = TextEditingController();
  final ageController = TextEditingController();
  
  // MGA BAGONG CONTROLLER AT VARIABLES
  final sectionController = TextEditingController();
  String? selectedCourse;
  String? selectedYear;

  String? selectedGender;
  String? selectedRole;
  bool isPasswordVisible = false;

  final List<String> genders = ['Male', 'Female'];  
  final List<String> roles = ['Student', 'Faculty member', 'Utility'];
  
  // MGA LISTAHAN PARA SA AKADEMIKONG DETALYE
  final List<String> years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> courses = ['Bachelor of Science in Information Technology', 'Bachelor of Science in Accountancy', 'Bachelor of Science in Civil Engineering', 'Bachelor of Elementary Education', 'Bachelor of Science in Tourism Management', 'Bachelor of Science in Business Administration','Bachelor of Science in Psychology']; // Pwede mong dagdagan o palitan ang mga kurso rito sa PSU

  String? validatePassword(String value) {
    if (value.length < 8) return "At least 8 characters required";
    if (!value.contains(RegExp(r'[a-z]'))) return "Must have at least 1 lowercase letter";
    return null;
  }

  Future<void> _register() async {
    // 1. Pangunahing Validation check
    if (idController.text.isEmpty || ageController.text.isEmpty || selectedGender == null || selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pakisagutan ang lahat ng fields."), backgroundColor: Colors.orange),
      );
      return;
    }

    // Karagdagang Validation: Kung Student ang Role, kailangang sagutan ang Course, Year, at Section
    if (selectedRole == 'Student') {
      if (selectedCourse == null || selectedYear == null || sectionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pakisagutan ang Course, Year, at Section para sa Estudyante."), backgroundColor: Colors.orange),
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
      String psuEmail = "${idController.text.trim()}@psu.edu.ph";
      int userAge = int.tryParse(ageController.text.trim()) ?? 0;

      // A. Create User sa Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: psuEmail,
        password: passwordController.text.trim(),
      );

      final String uid = userCredential.user!.uid;
      
      // Kunin ang petsa ngayon para sa initial last_update
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Ihanda ang mga karagdagang data (Ise-save lang bilang halaga kung student, kundi 'N/A')
      String courseValue = selectedRole == 'Student' ? selectedCourse! : 'N/A';
      String yearValue = selectedRole == 'Student' ? selectedYear! : 'N/A';
      String sectionValue = selectedRole == 'Student' ? sectionController.text.trim().toUpperCase() : 'N/A';

      // B. Save Profile Data sa Firestore (For records)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'psu_id': idController.text.trim(),
        'age': userAge,
        'gender': selectedGender,
        'role': selectedRole,
        'course': courseValue,
        'year': yearValue,
        'section': sectionValue,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // C. Save sa Realtime Database (Kasama ang bagong fields para madaling basahin ng Vendo dashboard)
      await FirebaseDatabase.instance.ref("users/$uid").set({
        'intake': 0,
        'age': userAge,
        'gender': selectedGender,
        'psu_id': idController.text.trim(),
        'role': selectedRole,
        'course': courseValue,
        'year': yearValue,
        'section': sectionValue,
        'last_update': today, // Mahalaga ito para sa Dashboard reset
      });
      
      if (mounted) Navigator.pop(context); // Tanggalin ang Loading Dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Created! Back to Login..."), 
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context); 
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      String errorMessage = "Wrong information provided.";
      if (e.code == 'email-already-in-use') errorMessage = "Wrong PSU ID Already in Use.";
      if (e.code == 'weak-password') errorMessage = "weak-password: Password should be at least 8 characters.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("DEBUG ERROR: $e"); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Check your connection or Database rules."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PSU Register"), backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "PSU ID Number", 
                hintText: "e.g. 2023311060",
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              initialValue: selectedGender,
              items: genders.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
              onChanged: (String? newValue) => setState(() => selectedGender = newValue),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder(), prefixIcon: Icon(Icons.work)),
              initialValue: selectedRole,
              items: roles.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedRole = newValue;
                  // I-reset ang student fields kapag pinalitan ang role para iwas maling data
                  if (selectedRole != 'Student') {
                    selectedCourse = null;
                    selectedYear = null;
                    sectionController.clear();
                  }
                });
              },
            ),
            
            // --- DYNAMIC STUDENT FIELDS (Lalabas lang kapag pinili ang 'Student') ---
            if (selectedRole == 'Student') ...[
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                isExpanded: true, // 1. MAHALAGA: Pinapayagan nito ang dropdown na gamitin ang buong lapad ng screen
                decoration: const InputDecoration(labelText: "Course", border: OutlineInputBorder(), prefixIcon: Icon(Icons.school)),
                value: selectedCourse,
                // 2. INAYOS NA ITEMS: Dito natin sinabihan ang text na mag-wrap kapag mahaba
                items: courses.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis, // Magiging "..." sa dulo kung sobrang haba talaga
                      maxLines: 2, // Papayagan nating maging 2 lines ang text para kasya buong kurso
                      style: const TextStyle(fontSize: 13), // Bahagyang pinalit para mas magkasya sa mobile screen
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) => setState(() => selectedCourse = newValue),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Year Level", border: OutlineInputBorder(), prefixIcon: Icon(Icons.layers)),
                value: selectedYear,
                items: years.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (String? newValue) => setState(() => selectedYear = newValue),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: sectionController,
                textCapitalization: TextCapitalization.characters, 
                decoration: const InputDecoration(
                  labelText: "Section", 
                  hintText: "A, B, C, etc.",
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.class_),
                ),
              ),
            ],
            
            const SizedBox(height: 15),
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
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("CREATE ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}