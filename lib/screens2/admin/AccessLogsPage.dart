import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AccessLogsPage extends StatelessWidget {
  const AccessLogsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journaux d\'accès'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .where('lastLogin', isNotEqualTo: null) // Seulement les utilisateurs avec lastLogin
              .orderBy('lastLogin', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // ... (le reste du builder reste similaire)
            
            var logs = snapshot.data!.docs;

            return RefreshIndicator(
              onRefresh: () async {
                // Implémentez la logique de rafraîchissement si nécessaire
              },
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  var userDoc = logs[index];
                  var userData = userDoc.data() as Map<String, dynamic>;
                  
                  var userId = userDoc.id;
                  var name = userData['name'] ?? 'Utilisateur inconnu';
                  var email = userData['email'] ?? 'Email non disponible';
                  var lastLogin = userData['lastLogin'] as Timestamp?;
                  
                  if (lastLogin == null) return Container();
                  
                  var date = lastLogin.toDate();
                  var formattedDate = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
                  var formattedTime = DateFormat('HH:mm:ss').format(date);

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      ),
                      title: Text(name),
                      subtitle: Text('Dernière connexion: $formattedDate à $formattedTime'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}