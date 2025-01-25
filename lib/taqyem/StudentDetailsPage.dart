import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentsListPage extends StatefulWidget {
  final String classId; // ID de la classe sélectionnée
  final String className; // Nom de la classe sélectionnée

  const StudentsListPage({required this.classId, required this.className});

  @override
  _StudentsListPageState createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final studentDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(widget.classId)
          .collection('students')
          .get();

      setState(() {
        _students = studentDocs.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
            'age': doc['age'],
            'phone': doc['phone'],
            'details': doc['details'], // Détails supplémentaires
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des élèves : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des élèves')),
      );
    }
  }

  Future<void> _addStudentDialog() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController ageController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة طالب جديد'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'الاسم الكامل'),
                textDirection: TextDirection.rtl,
              ),
              TextField(
                controller: ageController,
                decoration: InputDecoration(labelText: 'العمر'),
                keyboardType: TextInputType.number,
                textDirection: TextDirection.rtl,
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.rtl,
              ),
              TextField(
                controller: detailsController,
                decoration: InputDecoration(labelText: 'تفاصيل إضافية'),
                textDirection: TextDirection.rtl,
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
              if (nameController.text.isNotEmpty) {
                await _addStudent(
                  name: nameController.text,
                  age: ageController.text,
                  phone: phoneController.text,
                  details: detailsController.text,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('يرجى ملء جميع الحقول')),
                );
              }
            },
            child: Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudent({
    required String name,
    required String age,
    required String phone,
    required String details,
  }) async {
    try {
      final newStudent = {
        'name': name,
        'age': age,
        'phone': phone,
        'details': details,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(widget.classId)
          .collection('students')
          .add(newStudent);

      setState(() {
        _students.add(newStudent);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة الطالب بنجاح')),
      );
    } catch (e) {
      print("Erreur lors de l'ajout de l'élève : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إضافة الطالب')),
      );
    }
  }

  Future<void> _viewStudentDetails(Map<String, dynamic> student) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل الطالب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الاسم: ${student['name']}', textDirection: TextDirection.rtl),
            Text('العمر: ${student['age']}', textDirection: TextDirection.rtl),
            Text('الهاتف: ${student['phone']}', textDirection: TextDirection.rtl),
            Text('تفاصيل: ${student['details']}', textDirection: TextDirection.rtl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قائمة الطلاب - ${widget.className}'),
      ),
      body: ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return ListTile(
            title: Text(student['name'], textDirection: TextDirection.rtl),
            subtitle: Text('العمر: ${student['age']}', textDirection: TextDirection.rtl),
            trailing: IconButton(
              icon: Icon(Icons.info),
              onPressed: () => _viewStudentDetails(student),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStudentDialog,
        child: Icon(Icons.add),
        tooltip: 'إضافة طالب جديد',
      ),
    );
  }
}
