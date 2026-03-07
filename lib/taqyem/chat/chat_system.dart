// lib/taqyem/chat/chat_system.dart

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatSystem {
  static const String adminId = 'ADMIN';
  static const String adminCollection = 'admin_conversations';
  static const String usersCollection = 'user_conversations';
  
  // Créer ou récupérer une conversation
  static Future<String> getOrCreateConversation(String userId) async {
    final conversationId = 'user_$userId';
    final conversationRef = FirebaseFirestore.instance
        .collection(adminCollection)
        .doc(conversationId);
    
    final doc = await conversationRef.get();
    
    if (!doc.exists) {
      // Créer une nouvelle conversation
      await conversationRef.set({
        'userId': userId,
        'userName': await _getUserName(userId),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'unreadCount': 0,
        'lastMessageType': 'text',
      });
      
      // Ajouter un message système
      await _addSystemMessage(conversationId, 'بدأت المحادثة');
    }
    
    return conversationId;
  }
  
  // Récupérer le nom de l'utilisateur
  static Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return userDoc['name'] ?? 'مستخدم';
      }
    } catch (e) {
      print('Erreur lors de la récupération du nom: $e');
    }
    return 'مستخدم';
  }
  
  // Ajouter un message système
  static Future<void> _addSystemMessage(String conversationId, String content) async {
    await FirebaseFirestore.instance
        .collection(adminCollection)
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderId': 'system',
      'senderName': 'النظام',
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'system',
      'messageType': 'system',
    });
  }
  
  // Envoyer un message texte
  static Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;
    
    final batch = FirebaseFirestore.instance.batch();
    
    final messageRef = FirebaseFirestore.instance
        .collection(adminCollection)
        .doc(conversationId)
        .collection('messages')
        .doc();
    
    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'type': senderId == FirebaseAuth.instance.currentUser?.uid ? 'user' : 'admin',
      'messageType': 'text',
      'read': false,
    });
    
    final conversationRef = FirebaseFirestore.instance
        .collection(adminCollection)
        .doc(conversationId);
    
    batch.update(conversationRef, {
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
      'lastMessageType': 'text',
    });
    
    await batch.commit();
  }
  
  // Envoyer une image en base64
  static Future<void> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String base64Image,
    String? caption,
  }) async {
    if (base64Image.isEmpty) return;
    
    final batch = FirebaseFirestore.instance.batch();
    
    final messageRef = FirebaseFirestore.instance
        .collection(adminCollection)
        .doc(conversationId)
        .collection('messages')
        .doc();
    
    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'imageBase64': base64Image,
      'caption': caption,
      'timestamp': FieldValue.serverTimestamp(),
      'type': senderId == FirebaseAuth.instance.currentUser?.uid ? 'user' : 'admin',
      'messageType': 'image',
      'read': false,
    });
    
    final conversationRef = FirebaseFirestore.instance
        .collection(adminCollection)
        .doc(conversationId);
    
    final lastMessageText = caption ?? '🖼️ صورة';
    
    batch.update(conversationRef, {
      'lastMessage': lastMessageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
      'lastMessageType': 'image',
    });
    
    await batch.commit();
  }
  
  // Marquer les messages comme lus
  static Future<void> markMessagesAsRead(String conversationId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final messagesRef = FirebaseFirestore.instance
        .collection(adminCollection)
        .doc(conversationId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUser.uid);
    
    final snapshot = await messagesRef.get();
    
    if (snapshot.docs.isEmpty) return;
    
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    
    final conversationRef = FirebaseFirestore.instance
        .collection(adminCollection)
        .doc(conversationId);
    
    batch.update(conversationRef, {'unreadCount': 0});
    
    await batch.commit();
  }
  
  // Stream des messages
  static Stream<QuerySnapshot> getMessagesStream(String conversationId) {
    return FirebaseFirestore.instance
        .collection(adminCollection)
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // Stream du compteur de messages non lus
  static Stream<int> getUnreadCountStream(String userId) {
    final conversationId = 'user_$userId';
    return FirebaseFirestore.instance
        .collection(adminCollection)
        .doc(conversationId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data() as Map<String, dynamic>;
            return data['unreadCount'] ?? 0;
          }
          return 0;
        });
  }
}

