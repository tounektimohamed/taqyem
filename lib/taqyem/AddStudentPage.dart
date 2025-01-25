import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageClassesPage extends StatefulWidget {
  @override
  _ManageClassesPageState createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = []; // Liste des matières disponibles

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _fetchClasses();
    }
  }

  String? _selectedSubject; // Variable pour stocker la matière sélectionnée
Future<void> _addSubjectDialog(Map<String, dynamic> classData) async {
  await _loadSubjects(classData['class_id']); // Utilisez class_id pour charger les matières

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Ajouter une matière'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
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
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_selectedSubject != null) {
              await _addSubjectToClass(classData, _selectedSubject!);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Veuillez sélectionner une matière')));
            }
          },
          child: Text('Ajouter'),
        ),
      ],
    ),
  );
}
  Future<void> _addSubjectToClass(
    Map<String, dynamic> classData, String subjectName) async {
  try {
    List<String> updatedSubjects = List.from(classData['subjects']);
    if (!updatedSubjects.contains(subjectName)) {
      updatedSubjects.add(subjectName);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id']) // Utilisez l'ID du document dans user_classes
          .update({
        'subjects': updatedSubjects,
      });

      setState(() {
        classData['subjects'] = updatedSubjects;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Matière ajoutée avec succès')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cette matière est déjà dans la classe')));
    }
  } catch (e) {
    print("Erreur lors de l'ajout de la matière : $e");
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de la matière')));
  }
}
Future<void> _loadSubjects(String classId) async {
  try {
    final classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId) // Utilisez class_id pour accéder à la classe dans la collection classes
        .collection('matieres')
        .get();

    setState(() {
      _subjects = classDoc.docs.map((doc) {
        return {'id': doc.id, 'name': doc['name'] as String};
      }).toList();
    });
  } catch (e) {
    print("Erreur lors de la récupération des matières : $e");
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des matières')));
  }
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
          'id': doc.id, // ID du document dans user_classes
          'class_id': doc['class_id'], // ID de la classe dans la collection classes
          'class_name': doc['class_name'],
          'subjects': List<String>.from(doc['subjects']),
          'students': List<String>.from(doc['students']),
        };
      }).toList();
    });
  } catch (e) {
    print("Erreur lors du chargement des classes : $e");
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des classes')));
  }
}

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

  Future<void> _confirmDeleteClass(String classId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette classe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteClass(classId);
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(
      Map<String, dynamic> classData, String studentId) async {
    try {
      List<String> updatedStudents = List.from(classData['students']);
      updatedStudents.remove(studentId);

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

  Future<void> _confirmDeleteStudent(
      Map<String, dynamic> classData, String studentId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer cet élève ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent(classData, studentId);
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

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

  Future<void> _confirmDeleteSubject(
      Map<String, dynamic> classData, String subject) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette matière ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSubject(classData, subject);
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudent(Map<String, dynamic> classData) async {
    TextEditingController studentNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un élève'),
        content: TextField(
          controller: studentNameController,
          decoration: InputDecoration(labelText: 'Nom de l\'élève'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Créer un nouvel élève dans la collection `students`
                final studentRef = await FirebaseFirestore.instance
                    .collection('students')
                    .add({
                  'name':
                      studentNameController.text, // Stocker le nom de l'élève
                });

                // Ajouter l'ID de l'élève à la classe
                List<String> updatedStudents = List.from(classData['students']);
                updatedStudents.add(studentRef.id);

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
                    SnackBar(content: Text('Élève ajouté avec succès')));
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

  // Future<void> _addSubject(Map<String, dynamic> classData) async {
  //   TextEditingController subjectController = TextEditingController();

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Ajouter une matière'),
  //       content: TextField(
  //         controller: subjectController,
  //         decoration: InputDecoration(labelText: 'Nom de la matière'),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text('Annuler'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             try {
  //               List<String> updatedSubjects = List.from(classData['subjects']);
  //               updatedSubjects.add(subjectController.text);

  //               await FirebaseFirestore.instance
  //                   .collection('users')
  //                   .doc(currentUser!.uid)
  //                   .collection('user_classes')
  //                   .doc(classData['id'])
  //                   .update({
  //                 'subjects': updatedSubjects,
  //               });

  //               Navigator.pop(context);
  //               ScaffoldMessenger.of(context)
  //                   .showSnackBar(SnackBar(content: Text('Matière ajoutée')));
  //               _fetchClasses();
  //             } catch (e) {
  //               print("Erreur lors de l'ajout de la matière : $e");
  //               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //                   content: Text('Erreur lors de l\'ajout de la matière')));
  //             }
  //           },
  //           child: Text('Ajouter'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _editStudent(
      Map<String, dynamic> classData, String studentId) async {
    TextEditingController studentNameController = TextEditingController();

    // Récupérer le nom actuel de l'élève
    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .get();

    if (studentDoc.exists) {
      studentNameController.text = studentDoc['name'];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le nom de l\'élève'),
        content: TextField(
          controller: studentNameController,
          decoration: InputDecoration(labelText: 'Nouveau nom de l\'élève'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Mettre à jour uniquement le nom de l'élève
                await FirebaseFirestore.instance
                    .collection('students')
                    .doc(studentId)
                    .update({
                  'name': studentNameController.text,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nom de l\'élève modifié')));
                _fetchClasses(); // Rafraîchir la liste des classes
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

  Future<String?> _getStudentName(String studentId) async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        return studentDoc['name'];
      }
      return null;
    } catch (e) {
      print("Erreur lors de la récupération du nom de l'élève : $e");
      return null;
    }
  }

  Widget _buildClassList() {
    return ListView.builder(
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        var classData = _classes[index];
        return ExpansionTile(
          title: Text(classData['class_name']),
          subtitle: Text(
              'Élèves: ${classData['students'].length} | Matières: ${classData['subjects'].length}'),
          children: [
            ...classData['subjects'].map<Widget>((subject) {
              return ListTile(
                title: Text(subject),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _confirmDeleteSubject(classData, subject),
                ),
              );
            }).toList(),
            ...classData['students'].map<Widget>((studentId) {
              return FutureBuilder<String?>(
                future: _getStudentName(studentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Chargement...'),
                    );
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return ListTile(
                      title: Text('Élève inconnu'),
                    );
                  } else {
                    return ListTile(
                      title: Text(snapshot.data!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editStudent(classData, studentId),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () =>
                                _confirmDeleteStudent(classData, studentId),
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            }).toList(),
            ListTile(
              title: Text('Ajouter une matière'),
              trailing: IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _addSubjectDialog(classData),
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
            onPressed: () => _confirmDeleteClass(classData['id']),
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
