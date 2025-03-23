import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DemandManagementPage extends StatefulWidget {
  @override
  _DemandManagementPageState createState() => _DemandManagementPageState();
}

class _DemandManagementPageState extends State<DemandManagementPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Demandes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collectionGroup('payments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune demande trouvée.'));
          }

          final demands = snapshot.data!.docs;

          return ListView.builder(
            itemCount: demands.length,
            itemBuilder: (context, index) {
              final demand = demands[index];
              final data = demand.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final userId = demand.reference.parent.parent!.id;
              final photoUrl = data['photoUrl'];

              return ListTile(
                leading: GestureDetector(
                  onTap: () {
                    if (photoUrl != null) {
                      _showPhotoDialog(context, photoUrl);
                    }
                  },
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(photoUrl),
                    child: photoUrl == null
                        ? Icon(Icons.person)
                        : null,
                  ),
                ),
                title: Text('${data['nom']} ${data['prenom']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Forfait: ${data['forfait']}'),
                    Text('Statut: $status'),
                    // FutureBuilder<DocumentSnapshot>(
                    //   future: FirebaseFirestore.instance
                    //       .collection('Users')
                    //       .doc(userId)
                    //       .get(),
                    //   builder: (context, snapshot) {
                    //     if (snapshot.connectionState == ConnectionState.waiting) {
                    //       return Text('Chargement du statut...');
                    //     }
                    //     if (snapshot.hasError) {
                    //       return Text('Erreur de chargement du statut');
                    //     }
                    //     final isActive = snapshot.data?['isActive'] ?? false;
                    //     return Text('isActive: $isActive');
                    //   },
                    // ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _updateDemandStatus(demand.reference, 'active'),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => _updateDemandStatus(demand.reference, 'inactive'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  photoUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return CircularProgressIndicator();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.error, color: Colors.red);
                  },
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateDemandStatus(DocumentReference demandRef, String status) async {
    // Mettre à jour le statut de la demande
    await demandRef.update({'status': status});

    // Mettre à jour la variable isActive dans le document utilisateur
    final userId = demandRef.parent.parent!.id; // Récupérer l'ID de l'utilisateur
    final isActive = status == 'active'; // Définir isActive en fonction du statut

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .update({'isActive': isActive});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Statut de la demande mis à jour avec succès!')),
    );
  }
}