import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_model.dart';
import 'firebase_data-service.dart';


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class AddEditScreen extends StatefulWidget {
  final EducationalData? data;
  final Function(Map<String, dynamic>) onSave;

  const AddEditScreen({
    super.key,
    this.data,
    required this.onSave,
  });

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _classeController;
  late TextEditingController _matiereController;
  late TextEditingController _baremeController;
  
  List<TextEditingController> _problemeControllers = [];
  List<TextEditingController> _solutionControllers = [];
  
  bool _applyToAllSubclasses = false;
  bool _isMasterClass = false;

  @override
  void initState() {
    super.initState();
    _classeController = TextEditingController(text: widget.data?.classe ?? '');
    _matiereController = TextEditingController(text: widget.data?.matiere ?? '');
    _baremeController = TextEditingController(text: widget.data?.bareme ?? '');
    
    _isMasterClass = widget.data?.isMaster ?? 
        EducationalData.isMasterClass(_classeController.text.trim());
    _applyToAllSubclasses = _isMasterClass && widget.data != null;
    
    if (widget.data?.problemes != null && widget.data!.problemes.isNotEmpty) {
      _problemeControllers = widget.data!.problemes
          .map((probleme) => TextEditingController(text: probleme))
          .toList();
    } else {
      _problemeControllers = [TextEditingController()];
    }
    
    if (widget.data?.solutions != null && widget.data!.solutions.isNotEmpty) {
      _solutionControllers = widget.data!.solutions
          .map((solution) => TextEditingController(text: solution))
          .toList();
    } else {
      _solutionControllers = [TextEditingController()];
    }

    _classeController.addListener(_checkIfMasterClass);
  }

  @override
  void dispose() {
    _classeController.dispose();
    _matiereController.dispose();
    _baremeController.dispose();
    
    for (var controller in _problemeControllers) {
      controller.dispose();
    }
    for (var controller in _solutionControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _checkIfMasterClass() {
    final isMaster = EducationalData.isMasterClass(_classeController.text.trim());
    if (_isMasterClass != isMaster) {
      setState(() {
        _isMasterClass = isMaster;
        _applyToAllSubclasses = isMaster && widget.data != null;
      });
    }
  }

  void _addProblemeField() {
    setState(() {
      _problemeControllers.add(TextEditingController());
    });
  }

  void _removeProblemeField(int index) {
    if (_problemeControllers.length > 1) {
      setState(() {
        _problemeControllers[index].dispose();
        _problemeControllers.removeAt(index);
      });
    }
  }

  void _addSolutionField() {
    setState(() {
      _solutionControllers.add(TextEditingController());
    });
  }

  void _removeSolutionField(int index) {
    if (_solutionControllers.length > 1) {
      setState(() {
        _solutionControllers[index].dispose();
        _solutionControllers.removeAt(index);
      });
    }
  }

  Widget _buildListField({
    required String title,
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    String hintText = 'Saisissez ici...',
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$title (${controllers.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: iconColor ?? Colors.green),
                  onPressed: onAdd,
                  tooltip: 'Ajouter un élément',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(controllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: controllers[index],
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: hintText,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          suffixIcon: controllers.length > 1
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => onRemove(index),
                                  tooltip: 'Supprimer',
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ce champ est requis';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubclassOption() {
    if (!_isMasterClass || widget.data == null) return const SizedBox();

    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Classe Principale Détectée',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette classe sera appliquée à toutes les sections:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                for (var letter in ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز'])
                  Chip(
                    label: Text(
                      '${_classeController.text.trim()} $letter',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'NotoKufiArabic', // Police pour l'arabe
                      ),
                    ),
                    backgroundColor: Colors.orange[100],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              title: const Text(
                'Appliquer aux sous-classes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Les modifications seront automatiquement appliquées à toutes les sections (أ, ب, ج, د...)',
                style: TextStyle(fontSize: 12),
              ),
              value: _applyToAllSubclasses,
              onChanged: widget.data != null
                  ? (value) {
                      setState(() {
                        _applyToAllSubclasses = value;
                      });
                    }
                  : null,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            if (_applyToAllSubclasses)
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les modifications seront propagées à toutes les sous-classes.',
                        style: TextStyle(fontSize: 11, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextFormField(
              controller: _classeController,
              decoration: InputDecoration(
                labelText: 'Classe *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.school),
                suffixIcon: _isMasterClass
                    ? const Tooltip(
                        message: 'Classe principale détectée',
                        child: Icon(Icons.star, color: Colors.orange),
                      )
                    : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer la classe';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _matiereController,
              decoration: const InputDecoration(
                labelText: 'Matière *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer la matière';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _baremeController,
              decoration: const InputDecoration(
                labelText: 'Barème *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grade),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le barème';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final problemes = _problemeControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      
      final solutions = _solutionControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      
      if (problemes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter au moins un problème'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (solutions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter au moins une solution'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = EducationalData(
        id: widget.data?.id,
        classe: _classeController.text.trim(),
        matiere: _matiereController.text.trim(),
        bareme: _baremeController.text.trim(),
        solutions: solutions,
        problemes: problemes,
        isMaster: _isMasterClass,
      );
      
      final saveData = {
        'data': data,
        'applyToSubclasses': _applyToAllSubclasses && widget.data != null,
      };
      
      widget.onSave(saveData);
    }
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: Text(
          widget.data == null ? 'Ajouter' : 'Mettre à jour',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHelpInfo() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ℹ️ Guide d\'utilisation:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              icon: Icons.add_circle,
              color: Colors.green,
              text: 'Utilisez le bouton + pour ajouter plusieurs problèmes/solutions',
            ),
            _buildInfoItem(
              icon: Icons.remove_circle,
              color: Colors.red,
              text: 'Le bouton - supprime un élément (au moins un reste)',
            ),
            _buildInfoItem(
              icon: Icons.star,
              color: Colors.orange,
              text: 'Les classes sans lettre (ex: "السنة الأولى ابتدائي") sont principales',
            ),
            if (_isMasterClass && widget.data != null)
              _buildInfoItem(
                icon: Icons.sync,
                color: Colors.purple,
                text: 'Activez "Appliquer aux sous-classes" pour propager les modifications',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data == null ? 'Ajouter Données' : 'Modifier Données'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubclassOption(),
              
              const SizedBox(height: 16),
              
              _buildBasicInfoCard(),
              
              const SizedBox(height: 16),
              
              _buildListField(
                title: 'Problèmes',
                controllers: _problemeControllers,
                onAdd: _addProblemeField,
                onRemove: _removeProblemeField,
                hintText: 'Décrivez un problème rencontré...',
                iconColor: Colors.orange,
              ),
              
              const SizedBox(height: 16),
              
              _buildListField(
                title: 'Solutions',
                controllers: _solutionControllers,
                onAdd: _addSolutionField,
                onRemove: _removeSolutionField,
                hintText: 'Proposez une solution ou une activité...',
                iconColor: Colors.green,
              ),
              
              const SizedBox(height: 24),
              
              _buildActionButtons(),
              
              const SizedBox(height: 16),
              
              _buildHelpInfo(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminRequestsPage extends StatefulWidget {
  @override
  _AdminRequestsPageState createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'pending'; // pending, approved, rejected, all
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allRequests = [];
  List<DocumentSnapshot> _filteredRequests = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRequests);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRequests() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRequests = _allRequests.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['nom']?.toLowerCase().contains(query) == true ||
            data['prenom']?.toLowerCase().contains(query) == true ||
            data['email']?.toLowerCase().contains(query) == true ||
            data['ecole']?.toLowerCase().contains(query) == true;
      }).toList();
    });
  }

  Future<void> _updateRequestStatus(String docId, String status,
      {String? rejectionReason}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      // Récupérer la demande
      DocumentSnapshot requestDoc = await _firestore
          .collection('class_limit_requests')
          .doc(docId)
          .get();

      Map<String, dynamic> requestData =
          requestDoc.data() as Map<String, dynamic>;
      String userId = requestData['userId'];

      // Mettre à jour le statut dans la collection globale
      await _firestore.collection('class_limit_requests').doc(docId).update({
        'status': status,
        'processedBy': currentUser?.uid,
        'processedAt': FieldValue.serverTimestamp(),
        'processedByEmail': currentUser?.email,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      });

      // Mettre à jour le statut dans la collection de l'utilisateur
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('requests')
          .doc('class_limit_request')
          .update({
        'status': status,
        'processedBy': currentUser?.uid,
        'processedAt': FieldValue.serverTimestamp(),
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      });

      // Si approuvé, mettre à jour la limite de l'utilisateur
      if (status == 'approved') {
        await _firestore.collection('users').doc(userId).update({
          'classLimit': 10, // Nouvelle limite
          'requestApprovedAt': FieldValue.serverTimestamp(),
        });

        // Envoyer une notification (vous pouvez implémenter votre système de notification ici)
        await _createNotification(
          userId,
          'تم قبول طلبك',
          'تمت الموافقة على طلب زيادة عدد الأقسام. يمكنك الآن إضافة المزيد من الأقسام.',
        );
      } else if (status == 'rejected') {
        await _createNotification(
          userId,
          'تم رفض طلبك',
          rejectionReason ?? 'عذرًا، لم تتم الموافقة على طلبك.',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الطلب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Erreur lors de la mise à jour : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحديث الطلب'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createNotification(String userId, String title, String body) async {
    try {
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'title': title,
        'body': body,
        'type': 'request_update',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Erreur lors de la création de la notification : $e");
    }
  }

  void _showRejectionDialog(String docId) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('رفض الطلب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('يرجى إدخال سبب الرفض:'),
              SizedBox(height: 10),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'سبب الرفض...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _updateRequestStatus(docId, 'rejected',
                      rejectionReason: reasonController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('يرجى إدخال سبب الرفض'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('تأكيد الرفض'),
            ),
          ],
        );
      },
    );
  }

  void _showRequestDetails(Map<String, dynamic> requestData, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'تفاصيل الطلب',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildInfoCard(
                          icon: Icons.person,
                          title: 'المعلومات الشخصية',
                          children: [
                            _buildInfoRow('الاسم', requestData['nom'] ?? ''),
                            _buildInfoRow('اللقب', requestData['prenom'] ?? ''),
                            _buildInfoRow('رقم الهاتف', requestData['telephone'] ?? ''),
                            _buildInfoRow('البريد الإلكتروني', requestData['email'] ?? ''),
                          ],
                        ),
                        SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.school,
                          title: 'المعلومات المهنية',
                          children: [
                            _buildInfoRow('المؤسسة', requestData['ecole'] ?? ''),
                            _buildInfoRow('العنوان', requestData['adresseEcole'] ?? ''),
                          ],
                        ),
                        SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.description,
                          title: 'سبب الطلب',
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                requestData['raison'] ?? '',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.info,
                          title: 'معلومات إضافية',
                          children: [
                            _buildInfoRow(
                              'عدد الأقسام الحالي',
                              '${requestData['currentClassCount'] ?? 0}',
                            ),
                            _buildInfoRow(
                              'تاريخ الطلب',
                              requestData['timestamp'] != null
                                  ? DateFormat('yyyy/MM/dd HH:mm').format(
                                      (requestData['timestamp'] as Timestamp).toDate())
                                  : 'غير معروف',
                            ),
                            if (requestData['status'] != null)
                              _buildInfoRow(
                                'الحالة',
                                _getStatusText(requestData['status']),
                                statusColor: _getStatusColor(requestData['status']),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  if (requestData['status'] == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateRequestStatus(docId, 'approved');
                            },
                            icon: Icon(Icons.check),
                            label: Text('قبول'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showRejectionDialog(docId);
                            },
                            icon: Icon(Icons.close),
                            label: Text('رفض'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color.fromRGBO(7, 82, 96, 1)),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: statusColor ?? Colors.black,
                fontWeight: statusColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة طلبات الزيادة',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromRGBO(7, 82, 96, 1),
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن طلب...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Filtres
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('الكل', 'all', Icons.list),
                _buildFilterChip('قيد الانتظار', 'pending', Icons.hourglass_empty),
                _buildFilterChip('مقبول', 'approved', Icons.check_circle),
                _buildFilterChip('مرفوض', 'rejected', Icons.cancel),
              ],
            ),
          ),

          // Liste des demandes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('class_limit_requests')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('حدث خطأ: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var requests = snapshot.data!.docs;
                
                // Mettre à jour la liste complète
                _allRequests = requests;
                
                // Filtrer selon le statut
                var filteredRequests = _selectedFilter == 'all'
                    ? requests
                    : requests.where((doc) {
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        return data['status'] == _selectedFilter;
                      }).toList();

                // Appliquer la recherche
                if (_searchController.text.isNotEmpty) {
                  filteredRequests = filteredRequests.where((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String query = _searchController.text.toLowerCase();
                    return data['nom']?.toLowerCase().contains(query) == true ||
                        data['prenom']?.toLowerCase().contains(query) == true ||
                        data['email']?.toLowerCase().contains(query) == true ||
                        data['ecole']?.toLowerCase().contains(query) == true;
                  }).toList();
                }

                if (filteredRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    var doc = filteredRequests[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(data['status'] ?? 'pending')
                              .withOpacity(0.1),
                          child: Icon(
                            _getStatusIcon(data['status'] ?? 'pending'),
                            color: _getStatusColor(data['status'] ?? 'pending'),
                          ),
                        ),
                        title: Text(
                          '${data['nom'] ?? ''} ${data['prenom'] ?? ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              data['ecole'] ?? '',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  data['timestamp'] != null
                                      ? DateFormat('yyyy/MM/dd HH:mm').format(
                                          (data['timestamp'] as Timestamp).toDate())
                                      : 'غير معروف',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data['status'] ?? 'pending')
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(data['status'] ?? 'pending'),
                            style: TextStyle(
                              color: _getStatusColor(data['status'] ?? 'pending'),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () => _showRequestDetails(data, doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Statistiques flottantes
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStatistics,
        backgroundColor: Color.fromRGBO(7, 82, 96, 1),
        icon: Icon(Icons.bar_chart),
        label: Text('الإحصائيات'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    bool isSelected = _selectedFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Color.fromRGBO(7, 82, 96, 1),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('class_limit_requests').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var requests = snapshot.data!.docs;
            int total = requests.length;
            int pending = requests.where((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'pending';
            }).length;
            int approved = requests.where((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'approved';
            }).length;
            int rejected = requests.where((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'rejected';
            }).length;

            return AlertDialog(
              title: Text('إحصائيات الطلبات'),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatItem('إجمالي الطلبات', total, Colors.blue),
                    Divider(),
                    _buildStatItem('قيد الانتظار', pending, Colors.orange),
                    _buildStatItem('مقبول', approved, Colors.green),
                    _buildStatItem('مرفوض', rejected, Colors.red),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إغلاق'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}