import 'package:Taqyem/taqyem/header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClassificationPage2 extends StatefulWidget {
  final String selectedClass;
  final String selectedBaremeId;
  final User currentUser;
  final String profName;
  final String schoolName;
  final String className;
  final String matiereName;
  final String baremeName;
  final String? sousBaremeName; // Add this parameter
  final String? selectedSousBaremeId; // Add this parameter

  ClassificationPage2({
    required this.selectedClass,
    required this.selectedBaremeId,
    required this.currentUser,
    required this.profName,
    required this.schoolName,
    required this.className,
    required this.matiereName,
    required String matiereId,
    required this.baremeName,
    this.selectedSousBaremeId, // Make it optional
    this.sousBaremeName, // Add this line


  });

  @override
  _ClassificationPage2State createState() => _ClassificationPage2State();
}

class _ClassificationPage2State extends State<ClassificationPage2> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('خطة العلاج وأصل الخطأ'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            PageHeader(
              profName: widget.profName,
              schoolName: widget.schoolName,
              className: widget.className,
              matiereName: widget.matiereName,
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    'خطة العلاج وأصل الخطأ',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                  ),
                  Text(
                    'في مادة ${widget.matiereName} في معيار ${widget.baremeName}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            _buildLegend(),
            Expanded(
              child: FutureBuilder<List<Map<String, String>>>(
                future: _getClassifiedStudents(
                    widget.selectedClass, widget.selectedBaremeId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('لا توجد بيانات'));
                  }

                  var students = snapshot.data!;
                  Map<String, List<Map<String, String>>> groupedStudents = {};

                  // Group students by their group name
                  for (var student in students) {
                    String group = student['group'] ?? '';
                    if (!groupedStudents.containsKey(group)) {
                      groupedStudents[group] = [];
                    }
                    groupedStudents[group]!.add(student);
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(
                          label: Container(
                            alignment: Alignment.centerRight,
                            child: Text('اسم التلميذ'),
                          ),
                        ),
                        DataColumn(
                          label: Container(
                            alignment: Alignment.centerRight,
                            child: Text('العمل'),
                          ),
                        ),
                      ],
                      rows: groupedStudents.entries.map((groupEntry) {
                        String groupName = groupEntry.key;
                        List<Map<String, String>> groupStudents =
                            groupEntry.value;

                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                            Color rowColor;
                            switch (groupName) {
                              case 'مجموعة العلاج':
                                rowColor = Colors.red.withOpacity(0.7);
                                break;
                              case 'مجموعة الدعم':
                                rowColor = Colors.orange.withOpacity(0.7);
                                break;
                              case 'مجموعة التميز':
                                rowColor = Colors.green.withOpacity(0.7);
                                break;
                              default:
                                rowColor = Colors.transparent;
                            }
                            return rowColor;
                          }),
                          cells: [
                            DataCell(
                              Text(groupStudents
                                  .map((student) =>
                                      student['name'] ?? 'غير معروف')
                                  .join(", ")),
                            ),
                            DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  // Action for the group
                                  print('Action for group: $groupName');
                                  print('Class Name: ${widget.className}');
                                  print('Subject Name: ${widget.matiereName}');
                                  print(
                                      'Grading Scheme Name: ${widget.baremeName}');
                                  print('Action for group: $groupName');
                                },
                                child: Text('عمل لـ $groupName'),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('مجموعة العلاج', Colors.red.withOpacity(0.7)),
          SizedBox(width: 16),
          _buildLegendItem('مجموعة الدعم', Colors.orange.withOpacity(0.7)),
          SizedBox(width: 16),
          _buildLegendItem('مجموعة التميز', Colors.green.withOpacity(0.7)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        SizedBox(width: 8),
        Text(text, textDirection: TextDirection.rtl),
      ],
    );
  }

  Future<List<Map<String, String>>> _getClassifiedStudents(
      String classId, String baremeId) async {
    List<Map<String, String>> students = [];

    var studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
        .collection('user_classes')
        .doc(classId)
        .collection('students')
        .get();

    List<Future<void>> futures = [];

    for (var studentDoc in studentsSnapshot.docs) {
      var studentId = studentDoc.id;
      var studentName = studentDoc['name'] ?? 'غير معروف';

      futures.add(FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeId)
          .get()
          .then((baremeSnapshot) {
        if (baremeSnapshot.exists) {
          var baremeData = baremeSnapshot.data() as Map<String, dynamic>;
          var value = baremeData['Marks'] ?? '( - - - )';

          String group;
          if (value == '( + + + )') {
            group = 'مجموعة التميز';
          } else if (value == '( + + - )') {
            group = 'مجموعة الدعم';
          } else {
            group = 'مجموعة العلاج';
          }

          students.add({
            'name': studentName,
            'treatmentPlan': baremeData['treatmentPlan'] ?? '',
            'errorOrigin': baremeData['errorOrigin'] ?? '',
            'group': group,
          });
        }
      }));
    }

    await Future.wait(futures);
    return students;
  }
}
