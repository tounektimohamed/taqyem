import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  List<Map<String, String>> students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final studentsData = await _getClassifiedStudents(
      widget.selectedClass,
      widget.selectedBaremeId,
    );
    setState(() {
      students = studentsData;
    });
  }

  // Préparer les données pour le PDF
  Map<String, dynamic> preparePdfData() {
    return {
      'profName': widget.profName,
      'schoolName': widget.schoolName,
      'className': widget.className,
      'matiereName': widget.matiereName,
      'baremeName': widget.baremeName,
      'sousBaremeName': widget.sousBaremeName,
      'students': students.map((student) => {
        'name': student['name'],
        'group': student['group'],
      }).toList(),
    };
  }

  // Envoyer les données à Flask
  Future<void> sendDataToFlask(Map<String, dynamic> data) async {
    final url = Uri.parse('http://votre-adresse-flask/generate-pdf'); // Remplacez par l'URL de votre API Flask
    final headers = {"Content-Type": "application/json"};
    final body = json.encode(data);

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('PDF généré avec succès');
        // Vous pouvez ajouter ici une logique pour télécharger ou afficher le PDF
      } else {
        print('Erreur lors de la génération du PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi des données: $e');
    }
  }

  // Récupérer les élèves classés depuis Firestore
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
            'group': group,
          });
        }
      }));
    }

    await Future.wait(futures);
    return students;
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
            // En-tête
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'المدرسة: ${widget.schoolName}',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    'الصف: ${widget.className}',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    'المادة: ${widget.matiereName}',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    'المعيار: ${widget.baremeName}',
                    style: TextStyle(fontSize: 18),
                  ),
                  if (widget.sousBaremeName != null)
                    Text(
                      'المعيار الفرعي: ${widget.sousBaremeName}',
                      style: TextStyle(fontSize: 18),
                    ),
                ],
              ),
            ),

            // Légende
            _buildLegend(),

            // Tableau des élèves
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    title: Text(student['name'] ?? ''),
                    subtitle: Text(student['group'] ?? ''),
                    tileColor: _getGroupColor(student['group']),
                  );
                },
              ),
            ),

            // Bouton pour générer le PDF
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  final pdfData = preparePdfData();
                  await sendDataToFlask(pdfData);
                },
                child: Text('Générer PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Couleur de fond en fonction du groupe
  Color _getGroupColor(String? group) {
    switch (group) {
      case 'مجموعة العلاج':
        return Colors.red.withOpacity(0.7);
      case 'مجموعة الدعم':
        return Colors.orange.withOpacity(0.7);
      case 'مجموعة التميز':
        return Colors.green.withOpacity(0.7);
      default:
        return Colors.transparent;
    }
  }

  // Légende
  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(8),
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

  // Élément de légende
  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}