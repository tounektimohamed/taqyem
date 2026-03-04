import 'package:Taqyem/taqyem/payment/card_distribution_service.dart';
import 'package:Taqyem/taqyem/payment/card_management_page.dart';
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
  bool _isLoading = false;
  final CardDistributionService _cardService = CardDistributionService();
  bool _showCardStats = true;

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

  Color _getCardColor(String cardId) {
    switch (cardId) {
      case 'A':
        return Colors.blue;
      case 'B':
        return Colors.green;
      case 'C':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAdminCardStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _cardService.getDetailedStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        final cards = stats['cards'] as List;

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'إحصائيات البطاقات - ${stats['date']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ...cards.map((card) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getCardColor(card['id']),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                card['id'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: card['count'] / card['limit'],
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    card['count'] >= card['limit']
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '${card['count']}/${card['limit']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: card['count'] >= card['limit']
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    )),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجمالي اليومي:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    Text(
                      '${stats['totalToday']} / ${stats['maxDaily']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: stats['totalToday'] >= stats['maxDaily']
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'المتبقي: ${stats['remainingTotal']} مشترك',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Méthode pour obtenir le stream correct en fonction du filtre
  Stream<QuerySnapshot> _getDemandsStream() {
    if (_filterStatus == 'all') {
      return _firestore.collectionGroup('payments').snapshots();
    } else {
      return _firestore
          .collectionGroup('payments')
          .where('status', isEqualTo: _filterStatus)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'إدارة طلبات الدفع',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.credit_card),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CardManagementPage()),
              );
            },
            tooltip: 'إدارة البطاقات',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showCardStats) _buildAdminCardStats(),
                      SizedBox(height: 16),
                      // Header avec statistiques
                      _buildStatsHeader(),
                      SizedBox(height: 16),

                      // Filtres
                      _buildStatusFilter(),
                      SizedBox(height: 16),

                      // Liste des demandes
                      _buildDemandsList(),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildStatsHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collectionGroup('payments').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildStatsCard(0, 0, 0);
        }

        final demands = snapshot.data!.docs;
        final pending = demands.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['status'] == 'pending';
        }).length;

        final approved = demands.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['status'] == 'approved';
        }).length;

        final rejected = demands.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['status'] == 'rejected';
        }).length;

        return _buildStatsCard(pending, approved, rejected);
      },
    );
  }

  Widget _buildStatsCard(int pending, int approved, int rejected) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
                Icons.pending_actions, 'قيد الانتظار', pending, Colors.orange),
            _buildStatItem(
                Icons.check_circle, 'مقبولة', approved, Colors.green),
            _buildStatItem(Icons.cancel, 'مرفوضة', rejected, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تصفية الطلبات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', 'all', Icons.all_inclusive),
                  SizedBox(width: 8),
                  _buildFilterChip('قيد الانتظار', 'pending', Icons.pending),
                  SizedBox(width: 8),
                  _buildFilterChip('مقبولة', 'approved', Icons.check_circle),
                  SizedBox(width: 8),
                  _buildFilterChip('مرفوضة', 'rejected', Icons.cancel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : null),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontFamily: 'Tajawal')),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue.shade600,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildDemandsList() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      child: StreamBuilder<QuerySnapshot>(
        stream: _getDemandsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جاري تحميل الطلبات...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            print('Error loading demands: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'حدث خطأ في التحميل',
                    style: TextStyle(
                        fontSize: 18, color: Colors.red, fontFamily: 'Tajawal'),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'الرجاء المحاولة مرة أخرى',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('إعادة المحاولة'),
                    onPressed: () => setState(() {}),
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
                  Icon(Icons.inbox_outlined,
                      color: Colors.blue.shade300, size: 80),
                  SizedBox(height: 16),
                  Text(
                    _filterStatus == 'all'
                        ? 'لا توجد طلبات حالياً'
                        : 'لا توجد طلبات في هذه الفئة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _filterStatus == 'all'
                        ? 'سيظهر هنا الطلبات الجديدة عند توفرها'
                        : 'جرب تغيير الفلتر لعرض المزيد من الطلبات',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_filterStatus != 'all') ...[
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filterStatus = 'all';
                        });
                      },
                      child: Text('عرض جميع الطلبات'),
                    ),
                  ],
                ],
              ),
            );
          }

          final demands = snapshot.data!.docs;

          return ListView.separated(
            itemCount: demands.length,
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final demand = demands[index];
              final data = demand.data() as Map<String, dynamic>;
              return _buildDemandCard(demand, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildDemandCard(
      QueryDocumentSnapshot demand, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final userId = demand.reference.parent.parent!.id;
    final photoUrl = data['photoUrl'];
    final adminMessage = data['adminMessage'] ?? '';
    final forfaitType = data['forfait'];
    final paymentMethod = data['paymentMethod'] ?? 'manual';
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDemandDetails(context, data, status),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserAvatar(photoUrl, paymentMethod, status),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${data['nom']} ${data['prenom']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              Icons.credit_card,
                              'الباقة: $forfaitType',
                              Colors.blue.shade100,
                            ),
                            _buildInfoChip(
                              Icons.payment,
                              paymentMethod == 'online' ? 'إلكتروني' : 'يدوي',
                              paymentMethod == 'online'
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                            ),
                            _buildInfoChip(
                              Icons.calendar_today,
                              _formatDate(createdAt),
                              Colors.grey.shade100,
                            ),
                          ],
                        ),
                        if (adminMessage.isNotEmpty) ...[
                          SizedBox(height: 8),
                          _buildAdminMessage(adminMessage, status),
                        ],
                        if (status == 'approved' &&
                            data['activationEnd'] != null) ...[
                          SizedBox(height: 8),
                          _buildActivationDate(data['activationEnd'].toDate()),
                        ],
                        
                        // Ajout d'un bouton pour voir l'image si elle existe
                        if (photoUrl != null && photoUrl.isNotEmpty && paymentMethod != 'online') ...[
                          SizedBox(height: 8),
                          _buildPhotoViewButton(photoUrl),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildActionButtons(
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
  }

  // Nouveau widget pour afficher un bouton de visualisation d'image
  Widget _buildPhotoViewButton(String photoUrl) {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.image, size: 16, color: Colors.blue),
        label: Text(
          'عرض إثبات الدفع',
          style: TextStyle(fontSize: 12, fontFamily: 'Tajawal', color: Colors.blue),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.blue),
          padding: EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _showPhotoDialog(context, photoUrl),
      ),
    );
  }

  Widget _buildUserAvatar(
      String? photoUrl, String paymentMethod, String status) {
    return Stack(
      children: [
        GestureDetector(
          onTap: photoUrl != null && paymentMethod != 'online'
              ? () => _showPhotoDialog(context, photoUrl)
              : null,
          child: CircleAvatar(
            radius: 24,
            backgroundImage: photoUrl != null && paymentMethod != 'online'
                ? NetworkImage(photoUrl)
                : null,
            backgroundColor: _getStatusColor(status).withOpacity(0.1),
            child: paymentMethod == 'online'
                ? Icon(Icons.credit_card, color: Colors.green)
                : photoUrl == null
                    ? Icon(Icons.person, color: _getStatusColor(status))
                    : null,
          ),
        ),
        if (paymentMethod == 'online')
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            _getStatusText(status),
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(status),
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMessage(String message, String status) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getMessageBackgroundColor(status),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.message, size: 16, color: _getStatusColor(status)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: _getMessageColor(status),
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationDate(DateTime date) {
    final isExpired = date.isBefore(DateTime.now());
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isExpired ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.warning : Icons.check_circle,
            size: 14,
            color: isExpired ? Colors.red : Colors.green,
          ),
          SizedBox(width: 6),
          Text(
            '${isExpired ? 'منتهية' : 'صالحة حتى'}: ${_formatDate(date)}',
            style: TextStyle(
              fontSize: 12,
              color: isExpired ? Colors.red : Colors.green,
              fontWeight: FontWeight.w500,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    DocumentReference demandRef,
    String userId,
    String forfaitType,
    String status,
    String paymentMethod,
  ) {
    return Column(
      children: [
        if (status == 'pending')
          _buildPaymentVerificationButton(demandRef, paymentMethod),
        SizedBox(height: 8),
        Row(
          children: [
            if (status == 'pending') ...[
              Expanded(
                child: _buildActionButton(
                  'رفض',
                  Icons.cancel,
                  Colors.red.shade600,
                  () => _showMessageDialog(
                      context, demandRef, 'rejected', userId),
                ),
              ),
              SizedBox(width: 8),
              if (paymentMethod == 'online') ...[
                Expanded(
                  child: _buildActionButton(
                    'معالجة إلكتروني',
                    Icons.credit_card,
                    Colors.green,
                    () => _processOnlinePayment(demandRef, userId, forfaitType),
                  ),
                ),
                SizedBox(width: 8),
              ],
              Expanded(
                child: _buildActionButton(
                  paymentMethod == 'online' ? 'تفعيل يدوي' : 'تفعيل',
                  Icons.check_circle,
                  Colors.green,
                  () => _showActivationDialog(
                      context, demandRef, userId, forfaitType),
                ),
              ),
            ] else if (status == 'approved') ...[
              Expanded(
                child: _buildActionButton(
                  'تعطيل',
                  Icons.toggle_on,
                  Colors.orange,
                  () => _deactivateAccount(demandRef, userId),
                ),
              ),
            ] else if (status == 'rejected') ...[
              Expanded(
                child: _buildActionButton(
                  'إعادة التفعيل',
                  Icons.toggle_off,
                  Colors.blue,
                  () => _reactivateAccount(demandRef, userId),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(
        text,
        style: TextStyle(fontSize: 12, fontFamily: 'Tajawal'),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildPaymentVerificationButton(
      DocumentReference demandRef, String paymentMethod) {
    if (paymentMethod != 'online') return SizedBox.shrink();

    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.verified_user, size: 16),
        label: Text(
          'التحقق من الدفع الإلكتروني',
          style: TextStyle(fontSize: 12, fontFamily: 'Tajawal'),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.deepPurple,
          side: BorderSide(color: Colors.deepPurple),
          padding: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          html.window.open(
              'https://dashboard.konnect.network/admin/dashboard?filter[status]=success',
              '_blank');
        },
      ),
    );
  }

  void _showDemandDetails(
      BuildContext context, Map<String, dynamic> data, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'تفاصيل الطلب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDetailItem('الاسم العائلي', data['nom']),
                        _buildDetailItem('الاسم الشخصي', data['prenom']),
                        _buildDetailItem('الباقة', data['forfait']),
                        _buildDetailItem(
                            'طريقة الدفع',
                            data['paymentMethod'] == 'online'
                                ? 'إلكتروني'
                                : 'يدوي'),
                        _buildDetailItem('الحالة', _getStatusText(status)),
                        if (data['adminMessage'] != null)
                          _buildDetailItem(
                              'رسالة المسؤول', data['adminMessage']),
                        if (status == 'approved' &&
                            data['activationEnd'] != null)
                          _buildDetailItem('صالحة حتى',
                              _formatDate(data['activationEnd'].toDate())),
                        if (data['createdAt'] != null)
                          _buildDetailItem(
                              'تاريخ الطلب',
                              _formatDate(
                                  (data['createdAt'] as Timestamp).toDate())),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Ajout d'un bouton pour voir l'image dans les détails
                if (data['photoUrl'] != null && data['photoUrl'].isNotEmpty && data['paymentMethod'] != 'online') ...[
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.image),
                      label: Text('عرض إثبات الدفع', style: TextStyle(fontFamily: 'Tajawal')),
                      onPressed: () {
                        Navigator.pop(context); // Fermer la boîte de dialogue des détails
                        _showPhotoDialog(context, data['photoUrl']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('إغلاق',
                          style: TextStyle(fontFamily: 'Tajawal')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
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
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
          ),
          Divider(height: 16),
        ],
      ),
    );
  }

  void _showActivationDialog(
    BuildContext context,
    DocumentReference demandRef,
    String userId,
    String forfaitType,
  ) {
    int monthsToAdd = forfaitType == 'ثلاثية' ? 3 : 12;
    _activationEndDate = DateTime.now().add(Duration(days: monthsToAdd * 30));
    _messageController.text = predefinedMessages['approved']!;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'تفعيل الحساب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildDialogInfoRow('نوع الباقة:', forfaitType),
                      _buildDialogInfoRow('المدة:', '$monthsToAdd أشهر'),
                      _buildDialogInfoRow(
                          'تاريخ الانتهاء:', _formatDate(_activationEndDate!)),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'رسالة (اختيارية)',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontFamily: 'Tajawal'),
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
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('إلغاء',
                          style: TextStyle(
                              color: Colors.grey[600], fontFamily: 'Tajawal')),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                      child: Text('تأكيد التفعيل',
                          style: TextStyle(fontFamily: 'Tajawal')),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            style:
                TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Tajawal'),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style:
                TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
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
    setState(() {
      _isLoading = true;
    });

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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processOnlinePayment(
      DocumentReference demandRef, String userId, String forfaitType) async {
    setState(() {
      _isLoading = true;
    });

    int monthsToAdd = forfaitType == 'ثلاثية' ? 3 : 12;
    DateTime activationEndDate =
        DateTime.now().add(Duration(days: monthsToAdd * 30));

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
          content:
              Text('تم تفعيل الحساب حتى ${_formatDate(activationEndDate)}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في معالجة الدفع الإلكتروني: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deactivateAccount(
      DocumentReference demandRef, String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await demandRef.update({
        'status': 'rejected',
        'adminMessage': 'تم تعطيل الحساب من قبل المسؤول',
        'processedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('Users').doc(userId).update({
        'isActive': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تعطيل الحساب بنجاح'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reactivateAccount(
      DocumentReference demandRef, String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await demandRef.update({
        'status': 'approved',
        'adminMessage': 'تم إعادة تفعيل الحساب من قبل المسؤول',
        'processedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('Users').doc(userId).update({
        'isActive': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إعادة تفعيل الحساب بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

void _showPhotoDialog(BuildContext context, String photoUrl) {
  if (photoUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('رابط الصورة غير صالح', style: TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'إثبات الدفع',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Image
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'جاري تحميل الصورة...',
                                    style: TextStyle(fontFamily: 'Tajawal'),
                                  ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image in dialog: $error');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 64),
                                  SizedBox(height: 16),
                                  Text(
                                    'خطأ في تحميل الصورة',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'قد يكون الرابط غير صالح',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      try {
                                        html.window.open(photoUrl, '_blank');
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('لا يمكن فتح الرابط'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: Text('فتح في المتصفح'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Footer
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        icon: Icon(Icons.open_in_browser, size: 18),
                        label: Text('فتح في المتصفح'),
                        onPressed: () {
                          try {
                            html.window.open(photoUrl, '_blank');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('لا يمكن فتح الرابط'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.close, size: 18),
                        label: Text('إغلاق'),
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
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
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.message, color: Colors.blue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'إرسال رسالة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMessageType,
                      items: predefinedMessages.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style:
                                TextStyle(fontSize: 14, fontFamily: 'Tajawal'),
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
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('إلغاء',
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontFamily: 'Tajawal')),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                          child: Text('إرسال',
                              style: TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
    setState(() {
      _isLoading = true;
    });

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
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy - HH:mm').format(date);
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
        return Colors.green.shade50;
      case 'rejected':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
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
        return Colors.green.shade800;
      case 'rejected':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}