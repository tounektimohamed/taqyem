import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminRequestsPage extends StatefulWidget {
  @override
  _AdminRequestsPageState createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'pending';
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

  // Dialogue pour choisir la nouvelle limite
  Future<void> _showLimitDialog(String docId, String userId, int currentLimit) {
    TextEditingController limitController = TextEditingController();
    int selectedLimit = 10; // Valeur par défaut
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('تحديد الحد الجديد'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الحد الحالي: $currentLimit قسم'),
                  SizedBox(height: 20),
                  Text('اختر الحد الجديد:'),
                  SizedBox(height: 10),
                  // Options de limites
                  Wrap(
                    spacing: 8,
                    children: [8, 10, 12, 15, 20, 25, 30, 40, 50].map((limit) {
                      return ChoiceChip(
                        label: Text('$limit'),
                        selected: selectedLimit == limit,
                        onSelected: (selected) {
                          setState(() {
                            selectedLimit = limit;
                            limitController.text = limit.toString();
                          });
                        },
                        selectedColor: Colors.green.withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  Text('أو أدخل قيمة مخصصة:'),
                  SizedBox(height: 10),
                  TextField(
                    controller: limitController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'أدخل الحد الجديد',
                      suffixText: 'قسم',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          selectedLimit = int.tryParse(value) ?? selectedLimit;
                        });
                      }
                    },
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
                    int newLimit = selectedLimit;
                    if (limitController.text.isNotEmpty) {
                      newLimit = int.tryParse(limitController.text) ?? selectedLimit;
                    }
                    
                    if (newLimit <= currentLimit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('يجب أن يكون الحد الجديد أكبر من الحد الحالي'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.pop(context);
                    _updateRequestStatus(docId, userId, 'approved', newLimit: newLimit);
                  },
                  child: Text('قبول'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateRequestStatus(String docId, String userId, String status,
      {String? rejectionReason, int? newLimit}) async {
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

      Map<String, dynamic> requestData = requestDoc.data() as Map<String, dynamic>;

      // Mettre à jour le statut dans la collection globale
      await _firestore.collection('class_limit_requests').doc(docId).update({
        'status': status,
        'processedBy': currentUser?.uid,
        'processedAt': FieldValue.serverTimestamp(),
        'processedByEmail': currentUser?.email,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        if (newLimit != null) 'newLimit': newLimit,
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
        if (newLimit != null) 'newLimit': newLimit,
      });

      // Si approuvé, mettre à jour la limite de l'utilisateur
      if (status == 'approved' && newLimit != null) {
        // Récupérer les données actuelles de l'utilisateur
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        int oldLimit = userData['classLimit'] ?? 4;
        
        // Mettre à jour la limite
        await _firestore.collection('users').doc(userId).update({
          'classLimit': newLimit,
          'requestApprovedAt': FieldValue.serverTimestamp(),
          'requestApprovedBy': currentUser?.uid,
          'previousLimit': oldLimit,
          'limitUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Ajouter à l'historique des limites
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('limit_history')
            .add({
          'oldLimit': oldLimit,
          'newLimit': newLimit,
          'updatedBy': currentUser?.uid,
          'updatedByEmail': currentUser?.email,
          'updatedAt': FieldValue.serverTimestamp(),
          'requestId': docId,
        });

        // Créer une notification
        await _createNotification(
          userId,
          '✅ تم قبول طلبك',
          'تمت الموافقة على طلب زيادة عدد الأقسام. تم رفع الحد من $oldLimit إلى $newLimit قسم.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم قبول الطلب ورفع الحد إلى $newLimit قسم'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (status == 'rejected') {
        await _createNotification(
          userId,
          '❌ تم رفض طلبك',
          rejectionReason ?? 'عذرًا، لم تتم الموافقة على طلبك.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفض الطلب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Erreur lors de la mise à jour : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحديث الطلب: $e'),
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

  void _showRejectionDialog(String docId, String userId) {
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
                  _updateRequestStatus(docId, userId, 'rejected',
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

  void _showRequestDetails(Map<String, dynamic> requestData, String docId, String userId) {
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
                              'الحد الحالي',
                              '${requestData['currentLimit'] ?? 4}',
                            ),
                            _buildInfoRow(
                              'الحد المطلوب',
                              '${requestData['requestedLimit'] ?? 20}',
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
                              int currentLimit = requestData['currentLimit'] ?? 4;
                              _showLimitDialog(docId, userId, currentLimit);
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
                              _showRejectionDialog(docId, userId);
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
          if (_isLoading)
            Container(
              margin: EdgeInsets.all(8),
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
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
                _allRequests = requests;
                
                var filteredRequests = _selectedFilter == 'all'
                    ? requests
                    : requests.where((doc) {
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        return data['status'] == _selectedFilter;
                      }).toList();

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
                                  Icons.light,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'الحد المطلوب: ${data['requestedLimit'] ?? 20}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  data['timestamp'] != null
                                      ? DateFormat('yyyy/MM/dd').format(
                                          (data['timestamp'] as Timestamp).toDate())
                                      : '',
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
                        onTap: () => _showRequestDetails(data, doc.id, data['userId']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

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