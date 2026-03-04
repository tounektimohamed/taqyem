// lib/taqyem/payment/group_pack_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupPackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Générer un code de groupe pour le pack à 110 DT
  Future<String> generateGroupPackCode(String schoolName) async {
    final year = DateTime.now().year.toString();
    final sanitizedName = schoolName.toUpperCase().replaceAll(' ', '');
    
    // Obtenir le dernier numéro séquentiel
    final codesRef = _firestore
        .collection('group_packs')
        .where('school', isEqualTo: sanitizedName)
        .where('year', isEqualTo: year)
        .orderBy('sequentialNumber', descending: true)
        .limit(1);

    final snapshot = await codesRef.get();
    int nextNumber = 1;
    
    if (snapshot.docs.isNotEmpty) {
      nextNumber = (snapshot.docs.first['sequentialNumber'] as int) + 1;
    }

    final code = 'GROUP-$sanitizedName-$year-${nextNumber.toString().padLeft(3, '0')}';
    
    return code;
  }

  // Créer un nouveau pack groupe (par l'admin après validation du paiement)
  Future<void> createGroupPack({
    required String groupCode,
    required String schoolName,
    required String creatorId,
    required String creatorName,
    required String creatorWhatsapp,
  }) async {
    await _firestore.collection('group_packs').add({
      'code': groupCode,
      'school': schoolName,
      'year': DateTime.now().year.toString(),
      'sequentialNumber': int.parse(groupCode.split('-').last),
      'createdBy': creatorId,
      'createdByName': creatorName,
      'createdByWhatsapp': creatorWhatsapp,
      'createdAt': FieldValue.serverTimestamp(),
      'maxMembers': 6, // 6 membres maximum (creator + 5)
      'currentMembers': 1, // Le créateur est déjà membre
      'members': [creatorId],
      'memberNames': [creatorName],
      'price': 110,
      'isActive': true,
      'status': 'active',
      'activatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Valider et rejoindre un pack groupe
  Future<Map<String, dynamic>> validateAndJoinGroup(String code) async {
    final codesSnapshot = await _firestore
        .collection('group_packs')
        .where('code', isEqualTo: code)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (codesSnapshot.docs.isEmpty) {
      return {'success': false, 'message': 'كود المجموعة غير صالح'};
    }

    final codeDoc = codesSnapshot.docs.first;
    final codeData = codeDoc.data();
    final currentMembers = codeData['currentMembers'] ?? 1;
    final maxMembers = codeData['maxMembers'] ?? 6;

    if (currentMembers >= maxMembers) {
      return {
        'success': false, 
        'message': 'هذه المجموعة اكتملت (6/6)'
      };
    }

    // Vérifier si l'utilisateur est déjà dans un groupe
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists && userDoc['groupPackCode'] != null) {
        return {
          'success': false, 
          'message': 'أنت بالفعل عضو في مجموعة'
        };
      }
    }

    return {
      'success': true,
      'packId': codeDoc.id,
      'school': codeData['school'],
      'currentMembers': currentMembers,
      'maxMembers': maxMembers,
      'remaining': maxMembers - currentMembers,
    };
  }

  // Ajouter un membre au groupe
  Future<void> addMemberToGroup(String packId, String userId, String userName) async {
    final batch = _firestore.batch();
    
    final packRef = _firestore.collection('group_packs').doc(packId);
    batch.update(packRef, {
      'currentMembers': FieldValue.increment(1),
      'members': FieldValue.arrayUnion([userId]),
      'memberNames': FieldValue.arrayUnion([userName]),
    });

    final userRef = _firestore.collection('Users').doc(userId);
    batch.update(userRef, {
      'groupPackCode': packId,
      'joinedGroupAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Obtenir les détails d'un pack
  Future<Map<String, dynamic>?> getPackDetails(String packId) async {
    final doc = await _firestore.collection('group_packs').doc(packId).get();
    return doc.data();
  }

  // Vérifier si un code peut encore accepter des membres
  Future<bool> canJoinGroup(String packId) async {
    final doc = await _firestore.collection('group_packs').doc(packId).get();
    if (!doc.exists) return false;
    
    final data = doc.data()!;
    final current = data['currentMembers'] ?? 1;
    final max = data['maxMembers'] ?? 6;
    
    return current < max && (data['isActive'] ?? false);
  }

  // Désactiver un pack (par l'admin)
  Future<void> deactivatePack(String packId) async {
    await _firestore.collection('group_packs').doc(packId).update({
      'isActive': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
    });
  }
}