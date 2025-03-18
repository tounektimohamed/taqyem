import 'package:Taqyem/taqyem/AddClassPage.dart';
import 'package:Taqyem/taqyem/selectionPage.dart';
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
  List<Map<String, String>> _selectedSubjects =
      []; // Stocke les ID et noms des matières sélectionnées
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
    String? sousBaremeId, // Nouveau paramètre pour l'ID du sous-barème
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Aucun utilisateur connecté");
      }

      // Construire la référence de base du document
      var docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeId);

      // Si sousBaremeId est fourni, ajuster la référence à la sous-collection des sous-barèmes
      if (sousBaremeId != null) {
        docRef = docRef.collection('sous_baremes').doc(sousBaremeId);
      }

      // Récupérer le document
      var doc = await docRef.get();

      // Vérifier si le document existe et si le champ `value` existe
      if (doc.exists && doc.data()?.containsKey('Marks') == true) {
        return doc['Marks'] as String?; // Retourner la valeur du champ `value`
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
      final classDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId);

      // Supprimer la sous-collection "students"
      final studentsSnapshot = await classDocRef.collection('students').get();
      for (var studentDoc in studentsSnapshot.docs) {
        await studentDoc.reference.delete();
      }

      // Supprimer la sous-collection "subjects"
      final subjectsSnapshot = await classDocRef.collection('subjects').get();
      for (var subjectDoc in subjectsSnapshot.docs) {
        await subjectDoc.reference.delete();
      }

      // Supprimer le document de la classe
      await classDocRef.delete();

      // Mettre à jour l'état local
      setState(() {
        _classes.removeWhere((classData) => classData['id'] == classId);
      });

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classe et ses données supprimées')));
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
        content: Text(
            'Êtes-vous sûr de vouloir supprimer cette classe et toutes ses données associées (élèves et matières) ?'),
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
    String? sousBaremeId,
  }) async {
    try {
      // Vérifier si un utilisateur est connecté
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Aucun utilisateur connecté");

      // Référence à la collection baremes
      var baremesCollectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes');

      // Référence au document du barème principal
      var baremeRef = baremesCollectionRef.doc(baremeId);

      // Vérifier si le barème principal existe
      final baremeDoc = await baremeRef.get();

      // Si le document n'existe pas, le créer avec les champs de base
      if (!baremeDoc.exists) {
        await baremeRef.set({
          'createdAt': FieldValue.serverTimestamp(),
          'haveSoubarem':
              sousBaremeId != null, // Indique si des sous-barèmes existent
        });
        print("Document parent créé pour le barème $baremeId");
      }

      // Sauvegarder la valeur dans le barème principal ou le sous-barème
      if (sousBaremeId != null) {
        // Créer ou mettre à jour le sous-barème directement dans la collection baremes
        var sousBaremeDirectRef = baremesCollectionRef.doc(sousBaremeId);
        if (newValue != null) {
          await sousBaremeDirectRef
              .set({'Marks': newValue}, SetOptions(merge: true));
        } else {
          await sousBaremeDirectRef.update({'Marks': FieldValue.delete()});
        }

        // Créer ou mettre à jour le sous-barème dans la collection sous_baremes du barème principal
        var sousBaremeNestedRef =
            baremeRef.collection('sous_baremes').doc(sousBaremeId);
        if (newValue != null) {
          await sousBaremeNestedRef
              .set({'Marks': newValue}, SetOptions(merge: true));
        } else {
          await sousBaremeNestedRef.update({'Marks': FieldValue.delete()});
        }

        // Mettre à jour haveSoubarem dans le barème principal
        await baremeRef.update({'haveSoubarem': true});

        print('Sauvegarde réussie pour le sous-barème $sousBaremeId');
      } else {
        // Sauvegarder dans le barème principal
        if (newValue != null) {
          await baremeRef.set({'Marks': newValue}, SetOptions(merge: true));
        } else {
          await baremeRef.update({'Marks': FieldValue.delete()});
        }
        print('Sauvegarde réussie pour le barème $baremeId');
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );
    }
  }

  Future<void> _showSelectionsDialog(
      String classId, String matiereId, String studentId) async {
    final List<String> evaluationOptions = [
      '( - - - )',
      '( + - - )',
      '( + + - )',
      '( + + + )'
    ];
    final Map<String, Color> evaluationColors = {
      '( - - - )': Colors.red,
      '( + - - )': Colors.orange,
      '( + + - )': Colors.amber,
      '( + + + )': Colors.green,
    };

    try {
      CollectionReference selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(matiereId);

      var selectionsSnapshot = await selectionsRef.get();

      List<Map<String, dynamic>> selections = [];
      for (var doc in selectionsSnapshot.docs) {
        var sousBaremesRef = doc.reference.collection('sousBaremes');
        var sousBaremesSnapshot = await sousBaremesRef.get();
        List<Map<String, dynamic>> sousBaremes = [];

        for (var sousDoc in sousBaremesSnapshot.docs) {
          String? savedEvaluation = await _getEvaluation(
            classId: classId,
            studentId: studentId,
            baremeId: doc.id,
            sousBaremeId: sousDoc.id,
          );

          sousBaremes.add({
            'id': sousDoc.id,
            'sousBaremeName': sousDoc['sousBaremeName'],
            'evaluation': savedEvaluation ?? '( - - - )',
          });
        }

        String? savedEvaluation = sousBaremes.isEmpty
            ? await _getEvaluation(
                classId: classId, studentId: studentId, baremeId: doc.id)
            : null;

        selections.add({
          'id': doc.id,
          'baremeId': doc['baremeId'],
          'baremeName': doc['baremeName'],
          'evaluation': savedEvaluation ?? '( - - - )',
          'sousBaremes': sousBaremes,
        });
      }

      if (selections.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('لا توجد معايير محددة'),
            content: Text('لإجراء التقييم، يجب عليك أولاً برمجة معيار للتقييم'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectionPage(),
                    ),
                  );
                },
                child: Text('اذهب إلى صفحة الاختيار'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تقييم المعايير',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Divider(),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: selections.map((selection) {
                              bool hasSousBaremes =
                                  (selection['sousBaremes'] as List).isNotEmpty;
                              return Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        title: Text(
                                          selection['baremeName'] ?? 'بدون اسم',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        leading: Icon(Icons.assignment,
                                            color: Colors.blue),
                                        trailing: hasSousBaremes
                                            ? Icon(Icons.expand_more)
                                            : null,
                                      ),
                                      if (hasSousBaremes)
                                        Column(
                                          children: (selection['sousBaremes']
                                                  as List<Map<String, dynamic>>)
                                              .map((sousBareme) {
                                            return _buildSousBaremeCard(
                                                sousBareme,
                                                setState,
                                                evaluationOptions,
                                                evaluationColors);
                                          }).toList(),
                                        )
                                      else
                                        _buildEvaluationButtons(
                                          evaluationOptions,
                                          evaluationColors,
                                          selection['evaluation'],
                                          (newValue) {
                                            setState(() {
                                              selection['evaluation'] =
                                                  newValue;
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('إلغاء',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 16)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              bool confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('تأكيد'),
                                  content: Text(
                                      'هل أنت متأكد أنك تريد حفظ هذه التقييمات؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text('لا'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text('نعم'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm) {
                                for (var selection in selections) {
                                  if ((selection['sousBaremes'] as List)
                                      .isNotEmpty) {
                                    for (var sousBareme
                                        in selection['sousBaremes']) {
                                      await _saveEvaluation(
                                        classId: classId,
                                        studentId: studentId,
                                        baremeId: selection['baremeId'],
                                        sousBaremeId: sousBareme['id'],
                                        newValue: sousBareme['evaluation'],
                                      );
                                    }
                                  } else {
                                    await _saveEvaluation(
                                      classId: classId,
                                      studentId: studentId,
                                      baremeId: selection['baremeId'],
                                      newValue: selection['evaluation'],
                                    );
                                  }
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('تم حفظ التقييمات بنجاح!')),
                                );
                                Navigator.pop(context);
                              }
                            },
                            icon: Icon(Icons.save),
                            label: Text('تقييم'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      print('Erreur lors du chargement des sélections: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل التقييمات')),
      );
    }
  }

  Widget _buildEvaluationButtons(List<String> options,
      Map<String, Color> colors, String selectedValue, Function(String) onTap) {
    return Wrap(
      spacing: 8,
      children: options.map((Marks) {
        return GestureDetector(
          onTap: () => onTap(Marks),
          child: Chip(
            label: Text(Marks,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: colors[Marks] ?? Colors.blue,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            side: BorderSide(
              color: selectedValue == Marks ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSousBaremeCard(Map<String, dynamic> sousBareme,
      Function setState, List<String> options, Map<String, Color> colors) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: ListTile(
        title: Text(sousBareme['sousBaremeName'] ?? 'Sans nom'),
        subtitle: _buildEvaluationButtons(
          options,
          colors,
          sousBareme['evaluation'],
          (Marks) {
            setState(() {
              sousBareme['evaluation'] = Marks;
            });
          },
        ),
      ),
    );
  }

// Widget pour construire un bouton d'évaluation
  Widget _buildEvaluationButton({
    required String Marks,
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
          Marks,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<Color> _getStudentIndicatorColor(
      String classId, String studentId, String? subjectId) async {
    if (subjectId == null) return Colors.red;

    try {
      final selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(subjectId);

      final selectionsSnapshot = await selectionsRef.get();
      if (selectionsSnapshot.docs.isEmpty) return Colors.red;

      int total = 0;
      int evaluated = 0;

      for (var baremeDoc in selectionsSnapshot.docs) {
        final baremeId = baremeDoc.id;
        final hasSousBaremes = baremeDoc['haveSoubarem'] ?? false;

        if (hasSousBaremes) {
          final sousBaremesSnapshot =
              await baremeDoc.reference.collection('sousBaremes').get();
          total += sousBaremesSnapshot.size;

          for (var sousDoc in sousBaremesSnapshot.docs) {
            final eval = await _getEvaluation(
              classId: classId,
              studentId: studentId,
              baremeId: baremeId,
              sousBaremeId: sousDoc.id,
            );
            if (eval != null && eval != '( - - - )') evaluated++;
          }
        } else {
          total++;
          final eval = await _getEvaluation(
            classId: classId,
            studentId: studentId,
            baremeId: baremeId,
          );
          if (eval != null && eval != '( - - - )') evaluated++;
        }
      }

      if (evaluated == 0) return Colors.red;
      return evaluated == total ? Colors.green : Colors.orange;
    } catch (e) {
      print('Error getting indicator color: $e');
      return Colors.red;
    }
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
                              selectedClassId!, selectedSubjectId!, studentId!);
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
      appBar: AppBar(
        title: Text(
          'Gestion des classes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        elevation: 4,
      ),
      body: _classes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.class_,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 20),
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
          : Column(
              children: [
                // Affichage du message en haut si la liste n'est pas vide
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(230, 245, 255, 1),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color.fromRGBO(7, 82, 96, 1),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'هذه الصفحة تمكنك من اسناد العلامات للتلاميذ الموجودون في القسم حسب المواد',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'اختر القسم ثم اضغط على المادة المعنية حتى تضهر باللون الأخضر ثم قم بالضغط على اسم التلميذ المراد اسناد الاعداد له',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Liste des classes
                Expanded(child: _buildClassList()),
              ],
            ),
    );
  }
}
