import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddClassPage extends StatefulWidget {
  @override
  _AddClassPageState createState() => _AddClassPageState();
}

class _AddClassPageState extends State<AddClassPage> {
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();

  String? _currentClassId;
  String? _selectedClassName;
  String? _selectedSubjectName;
  final List<Map<String, String>> _subjects = [];
  final List<Map<String, String>> _students = [];
  bool _showSteps = false; // Contrôle de la visibilité des étapes

  final List<String> _classNames = [
    "السنة الأولى ابتدائي",
    "السنة الثانية ابتدائي",
    "السنة الثالثة ابتدائي",
    "السنة الرابعة ابتدائي",
    "السنة الخامسة ابتدائي",
    "السنة السادسة ابتدائي"
  ];

   final Map<String, List<String>> _classSubjects = {
    "السنة الأولى ابتدائي": [
      "قراءة قواعد لغة", "إنتاج كتابي", "رياضيات", "إيقاظ علمي", "تربية إسلامية"
    ],
    "السنة الثانية ابتدائي": [
      "تواصل شفوي", "قراءة", "قواعد لغة", "إنتاج كتابي", "رياضيات", "إيقاظ علمي", "تربية إسلامية"
    ],
    "السنة الثالثة ابتدائي": [
      "تواصل شفوي", "قراءة", "قواعد لغة", "إنتاج كتابي", "رياضيات", "إيقاظ علمي", "تربية إسلامية", "Expression orale et récitation", "Lecture compréhension et lecture vocale"
    ],
    "السنة الرابعة ابتدائي": [
      "تواصل شفوي", "قراءة", "قواعد لغة", "إنتاج كتابي", "رياضيات", "إيقاظ علمي", "تربية إسلامية", "Expression orale et récitation", "Lecture compréhension et lecture vocale"
    ],
    "السنة الخامسة ابتدائي": [
      "تواصل شفوي", "قراءة", "قواعد لغة", "إنتاج كتابي", "رياضيات", "إيقاظ علمي", "تربية إسلامية", "Expression orale et récitation", "Lecture compréhension et lecture vocale"
    ],
    "السنة السادسة ابتدائي": [
      "تواصل شفوي", "قراءة", "قواعد لغة", "إنتاج كتابي", "رياضيات", "إيقاظ علمي", "تربية إسلامية", "Expression orale et récitation", "Lecture compréhension et lecture vocale"
    ],
  };

