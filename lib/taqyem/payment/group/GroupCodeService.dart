// lib/services/group_code_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Générer un code intelligent
  Future<String> generateGroupCode(String schoolName) async {
    final year = DateTime.now().year.toString();
    final sanitizedName = schoolName.toUpperCase().replaceAll(' ', '');
    
    // Obtenir le dernier numéro séquentiel pour cette école/année
    final codesRef = _firestore
        .collection('group_codes')
        .where('school', isEqualTo: sanitizedName)
        .where('year', isEqualTo: year)
        .orderBy('sequentialNumber', descending: true)
        .limit(1);

    final snapshot = await codesRef.get();
    int nextNumber = 1;
    
    if (snapshot.docs.isNotEmpty) {
      nextNumber = (snapshot.docs.first['sequentialNumber'] as int) + 1;
    }

    final code = '$sanitizedName-$year-${nextNumber.toString().padLeft(3, '0')}';
    
    // Sauvegarder le code
    await _firestore.collection('group_codes').add({
      'code': code,
      'school': sanitizedName,
      'year': year,
      'sequentialNumber': nextNumber,
      'createdBy': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'maxMembers': 5,
      'currentMembers': 0,
      'isActive': true,
    });

    return code;
  }

  // Valider et rejoindre un groupe
  Future<Map<String, dynamic>> validateAndJoinGroup(String code) async {
    final codesSnapshot = await _firestore
        .collection('group_codes')
        .where('code', isEqualTo: code)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (codesSnapshot.docs.isEmpty) {
      return {'success': false, 'message': 'Code invalide'};
    }

    final codeDoc = codesSnapshot.docs.first;
    final codeData = codeDoc.data();
    final currentMembers = codeData['currentMembers'] ?? 0;
    final maxMembers = codeData['maxMembers'] ?? 5;

    if (currentMembers >= maxMembers) {
      return {'success': false, 'message': 'Ce groupe a atteint sa limite de 5 membres'};
    }

    // Vérifier si l'utilisateur est déjà dans un groupe
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists && userDoc['groupCode'] != null) {
        return {'success': false, 'message': 'Vous êtes déjà dans un groupe'};
      }
    }

    return {
      'success': true,
      'codeId': codeDoc.id,
      'school': codeData['school'],
      'currentMembers': currentMembers,
      'maxMembers': maxMembers,
    };
  }

  // Ajouter un membre au groupe
  Future<void> addMemberToGroup(String codeId, String userId) async {
    final batch = _firestore.batch();
    
    final codeRef = _firestore.collection('group_codes').doc(codeId);
    batch.update(codeRef, {
      'currentMembers': FieldValue.increment(1),
      'members': FieldValue.arrayUnion([userId]),
    });

    final userRef = _firestore.collection('Users').doc(userId);
    batch.update(userRef, {
      'groupCode': codeId,
      'joinedGroupAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Vérifier si un code peut encore accepter des membres
  Future<bool> canJoinGroup(String codeId) async {
    final doc = await _firestore.collection('group_codes').doc(codeId).get();
    if (!doc.exists) return false;
    
    final data = doc.data()!;
    final current = data['currentMembers'] ?? 0;
    final max = data['maxMembers'] ?? 5;
    
    return current < max && (data['isActive'] ?? false);
  }
}