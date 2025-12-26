import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddClassPage extends StatefulWidget {
  @override
  _AddClassPageState createState() => _AddClassPageState();
}

class _AddClassPageState extends State<AddClassPage> {
  String? _selectedClassName;
  List<String> _selectedSubjects = [];
  List<Map<String, String>> _subjects = [];
  List<Map<String, String>> _classNames = [];
  TextEditingController _studentNameController = TextEditingController();
  List<Map<String, String>> _students = [];
  TextEditingController _newSubjectController = TextEditingController();
  String? _selectedClassNameDisplay;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredClassNames = [];
  final List<Color> groupColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.deepPurple,
    Colors.lightGreen,
  ];

  @override
  void initState() {
    super.initState();
    _loadClassNames();
    _searchController.addListener(_filterClassNames);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClassNames() async {
    try {
      final classDocs =
          await FirebaseFirestore.instance.collection('classes').get();
      setState(() {
        _classNames = classDocs.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'] as String,
          };
        }).toList();
        _classNames.sort((a, b) => a['name']!.compareTo(b['name']!));
        _filteredClassNames = List.from(_classNames);
      });
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des classes')));
    }
  }

  void _filterClassNames() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClassNames = _classNames.where((classData) {
        return classData['name']!.toLowerCase().contains(query);
      }).toList()
        ..sort((a, b) => a['name']!.compareTo(b['name']!));
    });
  }

  Future<void> _saveClassData(String? newClassName) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (_selectedClassName != null && _selectedSubjects.isNotEmpty) {
        try {
          // Vérifier si la classe existe déjà
          final existingClass = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('user_classes')
              .where('class_id', isEqualTo: _selectedClassName)
              .get();

          if (existingClass.docs.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('هذا القسم مسجل مسبقًا!'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Enregistrer la classe
          var userClassesRef = FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('user_classes')
              .doc(_selectedClassName);
          await userClassesRef.set({
            'class_id': _selectedClassName,
            'class_name': newClassName ?? _selectedClassNameDisplay,
            'subjects': _selectedSubjects.map((subjectId) {
              var subject = _subjects.firstWhere(
                (s) => s['id'] == subjectId,
                orElse: () => {'name': 'غير معروف'},
              );
              return {
                'id': subjectId,
                'name': subject['name'],
              };
            }).toList(),
            'students': _students.map((student) => student['name']).toList(),
            'timestamp': FieldValue.serverTimestamp(),
          });

          setState(() {
            _students.clear();
            _selectedSubjects.clear();
            _selectedClassName = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم حفظ القسم بنجاح!')),
          );

          Navigator.pop(context);
        } catch (e) {
          print("Erreur lors de l'enregistrement : $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('يرجى ملء جميع الحقول.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('المستخدم غير متصل')),
      );
    }
  }

  Widget _buildSubjectCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2. اختر المواد',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey)),
        SizedBox(height: 10),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _subjects.map((subject) {
                return CheckboxListTile(
                  title: Text(subject['name'] ?? 'غير معروف',
                      style: TextStyle(fontSize: 16)),
                  value: _selectedSubjects.contains(subject['id']),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedSubjects.add(subject['id']!);
                      } else {
                        _selectedSubjects.remove(subject['id']);
                      }
                    });
                  },
                  activeColor: Colors.blueAccent,
                  checkColor: Colors.white,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la récupération des matières')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المواد', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        elevation: 4,
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. اختر القسم',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'بحث',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: Icon(Icons.search),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedClassName,
                      items: _filteredClassNames.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, String> classData = entry.value;
                        Color color =
                            groupColors[(index ~/ 5) % groupColors.length];
                        return DropdownMenuItem<String>(
                          value: classData['id'],
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.school, color: color),
                                SizedBox(width: 10),
                                Text(
                                  classData['name'] ?? 'اسم غير معروف',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() {
                          _selectedClassName = value;
                          _selectedClassNameDisplay = _classNames.firstWhere(
                            (classData) => classData['id'] == value,
                            orElse: () => {'name': 'اسم غير معروف'},
                          )['name'];
                        });
                        if (value != null) {
                          await _loadSubjects(value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'اختر القسم',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
                      dropdownColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_selectedClassNameDisplay != null)
              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: groupColors[(_filteredClassNames.indexWhere(
                                  (classData) =>
                                      classData['id'] == _selectedClassName) ~/
                              5) %
                          groupColors.length]
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: groupColors[(_filteredClassNames.indexWhere(
                                    (classData) =>
                                        classData['id'] ==
                                        _selectedClassName) ~/
                                5) %
                            groupColors.length]
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school,
                        color: groupColors[(_filteredClassNames.indexWhere(
                                    (classData) =>
                                        classData['id'] ==
                                        _selectedClassName) ~/
                                5) %
                            groupColors.length]),
                    SizedBox(width: 10),
                    Text(
                      _selectedClassNameDisplay!,
                      style: TextStyle(
                        color: groupColors[(_filteredClassNames.indexWhere(
                                    (classData) =>
                                        classData['id'] ==
                                        _selectedClassName) ~/
                                5) %
                            groupColors.length],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20),
            _buildSubjectCheckboxes(),
          ],
        ),
      ),
      
      // FloatingActionButton ajouté ici
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_selectedClassName != null && _selectedSubjects.isNotEmpty)
            ? () async {
                await _saveClassData(_selectedClassNameDisplay);
              }
            : null,
        backgroundColor: (_selectedClassName != null && _selectedSubjects.isNotEmpty)
            ? Colors.blueAccent
            : Colors.grey,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(Icons.check_circle),
        label: Text('تأكيد الإضافة'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}