// Widget pour afficher une image base64 (compatible Web)
class Base64ImageWidget extends StatelessWidget {
  final String base64String;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;

  const Base64ImageWidget({
    Key? key,
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      // Pour le Web, on peut utiliser directement le format data:image
      if (kIsWeb) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('data:image/jpeg;base64,$base64String'),
                fit: fit,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      
      // Pour mobile, utiliser Image.memory
      final bytes = base64.decode(base64String);
      return GestureDetector(
        onTap: onTap,
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.broken_image, color: Colors.grey[400]),
            );
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: frame == null
                  ? Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    )
                  : child,
            );
          },
        ),
      );
    } catch (e) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.error, color: Colors.red[300]),
      );
    }
  }
}

// Sélecteur d'image compatible Web/Mobile
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();
  
  static Future<String?> pickImageAsBase64() async {
    try {
      if (kIsWeb) {
        // Pour Web, utiliser l'input file HTML
        final completer = Completer<String?>();
        final uploadInput = html.FileUploadInputElement()
          ..accept = 'image/*'
          ..multiple = false;
        uploadInput.click();
        
        uploadInput.onChange.listen((event) {
          final files = uploadInput.files;
          if (files!.isEmpty) {
            completer.complete(null);
            return;
          }
          
          final reader = html.FileReader();
          reader.readAsDataUrl(files[0]);
          reader.onLoadEnd.listen((event) {
            final result = reader.result as String;
            // Enlever le préfixe "data:image/jpeg;base64,"
            final base64 = result.split(',').last;
            completer.complete(base64);
          });
        });
        
        return completer.future;
      } else {
        // Pour mobile
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 70,
        );
        
        if (image == null) return null;
        
        final bytes = await image.readAsBytes();
        return base64.encode(bytes);
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      return null;
    }
  }
  
  static Future<String?> takePhotoAsBase64() async {
    try {
      if (kIsWeb) {
        // Pour Web, utiliser l'input file - pas de capture directe possible
        final completer = Completer<String?>();
        final uploadInput = html.FileUploadInputElement()
          ..accept = 'image/*'
          ..multiple = false;
        // Sur le Web, on ne peut pas forcer l'utilisation de la caméra directement
        // L'utilisateur devra choisir "Prendre une photo" dans le sélecteur de fichiers
        uploadInput.click();
        
        uploadInput.onChange.listen((event) {
          final files = uploadInput.files;
          if (files!.isEmpty) {
            completer.complete(null);
            return;
          }
          
          final reader = html.FileReader();
          reader.readAsDataUrl(files[0]);
          reader.onLoadEnd.listen((event) {
            final result = reader.result as String;
            final base64 = result.split(',').last;
            completer.complete(base64);
          });
        });
        
        return completer.future;
      } else {
        // Pour mobile
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 70,
        );
        
        if (image == null) return null;
        
        final bytes = await image.readAsBytes();
        return base64.encode(bytes);
      }
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      return null;
    }
  }
}

// Page de chat (version arabe) - Design amélioré
class ChatPage extends StatefulWidget {
  final String conversationId;
  final String userId;
  final String userName;

