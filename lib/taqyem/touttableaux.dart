import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ClassListPage extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(child: Text('Utilisateur non connecté.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('قائمة الفصول', textDirection: TextDirection.rtl),
        backgroundColor: Colors.blue,
        elevation: 4,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .collection('user_classes')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('خطأ: ${snapshot.error}',
                      textDirection: TextDirection.rtl));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text('لم يتم العثور على أي فصل.',
                      textDirection: TextDirection.rtl));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var classDoc = snapshot.data!.docs[index];
                var classData = classDoc.data() as Map<String, dynamic>;
                var className = classData['class_name'] ?? 'فصل غير معروف';
                var classId = classData['class_id'] ?? '';

                return ListTile(
                  title: Text(className, textDirection: TextDirection.rtl),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatiereListPage(
                          SelectedClass: classId,

                          selectedClass: classId,
                          currentUser: currentUser!,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}



class MatiereListPage extends StatelessWidget {
  final String selectedClass;
  final String SelectedClass;

  final User currentUser;

  MatiereListPage({
        required this.SelectedClass,

    required this.selectedClass,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قائمة المواد', textDirection: TextDirection.rtl),
        backgroundColor: Colors.blue,
        elevation: 4,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .doc(selectedClass)
              .collection('matieres')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('خطأ: ${snapshot.error}',
                      textDirection: TextDirection.rtl));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text('لم يتم العثور على أي مادة.',
                      textDirection: TextDirection.rtl));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var matiereDoc = snapshot.data!.docs[index];
                var matiereData = matiereDoc.data() as Map<String, dynamic>;
                var matiereName = matiereData['name'] ?? 'مادة غير معروفة';
                var matiereId = matiereDoc.id;

                return ListTile(
                  title: Text(matiereName, textDirection: TextDirection.rtl),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TablePage(
                       // SelectedClass: SelectedClass,

                          selectedClass: selectedClass,
                          selectedMatiere: matiereId,
                          currentUser: currentUser,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}class TablePage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;
  final User currentUser;

  TablePage({
    required this.selectedClass,
    required this.selectedMatiere,
    required this.currentUser,
  });

  @override
  _TablePageState createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  String _profName = '';
  String _schoolName = '';
  bool _isDialogCompleted = false;

  // Variables pour stocker les marques
  Map<String, int> sumCriteriaMaxPerBareme = {};
  int totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Charger les données depuis Firestore
    fetchMarks(); // Récupérer les marques au chargement de la page
  }

  // Charger les données depuis Firestore
  void _loadUserData() async {
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
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

  void _showInputDialog() {
    // Implémentez la logique pour afficher la boîte de dialogue ici
  }

  // Récupérer les marques depuis Firestore
  Future<void> fetchMarks() async {
    try {
      // Récupérer tous les élèves de la classe
      var studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .where('class_id', isEqualTo: widget.selectedClass)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        print('Aucune classe trouvée pour cet utilisateur.');
        return;
      }

      var classDocId = studentsSnapshot.docs.first.id;

      var students = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(classDocId)
          .collection('students')
          .get();

      setState(() {
        totalStudents = students.docs.length; // Mettre à jour le nombre total d'élèves
      });

      // Récupérer les barèmes sélectionnés
      var selectedBaremes = await FirebaseFirestore.instance
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      // Initialiser les compteurs pour chaque barème
      for (var baremeDoc in selectedBaremes.docs) {
        var baremeId = baremeDoc['baremeId'];
        sumCriteriaMaxPerBareme[baremeId] = 0;
      }

      // Parcourir chaque élève
      for (var studentDoc in students.docs) {
        var studentId = studentDoc.id;

        // Parcourir chaque barème
        for (var baremeDoc in selectedBaremes.docs) {
          var baremeId = baremeDoc['baremeId'];

          // Récupérer la valeur du barème pour l'élève
          var baremeSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUser.uid)
              .collection('user_classes')
              .doc(classDocId)
              .collection('students')
              .doc(studentId)
              .collection('baremes')
              .doc(baremeId)
              .get();

          if (baremeSnapshot.exists) {
            var value = baremeSnapshot['value'];

            // Compter les occurrences de +++ et ++-
            if (value == '( + + + )' || value == '( + + - )') {
              sumCriteriaMaxPerBareme[baremeId] =
                  (sumCriteriaMaxPerBareme[baremeId] ?? 0) + 1;
            }
          }
        }
      }

      // Mettre à jour l'interface utilisateur
      setState(() {});
    } catch (e) {
      print('Erreur lors de la récupération des marques : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontFamily: 'ArabicFont', fontSize: 14),
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('الجدول الجامع للنتائج', textDirection: TextDirection.rtl),
          backgroundColor: Colors.blue,
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
                    border: Border.all(color: Color.fromARGB(255, 243, 243, 243)),
                  ),
                  child: Row(
                    children: [
                      // Professeur, matière et classe à gauche (alignés verticalement)
                      FutureBuilder<Map<String, String>>(
                        future: _getClassAndMatiereNames(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
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
                            crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
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
                                'القسم: ${classAndMatiereNames['className']}',
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
                  child: _buildTable(),
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
      // Récupérer le nom de la classe
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();
      var className = classDoc['name'] ?? 'غير معروف';

      // Récupérer le nom de la matière
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

  Widget _buildTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .where('class_id', isEqualTo: widget.selectedClass)
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

        var classDoc = userClassesSnapshot.data!.docs.first;
        var classDocId = classDoc.id;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUser.uid)
              .collection('user_classes')
              .doc(classDocId)
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
        );
      },
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
                  rows: [
                    ...studentsDocs.map((doc) {
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
                                      return CircularProgressIndicator(); // Afficher un indicateur de chargement
                                    }
                                    if (snapshot.hasError) {
                                      return Text('خطأ',
                                          textDirection: TextDirection
                                              .rtl); // Afficher une erreur
                                    }
                                    return Text(
                                      snapshot.data ??
                                          '( - - - )', // Afficher la valeur ou une valeur par défaut
                                      textDirection: TextDirection.rtl,
                                      style:
                                          TextStyle(color: Colors.grey.shade800),
                                    );
                                  },
                                ),
                              ),
                            ),
                      ],
                    );
                  }).toList(),
                  // Ajouter la ligne pour la somme des élèves avec les critères +++ et ++-
                  DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: 150,
                          child: Text(
                            'عدد التلاميذ المحققين للتملك الأدنى',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ),
                      for (var bareme in baremesValues)
                        DataCell(
                          Container(
                            width: 100,
                            child: Text(
                              sumCriteriaMaxPerBareme[bareme['id']!].toString(),
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Ajouter la ligne pour le pourcentage
                  DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: 150,
                          child: Text(
                            'النسبة المئوية للتلاميذ المحققين للتملك',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ),
                      for (var bareme in baremesValues)
                        DataCell(
                          Container(
                            width: 100,
                            child: Text(
                              '${((sumCriteriaMaxPerBareme[bareme['id']!] ?? 0) / totalStudents * 100).toStringAsFixed(2)}%',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ));
          
          },
        );
      },
    );
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

  Future<String> _getSelectedValue(String studentId, String baremeId) async {
    try {
      print('Récupération de la valeur pour studentId: $studentId, baremeId: $baremeId');

      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .where('class_id', isEqualTo: widget.selectedClass) // Ajoutez cette condition
          .get();

      if (snapshot.docs.isNotEmpty) {
        var classDoc = snapshot.docs.first;
        var classDocId = classDoc.id;

        var studentSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .collection('user_classes')
            .doc(classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeId)
            .get();

        if (studentSnapshot.exists) {
          var data = studentSnapshot.data() as Map<String, dynamic>;
          print('Données récupérées: $data');
          return data['value'] ?? '( - - - )';
        } else {
          print('Aucune donnée trouvée pour ce barème.');
          return '( - - - )';
        }
      } else {
        print('Aucune classe trouvée pour cet utilisateur.');
        return '( - - - )';
      }
    } catch (e) {
      print('Erreur lors de la récupération de la valeur: $e');
      return '( - - - )';
    }
  }
}