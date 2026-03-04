import 'dart:html' as html;
import 'package:Taqyem/taqyem/payment/card_distribution_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedForfait;
  String? _base64Image; // Nouvelle variable pour stocker l'image en base64

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _whatsappController =
      TextEditingController(); // جديد: حقل الواتساب
  html.File? _photo;
  bool _hasSubmittedForm = false;
  bool _isLoading = false;
  bool _isEditingExistingRequest = false;
  String? _existingPaymentId;
  String? _existingPhotoUrl;
  bool _useOnlinePayment = false;
  final CardDistributionService _cardService = CardDistributionService();
  bool _canSubscribe = true;
  String? _selectedCardId;
  Map<String, dynamic> _cardStats = {};

  // رقم الواتساب المستهدف (رقمك)
  final String _adminWhatsAppNumber = '99237770';

  // Détails de la carte sélectionnée automatiquement
  Map<String, dynamic>? _selectedCardDetails;

  final List<Map<String, dynamic>> forfaits = [
    {
      'type': 'ثلاثية',
      'prix': 40,
      'duration': '3 أشهر',
      'icon': Icons.calendar_today
    },
    {
      'type': 'سنوي',
      'prix': 70,
      'duration': '12 شهر',
      'icon': Icons.calendar_today
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkIfFormSubmitted();
    _checkSubscriptionAvailability();
    _selectBestCard();
  }

  Future<void> _selectBestCard() async {
    try {
      final bestCardId = await _cardService.selectBestCard();
      print('Meilleure carte sélectionnée: $bestCardId');

      if (bestCardId != null) {
        await _ensureCardDocument(bestCardId);
        final details = await _cardService.getCardDetails(bestCardId);
        print('Détails de la carte: $details');

        setState(() {
          _selectedCardId = bestCardId;
          _selectedCardDetails = details;
        });

        if (details == null) {
          print('⚠️ Détails de la carte manquants');
          _showErrorSnackbar('خطأ في تحميل معلومات البطاقة');
        } else if (details['qrCodeUrl'] == null || details['qrCodeUrl'] == '') {
          print('⚠️ QR Code manquant pour la carte $bestCardId');
          _showErrorSnackbar('البطاقة المختارة لا تحتوي على QR Code');
        }
      } else {
        print('❌ Aucune carte disponible');
        setState(() {
          _selectedCardId = null;
          _selectedCardDetails = null;
        });
        _showErrorSnackbar('عذراً، لا توجد بطاقات متاحة حالياً');
      }
    } catch (e) {
      print('❌ Erreur lors de la sélection de la carte: $e');
      _showErrorSnackbar('حدث خطأ في اختيار البطاقة');
    }
  }

  Future<void> _ensureCardDocument(String cardId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('cards')
          .doc(cardId)
          .get();

      if (!doc.exists) {
        print('📝 Création du document pour la carte $cardId...');
        await FirebaseFirestore.instance.collection('cards').doc(cardId).set({
          'id': cardId,
          'qrCodeUrl': '',
          'ribNumber': '',
          'bankName': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification du document: $e');
    }
  }

  // دالة جديدة لرفع الصورة إلى Firebase Storage
  Future<String> _uploadImageToStorage(html.File imageFile) async {
    try {
      final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child('payment_proofs/$fileName');
      await storageRef.putBlob(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      throw Exception('فشل رفع الصورة: $e');
    }
  }

  // دالة جديدة لحفظ البيانات في Firebase Firestore
  Future<void> _savePaymentDataToFirestore({
    required String nom,
    required String prenom,
    required String whatsapp,
    required String forfait,
    required String imageUrl,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      final paymentData = {
        'nom': nom,
        'prenom': prenom,
        'whatsapp': whatsapp,
        'forfait': forfait,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userEmail': user.email,
        'status': 'pending',
        'selectedCard': _selectedCardId,
      };

      await FirebaseFirestore.instance.collection('payments').add(paymentData);

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('payments')
          .add(paymentData);

      print('✅ تم حفظ البيانات بنجاح في Firestore');
    } catch (e) {
      print('❌ خطأ في حفظ البيانات: $e');
      throw Exception('فشل حفظ البيانات: $e');
    }
  }

  // دالة جديدة لفتح WhatsApp برسالة جاهزة
  Future<void> _openWhatsAppWithMessage({
    required String nom,
    required String prenom,
    required String whatsapp,
    required String imageUrl,
    required String forfait,
  }) async {
    try {
      String message = '''
مرحباً، أود تأكيد طلب الاشتراك:

👤 الاسم: $nom
👥 اللقب: $prenom
📱 رقم الواتساب: $whatsapp
📦 الباقة: $forfait
🖼️ رابط صورة الإثبات: $imageUrl

يرجى تأكيد الطلب. شكراً
''';

      String encodedMessage = Uri.encodeFull(message);
      String targetPhoneNumber = _adminWhatsAppNumber;
      String whatsappUrl =
          'https://wa.me/216$targetPhoneNumber?text=$encodedMessage';

      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
        print('✅ تم فتح WhatsApp بنجاح مع الرقم 216$targetPhoneNumber');
      } else {
        String webWhatsappUrl =
            'https://web.whatsapp.com/send?phone=216$targetPhoneNumber&text=$encodedMessage';
        if (await canLaunch(webWhatsappUrl)) {
          await launch(webWhatsappUrl);
        } else {
          throw Exception('لا يمكن فتح WhatsApp');
        }
      }
    } catch (e) {
      print('❌ خطأ في فتح WhatsApp: $e');
      throw Exception('فشل فتح WhatsApp: $e');
    }
  }

  // الدالة الجديدة للتعامل مع إرسال الواتساب
  Future<void> _handleWhatsAppSubmit() async {
    if (selectedForfait == null) {
      _showErrorSnackbar('الرجاء اختيار الباقة');
      return;
    }

    if (_nomController.text.isEmpty) {
      _showErrorSnackbar('الرجاء إدخال الاسم');
      return;
    }

    if (_prenomController.text.isEmpty) {
      _showErrorSnackbar('الرجاء إدخال اللقب');
      return;
    }

    if (_whatsappController.text.isEmpty) {
      _showErrorSnackbar('الرجاء إدخال رقم الواتساب الخاص بك');
      return;
    }

    if (_photo == null && _existingPhotoUrl == null) {
      _showErrorSnackbar('الرجاء إرفاق صورة الإثبات');
      return;
    }

    if (_selectedCardId == null) {
      _showErrorSnackbar('عذراً، لا توجد بطاقات متاحة حالياً');
      return;
    }

    if (!_canSubscribe) {
      _showErrorSnackbar('عذراً، تم بلوغ الحد الأقصى للاشتراكات اليوم');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl;
      if (_photo != null) {
        imageUrl = await _uploadImageToStorage(_photo!);
      } else {
        imageUrl = _existingPhotoUrl!;
      }

      String whatsappNumber = _whatsappController.text.trim();
      whatsappNumber = whatsappNumber.replaceAll(' ', '');
      if (!whatsappNumber.startsWith('+')) {
        if (whatsappNumber.startsWith('0')) {
          whatsappNumber = '+216${whatsappNumber.substring(1)}';
        } else {
          whatsappNumber = '+216$whatsappNumber';
        }
      }

      await _savePaymentDataToFirestore(
        nom: _nomController.text,
        prenom: _prenomController.text,
        whatsapp: whatsappNumber,
        forfait: selectedForfait!,
        imageUrl: imageUrl,
      );

      await _cardService.updateCardStats(_selectedCardId!);

      await _openWhatsAppWithMessage(
        nom: _nomController.text,
        prenom: _prenomController.text,
        whatsapp: whatsappNumber,
        imageUrl: imageUrl,
        forfait: selectedForfait!,
      );

      setState(() {
        _hasSubmittedForm = true;
        _isEditingExistingRequest = false;
      });

      _showSuccessSnackbar('تم إرسال طلبك بنجاح عبر WhatsApp');
    } catch (e) {
      _showErrorSnackbar('حدث خطأ: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFullQRCode(String qrUrl, String cardId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QR Code البطاقة $cardId',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      color: _getCardColor(cardId),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildQRImage(qrUrl, cardId, height: 250, width: 250),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCardColor(cardId).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'امسح الرمز للدفع',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                    color: _getCardColor(cardId),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRImage(String qrUrl, String cardId,
      {double height = 100, double width = 100}) {
    if (qrUrl.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code, size: 40, color: Colors.grey.shade400),
              SizedBox(height: 8),
              Text(
                'QR غير متوفر',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (qrUrl.startsWith('data:image')) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64.decode(qrUrl.split(',').last),
            height: height,
            width: width,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Erreur décodage base64: $error');
              return Container(
                height: height,
                width: width,
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          ),
        );
      } catch (e) {
        print('Error decoding base64: $e');
        return Container(
          height: height,
          width: width,
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(Icons.error, color: Colors.red),
          ),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        qrUrl,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Erreur chargement image: $error');
          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade200,
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        },
      ),
    );
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

  String _getCardName(String cardId) {
    switch (cardId) {
      case 'A':
        return 'البطاقة الأولى';
      case 'B':
        return 'البطاقة الثانية';
      case 'C':
        return 'البطاقة الثالثة';
      default:
        return 'بطاقة $cardId';
    }
  }

  Future<void> _checkSubscriptionAvailability() async {
    final canSubscribe = await _cardService.canSubscribeToday();
    final stats = await _cardService.getDetailedStats();

    setState(() {
      _canSubscribe = canSubscribe;
      _cardStats = stats;
    });

    if (!canSubscribe) {
      _showErrorSnackbar(
          'عذراً، تم بلوغ الحد الأقصى للاشتراكات اليوم (42 مشترك). الرجاء المحاولة غداً.');
    }
  }

  Future<void> _submitPayment() async {
    final selectedCard = await _cardService.selectBestCard();
    if (selectedCard == null) {
      _showErrorSnackbar(
          'عذراً، لا توجد بطاقات متاحة حالياً. الرجاء المحاولة غداً.');
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _selectedCardId = selectedCard;
    });

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

    if (!_canSubscribe) {
      _showErrorSnackbar('عذراً، تم بلوغ الحد الأقصى للاشتراكات اليوم');
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

      await _cardService.updateCardStats(selectedCard);

      final paymentData = {
        'forfait': selectedForfait,
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'whatsapp': _whatsappController.text, // إضافة رقم الواتساب
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'adminMessage': null,
        'paymentMethod': _useOnlinePayment ? 'online' : 'manual',
        'selectedCard': selectedCard,
        'cardAssignedAt': FieldValue.serverTimestamp(),
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

  Widget _buildCardStats() {
    if (_cardStats.isEmpty) return SizedBox.shrink();

    final cards = _cardStats['cards'] as List;
    final totalToday = _cardStats['totalToday'];
    final maxDaily = _cardStats['maxDaily'];

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade700),
              SizedBox(width: 8),
              Text(
                'حالة البطاقات اليوم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...cards.map((card) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
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
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${card['name']}: ${card['count']}/${card['limit']}',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: card['remaining'] > 0
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'متبقي ${card['remaining']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: card['remaining'] > 0
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إجمالي اليوم:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
              ),
              Text(
                '$totalToday / $maxDaily',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: totalToday >= maxDaily ? Colors.red : Colors.green,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          if (_canSubscribe)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '✅ يمكنك الاشتراك اليوم',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontFamily: 'Tajawal',
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '❌ تم بلوغ الحد الأقصى اليومي',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
        ],
      ),
    );
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
        if (paymentData['whatsapp'] != null) {
          _whatsappController.text = paymentData['whatsapp'];
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
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

    if (selectedForfait == 'ثلاثية') {
      html.window.open('https://knct.me/Kpli6qsCL', '_blank');
    } else if (selectedForfait == 'سنوي') {
      html.window.open('https://knct.me/lPHexB7Ju5', '_blank');
    }

    _submitPayment();
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
      _whatsappController.text = data['whatsapp'] ?? ''; // استعادة رقم الواتساب
      _existingPhotoUrl = data['photoUrl'];
      _hasSubmittedForm = false;
      _useOnlinePayment = data['paymentMethod'] == 'online';
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'Tajawal')),
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
        content: Text(message, style: TextStyle(fontFamily: 'Tajawal')),
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
          child: _hasSubmittedForm ? _buildStatusView() : _buildPaymentForm(),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                      if (_existingPhotoUrl != null &&
                          paymentMethod != 'online')
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
                        'أنت بصدد تعديل طلبك الذي سبق رفضه. يرجى مراجعة المعلومات المدخلة وتحديثها قبل إعادة الإرسال.',
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
                        'مرحباً أستاذي الفاضل',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'يمكنك الاشتراك بإحدى الباقتين المتاحتين (ثلاثية أو سنوية) للاستفادة من جميع خدمات التطبيق.',
                    style: TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'طرق الدفع المتاحة: إما عبر الحوالة البريدية أو D17 (مع إرفاق صورة الإثبات)، أو عبر الدفع الإلكتروني المباشر.',
                    style: TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          Text(
            'اختر الباقة المناسبة لك:',
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
            'اختر طريقة الدفع:',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal'),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _useOnlinePayment = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: !_useOnlinePayment
                          ? Colors.blue[50]
                          : Colors.grey[50],
                      border: Border.all(
                        color: !_useOnlinePayment
                            ? Colors.blue
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.money,
                            color:
                                !_useOnlinePayment ? Colors.blue : Colors.grey,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'تحويل بنكي / حوالة بريدية / D17',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Tajawal',
                              color: !_useOnlinePayment
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _useOnlinePayment = true;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _useOnlinePayment
                          ? Colors.green[50]
                          : Colors.grey[50],
                      border: Border.all(
                        color: _useOnlinePayment
                            ? Colors.green
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card,
                            color:
                                _useOnlinePayment ? Colors.green : Colors.grey,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'دفع إلكتروني (Konnect)',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: _useOnlinePayment
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          if (!_useOnlinePayment && _selectedCardDetails != null) ...[
            Card(
              color: Colors.blue.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'طريقة الدفع عبر D17',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'يرجى اتباع الخطوات التالية لإتمام عملية الاشتراك:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Tajawal',
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildStepItem('1', 'افتح تطبيق D17 على هاتفك.',
                              Icons.phone_android),
                          _buildStepItem(
                              '2', 'اختر "الدفع عبر QR".', Icons.qr_code),
                          _buildStepItem(
                              '3',
                              'قم بمسح رمز الـ QR المعروض أدناه.',
                              Icons.qr_code_scanner),
                          _buildStepItem(
                              '4',
                              'أدخل مبلغ الاشتراك: ${selectedForfait == 'ثلاثية' ? '40' : selectedForfait == 'سنوي' ? '70' : '...'} دينار',
                              Icons.attach_money),
                          _buildStepItem(
                              '5', 'أكد عملية التحويل.', Icons.check_circle),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.blue.shade200, width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'رمز QR للدفع عبر D17',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: 12),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                if (_selectedCardDetails != null &&
                                    _selectedCardDetails!['qrCodeUrl'] !=
                                        null) {
                                  _showFullQRCode(
                                      _selectedCardDetails!['qrCodeUrl'],
                                      _selectedCardId!);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _buildQRImage(
                                  _selectedCardDetails!['qrCodeUrl'] ?? '',
                                  _selectedCardId!,
                                  height: 180,
                                  width: 180,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'امسح الرمز باستخدام تطبيق D17',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Tajawal',
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedCardDetails!['ribNumber'] != null) ...[
                            SizedBox(height: 16),
                            Divider(),
                            SizedBox(height: 8),
                            Text(
                              'معلومات التحويل البنكي:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                                color: Colors.blue.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      _selectedCardDetails!['ribNumber'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.copy, size: 20),
                                    onPressed: () {
                                      html.window.navigator.clipboard
                                          ?.writeText(_selectedCardDetails![
                                              'ribNumber']);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('تم نسخ رقم RIB',
                                              style: TextStyle(
                                                  fontFamily: 'Tajawal')),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.amber.shade800),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'بعد إتمام عملية الدفع، يرجى تحميل صورة الإثبات في الأسفل لإكمال طلب الاشتراك.',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Tajawal',
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],

          if (_useOnlinePayment) ...[
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'الدفع الإلكتروني عبر بوابة Konnect',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                          color: Colors.green[800]),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'بعد تأكيد معلوماتك، سيتم توجيهك إلى صفحة الدفع الآمنة لإتمام العملية.',
                      style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Tajawal',
                          color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'تأكد من صحة جميع البيانات قبل المتابعة إلى الدفع.',
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
            'البيانات الشخصية:',
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
              hintText: 'مثال: أحمد',
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
              hintText: 'مثال: محمد',
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

          // حقل رقم الواتساب الجديد
          TextField(
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'رقم الواتساب الخاص بك',
              hintText: 'مثال: 50123456',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(Icons.phone_android),
              suffixIcon: Icon(Icons.message, color: Colors.green),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            textAlign: TextAlign.right,
          ),
          SizedBox(height: 20),

          if (!_useOnlinePayment) ...[
            Text(
              'إرفاق إثبات الدفع:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal'),
            ),
            SizedBox(height: 10),
            Text(
              'يرجى تحميل صورة واضحة للحوالة البريدية أو إيصال التحويل البنكي أو صورة من تطبيق D17:',
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
                        ? 'تغيير صورة الإثبات'
                        : 'اختيار صورة الإثبات'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          _photo != null || _existingPhotoUrl != null
                              ? const Color.fromARGB(255, 204, 191, 16)
                              : const Color.fromARGB(255, 248, 248, 248),
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
                            'صورة الإثبات المرفقة',
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
                            'يوجد صورة إثبات مرفوعة سابقاً',
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
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('إغلاق'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'معاينة الصورة السابقة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: const Color.fromARGB(255, 101, 165, 144),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // الزر الجديد للواتساب (يظهر فقط للدفع اليدوي)
            _buildWhatsAppButton(),
            SizedBox(height: 15),
          ],

          _buildSubmitButton(),
        ],
      ),
    );
  }

  // دالة مساعدة لبناء خطوات التعليمات
  Widget _buildStepItem(String number, String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.shade300],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Tajawal',
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Icon(icon, color: Colors.blue.shade400, size: 20),
        ],
      ),
    );
  }

  // الزر الجديد للواتساب
  Widget _buildWhatsAppButton() {
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
                      valueColor: AlwaysStoppedAnimation(Colors.green),
                      strokeWidth: 5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جاري تجهيز طلبك...',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          : ElevatedButton.icon(
              onPressed: _handleWhatsAppSubmit,
              icon: Icon(Icons.phone,
                  size: 24, color: const Color.fromARGB(255, 116, 235, 5)),
              label: Text(
                'تأكيد وإرسال عبر واتساب',
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                minimumSize: Size(double.infinity, 50),
              ),
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
              onPressed:
                  _useOnlinePayment ? _validateOnlinePayment : _submitPayment,
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
