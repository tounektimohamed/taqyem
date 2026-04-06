import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class GuideAdminPage extends StatefulWidget {
  const GuideAdminPage({Key? key}) : super(key: key);

  @override
  State<GuideAdminPage> createState() => _GuideAdminPageState();
}

class _GuideAdminPageState extends State<GuideAdminPage> {
  final ImagePicker _picker = ImagePicker();

  final List<GuideStepConfig> _steps = [
    GuideStepConfig(
        id: 'welcome',
        title: 'مرحباً بك!',
        defaultDescription: 'سنتعرف معاً على كيفية استخدام التطبيق خطوة بخطوة'),
    GuideStepConfig(
        id: 'create_class',
        title: 'إنشاء قسم',
        defaultDescription: 'ابدأ بإنشاء قسم جديد لطلابك من القائمة الجانبية'),
    GuideStepConfig(
        id: 'save_class',
        title: 'حفظ القسم',
        defaultDescription: 'أدخل اسم القسم ثم اضغط حفظ'),
    GuideStepConfig(
        id: 'manage_classes',
        title: 'إدارة الأقسام',
        defaultDescription: 'اذهب إلى إدارة الأقسام لاختيار القسم'),
    GuideStepConfig(
        id: 'select_class',
        title: 'اختيار القسم',
        defaultDescription: 'اضغط على اسم القسم للدخول إليه'),
    GuideStepConfig(
        id: 'add_student',
        title: 'إضافة التلاميذ',
        defaultDescription: 'اضغط على إضافة تلميذ لإضافة طلاب جدد'),
    GuideStepConfig(
        id: 'save_student',
        title: 'حفظ التلميذ',
        defaultDescription: 'أدخل اسم التلميذ ورقمه ثم اضغط حفظ'),
    GuideStepConfig(
        id: 'manage_bareme',
        title: 'إنشاء المعايير',
        defaultDescription: 'اضغط على إدارة المعايير لإنشاء سُلَّم التقييم'),
    GuideStepConfig(
        id: 'add_bareme',
        title: 'إضافة معايير',
        defaultDescription: 'أضف معايير مثل: الالتزام، التعاون، الإتقان'),
    GuideStepConfig(
        id: 'evaluate',
        title: 'تقييم التلاميذ',
        defaultDescription: 'اضغط على بطاقة تلميذ ثم اختر المعيار والقيمة'),
    GuideStepConfig(
        id: 'select_value',
        title: 'تحديد القيمة',
        defaultDescription: 'اختر المعيار واضغط على القيمة المناسبة'),
    GuideStepConfig(
        id: 'show_table',
        title: 'عرض الجدول',
        defaultDescription: 'اضغط على جدول النتائج لعرض جميع التقييمات'),
    GuideStepConfig(
        id: 'export',
        title: 'تصدير',
        defaultDescription: 'يمكنك تصدير الجدول أو طباعته'),
    GuideStepConfig(
        id: 'complete',
        title: 'تم!',
        defaultDescription: 'أنت جاهز الآن لاستخدام التطبيق. استمتع!'),
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
          .collection('guide_images')
          .doc('steps')
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
          .collection('guide_images')
          .doc('steps')
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
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('حذف الصورة'),
          content: Text('هل أنت متأكد من حذف هذه الصورة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('حذف'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      _imageBase64.remove(stepId);

      await FirebaseFirestore.instance
          .collection('guide_images')
          .doc('steps')
          .update({
        'images': _imageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم حذف الصورة'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في حذف الصورة: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة صور الدليل'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadImages),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                final imageBase64 = _imageBase64[step.id];
                final isUploading = _isUploading && _uploadingStepId == step.id;

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(26),
                                  shape: BoxShape.circle),
                              child: Text('${index + 1}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                                child: Text(step.title,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold))),
                            if (imageBase64 != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(26),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check,
                                          size: 14, color: Colors.green),
                                      SizedBox(width: 4),
                                      Text('صورة موجودة',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green)),
                                    ]),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(step.defaultDescription,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                        SizedBox(height: 16),
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: imageBase64 != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(
                                        base64Decode(
                                            imageBase64.split(',').last),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Center(
                                              child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                Icon(Icons.broken_image,
                                                    size: 48,
                                                    color: Colors.grey[400]),
                                                SizedBox(height: 8),
                                                Text('خطأ في تحميل الصورة',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[600])),
                                              ]));
                                        },
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Row(
                                          children: [
                                            _buildImageButton(
                                                icon: Icons.fullscreen,
                                                color: Colors.blue,
                                                onPressed: () => _showFullImage(
                                                    imageBase64)),
                                            SizedBox(width: 8),
                                            _buildImageButton(
                                                icon: Icons.edit,
                                                color: Colors.orange,
                                                onPressed: () =>
                                                    _pickAndUploadImage(
                                                        step.id)),
                                            SizedBox(width: 8),
                                            _buildImageButton(
                                                icon: Icons.delete,
                                                color: Colors.red,
                                                onPressed: () =>
                                                    _deleteImage(step.id)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : isUploading
                                  ? Center(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 12),
                                          Text('جاري حفظ الصورة...',
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                        ]))
                                  : InkWell(
                                      onTap: () => _pickAndUploadImage(step.id),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Center(
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                            Icon(Icons.add_photo_alternate,
                                                size: 48,
                                                color: Colors.grey[400]),
                                            SizedBox(height: 12),
                                            Text('اضغط لإضافة صورة',
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14)),
                                          ])),
                                    ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildImageButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 20)),
      ),
    );
  }

  void _showFullImage(String base64String) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    base64Decode(base64String.split(',').last),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuideStepConfig {
  final String id;
  final String title;
  final String defaultDescription;

  GuideStepConfig({
    required this.id,
    required this.title,
    required this.defaultDescription,
  });
}
