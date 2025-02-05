import 'package:Taqyem/screens2/admin/adminpage.dart';
import 'package:Taqyem/screens2/agent/Agentdashbord.dart';
import 'package:Taqyem/screens2/agent/TABAgentdashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Taqyem/auth/auth_page.dart';
import 'package:Taqyem/screens2/dashboard.dart';
import 'package:Taqyem/screens2/login_signup/email_verify.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            User? user = snapshot.data!;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('Users').doc(user.uid).get(),
              builder: (context, userDocSnapshot) {
                if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (userDocSnapshot.hasData && userDocSnapshot.data != null) {
                  bool isEmailVerified = user.emailVerified;
                  bool isAgent = userDocSnapshot.data!.get('isAgent') ?? false;

                  if (isEmailVerified) {
                    return isAgent ? const AgentDashboard() : const Agentdashboard();
                  } else {
                    return const EmailVerificationScreen();
                  }
                } else {
                  // Log de débogage
                  print('Erreur lors de la récupération du document utilisateur ou document introuvable.');
                  // Redirigez vers la page d'authentification si le document utilisateur n'est pas trouvé ou une erreur se produit
                  return const AuthPage();
                }
              },
            );
          } else {
            // Aucun utilisateur connecté
            return const AuthPage();
          }
        },
      ),
    );
  }
}
