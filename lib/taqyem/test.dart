import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddSubjectDialog extends StatefulWidget {
  @override
  _AddSubjectDialogState createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<AddSubjectDialog> {
  String? _selectedClassName; // Classe sélectionnée
  List<String> _selectedSubjects = []; // Liste des matières sélectionnées
  List<Map<String, String>> _subjects = []; // Liste des matières
  List<Map<String, String>> _classNames = []; // Liste des classes avec ID et nom
  TextEditingController _newSubjectController = TextEditingController(); // Contrôleur pour ajouter une nouvelle matière

  @override
  void initState() {
    super.initState();
    _loadClassNames(); // Charger les noms des classes au démarrage
  }

  // Charger les classes depuis Firestore
  Future<void> _loadClassNames() async {
    try {
      final classDocs = await FirebaseFirestore.instance
          .collection('classes')
          .get();

      setState(() {
        _classNames = classDocs.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'] as String,
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du chargement des classes')));
    }
  }

  // Charger les matières d'une classe spécifique
  Future<void> _loadSubjects(String classId) async {
    try {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('matieres')
          .get();

      if (classDoc.docs.isNotEmpty) {
        setState(() {
          _subjects.clear();
          _subjects.addAll(classDoc.docs.map((doc) {
            return {'name': doc['name'] as String};
          }).toList());
        });
      } else {
        setState(() {
          _subjects.clear();
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des matières : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la récupération des matières')));
    }
  }

  // Enregistrer les matières et la classe sous l'ID de l'utilisateur
  Future<void> _saveClassData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (_selectedClassName != null && _selectedSubjects.isNotEmpty) {
        try {
          var userClassesRef = FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('user_classes')
              .doc();

          await userClassesRef.set({
            'class_name': _selectedClassName,
            'subjects': _selectedSubjects,
            'timestamp': FieldValue.serverTimestamp(),
          });

          // Réinitialiser les champs après l'enregistrement
          setState(() {
            _selectedSubjects.clear();
            _selectedClassName = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Classe et matières enregistrées avec succès!')));
          Navigator.of(context).pop(); // Ferme la boîte de dialogue
        } catch (e) {
          print("Erreur lors de l'enregistrement : $e");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'enregistrement')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez compléter tous les champs.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Utilisateur non connecté')));
    }
  }

  // Interface utilisateur pour afficher les matières avec des cases à cocher
  Widget _buildSubjectCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2. Sélectionner des matières', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _subjects.map((subject) {
                return CheckboxListTile(
                  title: Text(subject['name'] ?? 'Inconnu'),
                  value: _selectedSubjects.contains(subject['name']),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedSubjects.add(subject['name']!);
                      } else {
                        _selectedSubjects.remove(subject['name']);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        TextField(
          controller: _newSubjectController,
          decoration: InputDecoration(
            labelText: 'Nom de la matière (Ajouter)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            String newSubject = _newSubjectController.text.trim();
            if (newSubject.isNotEmpty) {
              setState(() {
                _subjects.add({'name': newSubject});
                _newSubjectController.clear();
              });
            }
          },
          child: Text('Ajouter une matière'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Gérer les matières'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedClassName,
              items: _classNames.map((classData) {
                return DropdownMenuItem(
                  value: classData['id'],
                  child: Text(classData['name'] ?? 'Nom inconnu'),
                );
              }).toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedClassName = value;
                });
                if (value != null) {
                  await _loadSubjects(value);
                }
              },
              decoration: InputDecoration(
                labelText: 'Sélectionner une classe',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),
            _buildSubjectCheckboxes(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_selectedClassName != null && _selectedSubjects.isNotEmpty)
                  ? _saveClassData
                  : null,
              child: Text('Confirmer l\'ajout'),
            ),
          ],
        ),
      ),
    );
  }
}

// Fonction pour ouvrir le dialogue
void showAddSubjectDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AddSubjectDialog();
    },
  );
}
