import 'package:Taqyem/services2/AddClassPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:url_launcher/url_launcher.dart';

class ManageClassesPage extends StatefulWidget {
  @override
  _ManageClassesPageState createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;

//  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = []; // Liste des matières disponibles
  Uint8List? _imageBytes;
  String? _photoUrl;
  String? _selectedSubject; // Variable pour stocker la matière sélectionnée
  List<Map<String, String>> _selectedSubjects = []; // Stocke les ID et noms des matières sélectionnées
  // Ajoutez ces deux variables
  String? selectedClassId;
  String? selectedSubjectId;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _fetchClasses();
    }
  }

Future<String?> _getEvaluation({
  required String classId,
  required String studentId,
  required String baremeId,
}) async {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("Aucun utilisateur connecté");
    }

    // Référence au document de l'évaluation
    var docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('user_classes')
        .doc(classId)
        .collection('students')
        .doc(studentId)
        .collection('baremes')
        .doc(baremeId);

    // Récupérer le document
    var doc = await docRef.get();

    // Vérifier si le document existe et si le champ `value` existe
    if (doc.exists && doc.data()?.containsKey('value') == true) {
      return doc['value'] as String?; // Retourner la valeur du champ `value`
    }
    return null; // Retourner null si le document ou le champ `value` n'existe pas
  } catch (e) {
    print('Erreur lors de la récupération de l\'évaluation: $e');
    return null;
  }
}

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _addSubjectDialog(Map<String, dynamic> classData) async {
    await _loadSubjects(classData['class_id']);

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
                  value: subject['id'],
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
                var selectedSubject = _subjects
                    .firstWhere((subject) => subject['id'] == _selectedSubject);
                await _addSubjectToClass(classData, selectedSubject['name']!,
                    selectedSubject['id']!);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Veuillez sélectionner une matière')));
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSubjectToClass(Map<String, dynamic> classData,
      String subjectName, String subjectId) async {
    try {
      List<Map<String, String>> updatedSubjects =
          List.from(classData['subjects']);
      if (!updatedSubjects.any((subject) => subject['id'] == subjectId)) {
        updatedSubjects.add({'id': subjectId, 'name': subjectName});

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

  Future<void> _fetchClasses() async {
    try {
      final classDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .get();

      setState(() {
        _classes = classDocs.docs.map((doc) {
          // Convertir les sujets en List<Map<String, String>>
          List<Map<String, String>> subjects = [];
          if (doc['subjects'] != null) {
            subjects = (doc['subjects'] as List).map((subject) {
              return {
                'id': subject['id']
                    .toString(), // Assurez-vous que c'est une String
                'name': subject['name']
                    .toString(), // Assurez-vous que c'est une String
              };
            }).toList();
          }

          // Convertir les étudiants en List<String>
          List<String> students = [];
          if (doc['students'] != null) {
            students = (doc['students'] as List).map((student) {
              return student.toString(); // Assurez-vous que c'est une String
            }).toList();
          }

          return {
            'id': doc.id,
            'class_id':
                doc['class_id'].toString(), // Assurez-vous que c'est une String
            'class_name': doc['class_name']
                .toString(), // Assurez-vous que c'est une String
            'subjects': subjects,
            'students': students,
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des classes: $e')));
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
      // Étape 1 : Supprimer l'élève de la liste `students` dans le document de la classe
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

      // Étape 2 : Supprimer le document de l'élève dans la sous-collection `students`
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id'])
          .collection('students')
          .doc(studentId)
          .delete();

      // Mettre à jour l'état local
      setState(() {
        classData['students'] = updatedStudents;
      });

      // Afficher un message de succès
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Élève supprimé')));
    } catch (e) {
      // Gérer les erreurs
      print("Erreur lors de la suppression de l'élève : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression de l\'élève')),
      );
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
      Map<String, dynamic> classData, String subjectId) async {
    try {
      List<Map<String, String>> updatedSubjects =
          List.from(classData['subjects']);
      updatedSubjects.removeWhere((subject) => subject['id'] == subjectId);

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
      Map<String, dynamic> classData, String subjectId) async {
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
              _deleteSubject(classData, subjectId);
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
                final studentsCollection = FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(classData['id'])
                    .collection('students');

                final studentRef = await studentsCollection.add({
                  'name': studentNameController.text,
                  'parentName': '',
                  'parentPhone': '',
                  'birthDate': '',
                  'remarks': '',
                  'photoUrl': '',
                });

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
                _fetchClasses();
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

  Future<void> _editStudent(
      Map<String, dynamic> classData, String studentId) async {
    TextEditingController studentNameController = TextEditingController();

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
                await FirebaseFirestore.instance
                    .collection('students')
                    .doc(studentId)
                    .update({
                  'name': studentNameController.text,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nom de l\'élève modifié')));
                _fetchClasses();
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


Future<void> _saveEvaluation({
  required String classId,
  required String studentId,
  required String baremeId,
  required String? newValue,
}) async {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("Aucun utilisateur connecté");
    }

    // Référence au document de l'évaluation
    var docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('user_classes')
        .doc(classId)
        .collection('students')
        .doc(studentId)
        .collection('baremes')
        .doc(baremeId);

    // Sauvegarder la nouvelle valeur
    if (newValue != null) {
      await docRef.set({'value': newValue}, SetOptions(merge: true));
    } else {
      await docRef.update({'value': FieldValue.delete()}); // Supprimer le champ `value` si newValue est null
    }

    print('Évaluation sauvegardée avec succès pour le barème $baremeId');
  } catch (e) {
    print('Erreur lors de la sauvegarde de l\'évaluation: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la sauvegarde de l\'évaluation')),
    );
  }
}

//////////////////////////////////////////////////
Future<void> _showSelectionsDialog(String classId, String matiereId, String studentId) async {
  final List<String> evaluationOptions = ['( - - - )', '( + - - )', '( + + - )', '( + + + )'];
  final Map<String, Color> evaluationColors = {
    '( - - - )': Colors.red,
    '( + - - )': Colors.yellow,
    '( + + - )': Colors.orange,
    '( + + + )': Colors.green,
  };
  Color defaultColor = Colors.blue;

  try {
    CollectionReference selectionsRef = FirebaseFirestore.instance
        .collection('selections')
        .doc(classId)
        .collection(matiereId);

    var selectionsSnapshot = await selectionsRef.get();

    List<Map<String, dynamic>> selections = [];
    for (var doc in selectionsSnapshot.docs) {
      String? savedEvaluation = await _getEvaluation(
        classId: classId,
        studentId: studentId,
        baremeId: doc.id,
      );

      selections.add({
        'id': doc.id,
        'baremeId': doc['baremeId'],
        'baremeName': doc['baremeName'],
        'selectedAt': doc['selectedAt'],
        'evaluation': savedEvaluation ?? '( - - - )',
      });

      var sousBaremesRef = doc.reference.collection('sousBaremes');
      var sousBaremesSnapshot = await sousBaremesRef.get();
      List<Map<String, dynamic>> sousBaremes = [];
      for (var sousDoc in sousBaremesSnapshot.docs) {
        sousBaremes.add({
          'id': sousDoc.id,
          'sousBaremeName': sousDoc['sousBaremeName'],
          'selectedAt': sousDoc['selectedAt'],
        });
      }

      selections.last['sousBaremes'] = sousBaremes;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Récupérer la taille de l'écran
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 600; // Téléphone

          return AlertDialog(
            title: Text('Sélections associées'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Veuillez sélectionner une évaluation pour chaque barème.',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                  Divider(),
                  ...selections.map((selection) {
                    String selectedEvaluation = selection['evaluation'];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selection['baremeName'] ?? 'Sans nom',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            // Afficher les options d'évaluation en ligne ou en colonne selon la taille de l'écran
                            isSmallScreen
                                ? Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: evaluationOptions.map((value) {
                                      return _buildEvaluationButton(
                                        value: value,
                                        isSelected: selection['evaluation'] == value,
                                        color: evaluationColors[value] ?? defaultColor,
                                        onTap: () {
                                          setState(() {
                                            selection['evaluation'] = value;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  )
                                : Row(
                                    children: evaluationOptions.map((value) {
                                      return _buildEvaluationButton(
                                        value: value,
                                        isSelected: selection['evaluation'] == value,
                                        color: evaluationColors[value] ?? defaultColor,
                                        onTap: () {
                                          setState(() {
                                            selection['evaluation'] = value;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                          ],
                        ),
                        children: (selection['sousBaremes'] as List<Map<String, dynamic>>)
                            .map((sousBareme) => ListTile(
                                  title: Text(
                                    sousBareme['sousBaremeName'] ?? 'Sans nom',
                                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                                  ),
                                  subtitle: Text(
                                    'ID: ${sousBareme['id']}',
                                    style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Confirmer'),
                      content: Text('Êtes-vous sûr de vouloir enregistrer ces évaluations ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Non'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Oui'),
                        ),
                      ],
                    ),
                  );

                  if (confirm) {
                    for (var selection in selections) {
                      await _saveEvaluation(
                        classId: classId,
                        studentId: studentId,
                        baremeId: selection['baremeId'],
                        newValue: selection['evaluation'],
                      );
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Évaluations enregistrées avec succès!')),
                    );

                    Navigator.pop(context);
                  }
                },
                child: Text('Évaluer'),
              ),
            ],
          );
        },
      ),
    );
  } catch (e) {
    print('Erreur lors du chargement des sélections: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors du chargement des sélections')),
    );
  }
}

// Widget pour construire un bouton d'évaluation
Widget _buildEvaluationButton({
  required String value,
  required bool isSelected,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontSize: 14,
        ),
      ),
    ),
  );
}
/////////////////////////////////////////////////////////////////////////////
  Widget _buildClassList() {
    return ListView.builder(
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        var classData = _classes[index];
        return ExpansionTile(
          title: Text(classData['class_name']),
          subtitle: Text(
              'Élèves: ${classData['students'].length} | Matières: ${classData['subjects'].length}'),
          onExpansionChanged: (expanded) {
            if (expanded) {
              setState(() {
                selectedClassId = classData['class_id'];
                selectedSubjectId =
                    null; // Réinitialiser la sélection de la matière
              });

              String message = "ID de la classe : ${classData['class_id']}\n";
              message += "Matières :\n";
              for (var subject in classData['subjects']) {
                message += "- ${subject['name']} (ID: ${subject['id']})\n";
              }

              // showDialog(
              //   context: context,
              //   builder: (context) => AlertDialog(
              //     title: Text("Détails de la classe"),
              //     content: Text(message),
              //     actions: [
              //       TextButton(
              //         onPressed: () => Navigator.pop(context),
              //         child: Text("Fermer"),
              //       ),
              //     ],
              //   ),
              // );
            }
          },
          children: [
            ...classData['subjects'].map<Widget>((subject) {
              return ListTile(
                title: Text(subject['name']),
                tileColor: selectedSubjectId == subject['id']
                    ? const Color.fromARGB(255, 0, 255, 8)
                    : null, // Colorer en vert si sélectionné
                leading: selectedSubjectId == subject['id']
                    ? Icon(Icons.check_box,
                        color: Color.fromARGB(
                            255, 226, 107, 9)) // Icône de sélection
                    : Icon(Icons.check_box_outline_blank,
                        color: Colors.grey), // Icône non sélectionnée
                onTap: () {
                  setState(() {
                    selectedSubjectId = subject['id'];
                  });
                  print("ID de la classe : ${classData['class_id']}");
                  print("ID de la matière sélectionnée : ${subject['id']}");
                },
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () =>
                      _confirmDeleteSubject(classData, subject['id']),
                ),
              );
            }).toList(),
            ...classData['students'].map<Widget>((studentId) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(classData['id'])
                    .collection('students')
                    .doc(studentId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Chargement...'),
                    );
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return ListTile(
                      title: Text('Élève inconnu'),
                    );
                  } else {
                    final studentData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final photoUrl = studentData['photoUrl'];
                    final parentPhone = studentData['parentPhone'];
                    final birthDate = studentData['birthDate'];

                    return ListTile(
                      leading: photoUrl != null && photoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              placeholder: (context, url) => CircleAvatar(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) {
                                print(
                                    'Erreur de chargement de l\'image: $error');
                                return CircleAvatar(
                                  child: Icon(Icons.error),
                                );
                              },
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                backgroundImage: imageProvider,
                              ),
                            )
                          : CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                      title: Text(studentData['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Parent: ${studentData['parentName']}'),
                          Text(
                              'Date de naissance: ${birthDate ?? "Non renseignée"}'),
                          if (parentPhone != null && parentPhone.isNotEmpty)
                            Text('Téléphone: $parentPhone'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                _showStudentDetails(classData, studentId),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () =>
                                _confirmDeleteStudent(classData, studentId),
                          ),
                          if (parentPhone != null && parentPhone.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.phone),
                              onPressed: () async {
                                final url = 'tel:$parentPhone';
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Impossible de passer un appel')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                      onTap: () {
                          print("ID de l'élève sélectionné : $studentId");

                        if (selectedClassId != null &&
                            selectedSubjectId != null) {
                          _showSelectionsDialog(
                              selectedClassId!, selectedSubjectId!,studentId!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Veuillez sélectionner une classe et une matière")),
                          );
                        }
                      },
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

  Future<void> _showStudentDetails(
      Map<String, dynamic> classData, String studentId) async {
    TextEditingController parentNameController = TextEditingController();
    TextEditingController parentPhoneController = TextEditingController();
    TextEditingController birthDateController = TextEditingController();
    TextEditingController remarksController = TextEditingController();

    final studentsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('user_classes')
        .doc(classData['id'])
        .collection('students');

    final studentDoc = await studentsCollection.doc(studentId).get();

    if (studentDoc.exists) {
      parentNameController.text = studentDoc.get('parentName') ?? '';
      parentPhoneController.text = studentDoc.get('parentPhone') ?? '';
      birthDateController.text = studentDoc.get('birthDate') ?? '';
      remarksController.text = studentDoc.get('remarks') ?? '';
      _photoUrl = studentDoc.get('photoUrl') ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de l\'élève'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_imageBytes != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: MemoryImage(_imageBytes!),
                )
              else if (_photoUrl != null && _photoUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: _photoUrl!,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 50,
                    backgroundImage: imageProvider,
                  ),
                )
              else
                CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: Text('Prendre une photo'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: Text('Choisir une photo'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: parentNameController,
                decoration: InputDecoration(labelText: 'Nom du parent'),
              ),
              TextField(
                controller: parentPhoneController,
                decoration: InputDecoration(labelText: 'Numéro du parent'),
              ),
              TextField(
                controller: birthDateController,
                decoration: InputDecoration(labelText: 'Date de naissance'),
              ),
              TextField(
                controller: remarksController,
                decoration: InputDecoration(labelText: 'Remarques'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                String? photoUrl = _photoUrl;

                if (_imageBytes != null) {
                  final storageRef = FirebaseStorage.instance.ref().child(
                      'students/${currentUser!.uid}/${classData['id']}/$studentId.jpg');

                  await storageRef.putData(_imageBytes!);
                  photoUrl = await storageRef.getDownloadURL();
                }

                await studentsCollection.doc(studentId).update({
                  'parentName': parentNameController.text,
                  'parentPhone': parentPhoneController.text,
                  'birthDate': birthDateController.text,
                  'remarks': remarksController.text,
                  'photoUrl': photoUrl ?? '',
                });

                setState(() {
                  _photoUrl = photoUrl;
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Informations mises à jour')),
                );

                await _fetchClasses();
              } catch (e) {
                print("Erreur lors de la mise à jour des informations : $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Erreur lors de la mise à jour des informations')),
                );
              }
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Gestion des classes')),
    body: _classes.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Aucune classe trouvée.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  'Vous devez ajouter une classe dans l\'onglet "Ajouter une classe".',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Naviguer vers AddClassPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddClassPage(),
                      ),
                    );
                  },
                  child: Text('Ajouter une classe'),
                ),
              ],
            ),
          )
        : _buildClassList(),
  );
}
}
