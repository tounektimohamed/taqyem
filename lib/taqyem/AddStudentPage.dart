import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageClassesPage extends StatefulWidget {
  @override
  _ManageClassesPageState createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _classes = []; // Liste des classes

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _fetchClasses(); // Charger les classes dès le départ
    }
  }

  // Charger les classes depuis Firestore
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
            'id': doc.id, // Utiliser l'ID du document pour référence interne
            'class_name': doc['class_name'], // Nom de la classe
            'subjects': List<String>.from(doc['subjects']), // Matières
            'students': List<String>.from(doc['students']), // Élèves
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des classes')));
    }
  }

  // Supprimer une classe
  Future<void> _deleteClass(String classId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .delete();

      setState(() {
        _classes.removeWhere((classData) => classData['id'] == classId);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Classe supprimée')));
    } catch (e) {
      print("Erreur lors de la suppression : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression de la classe')));
    }
  }

  // Supprimer un élève
  Future<void> _deleteStudent(
      Map<String, dynamic> classData, String student) async {
    try {
      List<String> updatedStudents = List.from(classData['students']);
      updatedStudents.remove(student);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id'])
          .update({
        'students': updatedStudents,
      });

      setState(() {
        classData['students'] = updatedStudents;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Élève supprimé')));
    } catch (e) {
      print("Erreur lors de la suppression de l'élève : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression de l\'élève')));
    }
  }

  // Supprimer une matière
  Future<void> _deleteSubject(
      Map<String, dynamic> classData, String subject) async {
    try {
      List<String> updatedSubjects = List.from(classData['subjects']);
      updatedSubjects.remove(subject);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id'])
          .update({
        'subjects': updatedSubjects,
      });

      setState(() {
        classData['subjects'] = updatedSubjects;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Matière supprimée')));
    } catch (e) {
      print("Erreur lors de la suppression de la matière : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression de la matière')));
    }
  }

  // Ajouter un élève
  Future<void> _addStudent(Map<String, dynamic> classData) async {
    TextEditingController studentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un élève'),
        content: TextField(
          controller: studentController,
          decoration: InputDecoration(labelText: 'Nom de l\'élève'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                List<String> updatedStudents = List.from(classData['students']);
                updatedStudents.add(studentController.text);

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(classData['id'])
                    .update({
                  'students': updatedStudents,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Élève ajouté')));
                _fetchClasses(); // Rafraîchir la liste des classes
              } catch (e) {
                print("Erreur lors de l'ajout de l'élève : $e");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur lors de l\'ajout de l\'élève')));
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // Ajouter une matière
  Future<void> _addSubject(Map<String, dynamic> classData) async {
    TextEditingController subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter une matière'),
        content: TextField(
          controller: subjectController,
          decoration: InputDecoration(labelText: 'Nom de la matière'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                List<String> updatedSubjects = List.from(classData['subjects']);
                updatedSubjects.add(subjectController.text);

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(classData['id'])
                    .update({
                  'subjects': updatedSubjects,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Matière ajoutée')));
                _fetchClasses(); // Rafraîchir la liste des classes
              } catch (e) {
                print("Erreur lors de l'ajout de la matière : $e");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur lors de l\'ajout de la matière')));
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // Modifier le nom d'un élève
  Future<void> _editStudent(
      Map<String, dynamic> classData, String oldStudentName) async {
    TextEditingController studentController =
        TextEditingController(text: oldStudentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le nom de l\'élève'),
        content: TextField(
          controller: studentController,
          decoration: InputDecoration(labelText: 'Nom de l\'élève'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                List<String> updatedStudents = List.from(classData['students']);
                int studentIndex = updatedStudents.indexOf(oldStudentName);
                if (studentIndex != -1) {
                  updatedStudents[studentIndex] = studentController.text;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .collection('user_classes')
                      .doc(classData['id'])
                      .update({
                    'students': updatedStudents,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Nom de l\'élève modifié')));
                  _fetchClasses(); // Rafraîchir la liste des classes
                }
              } catch (e) {
                print("Erreur lors de la modification de l'élève : $e");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Erreur lors de la modification de l\'élève')));
              }
            },
            child: Text('Modifier'),
          ),
        ],
      ),
    );
  }

  // Affichage des classes (seulement le nom et actions CRUD)
  Widget _buildClassList() {
    return ListView.builder(
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        var classData = _classes[index];
        return ExpansionTile(
          title: Text(classData['class_name']), // Affichage du nom de la classe
          subtitle: Text(
              'Élèves: ${classData['students'].length} | Matières: ${classData['subjects'].length}'), // Nombre d'élèves et de matières
          children: [
            ...classData['subjects'].map<Widget>((subject) {
              return ListTile(
                title: Text(subject), // Affichage de la matière
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteSubject(classData, subject),
                ),
              );
            }).toList(),
            ...classData['students'].map<Widget>((student) {
              return ListTile(
                title: Text(student), // Affichage de l'élève
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editStudent(
                          classData, student), // Modifier le nom de l'élève
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteStudent(
                          classData, student), // Supprimer l'élève
                    ),
                  ],
                ),
              );
            }).toList(),
            // Ajouter matière et élève
            ListTile(
              title: Text('Ajouter une matière'),
              trailing: IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _addSubject(classData),
              ),
            ),
            ListTile(
              title: Text('Ajouter un élève'),
              trailing: IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _addStudent(classData),
              ),
            ),
          ],
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteClass(classData['id']),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestion des classes')),
      body: _classes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _buildClassList(),
    );
  }
}
