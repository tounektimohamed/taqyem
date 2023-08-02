import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mymeds_app/auth/auth_page.dart';

import 'package:mymeds_app/screens/dashboard.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //if user logged in show dashbaord else go to authentication page
          if (snapshot.hasData) {
            return const Dashboard();
          } else {
            //auth page
            return const AuthPage();
          }
        },
      ),
    );
  }
}
