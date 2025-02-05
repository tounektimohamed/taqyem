import 'package:Taqyem/taqyem/AddStudentPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddClassPage extends StatefulWidget {
  @override
  _AddClassPageState createState() => _AddClassPageState();
}

class _AddClassPageState extends State<AddClassPage> {
  String? _selectedClassName;
  List<String> _selectedSubjects = [];
  List<Map<String, String>> _subjects = [];
  List<Map<String, String>> _classNames = [];
  TextEditingController _studentNameController = TextEditingController();
  List<Map<String, String>> _students = [];
  TextEditingController _newSubjectController = TextEditingController();
  String? _selectedClassNameDisplay;

  @override
  void initState() {
    super.initState();
    _loadClassNames();
  }

  Future<void> _loadClassNames() async {
    try {
      final classDocs =
          await FirebaseFirestore.instance.collection('classes').get();
      setState(() {
        _classNames = classDocs.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'] as String,
          };
        }).toList();
        _classNames.sort((a, b) => a['name']!.compareTo(b['name']!));
      });
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des classes')));
    }
  }

  Future<void> _saveClassData(String? newClassName) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (_selectedClassName != null && _selectedSubjects.isNotEmpty) {
        try {
          var userClassesRef = FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('user_classes')
              .doc(_selectedClassName);
          await userClassesRef.set({
            'class_id': _selectedClassName,
            'class_name': newClassName ?? _selectedClassNameDisplay,
            'subjects': _selectedSubjects.map((subjectId) {
              var subject = _subjects.firstWhere((s) => s['id'] == subjectId,
                  orElse: () => {'name': 'Inconnu'});
              return {
                'id': subjectId,
                'name': subject['name'],
              };
            }).toList(),
            'students': _students.map((student) => student['name']).toList(),
            'timestamp': FieldValue.serverTimestamp(),
          });

          setState(() {
            _students.clear();
            _selectedSubjects.clear();
            _selectedClassName = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Classe enregistrée avec succès!')));
        } catch (e) {
          print("Erreur lors de l'enregistrement : $e");
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Veuillez compléter tous les champs.')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Utilisateur non connecté')));
    }
  }

  // Afficher un dialogue pour ajouter un caractère spécial au nom de la classe
  void _showRenameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('هل تريد إضافة حرف مميز للقسم؟'),
          content: TextField(
            controller: TextEditingController(text: _selectedClassNameDisplay),
            decoration:
                InputDecoration(hintText: "Entrez un nouveau nom de classe"),
            onChanged: (newName) {
              setState(() {
                _selectedClassNameDisplay = newName;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Si l'utilisateur choisit "Non", sauvegarder sans modification du nom
                _saveClassData(_selectedClassNameDisplay);
                Navigator.of(context).pop();
              },
              child: Text('Non'),
            ),
            TextButton(
              onPressed: () {
                // Si l'utilisateur choisit "Oui", sauvegarder avec le nouveau nom de classe
                _saveClassData(_selectedClassNameDisplay);
                Navigator.of(context).pop();
              },
              child: Text('Oui'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubjectCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2. Sélectionner des matières',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _subjects.map((subject) {
                return CheckboxListTile(
                  title: Text(subject['name'] ?? 'Inconnu'),
                  value: _selectedSubjects.contains(subject['id']),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedSubjects.add(subject['id']!);
                      } else {
                        _selectedSubjects.remove(subject['id']);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

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
            return {
              'id': doc.id,
              'name': doc['name']
                  as String, // Assurez-vous que 'name' est une String
            };
          }).toList());
        });
      } else {
        setState(() {
          _subjects.clear();
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des matières : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la récupération des matières')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gérer les matières')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Sélectionner une classe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
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
                  _selectedClassNameDisplay = _classNames.firstWhere(
                      (classData) => classData['id'] == value,
                      orElse: () => {'name': 'Nom inconnu'})['name'];
                });
                if (value != null) {
                  await _loadSubjects(value);
                }
              },
              decoration: InputDecoration(
                labelText: 'Sélectionner une classe',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),
            _buildSubjectCheckboxes(),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: (_selectedClassName != null &&
                        _selectedSubjects.isNotEmpty)
                    ? () async {
                        // Afficher le dialogue pour confirmer le renaming de la classe
                        _showRenameDialog();
                      }
                    : null, // Désactive le bouton si les conditions ne sont pas remplies
                child: Text('Confirmer l\'ajout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
