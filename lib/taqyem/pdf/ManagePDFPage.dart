import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class UploadPDFPage extends StatefulWidget {
  @override
  _UploadPDFPageState createState() => _UploadPDFPageState();
}

class _UploadPDFPageState extends State<UploadPDFPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double _uploadProgress = 0.0;

  Future<void> _uploadPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

      if (result != null) {
        Uint8List fileBytes = result.files.single.bytes!;

        String? customName = await _showFileNameDialog();
        if (customName == null || customName.isEmpty) return;

        String fileName = "$customName.pdf";

        User? user = _auth.currentUser;
        if (user == null) {
          throw Exception("Utilisateur non connecté");
        }

        String name = user.displayName ?? user.email ?? "مستخدم مجهول";

        Reference storageRef = _storage
            .ref()
            .child('pdfs/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        UploadTask uploadTask = storageRef.putData(fileBytes);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        });

        TaskSnapshot snapshot = await uploadTask;
        String fileUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('pdfs').add({
          'Name': fileName,
          'time': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'name': name,
          'fileUrl': fileUrl,
        });

        setState(() {
          _uploadProgress = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("تم رفع الملف بنجاح")));
      }
    } catch (e) {
      setState(() {
        _uploadProgress = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في رفع الملف : $e")));
    }
  }

  Future<String?> _showFileNameDialog() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("اسم الملف", textAlign: TextAlign.right),
          content: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            decoration: InputDecoration(hintText: "أدخل اسم الملف", hintTextDirection: TextDirection.rtl),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("إلغاء"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text("موافق"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadAndShowPDF(String fileUrl) async {
    try {
      if (await canLaunch(fileUrl)) {
        await launch(fileUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("تعذر فتح الملف PDF")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في فتح الملف PDF")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الملفات PDF',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        elevation: 4,
        actions: [
          TextButton.icon(
            onPressed: _uploadPDF,
            icon: Icon(Icons.add, color: Colors.yellowAccent),
            label: Text(
              'إضافة',
              style: TextStyle(color: Colors.yellowAccent),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ النص التشجيعي المضاف
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromRGBO(7, 82, 96, 0.9),
                  const Color.fromRGBO(7, 82, 96, 0.7),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.emoji_objects_outlined,
                  color: Colors.yellowAccent,
                  size: 30,
                ),
                SizedBox(height: 10),
                Text(
                  'هنا يمكنك مشاركة ملفات تساعد بها غيرك وتستفيد من خبرات بقية زملائك',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'لتشجيع ثقافة المشاركة والارتقاء بالمستوى التعليمي',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          if (_uploadProgress > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  LinearProgressIndicator(value: _uploadProgress),
                  SizedBox(height: 5),
                  Text(
                      "جاري الرفع : ${(100 * _uploadProgress).toStringAsFixed(2)}%"),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('pdfs')
                    .orderBy('time', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final pdfs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: pdfs.length,
                    itemBuilder: (context, index) {
                      final pdf = pdfs[index];
                      final fileName = pdf['Name'];
                      final docId = pdf.id;
                      final userId = pdf['userId'];
                      final name = pdf['name'];
                      final fileUrl = pdf['fileUrl'];
                      final time = (pdf['time'] as Timestamp?)?.toDate() ??
                          DateTime.now();

                      return Card(
                        elevation: 4.0,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12.0),
                          title: Text(fileName,
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('تمت المشاركة بواسطة: $name',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 14.0)),
                              Text('التاريخ: ${time.toLocal()}',
                                  textAlign: TextAlign.right),
                              Text(
                                  'لتحميل الملف، انقر على PDF المطلوب',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic)),
                            ],
                          ),
                          trailing: userId == _auth.currentUser?.uid
                              ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await _firestore
                                        .collection('pdfs')
                                        .doc(docId)
                                        .delete();
                                    await _storage.refFromURL(fileUrl).delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text("تم حذف الملف")));
                                  },
                                )
                              : null,
                          onTap: () => _downloadAndShowPDF(fileUrl),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}