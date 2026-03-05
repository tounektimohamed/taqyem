import 'package:Taqyem/taqyem/payment/card_distribution_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker_web/image_picker_web.dart';

class CardManagementPage extends StatefulWidget {
  @override
  _CardManagementPageState createState() => _CardManagementPageState();
}

class _CardManagementPageState extends State<CardManagementPage> with WidgetsBindingObserver {
  final CardDistributionService _cardService = CardDistributionService();
  final List<String> _cardIds = ['A', 'B', 'C'];
  final Map<String, TextEditingController> _qrControllers = {};
  final Map<String, TextEditingController> _ribControllers = {};
  final Map<String, TextEditingController> _bankControllers = {};
  final Map<String, Uint8List?> _qrImages = {};
  final Map<String, String?> _qrImageNames = {};
  bool _isLoading = false;
  String? _selectedCardForPreview;
  final Map<String, bool> _isUploading = {};
  
  // Pour gérer l'état du widget
  bool _mounted = true;
  
  // File d'attente pour les messages
  final List<Map<String, dynamic>> _messageQueue = [];
  bool _isShowingMessage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mounted = true;
    _initializeControllers();
    _loadCardsData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _mounted = false;
    } else if (state == AppLifecycleState.resumed) {
      _mounted = true;
    }
  }

  void _initializeControllers() {
    for (var cardId in _cardIds) {
      _qrControllers[cardId] = TextEditingController();
      _ribControllers[cardId] = TextEditingController();
      _bankControllers[cardId] = TextEditingController();
      _isUploading[cardId] = false;
    }
  }

  Future<void> _loadCardsData() async {
    if (!_mounted) return;
    setState(() => _isLoading = true);
    
    for (var cardId in _cardIds) {
      try {
        final details = await _cardService.getCardDetails(cardId);
        if (!_mounted) return;
        if (details != null) {
          print('Loading card $cardId: $details'); // Debug
          
          // Charger le RIB et le nom de la banque
          _ribControllers[cardId]?.text = details['ribNumber'] ?? '';
          _bankControllers[cardId]?.text = details['bankName'] ?? '';
          
          // Charger l'image QR Code si elle existe
          final qrCodeUrl = details['qrCodeUrl'] ?? '';
          if (qrCodeUrl.isNotEmpty) {
            if (qrCodeUrl.startsWith('data:image')) {
              // C'est une image base64
              try {
                // Extraire la partie base64
                final base64Data = qrCodeUrl.split(',').last;
                final decodedBytes = base64.decode(base64Data);
                setState(() {
                  _qrImages[cardId] = decodedBytes;
                  _qrImageNames[cardId] = 'صورة محفوظة';
                });
                print('Loaded base64 image for card $cardId');
              } catch (e) {
                print('Error decoding base64 for card $cardId: $e');
                _qrControllers[cardId]?.text = qrCodeUrl;
              }
            } else {
              // C'est une URL normale
              _qrControllers[cardId]?.text = qrCodeUrl;
            }
          }
        }
      } catch (e) {
        print('Error loading card $cardId: $e');
      }
    }
    
    if (!_mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _pickQRImage(String cardId) async {
    try {
      if (!_mounted) return;
      setState(() {
        _isUploading[cardId] = true;
      });

      final MediaInfo? mediaInfo = await ImagePickerWeb.getImageInfo();
      
      if (!_mounted) return;
      
      if (mediaInfo != null) {
        final Uint8List? imageData = mediaInfo.data;
        final String fileName = mediaInfo.fileName ?? 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
        
        if (imageData != null) {
          if (!_mounted) return;
          setState(() {
            _qrImages[cardId] = imageData;
            _qrImageNames[cardId] = fileName;
          });
          
          _queueMessage('تم اختيار صورة QR Code بنجاح', Colors.green);
        }
      }
    } catch (e) {
      _queueMessage('خطأ في اختيار الصورة: ${e.toString()}', Colors.red);
    } finally {
      if (!_mounted) return;
      setState(() {
        _isUploading[cardId] = false;
      });
    }
  }

  Future<void> _saveCard(String cardId) async {
    final rib = _ribControllers[cardId]?.text.trim() ?? '';
    final bank = _bankControllers[cardId]?.text.trim() ?? '';
    final qrImage = _qrImages[cardId];

    if (rib.isEmpty) {
      _queueMessage('الرجاء إدخال رقم RIB', Colors.red);
      return;
    }

    if (qrImage == null) {
      _queueMessage('الرجاء اختيار صورة QR Code', Colors.red);
      return;
    }

    if (!_mounted) return;
    setState(() => _isUploading[cardId] = true);

    try {
      // Convertir l'image en base64 pour Firestore
      final base64String = base64.encode(qrImage);
      final qrCodeUrl = 'data:image/png;base64,$base64String';
      
      print('Saving card $cardId with QR data length: ${qrCodeUrl.length}');
      
      // Sauvegarder dans Firestore via le service
      final success = await _cardService.updateCardDetails(
        cardId,
        qrCodeUrl: qrCodeUrl,
        ribNumber: rib,
        bankName: bank,
      );

      if (!_mounted) return;

      if (success) {
        _queueMessage('تم حفظ معلومات البطاقة $cardId بنجاح', Colors.green);
        
        // Mettre à jour l'affichage
        setState(() {
          _qrImageNames[cardId] = '${_qrImageNames[cardId]} (محفوظة)';
        });
      } else {
        _queueMessage('حدث خطأ في حفظ المعلومات', Colors.red);
      }
    } catch (e) {
      if (!_mounted) return;
      print('Error saving card $cardId: $e');
      _queueMessage('خطأ: ${e.toString()}', Colors.red);
    } finally {
      if (!_mounted) return;
      setState(() {
        _isUploading[cardId] = false;
      });
    }
  }

  // Système de file d'attente pour les messages
  void _queueMessage(String message, Color color) {
    if (!_mounted) {
      print('Widget not mounted, message ignored: $message');
      return;
    }
    
    _messageQueue.add({
      'message': message,
      'color': color,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    if (!_isShowingMessage) {
      _showNextMessage();
    }
  }

  void _showNextMessage() {
    if (!_mounted || _messageQueue.isEmpty) {
      _isShowingMessage = false;
      return;
    }

    _isShowingMessage = true;
    final messageData = _messageQueue.removeAt(0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          messageData['message'],
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: messageData['color'],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    ).closed.then((_) {
      if (_mounted) {
        _showNextMessage();
      }
    });
  }

  void _showQRCodePreview(String cardId) {
    if (!_mounted) return;
    
    final qrImage = _qrImages[cardId];

    if (qrImage == null) {
      _queueMessage('لا يوجد QR Code لهذه البطاقة', Colors.orange);
      return;
    }

    setState(() => _selectedCardForPreview = cardId);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
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
                    'معاينة QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      color: _getCardColor(cardId),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
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
                child: Image.memory(
                  qrImage,
                  height: 250,
                  width: 250,
                  fit: BoxFit.contain,
                ),
              ),
              
              SizedBox(height: 20),
              
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCardColor(cardId).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getCardName(cardId),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

  void _showInstructionsDialog() {
    if (!_mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text(
              'كيفية إضافة QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionItem(
                Icons.camera_alt,
                'اضغط على أيقونة الكاميرا لاختيار صورة QR Code',
              ),
              Divider(),
              _buildInstructionItem(
                Icons.image,
                'اختر صورة واضحة بصيغة PNG أو JPG',
              ),
              Divider(),
              _buildInstructionItem(
                Icons.preview,
                'معاينة الصورة قبل الحفظ',
              ),
              Divider(),
              _buildInstructionItem(
                Icons.save,
                'احفظ المعلومات بعد اختيار الصورة - سيتم حفظها في قاعدة البيانات',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'فهمت',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'إدارة البطاقات',
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
            icon: Icon(Icons.info_outline),
            onPressed: _showInstructionsDialog,
            tooltip: 'تعليمات',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCardsData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جاري تحميل البيانات...',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _cardIds.length,
              itemBuilder: (context, index) {
                final cardId = _cardIds[index];
                return _buildCardForm(cardId);
              },
            ),
    );
  }

  Widget _buildCardForm(String cardId) {
    final qrImage = _qrImages[cardId];
    final qrImageName = _qrImageNames[cardId];
    final isUploading = _isUploading[cardId] ?? false;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCardColor(cardId),
                        _getCardColor(cardId).withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      cardId,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
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
                        _getCardName(cardId),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      if (qrImage != null)
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '✅ صورة QR Code ${qrImageName?.contains('محفوظة') == true ? 'محفوظة' : 'مختارة'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade800,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: qrImage != null ? Colors.green.shade300 : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  if (qrImage != null)
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        image: DecorationImage(
                          image: MemoryImage(qrImage),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: isUploading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(Icons.camera_alt),
                            label: Text(
                              qrImage != null ? 'تغيير الصورة' : 'اختيار صورة QR Code',
                              style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getCardColor(cardId),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: isUploading ? null : () => _pickQRImage(cardId),
                          ),
                        ),
                        if (qrImage != null) ...[
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: _getCardColor(cardId).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.remove_red_eye, color: _getCardColor(cardId)),
                              onPressed: () => _showQRCodePreview(cardId),
                              tooltip: 'معاينة',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  if (qrImageName != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 16, left: 16, right: 16),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.image, size: 14, color: Colors.grey.shade700),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                qrImageName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade800,
                                  fontFamily: 'Tajawal',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 16),

            Text(
              'رقم RIB:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _ribControllers[cardId],
              decoration: InputDecoration(
                hintText: 'XX 00000 0000000000 00',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 16),

            Text(
              'اسم البنك (اختياري):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _bankControllers[cardId],
              decoration: InputDecoration(
                hintText: 'البنك التونسي',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                icon: isUploading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.save),
                label: Text(
                  'حفظ في قاعدة البيانات',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCardColor(cardId),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (isUploading || _isUploading[cardId] == true) ? null : () => _saveCard(cardId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor(String cardId) {
    switch (cardId) {
      case 'A': return Colors.blue;
      case 'B': return Colors.green;
      case 'C': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getCardName(String cardId) {
    switch (cardId) {
      case 'A': return 'البطاقة الأولى';
      case 'B': return 'البطاقة الثانية';
      case 'C': return 'البطاقة الثالثة';
      default: return 'بطاقة $cardId';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mounted = false;
    _messageQueue.clear();
    for (var controller in _qrControllers.values) {
      controller.dispose();
    }
    for (var controller in _ribControllers.values) {
      controller.dispose();
    }
    for (var controller in _bankControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}