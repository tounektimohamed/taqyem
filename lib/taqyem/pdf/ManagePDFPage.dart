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

  // Méthode pour uploader le fichier PDF
  Future<void> _uploadPDF() async {
    try {
      // Demander à l'utilisateur de sélectionner un fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      
      if (result != null) {
        // Obtenez les octets du fichier PDF
        Uint8List fileBytes = result.files.single.bytes!;
        String fileName = result.files.single.name;
        
        // Récupérer l'utilisateur connecté
        User? user = _auth.currentUser;
        if (user == null) {
          throw Exception("Utilisateur non connecté");
        }

        // Obtenez le nom de l'utilisateur à partir de Firebase Auth
        String userName = user.displayName ?? user.email ?? "Utilisateur anonyme";  // Utiliser l'email comme fallback

        // Télécharger le fichier dans Firebase Storage
        Reference storageRef = _storage.ref().child('pdfs/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        UploadTask uploadTask = storageRef.putData(fileBytes);
        TaskSnapshot snapshot = await uploadTask;

        // Récupérer l'URL du fichier après le téléchargement
        String fileUrl = await snapshot.ref.getDownloadURL();

        // Ajouter le fichier à Firestore sous la sous-collection 'pdfs' de l'utilisateur
        await _firestore.collection('users').doc(user.uid).collection('pdfs').add({
          'name': fileName,
          'time': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'userName': userName,  // Ajouter le nom de l'utilisateur
          'fileUrl': fileUrl,    // Stocker l'URL du fichier téléchargé
        });

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fichier téléchargé avec succès")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors du téléchargement : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Télécharger un fichier PDF'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _uploadPDF,
          child: Text('Télécharger un PDF'),
        ),
      ),
    );
  }
}


class DisplayPDFsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Méthode pour télécharger et afficher le PDF
  Future<void> _downloadAndShowPDF(String docId, BuildContext context) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(_auth.currentUser?.uid).collection('pdfs').doc(docId).get();
      if (doc.exists) {
        String fileUrl = doc['fileUrl'];

        // Utilisez url_launcher pour ouvrir l'URL dans un navigateur externe
        if (await canLaunch(fileUrl)) {
          await launch(fileUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Impossible d'ouvrir le fichier PDF")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors du téléchargement du PDF")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fichiers PDF'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').doc(_auth.currentUser?.uid).collection('pdfs').orderBy('time').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final pdfs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pdfs.length,
            itemBuilder: (context, index) {
              final pdf = pdfs[index];
              final fileName = pdf['name'];
              final docId = pdf.id;
              final userId = pdf['userId'];
              final userName = pdf['userName']; // Nom de l'utilisateur
              final time = (pdf['time'] as Timestamp).toDate(); // Convertir le timestamp en DateTime

              return ListTile(
                title: Text(fileName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Partagé par: $userName'),  // Correctly display the user name
                    Text('Date: ${time.toLocal()}'),
                  ],
                ),
                trailing: userId == FirebaseAuth.instance.currentUser?.uid
                    ? IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Supprimer uniquement si l'utilisateur est celui qui a téléchargé le fichier
                          await _firestore.collection('users').doc(userId).collection('pdfs').doc(docId).delete();
                          await FirebaseStorage.instance.refFromURL(pdf['fileUrl']).delete();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fichier supprimé")));
                        },
                      )
                    : null,
                onTap: () => _downloadAndShowPDF(docId, context),
              );
            },
          );
        },
      ),
    );
  }
}
