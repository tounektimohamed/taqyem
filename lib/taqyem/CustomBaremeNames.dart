// custom_names_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Classe pour gérer les noms personnalisés des barèmes
class CustomBaremeNames {
  final String userId;
  final String classId;
  final String matiereId;
  final Map<String, String> customBaremeNames;
  final Map<String, String> customSousBaremeNames;

  CustomBaremeNames({
    required this.userId,
    required this.classId,
    required this.matiereId,
    this.customBaremeNames = const {},
    this.customSousBaremeNames = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'classId': classId,
      'matiereId': matiereId,
      'customBaremeNames': customBaremeNames,
      'customSousBaremeNames': customSousBaremeNames,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  static CustomBaremeNames fromMap(Map<String, dynamic> map) {
    return CustomBaremeNames(
      userId: map['userId'] ?? '',
      classId: map['classId'] ?? '',
      matiereId: map['matiereId'] ?? '',
      customBaremeNames:
          Map<String, String>.from(map['customBaremeNames'] ?? {}),
      customSousBaremeNames:
          Map<String, String>.from(map['customSousBaremeNames'] ?? {}),
    );
  }
}

class CustomNamesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _customNamesCollection =>
      _firestore.collection('customBaremeNames');

  Future<CustomBaremeNames> getCustomNames({
    required String userId,
    required String classId,
    required String matiereId,
  }) async {
    try {
      final docId = _generateDocId(
          userId: userId, classId: classId, matiereId: matiereId);
      final doc = await _customNamesCollection.doc(docId).get();

      if (doc.exists) {
        return CustomBaremeNames.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        final customNames = CustomBaremeNames(
          userId: userId,
          classId: classId,
          matiereId: matiereId,
        );
        await _customNamesCollection.doc(docId).set(customNames.toMap());
        return customNames;
      }
    } catch (e) {
      print('Erreur lors de la récupération des noms personnalisés: $e');
      return CustomBaremeNames(
        userId: userId,
        classId: classId,
        matiereId: matiereId,
      );
    }
  }
  // Dans custom_names_service.dart, vérifiez ces méthodes :

  Future<void> updateBaremeCustomName({
    required String userId,
    required String classId,
    required String matiereId,
    required String baremeId,
    required String customName,
  }) async {
    try {
      final docId = _generateDocId(
        userId: userId,
        classId: classId,
        matiereId: matiereId,
      );

      print('💾 updateBaremeCustomName:');
      print('   docId: $docId');
      print('   baremeId: $baremeId');
      print('   customName: $customName');

      await _customNamesCollection.doc(docId).set({
        'customBaremeNames.$baremeId': customName,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Nom sauvegardé avec succès');
    } catch (e) {
      print('❌ Erreur updateBaremeCustomName: $e');
      rethrow;
    }
  }

  Future<void> updateSousBaremeCustomName({
    required String userId,
    required String classId,
    required String matiereId,
    required String sousBaremeId,
    required String customName,
  }) async {
    try {
      final docId = _generateDocId(
        userId: userId,
        classId: classId,
        matiereId: matiereId,
      );

      print('💾 updateSousBaremeCustomName:');
      print('   docId: $docId');
      print('   sousBaremeId: $sousBaremeId');
      print('   customName: $customName');

      await _customNamesCollection.doc(docId).set({
        'customSousBaremeNames.$sousBaremeId': customName,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Nom sous-barème sauvegardé avec succès');
    } catch (e) {
      print('❌ Erreur updateSousBaremeCustomName: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomName({
    required String userId,
    required String classId,
    required String matiereId,
    required String id,
    bool isSousBareme = false,
  }) async {
    try {
      final docId = _generateDocId(
          userId: userId, classId: classId, matiereId: matiereId);
      final field =
          isSousBareme ? 'customSousBaremeNames.$id' : 'customBaremeNames.$id';

      await _customNamesCollection.doc(docId).update({
        field: FieldValue.delete(),
      });
    } catch (e) {
      print('Erreur lors de la suppression du nom personnalisé: $e');
      rethrow;
    }
  }

  String _generateDocId({
    required String userId,
    required String classId,
    required String matiereId,
  }) {
    return '${userId}_${classId}_${matiereId}';
  }
}
