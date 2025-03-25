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
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collectionGroup('payments').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Veuillez réessayer plus tard',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Aucune demande trouvée',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            final demands = snapshot.data!.docs;

            return ListView.separated(
              itemCount: demands.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final demand = demands[index];
                final data = demand.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'pending';
                final userId = demand.reference.parent.parent!.id;
                final photoUrl = data['photoUrl'];
                final adminMessage = data['adminMessage'] ?? '';
                final forfaitType = data['forfait'];

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showDemandDetails(context, data, status),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Avatar
                          _buildUserAvatar(photoUrl),

                          SizedBox(width: 12),

                          // User Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${data['nom']} ${data['prenom']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                _buildInfoRow(
                                    Icons.credit_card, 'Forfait: $forfaitType'),
                                SizedBox(height: 4),
                                _buildStatusRow(status),
                                if (adminMessage.isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  _buildAdminMessage(adminMessage, status),
                                ],
                                if (status == 'approved' &&
                                    data['activationEnd'] != null) ...[
                                  SizedBox(height: 4),
                                  _buildActivationDate(
                                      data['activationEnd'].toDate()),
                                ],
                              ],
                            ),
                          ),

                          // Action Buttons
                          _buildActionButtons(
                            context,
                            demand.reference,
                            userId,
                            forfaitType,
                            status,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String? photoUrl) {
    return GestureDetector(
      onTap:
          photoUrl != null ? () => _showPhotoDialog(context, photoUrl) : null,
      child: CircleAvatar(
        radius: 24,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        backgroundColor: photoUrl == null ? Colors.grey[200] : null,
        child: photoUrl == null
            ? Icon(Icons.person, color: Colors.grey[600])
            : null,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String status) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(
          'Statut: ${_getStatusText(status)}',
          style: TextStyle(
            fontSize: 14,
            color: _getStatusColor(status),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMessage(String message, String status) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getMessageBackgroundColor(status),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: _getMessageColor(status),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildActivationDate(DateTime date) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 14, color: Colors.blue),
        SizedBox(width: 4),
        Text(
          'Valide jusqu\'au: ${_formatDate(date)}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _deactivateAccount(
      DocumentReference demandRef, String userId) async {
    try {
      await demandRef.update({
        'status': 'rejected',
        'adminMessage': 'Compte désactivé par l\'admin',
      });

      await _firestore.collection('Users').doc(userId).update({
        'isActive': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compte désactivé avec succès'),
          backgroundColor: Colors.orange,
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

  Future<void> _reactivateAccount(
      DocumentReference demandRef, String userId) async {
    try {
      await demandRef.update({
        'status': 'approved',
        'adminMessage': 'Compte réactivé par l\'admin',
      });

      await _firestore.collection('Users').doc(userId).update({
        'isActive': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compte réactivé avec succès'),
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

  Widget _buildActionButtons(
    BuildContext context,
    DocumentReference demandRef,
    String userId,
    String forfaitType,
    String status,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'pending') ...[
          IconButton(
            icon: Icon(Icons.check_circle, color: Colors.green),
            tooltip: 'Approuver',
            onPressed: () => _showActivationDialog(
              context,
              demandRef,
              userId,
              forfaitType,
            ),
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            tooltip: 'Rejeter',
            onPressed: () => _showMessageDialog(
              context,
              demandRef,
              'rejected',
              userId,
            ),
          ),
        ] else if (status == 'approved') ...[
          IconButton(
            icon: Icon(Icons.toggle_on, color: Colors.green),
            tooltip: 'Désactiver',
            onPressed: () => _deactivateAccount(demandRef, userId),
          ),
        ] else if (status == 'rejected') ...[
          IconButton(
            icon: Icon(Icons.toggle_off, color: Colors.red),
            tooltip: 'Réactiver',
            onPressed: () => _reactivateAccount(demandRef, userId),
          ),
        ],
      ],
    );
  }

  void _showDemandDetails(
      BuildContext context, Map<String, dynamic> data, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Détails de la demande'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('Nom', data['nom']),
                _buildDetailItem('Prénom', data['prenom']),
                _buildDetailItem('Forfait', data['forfait']),
                _buildDetailItem('Statut', _getStatusText(status)),
                if (data['adminMessage'] != null)
                  _buildDetailItem('Message', data['adminMessage']),
                if (status == 'approved' && data['activationEnd'] != null)
                  _buildDetailItem('Valide jusqu\'au',
                      _formatDate(data['activationEnd'].toDate())),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
          Divider(height: 16),
        ],
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
          title: Text('Activer le compte',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogInfoRow('Type de forfait:', forfaitType),
                _buildDialogInfoRow('Durée:', '$monthsToAdd mois'),
                _buildDialogInfoRow(
                    'Date de fin:', _formatDate(_activationEndDate!)),
                SizedBox(height: 20),
                Text(
                  'Message (optionnel)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Entrez un message personnalisé...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ANNULER', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () async {
                await _activateAccount(
                  demandRef,
                  userId,
                  _messageController.text,
                  _activationEndDate!,
                );
                Navigator.pop(context);
              },
              child: Text('CONFIRMER'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getMessageBackgroundColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green[50]!;
      case 'rejected':
        return Colors.red[50]!;
      default:
        return Colors.grey[100]!;
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
        return Colors.green[800]!;
      case 'rejected':
        return Colors.red[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  void _showPhotoDialog(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Image.network(
                        photoUrl,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error,
                                      color: Colors.red, size: 48),
                                  Text('Erreur de chargement'),
                                ],
                              ),
                            ),
                          );
                        },
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: Icon(Icons.close,
                                size: 16, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              title: Text('Envoyer un message',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedMessageType,
                      items: predefinedMessages.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMessageType = value;
                          _messageController.text = predefinedMessages[value]!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Type de message',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        hintText: 'Modifiez le message si nécessaire...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('ANNULER',
                      style: TextStyle(color: Colors.grey[600])),
                ), // This closing parenthesis was missing
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () async {
                    await _updateDemandStatus(
                      demandRef,
                      _selectedMessageType!,
                      userId,
                      _messageController.text,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('ENVOYER'),
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
