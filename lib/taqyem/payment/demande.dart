import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;


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
  String _filterStatus = 'all';

  final Map<String, String> predefinedMessages = {
    'approved': 'تم تفعيل الحساب بنجاح',
    'rejected': 'تم رفض الطلب، يرجى مراجعة المعلومات',
    'other': 'رسالة أخرى'
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
        title: Text('إدارة طلبات الدفع', style: TextStyle(fontFamily: 'Tajawal')),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            _buildStatusFilter(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _filterStatus == 'all'
                    ? _firestore.collectionGroup('payments').snapshots()
                    : _firestore.collectionGroup('payments')
                        .where('status', isEqualTo: _filterStatus).snapshots(),
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
                            'خطأ في التحميل',
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'الرجاء المحاولة لاحقًا',
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
                            'لا توجد طلبات',
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
                      final paymentMethod = data['paymentMethod'] ?? 'manual';

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
                                _buildUserAvatar(photoUrl, paymentMethod),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${data['nom']} ${data['prenom']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      _buildInfoRow(
                                          Icons.credit_card, 'الباقة: $forfaitType'),
                                      SizedBox(height: 4),
                                      _buildInfoRow(
                                          Icons.payment, 'الطريقة: ${paymentMethod == 'online' ? 'إلكتروني' : 'يدوي'}'),
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
                                _buildActionButtons(
                                  context,
                                  demand.reference,
                                  userId,
                                  forfaitType,
                                  status,
                                  paymentMethod,
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(width: 8),
            FilterChip(
              label: Text('الكل', style: TextStyle(fontFamily: 'Tajawal')),
              selected: _filterStatus == 'all',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = 'all';
                });
              },
            ),
            SizedBox(width: 8),
            FilterChip(
              label: Text('قيد الانتظار', style: TextStyle(fontFamily: 'Tajawal')),
              selected: _filterStatus == 'pending',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = 'pending';
                });
              },
            ),
            SizedBox(width: 8),
            FilterChip(
              label: Text('مقبولة', style: TextStyle(fontFamily: 'Tajawal')),
              selected: _filterStatus == 'approved',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = 'approved';
                });
              },
            ),
            SizedBox(width: 8),
            FilterChip(
              label: Text('مرفوضة', style: TextStyle(fontFamily: 'Tajawal')),
              selected: _filterStatus == 'rejected',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = 'rejected';
                });
              },
            ),
          ],
        ),
      ),
    );
  }
