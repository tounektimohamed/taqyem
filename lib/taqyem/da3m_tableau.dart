import 'package:Taqyem/taqyem/header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour utiliser rootBundle
import 'dart:convert'; // Pour décoder le JSON

class ClassificationPage extends StatefulWidget {
  final String selectedClass;
  final String selectedBaremeId;
  final User currentUser;
  final String profName;
  final String schoolName;
  final String className;
  final String matiereName;
  final String baremeName; // Nom du barème
  final String? sousBaremeName; // Nom du sous-barème (optionnel)
  final String? selectedSousBaremeId; // ID du sous-barème (optionnel)

  ClassificationPage({
    required this.selectedClass,
    required this.selectedBaremeId,
    required this.currentUser,
    required this.profName,
    required this.schoolName,
    required this.className,
    required this.matiereName,
    required this.baremeName,
    this.sousBaremeName, // Ajoutez ce paramètre
    this.selectedSousBaremeId, // Ajoutez ce paramètre
  });

  @override
  _ClassificationPageState createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
  List<dynamic> jsonData = []; // Pour stocker les données JSON

  @override
  void initState() {
    super.initState();
    printVariables(); // Afficher les variables dans la console
    loadJsonData(); // Charger les données JSON au démarrage
  }

  // Méthode pour afficher les variables dans la console
  void printVariables() {
    print("Classe sélectionnée: ${widget.selectedClass}");
    print("ID du barème sélectionné: ${widget.selectedBaremeId}");
    print("Utilisateur actuel: ${widget.currentUser}");
    print("Nom du professeur: ${widget.profName}");
    print("Nom de l'école: ${widget.schoolName}");
    print("Nom de la classe: ${widget.className}");
    print("Nom de la matière: ${widget.matiereName}");
    print("Nom du barème: ${widget.baremeName ?? 'Non défini'}"); // Gestion de la valeur nulle
    print("ID du sous-barème sélectionné: ${widget.selectedSousBaremeId ?? 'Non défini'}"); // Gestion de la valeur nulle
    print("Nom du sous-barème: ${widget.sousBaremeName ?? 'Non défini'}"); // Gestion de la valeur nulle
  }

  // Méthode pour charger les données JSON
  Future<void> loadJsonData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/data.json');
      setState(() {
        jsonData = json.decode(jsonString); // Décoder le JSON
      });
    } catch (e) {
      print("Erreur lors du chargement du fichier JSON: $e");
    }
  }

  // Méthode pour afficher la solution et le problème
  void showSolutionAndProbleme(String groupName) {
    // Afficher les valeurs pour déboguer
    print("Classe sélectionnée: ${widget.className}");
    print("Matière sélectionnée: ${widget.matiereName}");
    print("Barème sélectionné: ${widget.baremeName}");
    print("Sous-barème sélectionné: ${widget.sousBaremeName ?? 'Non défini'}");

    // Filtrer les données JSON
    var result = jsonData.firstWhere(
      (item) {
        // Normaliser les chaînes de caractères
        String jsonClasse = item['classe'].trim().toLowerCase();
        String jsonMatiere = item['matiere'].trim().toLowerCase();
        String jsonBareme = item['bareme'].trim().toLowerCase();

        String selectedClasse = widget.className.trim().toLowerCase();
        String selectedMatiere = widget.matiereName.trim().toLowerCase();
        String selectedBareme = (widget.sousBaremeName ?? widget.baremeName).trim().toLowerCase(); // Utiliser le sous-barème ou le barème

        // Comparer les valeurs normalisées
        bool condition = jsonClasse == selectedClasse &&
            jsonMatiere == selectedMatiere &&
            jsonBareme == selectedBareme;

        return condition;
      },
      orElse: () => null,
    );

    if (result != null) {
      String solution = result['solution'];
      String probleme = result['probleme'];

      // Afficher les données dans une boîte de dialogue
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
      // Si aucune donnée correspondante n'est trouvée
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
                    'في مادة ${widget.matiereName} في معيار ${widget.sousBaremeName ?? widget.baremeName}', // Afficher le sous-barème ou le barème
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

                  // Grouper les élèves par nom de groupe
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
                                  // Afficher les valeurs sélectionnées dans le terminal
                                  print(
                                      "Classe sélectionnée: ${widget.className}");
                                  print(
                                      "Matière sélectionnée: ${widget.matiereName}");
                                  print(
                                      "Barème sélectionné: ${widget.baremeName}");
                                  print(
                                      "Sous-barème sélectionné: ${widget.sousBaremeName ?? 'Non défini'}");

                                  // Appeler la méthode pour afficher la solution et le problème
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