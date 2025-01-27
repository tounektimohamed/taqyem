import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DynamicTablePage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;

  DynamicTablePage({
    required this.selectedClass,
    required this.selectedMatiere,
  });

  @override
  _DynamicTablePageState createState() => _DynamicTablePageState();
}

class _DynamicTablePageState extends State<DynamicTablePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _profName = '';
  String _schoolName = '';
  bool _isDialogCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Charger les données depuis Firestore
  }

  // Charger les données depuis Firestore
  void _loadUserData() async {
    if (currentUser != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _profName = userDoc['profName'] ?? '';
          _schoolName = userDoc['schoolName'] ?? '';
          _isDialogCompleted = _profName.isNotEmpty && _schoolName.isNotEmpty;
        });
      }

      // Afficher la boîte de dialogue uniquement si les données ne sont pas déjà enregistrées
      if (!_isDialogCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showInputDialog();
        });
      }
    }
  }

  // Afficher la boîte de dialogue pour saisir les informations
  void _showInputDialog() {
    TextEditingController profController = TextEditingController();
    TextEditingController schoolController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('معلومات جديدة', textDirection: TextDirection.rtl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: profController,
                decoration: InputDecoration(
                  labelText: 'اسم الأستاذ',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(
                  labelText: 'اسم المدرسة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('إلغاء', textDirection: TextDirection.rtl),
            ),
            TextButton(
              onPressed: () async {
                if (currentUser != null) {
                  // Enregistrer les données dans Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .set(
                          {
                        'profName': profController.text,
                        'schoolName': schoolController.text,
                      },
                          SetOptions(
                              merge:
                                  true)); // Merge pour ne pas écraser d'autres données

                  setState(() {
                    _profName = profController.text;
                    _schoolName = schoolController.text;
                    _isDialogCompleted = true;
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('حفظ', textDirection: TextDirection.rtl),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(child: Text('Utilisateur non connecté.'));
    }

    if (!_isDialogCompleted) {
      return Center(child: CircularProgressIndicator());
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          bodyMedium: TextStyle(
              fontFamily: 'ArabicFont', fontSize: 14), // Petite police
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title:
              Text('الجدول الجامع للنتائج', textDirection: TextDirection.rtl),
          backgroundColor: const Color.fromARGB(255, 169, 204, 233),
          elevation: 4,
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Column(
              children: [
                // En-tête professionnel
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    children: [
                      // Professeur, matière et classe à gauche (alignés verticalement)
                      FutureBuilder<Map<String, String>>(
                        future: _getClassAndMatiereNames(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text('خطأ في تحميل البيانات',
                                textDirection: TextDirection.rtl);
                          }
                          if (!snapshot.hasData) {
                            return Text('لا توجد بيانات',
                                textDirection: TextDirection.rtl);
                          }

                          var classAndMatiereNames = snapshot.data!;
                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start, // Alignement à gauche
                            children: [
                              Text(
                                'الأستاذ: $_profName',
                                style: TextStyle(fontSize: 14), // Petite police
                              ),
                              SizedBox(height: 8), // Espace entre les éléments
                              Text(
                                'المادة: ${classAndMatiereNames['matiereName']}',
                                style: TextStyle(fontSize: 14), // Petite police
                              ),
                              SizedBox(height: 8), // Espace entre les éléments
                              Text(
                                'الصف: ${classAndMatiereNames['className']}',
                                style: TextStyle(fontSize: 14), // Petite police
                              ),
                            ],
                          );
                        },
                      ),
                      Spacer(), // Espace entre les éléments
                      // Logo et nom de l'école à droite
                      Column(
                        children: [
                          SizedBox(height: 8),
                          Text(
                            'الجدول الجامع للنتائج', // Ajout de la guillemet fermante manquante
                            style: TextStyle(fontSize: 18), // Petite police
                          ),
                        ],
                      ),
                      Spacer(), // Espace entre les éléments
                      // Logo et nom de l'école à droite
                      Column(
                        children: [
                          Image.asset(
                            'lib/assets/icons/me/ministere.png', // Chemin vers le logo du ministère
                            height: 100, // Taille réduite du logo
                          ),
                          SizedBox(height: 8),
                          Text(
                            'مدرسة: $_schoolName',
                            style: TextStyle(fontSize: 14), // Petite police
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _buildMainContent(),
                ),
                // Pied de page
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    'تاريخ الإصدار: ${DateTime.now().toString().substring(0, 10)}',
                    style: TextStyle(fontSize: 14), // Petite police
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>> _getClassAndMatiereNames() async {
    try {
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();
      var className = classDoc['name'] ?? 'غير معروف';

      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();
      var matiereName = matiereDoc['name'] ?? 'غير معروف';

      return {
        'className': className,
        'matiereName': matiereName,
      };
    } catch (e) {
      print('Erreur lors de la récupération des noms: $e');
      return {
        'className': 'غير معروف',
        'matiereName': 'غير معروف',
      };
    }
  }

  Widget _buildMainContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .snapshots(),
      builder: (context, userClassesSnapshot) {
        if (userClassesSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (userClassesSnapshot.hasError) {
          return Center(
              child: Text('خطأ: ${userClassesSnapshot.error}',
                  textDirection: TextDirection.rtl));
        }
        if (!userClassesSnapshot.hasData ||
            userClassesSnapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('لم يتم العثور على أي فصل.',
                  textDirection: TextDirection.rtl));
        }

        for (var classDoc in userClassesSnapshot.data!.docs) {
          var classData = classDoc.data() as Map<String, dynamic>;
          var classIdFromFirestore = classData['class_id'] ?? '';

          if (widget.selectedClass == classIdFromFirestore) {
            return StudentsTable(
              classDocId: classDoc.id,
              selectedClass: widget.selectedClass,
              selectedMatiere: widget.selectedMatiere,
              currentUser: currentUser!,
            );
          }
        }

        return Center(
            child: Text('لم يتم العثور على أي فصل مطابق.',
                textDirection: TextDirection.rtl));
      },
    );
  }
}

class StudentsTable extends StatefulWidget {
  final String classDocId;
  final String selectedClass;
  final String selectedMatiere;
  final User currentUser;

  StudentsTable({
    required this.classDocId,
    required this.selectedClass,
    required this.selectedMatiere,
    required this.currentUser,
  });

  @override
  _StudentsTableState createState() => _StudentsTableState();
}

class _StudentsTableState extends State<StudentsTable> {
  final List<String> _dropdownValues = [
    '( - - - )',
    '( + - - )',
    '( + + - )',
    '( + + + )'
  ];
  Map<String, Map<String, String>> _selectedValues = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.currentUser.uid)
                .collection('user_classes')
                .doc(widget.classDocId)
                .collection('students')
                .snapshots(),
            builder: (context, studentsSnapshot) {
              if (studentsSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (studentsSnapshot.hasError) {
                return Center(
                    child: Text('خطأ: ${studentsSnapshot.error}',
                        textDirection: TextDirection.rtl));
              }
              if (!studentsSnapshot.hasData ||
                  studentsSnapshot.data!.docs.isEmpty) {
                return Center(
                    child: Text('لم يتم العثور على أي طالب.',
                        textDirection: TextDirection.rtl));
              }

              return _buildSelectionsTable(studentsSnapshot.data!.docs);
            },
          ),
        ),
        // Bouton "Terminer"
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _saveAllChanges,
            child: Text('Terminer', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionsTable(List<QueryDocumentSnapshot> studentsDocs) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .snapshots(),
      builder: (context, selectionsSnapshot) {
        if (selectionsSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (selectionsSnapshot.hasError) {
          return Center(
              child: Text('خطأ: ${selectionsSnapshot.error}',
                  textDirection: TextDirection.rtl));
        }
        if (!selectionsSnapshot.hasData ||
            selectionsSnapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('لم يتم العثور على أي معيار.',
                  textDirection: TextDirection.rtl));
        }

        var selectedBaremes = selectionsSnapshot.data!.docs;

        return FutureBuilder<List<Map<String, String>>>(
          future: _getBaremesValues(selectedBaremes),
          builder: (context, baremesValuesSnapshot) {
            if (baremesValuesSnapshot.connectionState ==
                ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (baremesValuesSnapshot.hasError) {
              return Center(
                  child: Text('خطأ: ${baremesValuesSnapshot.error}',
                      textDirection: TextDirection.rtl));
            }
            if (!baremesValuesSnapshot.hasData ||
                baremesValuesSnapshot.data!.isEmpty) {
              return Center(
                  child: Text('لم يتم العثور على أي معيار.',
                      textDirection: TextDirection.rtl));
            }

            var baremesValues = baremesValuesSnapshot.data!;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9),
                child: DataTable(
                  columnSpacing: 20,
                  horizontalMargin: 12,
                  columns: [
                    DataColumn(
                      label: Container(
                        width: 150,
                        child: Text(
                          'الاسم واللقب',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ),
                    for (var bareme in baremesValues)
                      DataColumn(
                        label: Container(
                          width: 100,
                          child: Text(
                            bareme['value'] ?? 'معيار',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        ),
                      ),
                  ],
                  rows: studentsDocs.map((doc) {
                    var studentData = doc.data() as Map<String, dynamic>;
                    var studentName = studentData['name'] ?? 'اسم غير معروف';
                    var studentId = doc.id;

                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            width: 150,
                            child: Text(
                              studentName,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          ),
                        ),
                        for (var bareme in baremesValues)
                          DataCell(
                            Container(
                              width: 100,
                              child: FutureBuilder<String>(
                                future:
                                    _getSelectedValue(studentId, bareme['id']!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (snapshot.hasError) {
                                    return Text('خطأ',
                                        textDirection: TextDirection.rtl);
                                  }
                                  var selectedValue =
                                      snapshot.data ?? _dropdownValues[0];
                                  return StudentDropdown(
                                    studentId: studentId,
                                    baremeId: bareme['id']!,
                                    initialValue: selectedValue,
                                    dropdownValues: _dropdownValues,
                                    onChanged: (studentId, baremeId, newValue) {
                                      if (!_selectedValues
                                          .containsKey(studentId)) {
                                        _selectedValues[studentId] = {};
                                      }
                                      _selectedValues[studentId]![baremeId] =
                                          newValue;
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _getSelectedValue(String studentId, String baremeId) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(widget.classDocId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeId)
          .get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        return data['value'] ?? _dropdownValues[0];
      } else {
        return _dropdownValues[0];
      }
    } catch (e) {
      print('Erreur lors de la récupération de la valeur: $e');
      return _dropdownValues[0];
    }
  }

  Future<List<Map<String, String>>> _getBaremesValues(
      List<QueryDocumentSnapshot> selectedBaremes) async {
    List<Map<String, String>> baremesValues = [];

    for (var baremeDoc in selectedBaremes) {
      var baremeId = baremeDoc['baremeId'];
      var baremeSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .collection('baremes')
          .doc(baremeId)
          .get();

      if (baremeSnapshot.exists) {
        var baremeData = baremeSnapshot.data() as Map<String, dynamic>;
        baremesValues.add({
          'id': baremeId,
          'value': baremeData['value'] ?? 'معيار',
        });
      }
    }

    return baremesValues;
  }

  void _saveAllChanges() async {
    try {
      if (_selectedValues.isEmpty) {
        print('Aucune donnée à enregistrer.');
        return;
      }

      for (var studentId in _selectedValues.keys) {
        for (var baremeId in _selectedValues[studentId]!.keys) {
          var newValue = _selectedValues[studentId]![baremeId]!;
          print(
              'Enregistrement pour studentId: $studentId, baremeId: $baremeId, valeur: $newValue');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUser
                  .uid) // Vérifiez que c'est bien "VusMWn6WMiWEl3QyukU7RTFm5Gj2"
              .collection('user_classes')
              .doc(widget
                  .classDocId) // Vérifiez que c'est bien "EzvT6tI82Ayj4mvwlLKA"
              .collection('students')
              .doc(studentId) // Vérifiez que c'est bien "cmfzHU0XUEUOKZBDQS7R"
              .collection('baremes')
              .doc(baremeId) // Vérifiez que c'est bien "nE7o2Qsg0yI6BLlpfjeP"
              .set({'value': newValue}, SetOptions(merge: true));

          print(
              'Enregistrement réussi pour studentId: $studentId, baremeId: $baremeId');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تم حفظ التغييرات بنجاح',
                textDirection: TextDirection.rtl)),
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde des modifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('خطأ في حفظ التغييرات', textDirection: TextDirection.rtl)),
      );
    }
  }
}

class StudentDropdown extends StatefulWidget {
  final String studentId;
  final String baremeId;
  final String initialValue;
  final List<String> dropdownValues;
  final Function(String, String, String) onChanged;

  StudentDropdown({
    required this.studentId,
    required this.baremeId,
    required this.initialValue,
    required this.dropdownValues,
    required this.onChanged,
  });

  @override
  _StudentDropdownState createState() => _StudentDropdownState();
}

class _StudentDropdownState extends State<StudentDropdown> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedValue,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedValue = newValue;
          });
          widget.onChanged(widget.studentId, widget.baremeId, newValue);
        }
      },
      items:
          widget.dropdownValues.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            textDirection: TextDirection.rtl,
          ),
        );
      }).toList(),
    );
  }
}
