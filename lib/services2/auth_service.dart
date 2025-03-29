import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../components/alert.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb 
        ? '781442905848-7stfoh28o31d2a0b1t7v3mg2pf96on5h.apps.googleusercontent.com' // Pour le web seulement
        : null, // Pour mobile, pas besoin de clientId
  );

  Future<UserCredential> signInWithGoogle(BuildContext context) async {
    try {
      // Afficher l'indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
      );

      // Déconnexion préalable et démarrage du processus
      await _googleSignIn.signOut();
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser == null) throw Exception("Connexion annulée");

      // Obtenir les informations d'authentification
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Créer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Connexion avec Firebase
      final userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Fermer l'indicateur de chargement
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      return userCredential;
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      // Gestion des erreurs spécifiques
      String errorMessage = "Erreur de connexion";
      if (e is FirebaseAuthException) {
        errorMessage = _mapFirebaseError(e.code);
      } else if (e.toString().contains("popup_closed")) {
        errorMessage = "La fenêtre de connexion a été fermée";
      }

      // Afficher l'alerte
      showDialog(
        context: context,
        builder: (context) => Alert_Dialog(
          isError: true,
          alertTitle: 'Erreur',
          errorMessage: errorMessage,
          buttonText: 'OK',
        ),
      );

      rethrow;
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cet email';
      case 'invalid-credential':
        return 'Identifiants invalides';
      case 'operation-not-allowed':
        return 'Connexion Google non autorisée';
      case 'user-disabled':
        return 'Compte désactivé';
      case 'user-not-found':
        return 'Compte introuvable';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-verification-code':
        return 'Code de vérification invalide';
      case 'invalid-verification-id':
        return 'ID de vérification invalide';
      default:
        return 'Erreur de connexion';
    }
  }
}