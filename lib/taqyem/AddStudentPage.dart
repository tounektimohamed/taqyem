import 'package:Taqyem/screens2/admin/AccessLogsPage.dart';
import 'package:Taqyem/taqyem/AddClassPage.dart';
import 'package:Taqyem/taqyem/SubjectHelper.dart';
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
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  Uint8List? _imageBytes;
  String? _photoUrl;
  String? _selectedSubject;
  List<Map<String, String>> _selectedSubjects = [];
  String? selectedClassId;
  String? selectedSubjectId;
  Map<String, dynamic>? _selectedClass;
  List<Map<String, dynamic>> _students = [];
  bool _showStudentsList = false;
final Map<String, String> subjectImages = {
  'التواصل الشفوي': 'assets/images/oral.png',
  'قراءة': 'assets/images/reading.png',
  'انتاج كتابي': 'assets/images/writing.png',
  'قواعد لغة': 'assets/images/grammar.png',
  'رياضيات': 'assets/images/math.png',
  'ايقاظ علمي': 'assets/images/science.png',
  'تربية اسلامية': 'assets/images/islamic.png',
  'تربية تكنولوجية': 'assets/images/technology.png',
  'تربية موسيقية': 'assets/images/music.png',
  'تربية تشكيلية': 'assets/images/art.png',
  'تربية بدنية': 'assets/images/sport.png',
  'التاريخ': 'assets/images/history.png',
  'الجغرافيا': 'assets/images/geography.png',
  'التربية المدنية': 'assets/images/civics.png',
  'Expression orale et récitation': 'assets/images/french_oral.png',
  'Lecture': 'assets/images/french_reading.png',
  'Production écrite': 'assets/images/french_writing.png',
  'écriture': 'assets/images/french_writing2.png',
  'dictée': 'assets/images/dictation.png',
  'langue': 'assets/images/french_language.png',
  'لغة انقليزية': 'assets/images/english.png',
};
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
    String? sousBaremeId,
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Aucun utilisateur connecté");
      }

      var docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeId);

      if (sousBaremeId != null) {
        docRef = docRef.collection('sous_baremes').doc(sousBaremeId);
      }

      var doc = await docRef.get();

      if (doc.exists && doc.data()?.containsKey('Marks') == true) {
        return doc['Marks'] as String?;
      }
      return null;
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
              'name': doc['name'] as String,
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
          List<Map<String, String>> subjects = [];
          if (doc['subjects'] != null) {
            subjects = (doc['subjects'] as List).map((subject) {
              return {
                'id': subject['id'].toString(),
                'name': subject['name'].toString(),
              };
            }).toList();
          }

          List<String> students = [];
          if (doc['students'] != null) {
            students = (doc['students'] as List).map((student) {
              return student.toString();
            }).toList();
          }

          return {
            'id': doc.id,
            'class_id': doc['class_id'].toString(),
            'class_name': doc['class_name'].toString(),
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

      final studentsSnapshot = await classDocRef.collection('students').get();
      for (var studentDoc in studentsSnapshot.docs) {
        await studentDoc.reference.delete();
      }

      final subjectsSnapshot = await classDocRef.collection('subjects').get();
      for (var subjectDoc in subjectsSnapshot.docs) {
        await subjectDoc.reference.delete();
      }

      await classDocRef.delete();

      setState(() {
        _classes.removeWhere((classData) => classData['id'] == classId);
        if (_selectedClass != null && _selectedClass!['id'] == classId) {
          _selectedClass = null;
          _showStudentsList = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classe et ses données supprimées')));
    } catch (e) {
      print("Erreur lors de la suppression : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression de la classe')));
    }
  }

  Future<void> _confirmDeleteClass(String classId) async {
    final classData =
        _classes.firstWhere((classData) => classData['id'] == classId);

    if (classData['students'].isNotEmpty) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Supprimer tous les élèves'),
          content: Text(
              'Cette classe contient des élèves. Voulez-vous d\'abord supprimer tous les élèves avant de supprimer la classe ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAllStudents(classData);
                await _deleteClass(classId);
              },
              child:
                  Text('Supprimer tout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      await _deleteClass(classId);
    }
  }

  Future<void> _deleteAllStudents(Map<String, dynamic> classData) async {
    try {
      final classDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id']);

      final studentsSnapshot = await classDocRef.collection('students').get();
      for (var studentDoc in studentsSnapshot.docs) {
        await studentDoc.reference.delete();
      }

      await classDocRef.update({
        'students': [],
      });

      setState(() {
        classData['students'].clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tous les élèves ont été supprimés')));
    } catch (e) {
      print("Erreur lors de la suppression des élèves : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression des élèves')));
    }
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id'])
          .collection('students')
          .doc(studentId)
          .delete();

      setState(() {
        classData['students'] = updatedStudents;
        _students.removeWhere((student) => student['id'] == studentId);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Élève supprimé')));
    } catch (e) {
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

  Future<void> _saveEvaluation({
    required String classId,
    required String studentId,
    required String baremeId,
    required String? newValue,
    String? sousBaremeId,
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Aucun utilisateur connecté");

      var baremesCollectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes');

      var baremeRef = baremesCollectionRef.doc(baremeId);

      // Utiliser un batch pour les opérations multiples
      WriteBatch batch = FirebaseFirestore.instance.batch();

      if (sousBaremeId != null) {
        // Supprimer le sous-barème dans la collection baremes
        var sousBaremeDirectRef = baremesCollectionRef.doc(sousBaremeId);
        batch.delete(sousBaremeDirectRef);

        // Supprimer le sous-barème dans la collection sous_baremes du barème principal
        var sousBaremeNestedRef =
            baremeRef.collection('sous_baremes').doc(sousBaremeId);
        batch.delete(sousBaremeNestedRef);
      } else {
        // Supprimer le barème principal
        batch.delete(baremeRef);
      }

      // Enregistrer la nouvelle évaluation
      if (newValue != null) {
        if (sousBaremeId != null) {
          // Enregistrer le sous-barème dans la collection baremes
          batch.set(baremesCollectionRef.doc(sousBaremeId), {
            'Marks': newValue,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Enregistrer le sous-barème dans la collection sous_baremes du barème principal
          batch.set(baremeRef.collection('sous_baremes').doc(sousBaremeId), {
            'Marks': newValue,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Mettre à jour haveSoubarem dans le barème principal
          batch.set(
              baremeRef,
              {
                'haveSoubarem': true,
                'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        } else {
          // Enregistrer le barème principal
          batch.set(
              baremeRef,
              {
                'Marks': newValue,
                'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        }
      }

      // Exécuter toutes les opérations en une seule transaction
      await batch.commit();

      print('Sauvegarde réussie pour le barème $baremeId');
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );
      rethrow;
    }
  }

  Future<void> _showSelectionsDialog(
      String classId, String matiereId, String studentId) async {
    // Afficher immédiatement un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
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

      CollectionReference selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(matiereId);

      var selectionsSnapshot = await selectionsRef.get();

      List<Map<String, dynamic>> selections = [];

      // Charger les données en parallèle pour améliorer les performances
      await Future.wait(selectionsSnapshot.docs.map((doc) async {
        var sousBaremesRef = doc.reference.collection('sousBaremes');
        var sousBaremesSnapshot = await sousBaremesRef.get();
        List<Map<String, dynamic>> sousBaremes = [];

        await Future.wait(sousBaremesSnapshot.docs.map((sousDoc) async {
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
        }));

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
      }));

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

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
        // Afficher le dialogue d'évaluation
        await showDialog(
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
                                // Afficher un indicateur pendant la sauvegarde
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                await Future.wait(
                                    selections.map((selection) async {
                                  if ((selection['sousBaremes'] as List)
                                      .isNotEmpty) {
                                    await Future.wait(
                                        (selection['sousBaremes'] as List)
                                            .map((sousBareme) async {
                                      await _saveEvaluation(
                                        classId: classId,
                                        studentId: studentId,
                                        baremeId: selection['baremeId'],
                                        sousBaremeId: sousBareme['id'],
                                        newValue: sousBareme['evaluation'],
                                      );
                                    }));
                                  } else {
                                    await _saveEvaluation(
                                      classId: classId,
                                      studentId: studentId,
                                      baremeId: selection['baremeId'],
                                      newValue: selection['evaluation'],
                                    );
                                  }
                                }));

                                Navigator.of(context)
                                    .pop(); // Fermer l'indicateur
                                Navigator.of(context)
                                    .pop(); // Fermer le dialogue

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('تم حفظ التقييمات بنجاح!')),
                                );
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
      Navigator.of(context).pop(); // Fermer le dialogue en cas d'erreur
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

      // Vérifier rapidement si l'élève a des évaluations
      final evaluationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .where('Marks', isNotEqualTo: '( - - - )')
          .limit(1)
          .get();

      return evaluationsSnapshot.docs.isEmpty ? Colors.red : Colors.green;
    } catch (e) {
      print('Error getting indicator color: $e');
      return Colors.red;
    }
  }

  Widget _buildClassList() {
    if (_selectedClass == null) {
      return ListView.builder(
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          var classData = _classes[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(classData['class_name']),
              subtitle: Text(
                  'Élèves: ${classData['students'].length} | Matières: ${classData['subjects'].length}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    child: Row(
                      children: [
                        Text(
                          'Ajouter élève',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.add,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                    onPressed: () => _addStudent(classData),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _confirmDeleteClass(classData['id']),
                  ),
                ],
              ),
              onTap: () async {
                setState(() {
                  _selectedClass = classData;
                  selectedClassId = classData['class_id'];
                  _showStudentsList = false;
                });
              },
            ),
          );
        },
      );
    } else {
      return Column(
        children: [
          AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedClass = null;
                  _showStudentsList = false;
                });
              },
            ),
            title: Text(_selectedClass!['class_name']),
            actions: [
              IconButton(
                icon: Icon(Icons.add),
                
                onPressed: () => _addSubjectDialog(_selectedClass!),
              ),
            ],
          ),
          if (!_showStudentsList) _buildSubjectsGrid(),
          if (_showStudentsList) _buildStudentsList(),
        ],
      );
    }
  }

  Widget _buildSubjectsGrid() {
  return Expanded(
    child: GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 colonnes
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9, // Format légèrement rectangulaire
      ),
      itemCount: _selectedClass!['subjects'].length,
      itemBuilder: (context, index) {
        var subject = _selectedClass!['subjects'][index];
        final subjectName = subject['name'];
        final icon = SubjectHelper.getIconForSubject(subjectName);
        final color = SubjectHelper.getSubjectColor(subjectName);
        
        return _buildSubjectGridItem(subject, subjectName, icon, color);
      },
    ),
  );
}
Widget _buildSubjectGridItem(Map<String, dynamic> subject, String subjectName, IconData icon, Color color) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias, // Important pour que l'icône ne soit pas coupée
    child: Stack(
      children: [
        // Contenu principal de la carte
        InkWell(
          onTap: () async {
            setState(() {
              selectedSubjectId = subject['id'];
              _showStudentsList = true;
            });
            await _loadStudentsForClass();
          },
          child: Container(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                SizedBox(height: 10),
                Text(
                  subjectName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        
        // Bouton de suppression positionné absolument
        Positioned(
          top: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
              ),
              onTap: () => _confirmDeleteSubject(_selectedClass!, subject['id']),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color.fromARGB(123, 255, 19, 2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
  Future<void> _loadStudentsForClass() async {
    try {
      final students = _selectedClass!['students'];
      List<Map<String, dynamic>> studentsData = [];

      for (var studentId in students) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(_selectedClass!['id'])
            .collection('students')
            .doc(studentId)
            .get();

        if (studentDoc.exists) {
          studentsData.add(
              {'id': studentId, ...studentDoc.data() as Map<String, dynamic>});
        }
      }

      studentsData.sort((a, b) => a['name'].compareTo(b['name']));

      setState(() {
        _students = studentsData;
      });
    } catch (e) {
      print("Erreur lors du chargement des élèves : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des élèves')));
    }
  }

Widget _buildStudentsList() {
  return Expanded(
    child: _students.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_outlined, size: 60, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "Aucun étudiant trouvé",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                if (_selectedClass != null)
                  TextButton(
                    onPressed: () {
                      // Ajouter un nouvel étudiant
                    },
                    child: Text("AJOUTER UN ÉTUDIANT"),
                  ),
              ],
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.all(12),
            itemCount: _students.length,
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final student = _students[index];
              final photoUrl = student['photoUrl'];
              final parentName = student['parentName'] ?? 'Non renseigné';
              final birthDate = student['birthDate'];

              return StatefulBuilder(
                builder: (context, setState) {
                  bool isLoading = false;
                  
                  return FutureBuilder<Color>(
                    future: _getStudentIndicatorColor(
                      _selectedClass!['class_id'], 
                      student['id'], 
                      selectedSubjectId
                    ),
                    builder: (context, snapshot) {
                      final statusColor = snapshot.data ?? Colors.grey;
                      
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          if (selectedClassId != null && selectedSubjectId != null) {
                            setState(() => isLoading = true);
                            await _showSelectionsDialog(
                              selectedClassId!,
                              selectedSubjectId!,
                              student['id']
                            );
                            setState(() => isLoading = false);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                content: Text("Veuillez sélectionner une classe et une matière"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                            )  ],
                          ),
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Photo et statut
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[200],
                                    ),
                                    child: photoUrl != null && photoUrl.isNotEmpty
                                        ? ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: photoUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                              ),
                                              errorWidget: (context, url, error) => 
                                                Icon(Icons.person, size: 30),
                                            ),
                                          )
                                        : Icon(Icons.person, size: 30),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(width: 16),
                              
                              // Infos étudiant
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    
                                    SizedBox(height: 4),
                                    
                                    Row(
                                      children: [
                                        Icon(Icons.people_outline, 
                                            size: 14, 
                                            color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          parentName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    if (birthDate != null && birthDate.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.cake_outlined, 
                                                size: 14, 
                                                color: Colors.grey),
                                            SizedBox(width: 4),
                                            Text(
                                              birthDate,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Actions
                              if (isLoading)
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.info_outline,
                                          color: Colors.blue),
                                      onPressed: () => _showStudentDetails(
                                          _selectedClass!, student['id']),
                                      tooltip: "Détails",
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: Colors.red[400]),
                                      onPressed: () => _confirmDeleteStudent(
                                          _selectedClass!, student['id']),
                                      tooltip: "Supprimer",
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
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
          _selectedClass == null
              ? 'Gestion des classes'
              : _selectedClass!['class_name'],
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
