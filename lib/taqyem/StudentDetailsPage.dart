import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageStudentGradesPage extends StatefulWidget {
  @override
  _ManageStudentGradesPageState createState() =>
      _ManageStudentGradesPageState();
}

class _ManageStudentGradesPageState extends State<ManageStudentGradesPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedClassId;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final classDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .get();

      setState(() {
        _classes = classDocs.docs.map((doc) {
          return {
            'id': doc.id,
            'class_id': doc['class_id'],
            'class_name': doc['class_name'],
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des classes')),
      );
    }
  }

  Future<void> _fetchStudents(String classId) async {
    try {
      final studentDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .get();

      final studentsWithGrades =
          await Future.wait(studentDocs.docs.map((doc) async {
        final grades = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classId)
            .collection('students')
            .doc(doc.id)
            .collection('grades')
            .get();

        return {
          'id': doc.id,
          'name': doc['name'],
          'parentName': doc['parentName'],
          'birthDate': doc['birthDate'],
          'grades': grades.docs.map((gradeDoc) => gradeDoc['subject']).toList(),
        };
      }));

      setState(() {
        _students = studentsWithGrades;
      });
    } catch (e) {
      print("Erreur lors du chargement des élèves : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des élèves')),
      );
    }
  }

  Future<void> _fetchSubjects(String classId) async {
    try {
      final subjectDocs = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('matieres')
          .get();

      setState(() {
        _subjects = subjectDocs.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des matières : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des matières')),
      );
    }
  }

  Future<void> _assignGrade(
      String studentId, String subject, double grade) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(_selectedClassId)
          .collection('students')
          .doc(studentId)
          .collection('grades')
          .add({
        'subject': subject,
        'grade': grade,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note attribuée avec succès')),
      );

      _fetchStudents(_selectedClassId!);
    } catch (e) {
      print("Erreur lors de l'attribution de la note : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'attribution de la note')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des notes'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: _classes.isEmpty
                ? Center(
                    child: Text(
                      'Aucune classe disponible',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _classes.length,
                    itemBuilder: (context, index) {
                      final classData = _classes[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: ListTile(
                          title: Text(
                            classData['class_name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            
                            setState(() {
                              _selectedClassId = classData['id'];
                              _selectedSubject = null;
                            });
                            _fetchStudents(classData['id']);
                            _fetchSubjects(classData['class_id']);
                          },
                        ),
                      );
                    },
                  ),
          ),
          if (_selectedClassId != null)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: DropdownButton<String>(
                      value: _selectedSubject,
                      hint: Text('Sélectionnez une matière'),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSubject = newValue;
                        });
                      },
                      items: _subjects.map<DropdownMenuItem<String>>((subject) {
                        return DropdownMenuItem<String>(
                          value: subject['name'],
                          child: Text(subject['name']),
                        );
                      }).toList(),
                      isExpanded: true,
                    ),
                  ),
                  Expanded(
                    child: _students.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun élève dans cette classe',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final isEvaluated = _selectedSubject != null &&
                                  student['grades'].contains(_selectedSubject);

                              return Card(
                                margin: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                child: ListTile(
                                  title: Text(
                                    student['name'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle:
                                      Text('Parent: ${student['parentName']}'),
                                  trailing: Icon(
                                    isEvaluated
                                        ? Icons.check_circle
                                        : Icons.circle,
                                    color: isEvaluated
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onTap: () {
                                    if (_selectedSubject != null) {
                                      _showGradeDialog(
                                          student['id'], _selectedSubject!);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showGradeDialog(String studentId, String subject) async {
    TextEditingController gradeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attribuer une note'),
        content: TextField(
          controller: gradeController,
          decoration: InputDecoration(labelText: 'Note (sur 20)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final grade = double.tryParse(gradeController.text);
              if (grade != null && grade >= 0 && grade <= 20) {
                _assignGrade(studentId, subject, grade);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Veuillez entrer une note valide (0-20)')),
                );
              }
            },
            child: Text('Valider'),
          ),
        ],
      ),
    );
  }
}