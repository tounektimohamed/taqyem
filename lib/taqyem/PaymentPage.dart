import 'dart:html' as html; // Pour interagir avec les éléments HTML
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedForfait;
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  html.File? _photo; // Utiliser html.File au lieu de dart:io.File
  bool _hasSubmittedForm = false; // Indicateur si l'utilisateur a déjà soumis un formulaire

  final List<Map<String, dynamic>> forfaits = [
    {'type': 'Trimestriel', 'prix': 25},
    {'type': 'Annuel', 'prix': 60},
  ];

  @override
  void initState() {
    super.initState();
    _checkIfFormSubmitted(); // Vérifier si l'utilisateur a déjà soumis un formulaire
  }

  // Vérifier si l'utilisateur a déjà soumis un formulaire
  Future<void> _checkIfFormSubmitted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final paymentSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('payments')
        .get();

    if (paymentSnapshot.docs.isNotEmpty) {
      setState(() {
        _hasSubmittedForm = true; // L'utilisateur a déjà soumis un formulaire
      });
    }
  }

  // Sélectionner une image depuis le navigateur
  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*'; // Limiter aux fichiers image
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        setState(() {
          _photo = file; // Stocker le fichier sélectionné
        });
      }
    });
  }

  // Soumettre le formulaire de paiement
  Future<void> _submitPayment() async {
    if (selectedForfait == null || _nomController.text.isEmpty || _prenomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs et sélectionner un forfait.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utilisateur non connecté.')),
      );
      return;
    }

    // Enregistrer les informations dans Firestore
    final paymentData = {
      'forfait': selectedForfait,
      'nom': _nomController.text,
      'prenom': _prenomController.text,
      'photoUrl': _photo != null ? await _uploadPhoto(_photo!) : null,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending', // Statut de la demande
    };

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('payments')
        .add(paymentData);

    setState(() {
      _hasSubmittedForm = true; // Marquer que l'utilisateur a soumis un formulaire
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paiement enregistré avec succès!')),
    );

    Navigator.pop(context); // Retourner à la page précédente
  }

  // Uploader la photo sur Firebase Storage
  Future<String?> _uploadPhoto(html.File photo) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('payments/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putBlob(photo); // Utiliser putBlob pour le web
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Erreur lors de l\'upload de la photo: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page de Paiement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _hasSubmittedForm
            ? Center(
                child: Text(
                  'Votre demande est en cours de traitement.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            : Column(
                children: [
                  // Sélection du forfait
                  DropdownButtonFormField<String>(
                    value: selectedForfait,
                    hint: Text('Choisissez un forfait'),
                    items: forfaits.map<DropdownMenuItem<String>>((forfait) {
                      return DropdownMenuItem<String>(
                        value: forfait['type'] as String, // Conversion explicite en String
                        child: Text('${forfait['type']} - ${forfait['prix']}€'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedForfait = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),

                  // Champ pour le nom
                  TextField(
                    controller: _nomController,
                    decoration: InputDecoration(labelText: 'Nom'),
                  ),
                  SizedBox(height: 20),

                  // Champ pour le prénom
                  TextField(
                    controller: _prenomController,
                    decoration: InputDecoration(labelText: 'Prénom'),
                  ),
                  SizedBox(height: 20),

                  // Bouton pour ajouter une photo
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Ajouter une photo'),
                  ),
                  SizedBox(height: 20),

                  // Afficher la photo sélectionnée
                  if (_photo != null)
                    Image.network(
                      html.Url.createObjectUrl(_photo!), // Utiliser l'URL de l'objet pour afficher l'image
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  SizedBox(height: 20),

                  // Bouton pour soumettre le formulaire
                  ElevatedButton(
                    onPressed: _submitPayment,
                    child: Text('Envoyer'),
                  ),
                ],
              ),
      ),
    );
  }
}