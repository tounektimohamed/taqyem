import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProposalsPage extends StatefulWidget {
  const AdminProposalsPage({Key? key}) : super(key: key);

  @override
  _AdminProposalsPageState createState() => _AdminProposalsPageState();
}

class _AdminProposalsPageState extends State<AdminProposalsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> get pendingProposals => _firestore
      .collectionGroup('user_proposals')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots();

Future<void> _updateProposalStatus(String proposalPath, String status) async {
  try {
    final proposalRef = _firestore.doc(proposalPath);
    final proposalId = proposalRef.id;
    final userId = proposalPath.split('/')[3]; // Extrait l'ID utilisateur du chemin

    // D'abord, récupérer les données de la proposition
    final proposalDoc = await proposalRef.get();
    final proposalData = proposalDoc.data() as Map<String, dynamic>;

    // Référence à la collection approved_proposals
    final approvedRef = _firestore
        .collection('users_proposals')
        .doc('global_proposals')
        .collection('approved_proposals')
        .doc(proposalId);

    final batch = _firestore.batch();

    // 1. Mise à jour du statut dans la proposition utilisateur originale
    batch.update(proposalRef, {
      'status': status,
      'reviewedBy': _auth.currentUser?.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'approved') {
      // 2. Ajout à la collection approved_proposals si approuvé
      batch.set(approvedRef, {
        'originalRef': proposalPath,
        'userId': userId,
        'userName': proposalData['userName'],
        'solution': proposalData['solution'],
        'probleme': proposalData['probleme'],
        'groupName': proposalData['groupName'],
        'className': proposalData['className'],
        'matiereName': proposalData['matiereName'],
        'baremeName': proposalData['baremeName'],
        'sousBaremeName': proposalData['sousBaremeName'] ?? '',
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
      });
    } else {
      // 3. Suppression de approved_proposals si rejeté
      batch.delete(approvedRef);
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Proposition $status avec succès')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة المقترحات'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pendingProposals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('خطأ في التحميل: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد مقترحات قيد المراجعة'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ProposalCard(
                proposal: data,
                onApprove: () => _updateProposalStatus(doc.reference.path, 'approved'),
                onReject: () => _updateProposalStatus(doc.reference.path, 'rejected'),
              );
            },
          );
        },
      ),
    );
  }
}
class ProposalCard extends StatelessWidget {
  final Map<String, dynamic> proposal;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const ProposalCard({
    required this.proposal,
    required this.onApprove,
    required this.onReject,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec informations utilisateur
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 8),
                Text(
                  proposal['userName'] ?? 'مستخدم غير معروف',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  _formatDate(proposal['createdAt']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informations sur le contexte pédagogique
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip('الصف: ${proposal['className']}', Colors.blue),
                _buildInfoChip('المادة: ${proposal['matiereName']}', Colors.green),
                _buildInfoChip('المعيار: ${proposal['baremeName']}', Colors.orange),
                if (proposal['sousBaremeName'] != null && proposal['sousBaremeName'].isNotEmpty)
                  _buildInfoChip('المعيار الفرعي: ${proposal['sousBaremeName']}', Colors.purple),
                _buildInfoChip('المجموعة: ${proposal['groupName']}', Colors.red),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Section Solution
            const Text(
              'الحل المقترح:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              proposal['solution'] ?? 'لا يوجد حل مقدم',
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            // Section Problème
            const Text(
              'أصل المشكلة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              proposal['probleme'] ?? 'لا يوجد تحليل للمشكلة',
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onReject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('رفض', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('موافقة', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}