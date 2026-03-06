// migration_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Méthode à exécuter une seule fois pour migrer tous les utilisateurs existants
  static Future<void> migrateAllUsers() async {
    final service = MigrationService();
    await service._addClassLimitToAllUsers();
  }

  // Méthode à appeler au démarrage de l'app pour gérer les nouveaux utilisateurs
  static void setupNewUserListener() {
    final service = MigrationService();
    service._listenForNewUsers();
  }

  Future<void> _addClassLimitToAllUsers() async {
    print('🚀 Début de la migration des utilisateurs...');
    
    try {
      // Récupérer tous les utilisateurs
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      int totalUsers = usersSnapshot.docs.length;
      int updatedUsers = 0;
      int skippedUsers = 0;

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        
        if (!userData.containsKey('classLimit')) {
          // Ajouter le champ classLimit avec la valeur par défaut (4)
          await _firestore.collection('users').doc(doc.id).update({
            'classLimit': 4,
            'classLimitUpdatedAt': FieldValue.serverTimestamp(),
            'classLimitSource': 'migration',
          });
          
          updatedUsers++;
          print('✅ Utilisateur ${doc.id}: classLimit ajouté');
        } else {
          skippedUsers++;
          print('⏭️ Utilisateur ${doc.id}: déjà configuré (${userData['classLimit']})');
        }
        
        // Petite pause pour éviter de surcharger Firestore
        await Future.delayed(Duration(milliseconds: 100));
      }

      print('\n📊 Résumé de la migration:');
      print('   Total utilisateurs: $totalUsers');
      print('   Mis à jour: $updatedUsers');
      print('   Ignorés: $skippedUsers');
      print('✅ Migration terminée avec succès!');
      
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
      rethrow;
    }
  }

  void _listenForNewUsers() {
    // Écouter les nouveaux utilisateurs créés dans Firebase Auth
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _ensureUserHasClassLimit(user.uid);
      }
    });

    // Écouter également les nouveaux documents dans Firestore
    _firestore.collection('users').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _ensureUserHasClassLimit(change.doc.id);
        }
      }
    });
  }

  Future<void> _ensureUserHasClassLimit(String userId) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        if (!userData.containsKey('classLimit')) {
          await userRef.update({
            'classLimit': 4,
            'classLimitUpdatedAt': FieldValue.serverTimestamp(),
            'classLimitSource': 'auto_created',
          });
          print('✅ Champ classLimit ajouté automatiquement pour: $userId');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification du classLimit: $e');
    }
  }
}