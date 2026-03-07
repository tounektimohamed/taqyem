// lib/taqyem/chat/admin_chat_panel.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'chat_system.dart';

class AdminChatPanel extends StatefulWidget {
  const AdminChatPanel({Key? key}) : super(key: key);

  @override
  _AdminChatPanelState createState() => _AdminChatPanelState();
}

class _AdminChatPanelState extends State<AdminChatPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSendingBroadcast = false;

  Future<void> _showBroadcastDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    bool includeImage = false;
    String? base64Image;
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Envoyer un message à tous les utilisateurs'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titre du message
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Titre du message',
                    hintText: 'Ex: Information importante',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Contenu du message
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    hintText: 'Écrivez votre message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.message),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Option d'ajouter une image
                CheckboxListTile(
                  title: const Text('Ajouter une image'),
                  value: includeImage,
                  onChanged: (value) {
                    setState(() {
                      includeImage = value ?? false;
                      if (!includeImage) {
                        base64Image = null;
                      }
                    });
                  },
                ),
                
                if (includeImage) ...[
                  const SizedBox(height: 8),
                  if (base64Image == null)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final image = await ImagePickerHelper.pickImageAsBase64();
                        if (image != null) {
                          setState(() {
                            base64Image = image;
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Choisir une image'),
                    )
                  else ...[
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Base64ImageWidget(
                          base64String: base64Image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          base64Image = null;
                        });
                      },
                      child: const Text('Supprimer l\'image'),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: _isSendingBroadcast
                  ? null
                  : () async {
                      if (messageController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez entrer un message'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      setState(() {
                        _isSendingBroadcast = true;
                      });
                      
                      await _sendBroadcastMessage(
                        title: titleController.text.trim().isEmpty 
                            ? null 
                            : titleController.text.trim(),
                        message: messageController.text.trim(),
                        base64Image: base64Image,
                      );
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message envoyé à tous les utilisateurs'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      
                      setState(() {
                        _isSendingBroadcast = false;
                      });
                    },
              child: _isSendingBroadcast
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendBroadcastMessage({
    String? title,
    required String message,
    String? base64Image,
  }) async {
    try {
      // Récupérer tous les utilisateurs
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .get();
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      int successCount = 0;
      int totalUsers = usersSnapshot.docs.length;
      
      // Pour chaque utilisateur, créer ou récupérer une conversation et envoyer le message
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userName = userDoc['name'] ?? 'Utilisateur';
        
        try {
          // Créer ou récupérer la conversation
          final conversationId = await ChatSystem.getOrCreateConversation(userId);
          
          // Formater le message avec le titre si présent
          String finalMessage = message;
          if (title != null && title.isNotEmpty) {
            finalMessage = '📢 **$title**\n\n$message';
          }
          
          if (base64Image != null) {
            // Envoyer un message avec image
            await ChatSystem.sendImageMessage(
              conversationId: conversationId,
              senderId: currentUser.uid,
              senderName: 'Admin',
              base64Image: base64Image,
              caption: finalMessage,
            );
          } else {
            // Envoyer un message texte
            await ChatSystem.sendMessage(
              conversationId: conversationId,
              senderId: currentUser.uid,
              senderName: 'Admin',
              content: finalMessage,
            );
          }
          
          successCount++;
          
          // Petite pause pour éviter de surcharger Firestore
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('Erreur pour l\'utilisateur $userId: $e');
        }
      }
      
      // Enregistrer le broadcast dans l'historique
      await FirebaseFirestore.instance.collection('broadcast_messages').add({
        'title': title,
        'message': message,
        'hasImage': base64Image != null,
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': currentUser.uid,
        'recipientCount': successCount,
        'totalUsers': totalUsers,
      });
      
      print('Message broadcast envoyé à $successCount utilisateurs');
    } catch (e) {
      print('Erreur lors de l\'envoi broadcast: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages des utilisateurs'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          // Bouton pour message broadcast
          IconButton(
            icon: const Icon(Icons.campaign, color: Colors.white),
            tooltip: 'Message à tous',
            onPressed: _showBroadcastDialog,
          ),
          // Historique des broadcasts
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Historique des messages',
            onPressed: _showBroadcastHistory,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admin_conversations')
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final conversations = snapshot.data!.docs;

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final data = conversation.data() as Map<String, dynamic>;
              
              return _buildConversationTile(conversation.id, data);
            },
          );
        },
      ),
    );
  }

  void _showBroadcastHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BroadcastHistoryPage(),
      ),
    );
  }

  Widget _buildConversationTile(String conversationId, Map<String, dynamic> data) {
    final lastMessage = data['lastMessage'] ?? '';
    final lastMessageTime = (data['lastMessageTime'] as Timestamp?)?.toDate();
    final userName = data['userName'] ?? 'Utilisateur inconnu';
    final unreadCount = data['unreadCount'] ?? 0;
    final lastMessageType = data['lastMessageType'] ?? 'text';
    
    String displayMessage = lastMessage;
    if (lastMessageType == 'image') {
      displayMessage = '🖼️ Image';
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          displayMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (lastMessageTime != null)
              Text(
                DateFormat('HH:mm').format(lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          _openAdminChat(conversationId, userName);
        },
      ),
    );
  }

  void _openAdminChat(String conversationId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminChatDetail(
          conversationId: conversationId,
          userName: userName,
        ),
      ),
    );
  }
}

