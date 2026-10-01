import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; 
import 'register_page.dart'; 
import 'dashboard.dart';    
import 'change_password_page.dart'; 
import 'forgotpassMobile_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    String psuId = idController.text.trim();
    String inputPassword = passwordController.text.trim();

    if (psuId.isEmpty || inputPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter your PSU ID and Password."),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. SILIPIN ANG BUONG USERS NODE PARA HANAPIN KUNG NASAAN ANG PSU ID
      final databaseRef = FirebaseDatabase.instance.ref().child('users');
      final snapshot = await databaseRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> allUsers = snapshot.value as Map<dynamic, dynamic>;
        Map<dynamic, dynamic>? targetUserData;

        // Iikutin ang bawat mahabang UID folder para hanapin ang tumutugmang psu_id
        allUsers.forEach((key, value) {
          if (value is Map && value['psu_id'].toString() == psuId) {
            targetUserData = value;
          }
        });

        // Kung nahanap ang account ng estudyante sa database
        if (targetUserData != null) {
          // KUNG ANG ACCOUNT AY NI-RESET NG ADMIN AT TUGMA ANG INPUT PASSWORD
          if (targetUserData!['status'] == 'Password Reset by Admin' && 
              (targetUserData!['password'] == inputPassword || inputPassword == "PsulubaoH2o" || inputPassword == "${psuId}H2o")) {
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Admin Reset Detected! Please enter your new password."), 
                  backgroundColor: Colors.blue.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              // DIRETSO SA CHANGE PASSWORD PAGE 
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
              );
            }
            return; // Hihinto na rito, ligtas sa Auth block!
          }
        }
      }

      // 2. NORMAL LOGIN: Kung hindi naman ni-reset o normal ang status
      String psuEmail = "$psuId@pampangastateu.edu.ph";
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: psuEmail,
        password: inputPassword,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Wrong PSU ID or Password.";
      if (e.code == 'user-not-found') {
        errorMessage = "Not registered PSU ID.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password. Please try again.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Email format error.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage), 
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("System Error: ${e.toString()}"), 
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Branding / Logo Header
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue.shade100, width: 2),
                    ),
                    child: Icon(
                      Icons.water_drop_rounded, 
                      size: 64, 
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    "PSU H2O HUB", 
                    style: TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.blue.shade900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Sign in to access your water monitoring account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Main Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PSU ID FIELD
                        Text(
                          "PSU ID Number",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: idController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade900,
                          ),
                          decoration: InputDecoration(
                            hintText: "e.g. 2023311060",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            prefixIcon: Icon(Icons.badge_outlined, color: Colors.blue.shade700, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 1.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // PASSWORD FIELD
                        Text(
                          "Password",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade900,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.blue.shade700, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                              onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 1.8),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 6),

                        // FORGOT PASSWORD LINK
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPassMobilePage()),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Colors.red.shade600, 
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade900,
                                  Colors.blue.shade700,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade300.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isLoading ? null : _login,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          "LOGIN", 
                                          style: TextStyle(
                                            color: Colors.white, 
                                            fontSize: 15, 
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // REGISTER LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        ),
                        child: Text(
                          "Register here", 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.blue.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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