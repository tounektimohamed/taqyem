import 'package:DREHATT_app/landing/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:DREHATT_app/screens2/app%20option%20setting/onboarding.dart';

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
    if (showOnboarding) {
      return Onboarding(
        goToHomePage: goToHomePage,
      );
    } else {
      return  MyHomePage(); // Naviguez vers MyHomePage après l'onboarding
    }
  }
}
