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
  final TextEditingController _messageController = TextEditingController();
  String? _selectedMessageType;
  DateTime? _activationEndDate;

  final Map<String, String> predefinedMessages = {
    'approved': 'Compte activé, merci pour votre confiance',
    'rejected': 'Demande non valide, veuillez vérifier vos informations',
    'other': 'Autre message'
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

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
              final adminMessage = data['adminMessage'] ?? '';
              final forfaitType = data['forfait'];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: GestureDetector(
                    onTap: () {
                      if (photoUrl != null) {
                        _showPhotoDialog(context, photoUrl);
                      }
                    },
                    child: CircleAvatar(
                      backgroundImage: photoUrl != null 
                          ? NetworkImage(photoUrl) 
                          : null,
                      child: photoUrl == null ? Icon(Icons.person) : null,
                    ),
                  ),
                  title: Text('${data['nom']} ${data['prenom']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Forfait: ${data['forfait']}'),
                      Text('Statut: ${_getStatusText(status)}'),
                      if (adminMessage.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Message: $adminMessage',
                            style: TextStyle(
                              color: _getMessageColor(status),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (status == 'approved' && data['activationEnd'] != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Valide jusqu\'au: ${_formatDate(data['activationEnd'].toDate())}',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => _showActivationDialog(
                          context,
                          demand.reference,
                          userId,
                          forfaitType,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _showMessageDialog(
                          context,
                          demand.reference,
                          'rejected',
                          userId,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showActivationDialog(
    BuildContext context,
    DocumentReference demandRef,
    String userId,
    String forfaitType,
  ) {
    int monthsToAdd = forfaitType == 'ثلاثية' ? 3 : 12;
    _activationEndDate = DateTime.now().add(Duration(days: monthsToAdd * 30));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Activer le compte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type de forfait: $forfaitType'),
              SizedBox(height: 10),
              Text('Durée: ${monthsToAdd} mois'),
              SizedBox(height: 10),
              Text('Date de fin: ${_formatDate(_activationEndDate!)}'),
              SizedBox(height: 20),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _activateAccount(
                  demandRef,
                  userId,
                  _messageController.text,
                  _activationEndDate!,
                );
                Navigator.pop(context);
              },
              child: Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _activateAccount(
    DocumentReference demandRef,
    String userId,
    String message,
    DateTime endDate,
  ) async {
    try {
      // Update payment status and set activation period
      await demandRef.update({
        'status': 'approved',
        'adminMessage': message.isNotEmpty ? message : 'Compte activé',
        'processedAt': FieldValue.serverTimestamp(),
        'activationStart': FieldValue.serverTimestamp(),
        'activationEnd': endDate,
      });

      // Update user active status and set expiration
      await _firestore.collection('Users').doc(userId).update({
        'isActive': true,
        'accountExpiration': endDate,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compte activé jusqu\'au ${_formatDate(endDate)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'pending':
        return 'En attente';
      default:
        return status;
    }
  }

  Color _getMessageColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
                  onPressed: () => Navigator.pop(context),
                  child: Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessageDialog(
    BuildContext context,
    DocumentReference demandRef,
    String messageType,
    String userId,
  ) {
    _selectedMessageType = messageType;
    _messageController.text = predefinedMessages[messageType]!;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Envoyer un message'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedMessageType,
                    items: predefinedMessages.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMessageType = value;
                        _messageController.text = predefinedMessages[value]!;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Type de message'),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _updateDemandStatus(
                      demandRef,
                      _selectedMessageType!,
                      userId,
                      _messageController.text,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('Envoyer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateDemandStatus(
    DocumentReference demandRef,
    String status,
    String userId,
    String message,
  ) async {
    try {
      // Update payment status and admin message
      await demandRef.update({
        'status': status,
        'adminMessage': message,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Update user active status
      final isActive = status == 'approved';
      await _firestore.collection('Users').doc(userId).update({
        'isActive': isActive,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande mise à jour avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}