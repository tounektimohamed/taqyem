import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Taqyem/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' show File;

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({Key? key}) : super(key: key);

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      print('Erreur sélection image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() => _isUploading = true);

    try {
      final fileName =
          'notifications/${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.name}';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(
        File(_selectedImage!.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();
      setState(() => _isUploading = false);
      return url;
    } catch (e) {
      print('Erreur upload image: $e');
      setState(() => _isUploading = false);
      return null;
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _imageUrlController.clear();
    });
  }

  void _clearUrlImage() {
    setState(() {
      _imageUrlController.clear();
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  bool _isFrenchInterface = false;

  String _t(String ar, String fr) => _isFrenchInterface ? fr : ar;

  void _showUrlInputDialog() {
    final urlController = TextEditingController(text: _imageUrlController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('إدخال رابط الصورة', 'Entrer l\'URL de l\'image')),
        content: TextField(
          controller: urlController,
          decoration: InputDecoration(
            hintText: 'https://exemple.com/image.jpg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('إلغاء', 'Annuler')),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _imageUrlController.text = urlController.text;
                _selectedImage = null;
                _uploadedImageUrl = null;
              });
              Navigator.pop(context);
            },
            child: Text(_t('تأكيد', 'Confirmer')),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      String? imageUrl;

      // Upload image if selected from phone
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        imageUrl = _imageUrlController.text.trim();
      }

      await NotificationService.sendNotificationToAllUsers(
        title: _titleController.text.trim(),
        body: _messageController.text.trim(),
        imageUrl: imageUrl,
      );

      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'target': 'all',
        'sentBy': FirebaseAuth.instance.currentUser?.uid,
        'sentAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(
              'تم إرسال الإشعار بنجاح',
              'Notification envoyée avec succès',
            )),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _t('خطأ في إرسال الإشعار: $e', 'Erreur lors de l\'envoi: $e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('إرسال إشعار', 'Envoyer une notification')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _t('إشعار جديد', 'Nouvelle notification'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t('أرسل رسالة لجميع المستخدمين',
                          'Envoyez un message à tous les utilisateurs'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _t('عنوان الإشعار', 'Titre de la notification'),
                  hintText: _t('مثال: تحديث جديد', 'Ex: Nouvelle mise à jour'),
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _t('يرجى إدخال العنوان', 'Veuillez entrer un titre');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: _t('محتوى الإشعار', 'Contenu de la notification'),
                  hintText:
                      _t('أدخل رسالتك هنا...', 'Entrez votre message ici...'),
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.message),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _t(
                        'يرجى إدخال المحتوى', 'Veuillez entrer le contenu');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image picker section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('صورة الإشعار (اختياري)',
                          'Image de la notification (optionnel)'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImage != null ||
                        _imageUrlController.text.isNotEmpty) ...[
                      Stack(
                        children: [
                          if (_selectedImage != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedImage!.path),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (_imageUrlController.text.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imageUrlController.text,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              onPressed: _selectedImage != null
                                  ? _removeImage
                                  : _clearUrlImage,
                              icon: CircleAvatar(
                                backgroundColor: Colors.red,
                                radius: 14,
                                child: Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploading ? null : _pickImage,
                            icon: _isUploading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(Icons.photo_library),
                            label: Text(
                                _t('اختيار من الهاتف', 'Choisir du téléphone')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Show URL input dialog
                              _showUrlInputDialog();
                            },
                            icon: Icon(Icons.link),
                            label: Text(_t('رابط URL', 'Lien URL')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSending ? null : _sendNotification,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSending
                      ? _t('جاري الإرسال...', 'Envoi en cours...')
                      : _t('إرسال إلى جميع المستخدمين',
                          'Envoyer à tous les utilisateurs'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _t('سجل الإشعارات المرسلة',
                    'Historique des notifications envoyées'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildNotificationHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_notifications')
          .orderBy('sentAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data!.docs;
        if (notifications.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _t('لا توجد إشعارات سابقة', 'Aucune notification précédente'),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            final data = notif.data() as Map<String, dynamic>;
            final sentAt = data['sentAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.notifications,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  data['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['message'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          sentAt != null ? _formatDate(sentAt.toDate()) : '',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
