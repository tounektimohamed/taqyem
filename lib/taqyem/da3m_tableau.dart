import 'dart:io';

import 'package:Taqyem/taqyem/header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import 'dart:html' as html; // Pour Flutter Web seulement

class ClassificationPage extends StatefulWidget {
  final String selectedClass;
  final String selectedBaremeId;
  final User currentUser;
  final String profName;
  final String schoolName;
  final String className;
  final String matiereName;
  final String baremeName;
  final String? sousBaremeName;
  final String? selectedSousBaremeId;

  ClassificationPage({
    required this.selectedClass,
    required this.selectedBaremeId,
    required this.currentUser,
    required this.profName,
    required this.schoolName,
    required this.className,
    required this.matiereName,
    required this.baremeName,
    this.sousBaremeName,
    this.selectedSousBaremeId,
  });

  @override
  _ClassificationPageState createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
  List<dynamic> jsonData = [];

  @override
  void initState() {
    super.initState();
    printVariables();
    loadJsonData();
  }

  void printVariables() {
    print("Classe sélectionnée: ${widget.selectedClass}");
    print("ID du barème sélectionné: ${widget.selectedBaremeId}");
    print("Utilisateur actuel: ${widget.currentUser}");
    print("Nom du professeur: ${widget.profName}");
    print("Nom de l'école: ${widget.schoolName}");
    print("Nom de la classe: ${widget.className}");
    print("Nom de la matière: ${widget.matiereName}");
    print("Nom du barème: ${widget.baremeName ?? 'Non défini'}");
    print("ID du sous-barème sélectionné: ${widget.selectedBaremeId}");
    print("Nom du sous-barème: ${widget.baremeName ?? 'Non défini'}");
  }

  Future<void> loadJsonData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/data.json');
      setState(() {
        jsonData = json.decode(jsonString);
      });
    } catch (e) {
      print("Erreur lors du chargement du fichier JSON: $e");
    }
  }

  void showSolutionAndProbleme(String groupName) {
    print("Classe sélectionnée: ${widget.className}");
    print("Matière sélectionnée: ${widget.matiereName}");
    print("Barème sélectionné: ${widget.baremeName}");
    print("Sous-barème sélectionné: ${widget.sousBaremeName ?? 'Non défini'}");

    var result = jsonData.firstWhere(
      (item) {
        String jsonClasse = item['classe'].trim().toLowerCase();
        String jsonMatiere = item['matiere'].trim().toLowerCase();
        String jsonBareme = item['bareme'].trim().toLowerCase();

        String selectedClasse = widget.className.trim().toLowerCase();
        String selectedMatiere = widget.matiereName.trim().toLowerCase();
        String selectedBareme =
            (widget.sousBaremeName ?? widget.baremeName).trim().toLowerCase();

        return jsonClasse == selectedClasse &&
            jsonMatiere == selectedMatiere &&
            jsonBareme == selectedBareme;
      },
      orElse: () => null,
    );

    if (result != null) {
      String solution = result['solution'];
      String probleme = result['probleme'];

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('خطة العلاج وأصل الخطأ لـ $groupName'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الحل:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(solution),
                  SizedBox(height: 16),
                  Text('المشكلة:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(probleme),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('إغلاق'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('خطأ'),
            content: Text('لا توجد بيانات متاحة لـ $groupName'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('إغلاق'),
              ),
            ],
          );
        },
      );
    }
  }

Future<void> _generateAndSavePDF() async {
  try {
    final groupedStudents = await _getGroupedStudentsData();
    
    // Récupérer les données de solutions depuis jsonData (une seule fois)
    Map<String, dynamic> solutionsData = {};
    
    var result = jsonData.firstWhere(
      (item) {
        String jsonClasse = item['classe'].trim().toLowerCase();
        String jsonMatiere = item['matiere'].trim().toLowerCase();
        String jsonBareme = item['bareme'].trim().toLowerCase();

        String selectedClasse = widget.className.trim().toLowerCase();
        String selectedMatiere = widget.matiereName.trim().toLowerCase();
        String selectedBareme = 
            (widget.sousBaremeName ?? widget.baremeName).trim().toLowerCase();

        return jsonClasse == selectedClasse &&
            jsonMatiere == selectedMatiere &&
            jsonBareme == selectedBareme;
      },
      orElse: () => null,
    );

    if (result != null) {
      solutionsData = {
        'solution': result['solution'],
        'probleme': result['probleme'],
      };
    }

    const serverUrl = 'http://localhost:5000/generate-pdf';
    
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'groupedStudents': groupedStudents,
        'className': widget.className,
        'matiereName': widget.matiereName,
        'baremeName': widget.baremeName,
        'sousBaremeName': widget.sousBaremeName,
        'profName': widget.profName,
        'schoolName': widget.schoolName,
        'solutionsData': solutionsData, // Données uniques
      }),
    );

    if (response.statusCode == 200) {
      // Pour Flutter Web
      final bytes = response.bodyBytes;
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'classification.pdf')
        ..click();
      
      html.Url.revokeObjectUrl(url);
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: ${e.toString()}')),
    );
  }
}

  // Future<void> saveAndOpenPDF(Uint8List bytes) async {
  //   final directory = await getApplicationDocumentsDirectory();
  //   final file = File('${directory.path}/classification.pdf');
  //   await file.writeAsBytes(bytes);
  //   OpenFile.open(file.path);
  // }

  Future<Map<String, dynamic>> _getGroupedStudentsData() async {
    var students = await _getClassifiedStudents(
        widget.selectedClass, widget.selectedBaremeId);
    Map<String, List<Map<String, String>>> groupedStudents = {};

    for (var student in students) {
      String group = student['group'] ?? '';
      if (!groupedStudents.containsKey(group)) {
        groupedStudents[group] = [];
      }
      groupedStudents[group]!.add(student);
    }

    return groupedStudents;
  }

  Future<void> _saveAndLaunchPDF(Uint8List bytes, String fileName) async {
    final directory = await getExternalStorageDirectory();
    final file = File('${directory?.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('خطة العلاج وأصل الخطأ'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.print),
              onPressed: _generateAndSavePDF,
              tooltip: 'Exporter en PDF',
            ),
          ],
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
                    'في مادة ${widget.matiereName} في معيار ${widget.sousBaremeName ?? widget.baremeName}',
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
                                  showSolutionAndProbleme(groupName);
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
