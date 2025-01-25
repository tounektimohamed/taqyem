import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectionListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Sélections'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('selections').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune sélection trouvée.'));
          }

          // Afficher la liste des sélections
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var selection = snapshot.data!.docs[index];
              String classId = selection['classId'] ?? 'N/A';
              String matiereId = selection['matiereId'] ?? 'N/A';
              String baremeId = selection['baremeId'] ?? 'N/A';
              Timestamp selectedAt = selection['selectedAt'] ?? Timestamp.now();

              return ListTile(
                title: Text('Classe: $classId'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Matière: $matiereId'),
                    Text('Barème: $baremeId'),
                    Text('Sélectionné le: ${selectedAt.toDate()}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}