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
  String? _selectedSubjectName; // Variable pour la matière sélectionnée
  final List<Map<String, String>> _subjects = [];
  final List<Map<String, String>> _students = [];

  final List<String> _classNames = [
    "السنة الأولى ابتدائي",
    "السنة الثانية ابتدائي",
    "السنة الثالثة ابتدائي",
    "السنة الرابعة ابتدائي",
    "السنة الخامسة ابتدائي",
    "السنة السادسة ابتدائي"
  ];

  // Matières associées à chaque classe
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

  // Logique pour ajouter une matière
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

  // Ajouter la classe
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
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Classe ajoutée avec succès !')),
      );
    }
  }

  // Logique pour ajouter un élève
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                '1. Sélectionner une classe',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedClassName,
                      items: _classNames.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClassName = value;
                          _selectedSubjectName = null; // Réinitialiser la matière
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Nom de la classe',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _addClass,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Ajouter Classe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color.fromARGB(255, 7, 82, 96),
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedClassName != null) ...[
              Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                child: Text(
                  '2. Sélectionner une matière',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedSubjectName,
                        items: _classSubjects[_selectedClassName]!
                            .map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubjectName = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Nom de la matière',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: _addSubject,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Ajouter Matière',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color.fromARGB(255, 7, 82, 96),
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Afficher la matière sélectionnée temporairement
                      if (_selectedSubjectName != null) 
                        Text(
                          'Matière sélectionnée : $_selectedSubjectName',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: Text(
                '3. Ajouter un élève',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _studentNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom de l\'élève',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _addStudent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Ajouter Élève',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color.fromARGB(255, 7, 82, 96),
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