  const ChatPage({
    Key? key,
    required this.conversationId,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  late AnimationController _typingAnimationController;
  bool _isSending = false;
  
  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }
  
  Future<void> _markMessagesAsRead() async {
    await ChatSystem.markMessagesAsRead(widget.conversationId);
  }
  
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;
    
    setState(() => _isSending = true);
    
    final content = _messageController.text;
    _messageController.clear();
    
    await ChatSystem.sendMessage(
      conversationId: widget.conversationId,
      senderId: widget.userId,
      senderName: widget.userName,
      content: content,
    );
    
    setState(() => _isSending = false);
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }
  
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'إرفاق صورة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'المعرض',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      final base64Image = await ImagePickerHelper.pickImageAsBase64();
                      if (base64Image != null && mounted) {
                        _showCaptionDialog(base64Image);
                      }
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'الكاميرا',
                    color: Colors.green,
                    onTap: () async {
                      Navigator.pop(context);
                      final base64Image = await ImagePickerHelper.takePhotoAsBase64();
                      if (base64Image != null && mounted) {
                        _showCaptionDialog(base64Image);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showCaptionDialog(String base64Image) async {
    final captionController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إضافة تعليق',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Base64ImageWidget(
                    base64String: base64Image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captionController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'أضف تعليقاً (اختياري)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ChatSystem.sendImageMessage(
                          conversationId: widget.conversationId,
                          senderId: widget.userId,
                          senderName: widget.userName,
                          base64Image: base64Image,
                          caption: captionController.text.isEmpty ? null : captionController.text,
                        );
                        _scrollToBottom();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إرسال',
                        style: TextStyle(fontSize: 16),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Color.fromARGB(255, 44, 120, 190),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المسؤول',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'متصل',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2A9D8F),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bannière d'information améliorée
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2A9D8F).withOpacity(0.1),
                  const Color(0xFFE9C46A).withOpacity(0.1),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2A9D8F).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A9D8F).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF2A9D8F),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وقت الرد المتوقع',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'خلال 2-4 ساعات',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A9D8F),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A9D8F).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Color(0xFF2A9D8F),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'سريع',
                        style: TextStyle(
                          color: Color(0xFF2A9D8F),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ChatSystem.getMessagesStream(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'حدث خطأ: ${snapshot.error}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF2A9D8F),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'جاري التحميل...',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                
                final messages = snapshot.data!.docs;
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A9D8F).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: const Color(0xFF2A9D8F).withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'لا توجد رسائل',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'كن أول من يرسل رسالة',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A9D8F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 16, color: Color(0xFF2A9D8F)),
                              SizedBox(width: 8),
                              Text(
                                'المحادثة آمنة وخاصة',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2A9D8F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == widget.userId;
                    final isSystem = message['type'] == 'system';
                    
                    if (isSystem) {
                      return _buildSystemMessage(message);
                    }
                    
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          
          // Zone de saisie améliorée
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Bouton image
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2A9D8F).withOpacity(0.1),
                          const Color(0xFFE9C46A).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFF2A9D8F),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Champ de texte
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? const Color(0xFF2A9D8F)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: 'اكتب رسالتك...',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        if (_messageController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _messageController.clear(),
                            iconSize: 20,
                            color: Colors.grey[400],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Bouton envoi
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2A9D8F),
                          Color(0xFFE9C46A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2A9D8F).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSystemMessage(Map<String, dynamic> message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                message['content'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();
    final timeString = timestamp != null
        ? DateFormat('HH:mm').format(timestamp)
        : '';
    final messageType = message['messageType'] ?? 'text';
    final imageBase64 = message['imageBase64'];
    final caption = message['caption'];
    final isRead = message['read'] ?? false;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2A9D8F),
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF2A9D8F),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF2A9D8F),
                          Color(0xFF264653),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMe
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe) ...[
                    const Text(
                      'المسؤول',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A9D8F),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Afficher l'image si présente
                  if (messageType == 'image' && imageBase64 != null) ...[
                    GestureDetector(
                      onTap: () => _showFullScreenImage(imageBase64, caption),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 250,
                          maxHeight: 250,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Base64ImageWidget(
                            base64String: imageBase64,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    if (caption != null && caption.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          caption,
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Message texte normal
                    Text(
                      message['content'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isMe)
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead
                              ? const Color(0xFFE9C46A)
                              : Colors.white.withOpacity(0.5),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
  
  void _showFullScreenImage(String base64Image, String? caption) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Base64ImageWidget(
                    base64String: base64Image,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              if (caption != null && caption.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
  
  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text(
                  'حذف المحادثة',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_outlined, color: Colors.orange),
                ),
                title: const Text(
                  'حظر',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('هذه الميزة غير متوفرة'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.report_problem_outlined, color: Colors.blue),
                ),
                title: const Text(
                  'الإبلاغ عن مشكلة',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'حذف المحادثة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'هل أنت متأكد من رغبتك في حذف جميع الرسائل؟',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('حذف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showReportDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'الإبلاغ عن مشكلة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'يرجى وصف المشكلة التي واجهتها:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'رسالتك...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                const Text('شكراً على الإبلاغ'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إرسال'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bouton de chat flottant amélioré
class ChatFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int unreadCount;

  const ChatFloatingButton({
    Key? key,
    required this.onPressed,
    this.unreadCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2A9D8F),
                Color(0xFFE9C46A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A9D8F).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(
              Icons.chat,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}