// Page d'historique des messages broadcast
class BroadcastHistoryPage extends StatelessWidget {
  const BroadcastHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des messages'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('broadcast_messages')
            .orderBy('sentAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final broadcasts = snapshot.data!.docs;

          if (broadcasts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun message envoyé',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: broadcasts.length,
            itemBuilder: (context, index) {
              final broadcast = broadcasts[index];
              final data = broadcast.data() as Map<String, dynamic>;
              
              return _buildBroadcastTile(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildBroadcastTile(Map<String, dynamic> data) {
    final title = data['title'];
    final message = data['message'] ?? '';
    final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
    final hasImage = data['hasImage'] ?? false;
    final recipientCount = data['recipientCount'] ?? 0;
    final totalUsers = data['totalUsers'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: hasImage ? Colors.green[100] : Colors.blue[100],
          child: Icon(
            hasImage ? Icons.image : Icons.message,
            color: hasImage ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          title ?? 'Message sans titre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$recipientCount/$totalUsers reçu',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: sentAt != null
            ? Text(
                DateFormat('dd/MM/yyyy HH:mm').format(sentAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    'Titre: $title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Message:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Le reste du code AdminChatDetail reste identique
class AdminChatDetail extends StatefulWidget {
  final String conversationId;
  final String userName;

  const AdminChatDetail({
    Key? key,
    required this.conversationId,
    required this.userName,
  }) : super(key: key);

  @override
  _AdminChatDetailState createState() => _AdminChatDetailState();
}

class _AdminChatDetailState extends State<AdminChatDetail> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await FirebaseFirestore.instance
        .collection('admin_conversations')
        .doc(widget.conversationId)
        .update({'unreadCount': 0});
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text;
    _messageController.clear();

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await ChatSystem.sendMessage(
      conversationId: widget.conversationId,
      senderId: currentUser.uid,
      senderName: 'Admin',
      content: content,
    );

    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final base64Image = await ImagePickerHelper.pickImageAsBase64();
                if (base64Image != null && mounted) {
                  _showCaptionDialog(base64Image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Prendre une photo'),
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
      ),
    );
  }
  
  Future<void> _showCaptionDialog(String base64Image) async {
    final captionController = TextEditingController();
    final currentUser = _auth.currentUser;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une légende'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Base64ImageWidget(
                  base64String: base64Image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: captionController,
              decoration: InputDecoration(
                hintText: 'Ajouter une légende (optionnel)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (currentUser != null) {
                await ChatSystem.sendImageMessage(
                  conversationId: widget.conversationId,
                  senderId: currentUser.uid,
                  senderName: 'Admin',
                  base64Image: base64Image,
                  caption: captionController.text.isEmpty ? null : captionController.text,
                );
                _scrollToBottom();
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isAdmin = message['type'] == 'admin';
                    final isSystem = message['type'] == 'system';
                    
                    if (isSystem) {
                      return _buildSystemMessage(message);
                    }
                    
                    return _buildMessageBubble(message, isAdmin);
                  },
                );
              },
            ),
          ),
          
          // Zone de saisie avec bouton image
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.image, color: Colors.white),
                    onPressed: _pickImage,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrivez votre réponse...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message['content'] ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isAdmin) {
    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();
    final timeString = timestamp != null
        ? DateFormat('HH:mm').format(timestamp)
        : '';
    final messageType = message['messageType'] ?? 'text';
    final imageBase64 = message['imageBase64'];
    final caption = message['caption'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 14, color: Colors.grey),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAdmin ? Theme.of(context).primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isAdmin ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isAdmin ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isAdmin) ...[
                    Text(
                      message['senderName'] ?? 'Utilisateur',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Afficher l'image si présente
                  if (messageType == 'image' && imageBase64 != null) ...[
                    GestureDetector(
                      onTap: () {
                        _showFullScreenImage(imageBase64, caption);
                      },
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 250,
                          maxHeight: 250,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAdmin ? Colors.white24 : Colors.grey[300]!,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Base64ImageWidget(
                            base64String: imageBase64,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    if (caption != null && caption.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        caption,
                        style: TextStyle(
                          fontSize: 14,
                          color: isAdmin ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ] else ...[
                    // Message texte normal
                    Text(
                      message['content'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        color: isAdmin ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 10,
                      color: isAdmin ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.admin_panel_settings, size: 14, color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showFullScreenImage(String base64Image, String? caption) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Base64ImageWidget(
                          base64String: base64Image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  if (caption != null && caption.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.black87,
                      child: Text(
                        caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}