  Future<void> _addClass() async {
    final className = _selectedClassName;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (className != null && userId != null) {
      final classRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('classes')
          .add({'name': className});
      setState(() {
        _currentClassId = classRef.id;
        _showSteps = true; // Affiche les étapes après avoir ajouté une classe
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Classe ajoutée avec succès !')),
      );
    }
  }

  Future<void> _addSubject() async {
    if (_selectedSubjectName != null && _currentClassId != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('classes')
            .doc(_currentClassId)
            .collection('subjects')
            .add({'name': _selectedSubjectName});
        setState(() {
          _subjects.add({'name': _selectedSubjectName!});
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Matière ajoutée avec succès !')),
        );
      }
    }
  }

  Future<void> _addStudent() async {
    final studentName = _studentNameController.text;
    if (studentName.isNotEmpty && _currentClassId != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('classes')
            .doc(_currentClassId)
            .collection('students')
            .add({'name': studentName});
        setState(() {
          _students.add({'name': studentName});
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Élève ajouté avec succès !')),
        );
      }
    }
  }
Future<void> _confirmAllAdditions() async {
    if (_students.isNotEmpty && _subjects.isNotEmpty && _selectedClassName != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        // Vous pouvez aussi mettre en place un "batch" pour ajouter tous les éléments à Firestore
        final batch = FirebaseFirestore.instance.batch();

        // Ajouter les matières
        for (var subject in _subjects) {
          final subjectRef = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('classes')
              .doc(_currentClassId)
              .collection('subjects')
              .doc();
          batch.set(subjectRef, {'name': subject['name']});
        }

        // Ajouter les élèves
        // for (var student in _students) {
        //   final studentRef = FirebaseFirestore.instance
        //       .collection('users')
        //       .doc(userId)
        //       .collection('classes')
        //       .doc(_currentClassId)
        //       .collection('students')
        //       .doc();
        //   batch.set(studentRef, {'name': student['name']});
        // }

        // Ajouter la classe
        final classRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('classes')
            .doc(_currentClassId!);
        batch.set(classRef, {'name': _selectedClassName});

        // Commettre toutes les actions de manière atomique
        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ajout finalisé avec succès !')),
        );

        // Vous pouvez réinitialiser les valeurs ou naviguer vers une autre page ici
        setState(() {
          _students.clear();
          _subjects.clear();
          _showSteps = false;
        });
      }
    } else {
      // Message si les éléments à confirmer sont manquants
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez ajouter des élèves et des matières avant de confirmer !')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter une classe et ses détails'),
        backgroundColor: Color.fromARGB(255, 203, 230, 227),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ajouter une classe
            _buildAddClassSection(),
            if (_showSteps) ...[
              Divider(),
              // Ajouter une matière
              _buildAddSubjectSection(),
              Divider(),
              // Ajouter un élève
              _buildAddStudentSection(),
                            Divider(),
              ElevatedButton(
                onPressed: _confirmAllAdditions,
                child: Text('Confirmer les ajouts'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddClassSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Sélectionner une classe',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedClassName,
                  items: _classNames.map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClassName = value;
                      _selectedSubjectName = null;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Nom de la classe',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _addClass,
                  child: Text('Ajouter Classe'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddSubjectSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '2. Sélectionner des matières',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () => _showSubjectSelectionModal(),
                child: Text('Choisir des matières'),
              ),
              SizedBox(height: 15),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _subjects.map((subject) {
                  return Chip(
                    label: Text(subject['name'] ?? ''),
                    onDeleted: () {
                      setState(() {
                        _subjects.remove(subject);
                      });
                    },
                  );
                }).toList(),
              ),
              // ElevatedButton(
              //   onPressed: _addSubjectsToFirestore,
              //   child: Text('Ajouter Matières'),
              // ),
            ],
          ),
        ),
      ),
    ],
  );
}

void _showSubjectSelectionModal() {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      final availableSubjects = _classSubjects[_selectedClassName] ?? [];
      final selectedSubjects = Set<String>.from(
        _subjects.map((subject) => subject['name']!),
      );

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélectionnez les matières',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableSubjects.length,
                    itemBuilder: (context, index) {
                      final subject = availableSubjects[index];
                      return CheckboxListTile(
                        title: Text(subject),
                        value: selectedSubjects.contains(subject),
                        onChanged: (isChecked) {
                          setModalState(() {
                            if (isChecked == true) {
                              selectedSubjects.add(subject);
                            } else {
                              selectedSubjects.remove(subject);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _subjects.clear();
                      _subjects.addAll(
                        selectedSubjects.map((subject) => {'name': subject}),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Confirmer'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _addSubjectsToFirestore() async {
  if (_currentClassId != null && _subjects.isNotEmpty) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final batch = FirebaseFirestore.instance.batch();

      for (var subject in _subjects) {
        final subjectRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('classes')
            .doc(_currentClassId)
            .collection('subjects')
            .doc();
        batch.set(subjectRef, {'name': subject['name']});
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Matières ajoutées avec succès !')),
      );
    }
  }
}

Widget _buildAddStudentSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '3. Ajouter un élève',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Section to show added students
              if (_students.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Élèves ajoutés:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ..._students.map((student) {
                      return ListTile(
                        title: Text(student['name']!),
                      );
                    }).toList(),
                  ],
                ),
              SizedBox(height: 15),
              TextField(
                controller: _studentNameController,
                decoration: InputDecoration(
                  labelText: 'Nom de l\'élève',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: _addStudent,
                child: Text('Ajouter Élève'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

}
