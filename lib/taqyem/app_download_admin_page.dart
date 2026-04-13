import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AppDownloadAdminPage extends StatefulWidget {
  const AppDownloadAdminPage({Key? key}) : super(key: key);

  @override
  State<AppDownloadAdminPage> createState() => _AppDownloadAdminPageState();
}

class _AppDownloadAdminPageState extends State<AppDownloadAdminPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _currentApkUrl;
  String _currentVersion = '1.0.0';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_info')
          .doc('download')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _currentApkUrl = data['apkUrl'];
          _currentVersion = data['version'] ?? '1.0.0';
        });
      }
    } catch (e) {
      print('Error loading app info: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _uploadApk() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final filePath = file.path;
      if (filePath == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      final fileName = 'taqyem_${DateTime.now().millisecondsSinceEpoch}.apk';
      final storageRef = _storage.ref().child('apk').child(fileName);

      final uploadTask = storageRef.putFile(
        File(filePath),
        SettableMetadata(
          contentType: 'application/vnd.android.package-archive',
        ),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final TaskSnapshot snapshot = await uploadTask;
      final apkUrl = await snapshot.ref.getDownloadURL();

      final versionController = TextEditingController(text: _currentVersion);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('تم رفع التطبيق بنجاح!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الإصدار الحالي: $_currentVersion'),
              SizedBox(height: 16),
              TextField(
                controller: versionController,
                decoration: InputDecoration(
                  labelText: 'الإصدار الجديد',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('حفظ'),
            ),
          ],
        ),
      );

      final version = versionController.text.trim().isEmpty
          ? _currentVersion
          : versionController.text.trim();

      if (confirm == true) {
        await FirebaseFirestore.instance
            .collection('app_info')
            .doc('download')
            .set({
          'apkUrl': apkUrl,
          'version': versionController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _currentApkUrl = apkUrl;
          _currentVersion = versionController.text;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حفظ معلومات التطبيق!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع التطبيق: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
    }
  }

  Future<void> _deleteApk() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('حذف التطبيق'),
          content: Text('هل أنت متأكد من حذف رابط التحميل؟'),
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

      await FirebaseFirestore.instance
          .collection('app_info')
          .doc('download')
          .update({
        'apkUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _currentApkUrl = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الرابط'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة تحميل التطبيق'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  SizedBox(height: 20),
                  _buildUploadCard(),
                  if (_currentApkUrl != null) ...[
                    SizedBox(height: 20),
                    _buildCurrentApkCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.android, size: 60, color: Colors.green),
            SizedBox(height: 15),
            Text(
              'إدارة تحميل التطبيق',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'قم برفع ملف APK ليتمكن المستخدمون من تحميل التطبيق',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  'رفع تطبيق جديد',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.android,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'ملف APK',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 15),
                  if (_isUploading)
                    Column(
                      children: [
                        LinearProgressIndicator(value: _uploadProgress),
                        SizedBox(height: 10),
                        Text(
                          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _uploadApk,
                      icon: Icon(Icons.cloud_upload),
                      label: Text('اختيار ملف APK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentApkCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  'التطبيق الحالي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withAlpha(77)),
              ),
              child: Row(
                children: [
                  Icon(Icons.android, color: Colors.green, size: 40),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الإصدار: $_currentVersion',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'متاح للتحميل',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteApk,
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
