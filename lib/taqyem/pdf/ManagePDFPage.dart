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
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      
      if (result != null) {
        Uint8List fileBytes = result.files.single.bytes!;
        
        String? customName = await _showFileNameDialog();
        if (customName == null || customName.isEmpty) return;

        String fileName = "$customName.pdf";

        User? user = _auth.currentUser;
        if (user == null) {
          throw Exception("Utilisateur non connecté");
        }

        String name = user.displayName ?? user.email ?? "Utilisateur anonyme";

        Reference storageRef = _storage.ref().child('pdfs/${DateTime.now().millisecondsSinceEpoch}_$fileName');
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

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fichier téléchargé avec succès")));
      }
    } catch (e) {
      setState(() {
        _uploadProgress = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors du téléchargement : $e")));
    }
  }

  Future<String?> _showFileNameDialog() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Nom du fichier"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Entrez le nom du fichier"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text("OK"),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Impossible d'ouvrir le fichier PDF")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'ouverture du PDF")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des fichiers PDF'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _uploadPDF,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_uploadProgress > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  LinearProgressIndicator(value: _uploadProgress),
                  SizedBox(height: 5),
                  Text("Téléchargement : ${(100 * _uploadProgress).toStringAsFixed(2)}%"),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('pdfs').orderBy('time', descending: true).snapshots(),
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
                      final time = (pdf['time'] as Timestamp?)?.toDate() ?? DateTime.now();

                      return Card(
                        elevation: 4.0,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12.0),
                          title: Text(fileName, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Partagé par: $name', style: TextStyle(fontSize: 14.0)),
                              Text('Date: ${time.toLocal()}'),
                            ],
                          ),
                          trailing: userId == _auth.currentUser?.uid
                              ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await _firestore.collection('pdfs').doc(docId).delete();
                                    await _storage.refFromURL(fileUrl).delete();
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fichier supprimé")));
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