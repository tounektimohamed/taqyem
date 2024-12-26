import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddClassPage extends StatefulWidget {
  @override
  _AddClassPageState createState() => _AddClassPageState();
}

class _AddClassPageState extends State<AddClassPage> {
  String? _selectedClassName; // Classe sélectionnée
  List<String> _selectedSubjects = []; // Liste des matières sélectionnées
  List<Map<String, String>> _subjects = []; // Liste des matières
  List<Map<String, String>> _classNames = []; // Liste des classes avec ID et nom
  TextEditingController _studentNameController = TextEditingController(); // Contrôleur pour le nom de l'élève
  List<Map<String, String>> _students = []; // Liste des élèves ajoutés
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
        // Charger les classes sous forme de Map contenant 'id' et 'name'
        _classNames = classDocs.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'] as String, // Assurez-vous que 'name' existe dans votre Firestore
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

  // Ajouter un élève à la liste
  void _addStudent() {
    String studentName = _studentNameController.text.trim();
    if (studentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez entrer un nom d\'élève')));
    } else {
      setState(() {
        _students.add({'name': studentName});
        _studentNameController.clear();
      });
    }
  }

  // Enregistrer les matières, les élèves et la classe sous l'ID de l'utilisateur
  Future<void> _saveClassData() async {
    User? currentUser = FirebaseAuth.instance.currentUser; // Obtenir l'utilisateur connecté
    if (currentUser != null) {
      if (_selectedClassName != null && _students.isNotEmpty && _selectedSubjects.isNotEmpty) {
        try {
          // Référence à la collection 'user_classes' sous l'ID de l'utilisateur connecté
          var userClassesRef = FirebaseFirestore.instance
              .collection('users') // Collection des utilisateurs
              .doc(currentUser.uid) // Utiliser l'ID de l'utilisateur connecté
              .collection('user_classes') // Sous-collection pour les classes
              .doc(); // Créer un nouveau document

          await userClassesRef.set({
            'class_name': _selectedClassName, // Classe sélectionnée
            'subjects': _selectedSubjects, // Matières sélectionnées
            'students': _students.map((student) => student['name']).toList(), // Liste des élèves
            'timestamp': FieldValue.serverTimestamp(), // Date de l'ajout
          });

          // Réinitialiser les champs après l'enregistrement
          setState(() {
            _students.clear();
            _selectedSubjects.clear();
            _selectedClassName = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Classe et élèves enregistrés avec succès!')));
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
        // Ajouter une matière personnalisée
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

  // Interface utilisateur pour ajouter un élève
  Widget _buildAddStudentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _studentNameController,
          decoration: InputDecoration(
            labelText: 'Nom de l\'élève',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addStudent,
          child: Text('Ajouter l\'élève'),
        ),
        SizedBox(height: 15),
        Text('Élèves ajoutés:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Column(
          children: _students.map((student) {
            return ListTile(
              title: Text(student['name'] ?? 'Inconnu'),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gérer les matières et les élèves')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            _buildAddStudentField(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_selectedClassName != null && _students.isNotEmpty && _selectedSubjects.isNotEmpty)
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
