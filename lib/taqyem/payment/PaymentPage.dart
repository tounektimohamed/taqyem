import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedForfait;
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  html.File? _photo;
  bool _hasSubmittedForm = false;
  bool _isLoading = false;
  bool _isEditingExistingRequest = false;
  String? _existingPaymentId;
  String? _existingPhotoUrl;
  bool _useOnlinePayment = false;

  final List<Map<String, dynamic>> forfaits = [
    {
      'type': 'ثلاثية',
      'prix': 25,
      'duration': '3 أشهر',
      'icon': Icons.calendar_today
    },
    {
      'type': 'سنوي',
      'prix': 60,
      'duration': '12 شهر',
      'icon': Icons.calendar_today
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkIfFormSubmitted();
  }

  Future<void> _checkIfFormSubmitted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final paymentSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('payments')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (paymentSnapshot.docs.isNotEmpty) {
      final paymentData = paymentSnapshot.docs.first.data();
      setState(() {
        _hasSubmittedForm = true;
        _existingPaymentId = paymentSnapshot.docs.first.id;
        _existingPhotoUrl = paymentData['photoUrl'];
        _useOnlinePayment = paymentData['paymentMethod'] == 'online';
      });
    }
  }

  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        setState(() {
          _photo = file;
          _existingPhotoUrl = null;
        });
      }
    });
  }

  void _validateOnlinePayment() {
    if (selectedForfait == null) {
      _showErrorSnackbar('الرجاء اختيار الباقة المفضلة');
      return;
    }

    if (_nomController.text.isEmpty || _prenomController.text.isEmpty) {
      _showErrorSnackbar('الرجاء إدخال الاسم العائلي والاسم الشخصي');
      return;
    }

    html.window.open('https://gateway.konnect.network/me/taqyem', '_blank');
    _submitPayment();
  }

  Future<void> _submitPayment() async {
    if (selectedForfait == null ||
        _nomController.text.isEmpty ||
        _prenomController.text.isEmpty) {
      _showErrorSnackbar('الرجاء ملء جميع المعطيات واختيار الباقة');
      return;
    }

    if (!_useOnlinePayment && _photo == null && _existingPhotoUrl == null) {
      _showErrorSnackbar('الرجاء إرفاق صورة الحوالة البريدية');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackbar('المستخدم غير مسجل الدخول');
        return;
      }

      final paymentData = {
        'forfait': selectedForfait,
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'adminMessage': null,
        'paymentMethod': _useOnlinePayment ? 'online' : 'manual',
      };

      if (!_useOnlinePayment) {
        if (_photo != null) {
          paymentData['photoUrl'] = await _uploadPhoto(_photo!);
        } else if (_existingPhotoUrl != null) {
          paymentData['photoUrl'] = _existingPhotoUrl;
        }
      }

      if (_isEditingExistingRequest && _existingPaymentId != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('payments')
            .doc(_existingPaymentId)
            .update(paymentData);
      } else {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('payments')
            .add(paymentData);
      }

      setState(() {
        _hasSubmittedForm = true;
        _isEditingExistingRequest = false;
      });

      _showSuccessSnackbar(
          'تم تسجيل طلب الدفع بنجاح! ${_useOnlinePayment ? 'يرجى إتمام الدفع الإلكتروني' : ''}');
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء إرسال الطلب: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _uploadPhoto(html.File photo) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('payments/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putBlob(photo);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('خطأ في تحميل الصورة: $e');
      throw e;
    }
  }

  void _loadExistingRequest(DocumentSnapshot payment) {
    final data = payment.data() as Map<String, dynamic>;
    setState(() {
      _isEditingExistingRequest = true;
      selectedForfait = data['forfait'];
      _nomController.text = data['nom'] ?? '';
      _prenomController.text = data['prenom'] ?? '';
      _existingPhotoUrl = data['photoUrl'];
      _hasSubmittedForm = false;
      _useOnlinePayment = data['paymentMethod'] == 'online';
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحة الدفع', style: TextStyle(fontFamily: 'Tajawal')),
        centerTitle: true,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _hasSubmittedForm
              ? _buildStatusView()
              : _buildPaymentForm(),
        ),
      ),
    );
  }

  Widget _buildStatusView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('payments')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 60,
                  color: Colors.orange,
                ),
                SizedBox(height: 20),
                Text(
                  'طلبك قيد المعالجة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          );
        }

        final payment = snapshot.data!.docs.first;
        final data = payment.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';
        final adminMessage = data['adminMessage'] ?? '';
        final paymentMethod = data['paymentMethod'] ?? 'manual';

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: status == 'approved'
                            ? Colors.green.withOpacity(0.1)
                            : status == 'rejected'
                                ? Colors.red.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                      ),
                      child: Icon(
                        status == 'approved'
                            ? Icons.check_circle
                            : status == 'rejected'
                                ? Icons.error_outline
                                : Icons.access_time,
                        size: 60,
                        color: status == 'approved'
                            ? Colors.green
                            : status == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      status == 'approved'
                          ? 'تم تفعيل حسابك بنجاح'
                          : status == 'rejected'
                              ? 'تم رفض طلبك'
                              : 'طلبك قيد المراجعة',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                        color: status == 'approved'
                            ? Colors.green
                            : status == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'طريقة الدفع: ${paymentMethod == 'online' ? 'إلكتروني' : 'يدوي'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Tajawal',
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16),
                    if (adminMessage.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'رسالة الإدارة:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              adminMessage,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Tajawal',
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: status == 'approved'
                            ? Colors.green.withOpacity(0.05)
                            : status == 'rejected'
                                ? Colors.red.withOpacity(0.05)
                                : Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == 'approved'
                            ? 'يمكنك الآن الاستفادة من جميع ميزات التطبيق'
                            : status == 'rejected'
                                ? 'يرجى مراجعة المعلومات المقدمة وتعديل الطلب'
                                : 'سيتم مراجعة طلبك وإعلامك عند التأكيد',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Tajawal',
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    if (status == 'rejected' && adminMessage.isNotEmpty) ...[
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () => _loadExistingRequest(payment),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.blue[700],
                        ),
                        child: Text(
                          'تعديل الطلب',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      if (_existingPhotoUrl != null && paymentMethod != 'online')
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.network(_existingPhotoUrl!),
                                      SizedBox(height: 16),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('إغلاق'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'عرض إثبات الدفع السابق',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditingExistingRequest)
            Card(
              color: Colors.blue[50],
              margin: EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'أنت تقوم بتعديل طلبك المرفوض. يرجى التحقق من المعلومات وتحديثها قبل إعادة الإرسال.',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'أستاذي',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'يمكنك اختيار باقة ثلاثة أشهر أو باقة سنوية للتمتع بامتيازات التطبيق كاملة.',
                    style: TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'يمكنكم إرسال مبلغ الباقة عن طريق حوالة بريدية أو عن طريق D17 أو الدفع الإلكتروني عبر الرابط التالي.',
                    style: TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
                  ),
                ],
              ),
            ),
          ),
          Text(
            'اختر الباقة المفضلة:',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal'),
          ),
          SizedBox(height: 10),
          Row(
            children: forfaits.map((forfait) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: selectedForfait == forfait['type']
                          ? Colors.blue[50]
                          : Colors.white,
                      border: Border.all(
                        color: selectedForfait == forfait['type']
                            ? Colors.blue
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          selectedForfait = forfait['type'];
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectedForfait == forfait['type']
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                              ),
                              child: Icon(
                                forfait['icon'],
                                size: 30,
                                color: selectedForfait == forfait['type']
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              forfait['type'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Tajawal',
                                color: selectedForfait == forfait['type']
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${forfait['prix']} دينار',
                              style: TextStyle(
                                  color: selectedForfait == forfait['type']
                                      ? Colors.blue
                                      : Colors.blue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal'),
                            ),
                            SizedBox(height: 5),
                            Text(
                              forfait['duration'],
                              style: TextStyle(
                                  fontSize: 14,
                                  color: selectedForfait == forfait['type']
                                      ? Colors.blue
                                      : Colors.grey,
                                  fontFamily: 'Tajawal'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 30),
          Text(
            'طريقة الدفع:',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal'),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _useOnlinePayment = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: !_useOnlinePayment ? Colors.blue[50] : Colors.grey[50],
                      border: Border.all(
                        color: !_useOnlinePayment ? Colors.blue : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.money,
                          color: !_useOnlinePayment ? Colors.blue : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'حوالة بريدية / D17',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: !_useOnlinePayment ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _useOnlinePayment = true;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _useOnlinePayment ? Colors.green[50] : Colors.grey[50],
                      border: Border.all(
                        color: _useOnlinePayment ? Colors.green : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: _useOnlinePayment ? Colors.green : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'دفع إلكتروني',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: _useOnlinePayment ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (_useOnlinePayment) ...[
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'الدفع الإلكتروني عبر Konnect',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                          color: Colors.green[800]),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'سيتم فتح صفحة الدفع الإلكتروني بعد تأكيد المعلومات',
                      style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Tajawal',
                          color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'الرجاء التأكد من صحة المعلومات قبل المتابعة',
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Tajawal',
                          color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
          Text(
            'المعلومات الشخصية:',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal'),
          ),
          SizedBox(height: 15),
          TextField(
            controller: _nomController,
            decoration: InputDecoration(
              labelText: 'الاسم العائلي',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(Icons.person),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            textAlign: TextAlign.right,
          ),
          SizedBox(height: 20),
          TextField(
            controller: _prenomController,
            decoration: InputDecoration(
              labelText: 'الاسم الشخصي',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(Icons.person_outline),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            textAlign: TextAlign.right,
          ),
          SizedBox(height: 20),
          if (!_useOnlinePayment) ...[
            Text(
              'إثبات الدفع:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal'),
            ),
            SizedBox(height: 10),
            Text(
              'يرجى تحميل صورة الحوالة البريدية أو إثبات التحويل:',
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[700], fontFamily: 'Tajawal'),
            ),
            SizedBox(height: 15),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _photo != null || _existingPhotoUrl != null
                    ? Colors.green[50]
                    : Colors.grey[50],
                border: Border.all(
                  color: _photo != null || _existingPhotoUrl != null
                      ? Colors.green
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.upload),
                    label: Text(_photo != null || _existingPhotoUrl != null
                        ? 'تغيير الصورة'
                        : 'تحميل صورة الحوالة البريدية'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _photo != null || _existingPhotoUrl != null
                          ? Colors.green
                          : Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (_photo != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              html.Url.createObjectUrl(_photo!),
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'صورة الحوالة المرفقة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_existingPhotoUrl != null && _photo == null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'تم تحميل صورة سابقة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.network(_existingPhotoUrl!),
                                        SizedBox(height: 16),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('إغلاق'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'عرض الصورة السابقة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 30),
          ],
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: _isLoading
          ? Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.blue),
                      strokeWidth: 5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جاري معالجة طلبك...',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          : ElevatedButton(
              onPressed: _useOnlinePayment ? _validateOnlinePayment : _submitPayment,
              child: Text(
                _isEditingExistingRequest
                    ? 'تحديث الطلب'
                    : _useOnlinePayment
                        ? 'تأكيد ومتابعة الدفع'
                        : 'إرسال الطلب',
                style: TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                    _useOnlinePayment ? Colors.green[700] : Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                shadowColor: (_useOnlinePayment ? Colors.green : Colors.blue)
                    .withOpacity(0.3),
              ),
            ),
    );
  }
}