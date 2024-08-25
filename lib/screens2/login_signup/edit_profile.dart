import 'package:flutter/material.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le profil"),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/user.webp',
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            "Ici, vous pouvez modifier les paramètres de votre profil.",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            "Si vous oubliez votre mot de passe, détendez-vous et essayez de vous en souvenir.",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ],
      )),
    );
  }
}
