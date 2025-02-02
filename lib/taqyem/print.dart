import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GradesPage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;

  GradesPage({
    required this.selectedClass,
    required this.selectedMatiere,
  });

  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, String> _grades = {}; // Pour stocker les notes des élèves

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إعطاء النقاط', textDirection: TextDirection.rtl),
        backgroundColor: const Color.fromARGB(255, 169, 204, 233),
      ),
      body: _buildGradesTable(),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveGrades,
        child: Icon(Icons.save),
      ),
    );
  }

  Widget _buildGradesTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(widget.selectedClass)
          .collection('students')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}', textDirection: TextDirection.rtl));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('لم يتم العثور على أي طالب.', textDirection: TextDirection.rtl));
        }

        var students = snapshot.data!.docs;
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            var student = students[index];
            var studentName = student['name'] ?? 'اسم غير معروف';
            var studentId = student.id;

            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(studentName, textDirection: TextDirection.rtl),
                trailing: SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'النقطة',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _grades[studentId] = value; // Enregistrer la note
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _saveGrades() async {
    try {
      for (var studentId in _grades.keys) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(widget.selectedClass)
            .collection('students')
            .doc(studentId)
            .collection('grades')
            .doc(widget.selectedMatiere)
            .set({
              'grade': _grades[studentId],
              'date': DateTime.now(),
            }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ النقاط بنجاح', textDirection: TextDirection.rtl),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ النقاط: $e', textDirection: TextDirection.rtl),
        ),
      );
    }
  }
}