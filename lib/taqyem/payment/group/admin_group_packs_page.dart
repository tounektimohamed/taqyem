// lib/taqyem/payment/group/admin_group_packs_page.dart
import 'package:Taqyem/taqyem/payment/group/group_pack_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminGroupPacksPage extends StatefulWidget {
  @override
  _AdminGroupPacksPageState createState() => _AdminGroupPacksPageState();
}

class _AdminGroupPacksPageState extends State<AdminGroupPacksPage> {
  final GroupPackService _packService = GroupPackService();
  final TextEditingController _schoolController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'باقات المجموعات (110 DT)',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Stats Card
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('group_packs')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox.shrink();
              }

              final totalPacks = snapshot.data!.docs.length;
              final activePacks = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isActive'] == true;
              }).length;
              final totalMembers = snapshot.data!.docs.fold<int>(0, (sum, doc) {
                final data = doc.data() as Map<String, dynamic>;
                return sum + (data['currentMembers'] as int? ?? 1);
              });

              return Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade50, Colors.purple.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'إجمالي الباقات',
                      totalPacks.toString(),
                      Icons.card_giftcard,
                      Colors.purple,
                    ),
                    _buildStatItem(
                      'باقات نشطة',
                      activePacks.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatItem(
                      'إجمالي المستخدمين',
                      totalMembers.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ],
                ),
              );
            },
          ),

          // Liste des packs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_packs')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off,
                            color: Colors.grey.shade400, size: 80),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد باقات مجموعات بعد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'عند تفعيل طلب pack groupe، سيظهر هنا',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final pack = snapshot.data!.docs[index];
                    final data = pack.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête avec code
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.group,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['code'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Tajawal',
                                          letterSpacing: 1,
                                          color: Colors.purple.shade800,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'المدرسة: ${data['school'] ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (data['currentMembers'] ?? 1) >=
                                            (data['maxMembers'] ?? 6)
                                        ? Colors.red.shade50
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${data['currentMembers'] ?? 1}/${data['maxMembers'] ?? 6}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: (data['currentMembers'] ?? 1) >=
                                              (data['maxMembers'] ?? 6)
                                          ? Colors.red
                                          : Colors.green,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 12),
                            Divider(height: 1),
                            SizedBox(height: 12),

                            // Informations du créateur
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'المنشئ: ${data['createdByName'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            if (data['createdByWhatsapp'] != null) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'واتساب: ${data['createdByWhatsapp']}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            SizedBox(height: 8),

                            // Liste des membres
                            if (data['memberNames'] != null && 
                                (data['memberNames'] as List).length > 1) ...[
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الأعضاء:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    ...(data['memberNames'] as List).map((name) {
                                      return Padding(
                                        padding: EdgeInsets.only(right: 8, bottom: 2),
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_outline,
                                                size: 12, color: Colors.grey),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '• $name',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'Tajawal',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ],

                            SizedBox(height: 12),

                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تاريخ التفعيل:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                      Text(
                                        data['activatedAt'] != null
                                            ? _formatDate(
                                                (data['activatedAt'] as Timestamp)
                                                    .toDate())
                                            : 'غير معروف',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    // زر نسخ الكود
                                    IconButton(
                                      icon: Icon(Icons.copy,
                                          color: Colors.blue, size: 20),
                                      onPressed: () {
                                        _copyToClipboard(data['code']);
                                      },
                                      tooltip: 'نسخ الكود',
                                    ),
                                    // زر تفعيل/تعطيل
                                    Switch(
                                      value: data['isActive'] ?? true,
                                      activeColor: Colors.green,
                                      onChanged: (value) {
                                        _togglePackStatus(pack.id, value);
                                      },
                                    ),
                                  ],
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Tajawal',
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    // import 'dart:html' as html;
    // html.window.navigator.clipboard?.writeText(text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ الكود: $text'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _togglePackStatus(String packId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('group_packs')
          .doc(packId)
          .update({'isActive': newStatus});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? 'تم تفعيل الباقة' : 'تم تعطيل الباقة',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}