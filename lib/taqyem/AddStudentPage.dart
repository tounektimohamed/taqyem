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
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
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
  bool _showHelpSection = true;
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

  void _buildHelpSection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تعليمات الاستخدام',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كيفية استخدام التطبيق:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                _buildHelpItem(
                    '1. اضغط على أي قسم لرؤية المواد والتلاميذ المرتبطين به'),
                _buildHelpItem(
                    '2. استخدم زر "إضافة تلميذ" لإضافة تلميذ جديد للقسم'),
                _buildHelpItem(
                    '3. استخدم زر "إضافة مادة" لإضافة مواد دراسية للقسم'),
                _buildHelpItem('4. اضغط على أيقونة السلة الحمراء لحذف القسم'),
                _buildHelpItem(
                    '5. اضغط على اسم المادة لرؤية قائمة التلاميذ وتقييمهم'),
                _buildHelpItem(
                    '6. بعد اختيار المادة، اضغط على اسم التلميذ الذي ترغب في تقييمه'),
                SizedBox(height: 8),
                Text('إرشادات سريعة:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                _buildHelpItemWithIcon(
                    Icons.touch_app, 'اضغط على القسم لعرض محتوياته'),
                _buildHelpItemWithIcon(
                    Icons.add, 'استخدم الأزرار الزرقاء للإضافة'),
                _buildHelpItemWithIcon(
                    Icons.delete, 'استخدم الأيقونات الحمراء للحذف'),
                _buildHelpItemWithIcon(
                    Icons.info, 'اضغط على معلومات التلميذ لرؤية التفاصيل'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إغلاق', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildHelpItemWithIcon(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15))),
        ],
      ),
    );
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
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text(
            'إضافة مادة دراسية',
            style: TextStyle(fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end, // Alignement à droite
              children: [
                const Text(
                  'اختر المادة المطلوبة:',
                  style: TextStyle(color: Colors.grey),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSubject,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    hint: const Text(
                      'اختر مادة',
                      textDirection: TextDirection.rtl,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubject = newValue;
                      });
                    },
                    items: _subjects.map<DropdownMenuItem<String>>((subject) {
                      return DropdownMenuItem<String>(
                        value: subject['id'],
                        child: Text(
                          subject['name'],
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_subjects.isEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد مواد متاحة',
                    style: TextStyle(color: Colors.orange),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedSubject == null
                    ? Colors.grey.shade300
                    : Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: _selectedSubject == null
                  ? null
                  : () async {
                      final selectedSubject = _subjects.firstWhere(
                          (subject) => subject['id'] == _selectedSubject);
                      await _addSubjectToClass(classData,
                          selectedSubject['name']!, selectedSubject['id']!);
                      if (mounted) Navigator.pop(context);
                    },
              child: const Text('إضافة'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.start, // Alignement des boutons à gauche
        );
      },
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
          SnackBar(content: Text('تم حذف القسم وبياناته')));
    } catch (e) {
      print("خطأ أثناء الحذف: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حدث خطأ أثناء حذف القسم')));
    }
  }

  Future<void> _confirmDeleteClass(String classId) async {
    final classData =
        _classes.firstWhere((classData) => classData['id'] == classId);

    if (classData['students'].isNotEmpty) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('حذف جميع التلاميذ'),
          content: Text(
              'هذا القسم يحتوي على تلاميذ. هل تريد حذف جميع التلاميذ قبل حذف القسم؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAllStudents(classData);
                await _deleteClass(classId);
              },
              child:
                  Text('حذف الكل', style: TextStyle(color: Colors.red)),
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
          SnackBar(content: Text('تم حذف جميع التلاميذ')));
    } catch (e) {
      print("خطأ أثناء حذف التلاميذ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف التلاميذ')));
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
          .showSnackBar(SnackBar(content: Text('تم حذف التلميذ')));
    } catch (e) {
      print("خطأ أثناء حذف التلميذ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف التلميذ')),
      );
    }
  }

  Future<void> _confirmDeleteStudent(
      Map<String, dynamic> classData, String studentId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف هذا التلميذ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent(classData, studentId);
            },
            child: Text('حذف'),
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
          .showSnackBar(SnackBar(content: Text('تم حذف المادة')));
    } catch (e) {
      print("خطأ أثناء حذف المادة: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حدث خطأ أثناء حذف المادة')));
    }
  }

  Future<void> _confirmDeleteSubject(
      Map<String, dynamic> classData, String subjectId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف هذه المادة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSubject(classData, subjectId);
            },
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }
Future<void> _addStudent(Map<String, dynamic> classData) async {
  List<TextEditingController> studentControllers = [TextEditingController()];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('إضافة تلاميذ', textDirection: TextDirection.rtl),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 200,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: studentControllers.length,
                    itemBuilder: (context, index) {
                      return Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          if (studentControllers.length > 1)
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  studentControllers.removeAt(index);
                                });
                              },
                            ),
                          Expanded(
                            child: TextField(
                              controller: studentControllers[index],
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'اسم التلميذ ${index + 1}',
                                floatingLabelAlignment: FloatingLabelAlignment.start,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('إضافة تلميذ آخر'),
                  onPressed: () {
                    setState(() {
                      studentControllers.add(TextEditingController());
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', textDirection: TextDirection.rtl),
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

                List<String> updatedStudents = List.from(classData['students']);

                for (var controller in studentControllers) {
                  if (controller.text.isNotEmpty) {
                    final studentRef = await studentsCollection.add({
                      'name': controller.text,
                      'parentName': '',
                      'parentPhone': '',
                      'birthDate': '',
                      'remarks': '',
                      'photoUrl': '',
                    });

                    updatedStudents.add(studentRef.id);
                  }
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(classData['id'])
                    .update({
                  'students': updatedStudents,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'تم إضافة ${studentControllers.length} تلميذ بنجاح',
                        textDirection: TextDirection.rtl)));
                _fetchClasses();
              } catch (e) {
                print("خطأ في إضافة التلاميذ: $e");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('حدث خطأ أثناء إضافة التلاميذ',
                        textDirection: TextDirection.rtl)));
              }
            },
            child: Text('إضافة', textDirection: TextDirection.rtl),
          ),
        ],
      );
    },
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

      WriteBatch batch = FirebaseFirestore.instance.batch();

      if (sousBaremeId != null) {
        var sousBaremeDirectRef = baremesCollectionRef.doc(sousBaremeId);
        batch.delete(sousBaremeDirectRef);

        var sousBaremeNestedRef =
            baremeRef.collection('sous_baremes').doc(sousBaremeId);
        batch.delete(sousBaremeNestedRef);
      } else {
        batch.delete(baremeRef);
      }

      if (newValue != null) {
        if (sousBaremeId != null) {
          batch.set(baremesCollectionRef.doc(sousBaremeId), {
            'Marks': newValue,
            'createdAt': FieldValue.serverTimestamp(),
          });

          batch.set(baremeRef.collection('sous_baremes').doc(sousBaremeId), {
            'Marks': newValue,
            'createdAt': FieldValue.serverTimestamp(),
          });

          batch.set(
              baremeRef,
              {
                'haveSoubarem': true,
                'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        } else {
          batch.set(
              baremeRef,
              {
                'Marks': newValue,
                'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        }
      }

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
    return _selectedClass == null
        ? _buildClassListView()
        : _buildClassDetailsView();
  }

  Widget _buildClassListView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classData = _classes[index];
        return _buildClassListItem(classData);
      },
    );
  }

  Widget _buildClassListItem(Map<String, dynamic> classData) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectClass(classData),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    classData['class_name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteClass(classData['id']),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Élèves: ${classData['students'].length} | Matières: ${classData['subjects'].length}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.add, size: 16),
                    label: Text('إضافة تلاميذ'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: () => _addStudent(classData),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectClass(Map<String, dynamic> classData) {
    setState(() {
      _selectedClass = classData;
      selectedClassId = classData['class_id'];
      _showStudentsList = false;
    });
  }

  Widget _buildClassDetailsView() {
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
            // Version avec TextButton
            TextButton.icon(
              icon: Icon(Icons.add, size: 20),
              label: Text('إضافة مادة'),
              style: TextButton.styleFrom(
                foregroundColor: Color.fromARGB(255, 10, 101, 236),
              ),
              onPressed: () => _addSubjectDialog(_selectedClass!),
            ),
          ],
        ),
        Expanded(
          child:
              _showStudentsList ? _buildStudentsList() : _buildSubjectsGrid(),
        ),
      ],
    );
  }

  Widget _buildSubjectsGrid() {
    final subjects = _selectedClass!['subjects'];
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isSmallScreen ? 0.85 : 0.9,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final subjectName = subject['name'];
        return _buildSubjectGridItem(
          subject,
          subjectName,
          SubjectHelper.getIconForSubject(subjectName),
          SubjectHelper.getSubjectColor(subjectName),
        );
      },
    );
  }

  Widget _buildSubjectGridItem(
    Map<String, dynamic> subject,
    String subjectName,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          setState(() {
            selectedSubjectId = subject['id'];
            _showStudentsList = true;
          });
          await _loadStudentsForClass();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 150, // Set a minimum height
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important for GridView items
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      subjectName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () =>
                      _confirmDeleteSubject(_selectedClass!, subject['id']),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 18),
                      SizedBox(width: 8),
                      Text('حذف'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
    return _students.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_outlined,
                    size: 60, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "لا يوجد تلاميذ",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                if (_selectedClass != null)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: () => _addStudent(_selectedClass!),
                      child: Text("إضافة تلاميذ"),
                    ),
                  ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: _buildStudentCard(student),
              );
            },
          );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final photoUrl = student['photoUrl'];
    final parentName = student['parentName'] ?? 'Non renseigné';
    final birthDate = student['birthDate'];

    return FutureBuilder<Color>(
      future: _getStudentIndicatorColor(
          _selectedClass!['class_id'], student['id'], selectedSubjectId),
      builder: (context, snapshot) {
        final statusColor = snapshot.data ?? Colors.grey;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (selectedClassId != null && selectedSubjectId != null) {
                await _showSelectionsDialog(
                    selectedClassId!, selectedSubjectId!, student['id']);
              }
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
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
                        Text(
                          parentName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (birthDate != null && birthDate.isNotEmpty)
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.info_outline, color: Colors.blue),
                        onPressed: () =>
                            _showStudentDetails(_selectedClass!, student['id']),
                      ),
                      IconButton(
                        icon:
                            Icon(Icons.delete_outline, color: Colors.red[400]),
                        onPressed: () => _confirmDeleteStudent(
                            _selectedClass!, student['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

  // Fonction pour sélectionner la date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
    if (picked != null) {
      birthDateController.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('تفاصيل التلميذ', textDirection: TextDirection.rtl),
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
                  child: Text('التقاط صورة'),
                ),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: Text('اختيار صورة'),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: parentNameController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'اسم ولي الأمر',
                floatingLabelAlignment: FloatingLabelAlignment.start,
              ),
            ),
            TextField(
              controller: parentPhoneController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم هاتف ولي الأمر',
                floatingLabelAlignment: FloatingLabelAlignment.start,
              ),
            ),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: birthDateController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'تاريخ الميلاد',
                    floatingLabelAlignment: FloatingLabelAlignment.start,
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            TextField(
              controller: remarksController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'ملاحظات',
                floatingLabelAlignment: FloatingLabelAlignment.start,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء'),
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
                SnackBar(content: Text('تم تحديث المعلومات بنجاح')),
              );

              await _fetchClasses();
            } catch (e) {
              print("خطأ في تحديث المعلومات: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('حدث خطأ أثناء تحديث المعلومات')),
              );
            }
          },
          child: Text('حفظ'),
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
            ? 'إدارة الاقسام'
            : _selectedClass!['class_name'],
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
      elevation: 4,
      actions: [
        IconButton(
          icon: Icon(Icons.help_outline, color: Colors.white),
          onPressed: () => _buildHelpSection(context),
        ),
      ],
    ),
    body: SafeArea(
      child: _classes.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Directionality(
                  textDirection: TextDirection.rtl,
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
                        'لا توجد اقسام متاحة',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'يجب عليك إضافة قسم من خلال قسم "إضافة قسم جديد"',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
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
                        child: Text('إضافة قسم جديد'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Directionality(
              textDirection: TextDirection.rtl,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildClassList();
                },
              ),
            ),
    ),
  );
}
}
