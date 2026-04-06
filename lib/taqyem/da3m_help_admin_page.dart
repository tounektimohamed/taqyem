import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class Da3mHelpAdminPage extends StatefulWidget {
  const Da3mHelpAdminPage({Key? key}) : super(key: key);

  @override
  State<Da3mHelpAdminPage> createState() => _Da3mHelpAdminPageState();
}

class _Da3mHelpAdminPageState extends State<Da3mHelpAdminPage> {
  final ImagePicker _picker = ImagePicker();

  final List<HelpImageConfig> _steps = [
    HelpImageConfig(
        id: 'select_errors',
        title: 'تحديد الأخطاء',
        defaultDescription: 'Sélectionner les erreurs'),
    HelpImageConfig(
        id: 'generate_ai',
        title: 'توليد تمارين بالذكاء الاصطناعي',
        defaultDescription: 'Générer des exercices par IA'),
    HelpImageConfig(
        id: 'choose_exercises',
        title: 'اختيار التمارين',
        defaultDescription: 'Choisir les exercices'),
    HelpImageConfig(
        id: 'print_file',
        title: 'طباعة الملف',
        defaultDescription: 'Imprimer le fichier'),
  ];

  Map<String, String> _imageBase64 = {};
  bool _isLoading = true;
  bool _isUploading = false;
  String? _uploadingStepId;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('da3m_images')
          .doc('help')
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _imageBase64 = Map<String, String>.from(doc.data()!['images'] ?? {});
        });
      }
    } catch (e) {
      print('Error loading images: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadImage(String stepId) async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text('اختر مصدر الصورة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'كاميرا',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(stepId, ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'الصور',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(stepId, ImageSource.gallery);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.folder,
                  label: 'الملفات',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(stepId);
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(String stepId, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (image != null) {
        await _processAndSaveImage(stepId, await image.readAsBytes(), 'jpg');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في اختيار الصورة: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickFile(String stepId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          final extension = result.files.first.extension ?? 'png';
          await _processAndSaveImage(stepId, bytes, extension);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في اختيار الملف: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processAndSaveImage(
      String stepId, Uint8List bytes, String extension) async {
    setState(() {
      _isUploading = true;
      _uploadingStepId = stepId;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final base64Image = base64Encode(bytes);
      final dataUrl = 'data:image/$extension;base64,$base64Image';

      _imageBase64[stepId] = dataUrl;

      await FirebaseFirestore.instance
          .collection('da3m_images')
          .doc('help')
          .set({
        'images': _imageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });

      setState(() {
        _isUploading = false;
        _uploadingStepId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم حفظ الصورة بنجاح!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadingStepId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في حفظ الصورة: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteImage(String stepId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('حذف الصورة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف هذه الصورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(stepId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String stepId) async {
    setState(() {
      _isUploading = true;
      _uploadingStepId = stepId;
    });

    try {
      _imageBase64.remove(stepId);

      await FirebaseFirestore.instance
          .collection('da3m_images')
          .doc('help')
          .set({
        'images': _imageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isUploading = false;
        _uploadingStepId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم حذف الصورة'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadingStepId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في الحذف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildImagePreview(String? imageUrl, double height) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(Icons.image, color: Colors.grey, size: 48),
        ),
      );
    }

    try {
      String base64String = imageUrl;
      if (imageUrl.contains(',')) {
        base64String = imageUrl.split(',').last;
      }
      final bytes = base64Decode(base64String);

      return Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      return Container(
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة صور المساعدة - da3m'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'إدارة صور المساعدة لصفحة da3m_tableau.\nاضغط على + لإضافة صورة و - لحذفها.',
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ...List.generate(_steps.length, (index) {
                    final step = _steps[index];
                    final imageUrl = _imageBase64[step.id];
                    final isUploading = _uploadingStepId == step.id;

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.help_outline,
                                      color: Colors.purple.shade700),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        step.defaultDescription,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isUploading)
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),
                            _buildImagePreview(imageUrl, 150),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isUploading
                                        ? null
                                        : () => _pickAndUploadImage(step.id),
                                    icon: Icon(Icons.add_photo_alternate),
                                    label: Text('إضافة/تعديل'),
                                  ),
                                ),
                                SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: imageUrl == null || isUploading
                                      ? null
                                      : () => _deleteImage(step.id),
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  label: Text('حذف',
                                      style: TextStyle(color: Colors.red)),
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(color: Colors.red.shade200),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class HelpImageConfig {
  final String id;
  final String title;
  final String defaultDescription;

  HelpImageConfig({
    required this.id,
    required this.title,
    required this.defaultDescription,
  });
}