// Ajouter cette méthode dans la classe _DemandManagementPageState
Widget _buildPaymentVerificationButton(DocumentReference demandRef) {
  return FutureBuilder<DocumentSnapshot>(
    future: demandRef.get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return SizedBox.shrink();
      
      final data = snapshot.data!.data() as Map<String, dynamic>;
      final paymentMethod = data['paymentMethod'] ?? 'manual';
      final status = data['status'] ?? 'pending';

      if (paymentMethod == 'online' && status == 'pending') {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: ElevatedButton.icon(
            icon: Icon(Icons.verified, size: 20),
            label: Text('تحقق من الدفع الإلكتروني', 
                style: TextStyle(fontSize: 14, fontFamily: 'Tajawal')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              html.window.open(
                'https://dashboard.konnect.network/admin/dashboard?filter[status]=success',
                '_blank'
              );
            },
          ),
        );
      }
      return SizedBox.shrink();
    },
  );
}
  Widget _buildUserAvatar(String? photoUrl, String paymentMethod) {
    return GestureDetector(
      onTap: photoUrl != null && paymentMethod != 'online'
          ? () => _showPhotoDialog(context, photoUrl)
          : null,
      child: CircleAvatar(
        radius: 24,
        backgroundImage: photoUrl != null && paymentMethod != 'online'
            ? NetworkImage(photoUrl)
            : null,
        backgroundColor: photoUrl == null || paymentMethod == 'online'
            ? Colors.grey[200]
            : null,
        child: paymentMethod == 'online'
            ? Icon(Icons.credit_card, color: Colors.green)
            : photoUrl == null
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
          style: TextStyle(fontSize: 14, color: Colors.grey[700], fontFamily: 'Tajawal'),
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
          'الحالة: ${_getStatusText(status)}',
          style: TextStyle(
            fontSize: 14,
            color: _getStatusColor(status),
            fontWeight: FontWeight.w500,
            fontFamily: 'Tajawal',
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
          fontFamily: 'Tajawal',
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
          'صالحة حتى: ${_formatDate(date)}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
            fontFamily: 'Tajawal',
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
        'adminMessage': 'تم تعطيل الحساب من قبل المسؤول',
      });

      await _firestore.collection('Users').doc(userId).update({
        'isActive': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تعطيل الحساب بنجاح'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _reactivateAccount(
      DocumentReference demandRef, String userId) async {
    try {
      await demandRef.update({
        'status': 'approved',
        'adminMessage': 'تم إعادة تفعيل الحساب من قبل المسؤول',
      });

      await _firestore.collection('Users').doc(userId).update({
        'isActive': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إعادة تفعيل الحساب بنجاح'),
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
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
  String paymentMethod,
) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'pending') ...[
            if (paymentMethod == 'online')
              IconButton(
                icon: Icon(Icons.credit_card, color: Colors.green),
                tooltip: 'معالجة الدفع الإلكتروني',
                onPressed: () => _processOnlinePayment(demandRef, userId, forfaitType),
              ),
            IconButton(
              icon: Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'تأكيد الدفع اليدوي',
              onPressed: () => _showActivationDialog(
                context,
                demandRef,
                userId,
                forfaitType,
              ),
            ),
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.red),
              tooltip: 'رفض الطلب',
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
              tooltip: 'تعطيل الحساب',
              onPressed: () => _deactivateAccount(demandRef, userId),
            ),
          ] else if (status == 'rejected') ...[
            IconButton(
              icon: Icon(Icons.toggle_off, color: Colors.red),
              tooltip: 'إعادة التفعيل',
              onPressed: () => _reactivateAccount(demandRef, userId),
            ),
          ],
        ],
      ),
      _buildPaymentVerificationButton(demandRef),
    ],
  );
}

  void _showDemandDetails(
      BuildContext context, Map<String, dynamic> data, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تفاصيل الطلب', style: TextStyle(fontFamily: 'Tajawal')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('الاسم العائلي', data['nom']),
                _buildDetailItem('الاسم الشخصي', data['prenom']),
                _buildDetailItem('الباقة', data['forfait']),
                _buildDetailItem('طريقة الدفع', 
                    data['paymentMethod'] == 'online' ? 'إلكتروني' : 'يدوي'),
                _buildDetailItem('الحالة', _getStatusText(status)),
                if (data['adminMessage'] != null)
                  _buildDetailItem('رسالة المسؤول', data['adminMessage']),
                if (status == 'approved' && data['activationEnd'] != null)
                  _buildDetailItem('صالحة حتى',
                      _formatDate(data['activationEnd'].toDate())),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal')),
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
              fontFamily: 'Tajawal',
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
          ),
          Divider(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
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
          title: Text('تفعيل الحساب', 
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogInfoRow('نوع الباقة:', forfaitType),
                _buildDialogInfoRow('المدة:', '$monthsToAdd أشهر'),
                _buildDialogInfoRow(
                    'تاريخ الانتهاء:', _formatDate(_activationEndDate!)),
                SizedBox(height: 20),
                Text(
                  'رسالة (اختيارية)',
                  style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Tajawal'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'أدخل رسالة مخصصة...',
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
              child: Text('إلغاء', 
                  style: TextStyle(color: Colors.grey[600], fontFamily: 'Tajawal')),
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
              child: Text('تأكيد', style: TextStyle(fontFamily: 'Tajawal')),
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
            style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Tajawal'),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
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
      await demandRef.update({
        'status': 'approved',
        'adminMessage': message.isNotEmpty ? message : 'تم تفعيل الحساب',
        'processedAt': FieldValue.serverTimestamp(),
        'activationStart': FieldValue.serverTimestamp(),
        'activationEnd': endDate,
      });

      await _firestore.collection('Users').doc(userId).update({
        'isActive': true,
        'accountExpiration': endDate,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تفعيل الحساب حتى ${_formatDate(endDate)}'),
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
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _processOnlinePayment(
      DocumentReference demandRef, String userId, String forfaitType) async {
    int monthsToAdd = forfaitType == 'ثلاثية' ? 3 : 12;
    DateTime activationEndDate = DateTime.now().add(Duration(days: monthsToAdd * 30));

    try {
      await demandRef.update({
        'status': 'approved',
        'adminMessage': 'تم الدفع إلكترونيًا وتفعيل الحساب',
        'processedAt': FieldValue.serverTimestamp(),
        'activationStart': FieldValue.serverTimestamp(),
        'activationEnd': activationEndDate,
      });

      await _firestore.collection('Users').doc(userId).update({
        'isActive': true,
        'accountExpiration': activationEndDate,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تفعيل الحساب حتى ${_formatDate(activationEndDate)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في معالجة الدفع الإلكتروني: ${e.toString()}'),
          backgroundColor: Colors.red,
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
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
        return 'قيد الانتظار';
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
                                  Text('خطأ في تحميل الصورة'),
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
              title: Text('إرسال رسالة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
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
                            style: TextStyle(fontSize: 14, fontFamily: 'Tajawal'),
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
                        labelText: 'نوع الرسالة',
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
                        labelText: 'الرسالة',
                        hintText: 'قم بتعديل الرسالة إذا لزم الأمر...',
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
                  child: Text('إلغاء',
                      style: TextStyle(color: Colors.grey[600], fontFamily: 'Tajawal')),
                ),
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
                  child: Text('إرسال', style: TextStyle(fontFamily: 'Tajawal')),
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
      await demandRef.update({
        'status': status,
        'adminMessage': message,
        'processedAt': FieldValue.serverTimestamp(),
      });

      final isActive = status == 'approved';
      await _firestore.collection('Users').doc(userId).update({
        'isActive': isActive,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث الطلب بنجاح!'),
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
          content: Text('خطأ: ${e.toString()}'),
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