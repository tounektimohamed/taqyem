// migration_add_class_limit.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MigrationAddClassLimit {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addClassLimitToAllUsers() async {
    try {
      // Récupérer tous les utilisateurs
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      for (var doc in usersSnapshot.docs) {
        // Vérifier si le champ classLimit existe déjà
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        
        if (!userData.containsKey('classLimit')) {
          // Ajouter le champ classLimit avec une valeur par défaut (4)
          await _firestore.collection('users').doc(doc.id).update({
            'classLimit': 4,
            'classLimitUpdatedAt': FieldValue.serverTimestamp(),
          });
          
          print('✅ Champ classLimit ajouté pour l\'utilisateur: ${doc.id}');
        } else {
          print('⏭️ Champ classLimit déjà existant pour: ${doc.id}');
        }
      }
      
      print('✅ Migration terminée avec succès!');
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
    }
  }

  // Méthode pour ajouter classLimit lors de la création d'un nouvel utilisateur
  Future<void> setupUserCreationListener() async {
    // Écouter les nouveaux utilisateurs créés dans Firebase Auth
    // Note: Vous devez appeler cette méthode une fois au démarrage de l'app
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        await ensureUserHasClassLimit(user.uid);
      }
    });
  }

  Future<void> ensureUserHasClassLimit(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        if (!userData.containsKey('classLimit')) {
          await _firestore.collection('users').doc(userId).update({
            'classLimit': 4,
            'classLimitUpdatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Champ classLimit ajouté pour le nouvel utilisateur: $userId');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification du classLimit: $e');
    }
  }
}