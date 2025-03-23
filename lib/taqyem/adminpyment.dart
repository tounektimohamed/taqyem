import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaymentManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Paiements'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final Users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: Users.length,
            itemBuilder: (context, index) {
              final user = Users[index];
              final userId = user.id;
              final userData = user.data() as Map<String, dynamic>;

              return ExpansionTile(
                title: Text(userData['email'] ?? 'No Email'),
                subtitle: Text(userData['isActive'] == true ? 'Compte activé' : 'Compte désactivé'),
                trailing: Switch(
                  value: userData['isActive'] ?? false,
                  onChanged: (value) {
                    FirebaseFirestore.instance
                        .collection('Users')
                        .doc(userId)
                        .update({'isActive': value});
                  },
                ),
                children: [
                  // Afficher les paiements de l'utilisateur
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(userId)
                        .collection('payments')
                        .snapshots(),
                    builder: (context, paymentSnapshot) {
                      if (!paymentSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final payments = paymentSnapshot.data!.docs;

                      return Column(
                        children: payments.map((payment) {
                          final paymentData = payment.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text('Forfait: ${paymentData['forfait']}'),
                            subtitle: Text(
                                'Nom: ${paymentData['nom']}, Prénom: ${paymentData['prenom']}'),
                            trailing: paymentData['photoUrl'] != null
                                ? Image.network(
                                    paymentData['photoUrl'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}