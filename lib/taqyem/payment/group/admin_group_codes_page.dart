// lib/taqyem/payment/group/admin_group_codes_page.dart
import 'dart:ui' as html;

import 'package:Taqyem/taqyem/payment/group/GroupCodeService.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/route_manager.dart';

class AdminGroupCodesPage extends StatefulWidget {
  @override
  _AdminGroupCodesPageState createState() => _AdminGroupCodesPageState();
}

class _AdminGroupCodesPageState extends State<AdminGroupCodesPage> {
  final GroupCodeService _codeService = GroupCodeService();
  final TextEditingController _schoolController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة أكواد المجموعات',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // قسم إنشاء كود جديد
          Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.green, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'إنشاء كود مجموعة جديد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _schoolController,
                      decoration: InputDecoration(
                        labelText: 'اسم المدرسة',
                        hintText: 'مثال: TOUNEKT',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.school),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generateCode,
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Icon(Icons.qr_code),
                        label: Text(
                          _isLoading ? 'جاري التوليد...' : 'توليد كود جديد',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // قائمة الأكواد
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_codes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'حدث خطأ في تحميل البيانات',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.red,
                          ),
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
                        Icon(Icons.qr_code,
                            color: Colors.grey.shade400, size: 80),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد أكواد بعد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'قم بإنشاء أول كود مجموعة من الأعلى',
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
                    final code = snapshot.data!.docs[index];
                    final data = code.data() as Map<String, dynamic>;
                    
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
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.qr_code,
                                    color: Colors.blue.shade700,
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
                                    color: (data['currentMembers'] ?? 0) >=
                                            (data['maxMembers'] ?? 5)
                                        ? Colors.red.shade50
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${data['currentMembers'] ?? 0}/${data['maxMembers'] ?? 5}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: (data['currentMembers'] ?? 0) >=
                                              (data['maxMembers'] ?? 5)
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'تاريخ الإنشاء:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                      Text(
                                        data['createdAt'] != null
                                            ? _formatDate(
                                                (data['createdAt'] as Timestamp)
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
                                  
                                    // زر تفعيل/تعطيل
                                    Switch(
                                      value: data['isActive'] ?? true,
                                      activeColor: Colors.green,
                                      onChanged: (value) {
                                        _toggleCodeStatus(code.id, value);
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

  // دالة توليد الكود - الآن مع إمكانية الوصول إلى context
  Future<void> _generateCode() async {
    if (_schoolController.text.isEmpty) {
      _showMessage('الرجاء إدخال اسم المدرسة', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final code = await _codeService.generateGroupCode(_schoolController.text);
      _schoolController.clear();
      _showMessage('تم توليد الكود: $code', Colors.green);
    } catch (e) {
      _showMessage('خطأ: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة نسخ النص إلى الحافظة
 

  // دالة تفعيل/تعطيل الكود
  Future<void> _toggleCodeStatus(String codeId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('group_codes')
          .doc(codeId)
          .update({'isActive': newStatus});
      
      _showMessage(
        newStatus ? 'تم تفعيل الكود' : 'تم تعطيل الكود',
        newStatus ? Colors.green : Colors.orange,
      );
    } catch (e) {
      _showMessage('خطأ في تحديث الحالة: $e', Colors.red);
    }
  }

  // دالة عرض الرسائل
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // دالة تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}