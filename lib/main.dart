import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this
import 'package:firebase_database/firebase_database.dart'; // Add this
import 'login_page.dart';
import 'dashboard.dart'; // Siguraduhing naka-import ang Dashboard mo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Ito ang sikreto para gumana ang App kahit walang internet:
  // I-enable ang Offline Persistence para sa Database
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  
  runApp(const H2OApp());
}

class H2OApp extends StatelessWidget {
  const H2OApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'H2O Smart System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Dito natin i-che-check kung naka-login na ang user o hindi
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Kapag may data (naka-login), rekta sa Dashboard
          if (snapshot.hasData) {
            return const Dashboard();
          }
          // Kapag walang data, dun lang pupunta sa LoginPage
          return const LoginPage();
        },
      ),
    );
  }
}