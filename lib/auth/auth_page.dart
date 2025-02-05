import 'package:Taqyem/auth/main_page.dart';
import 'package:Taqyem/landing/views/home_page.dart';
import 'package:Taqyem/screens2/agent/Agentdashbord.dart';
import 'package:Taqyem/screens2/login_signup/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Taqyem/screens2/app%20option%20setting/onboarding.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showOnboarding = true;

  @override
  void initState() {
    super.initState();
  }

  void goToHomePage() {
    setState(() {
      showOnboarding = false;
    });
  }

@override
Widget build(BuildContext context) {
  // Vérifier si l'utilisateur est authentifié
  final user = FirebaseAuth.instance.currentUser;

  if (showOnboarding) {
    return Onboarding(
      goToHomePage: goToHomePage,
    );
  } else {
    // Si l'utilisateur est authentifié, naviguer vers le tableau de bord, sinon vers la page de connexion
    if (user != null) {
      return  MainPage(); // Page de tableau de bord
    } else {
      return SignIn(); // Page de connexion
    }
  }
}

}
