import 'package:DREHATT_app/screens2/Agentdashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:DREHATT_app/auth/auth_page.dart';
import 'package:DREHATT_app/screens2/dashboard.dart';
import 'package:DREHATT_app/screens2/email_verify.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            User? user = snapshot.data!;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('Users').doc(user.uid).get(),
              builder: (context, userDocSnapshot) {
                if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (userDocSnapshot.hasData && userDocSnapshot.data != null) {
                  bool isEmailVerified = user.emailVerified;
                  bool isAgent = userDocSnapshot.data!.get('isAgent') ?? false;

                  // Debugging information
                  print('User document exists: ${userDocSnapshot.data!.exists}');
                  print('isAgent value: $isAgent');

                  if (isEmailVerified) {
                    if (isAgent) {
                      return const Agentdashboard();
                    } else {
                      return const Dashboard();
                    }
                  } else {
                    return const EmailVerificationScreen();
                  }
                } else {
                  // User document not found or error fetching data
                  return const AuthPage(); // Go to authentication page
                }
              },
            );
          } else {
            // No user logged in
            return const AuthPage(); // Go to authentication page
          }
        },
      ),
    );
  }
}
