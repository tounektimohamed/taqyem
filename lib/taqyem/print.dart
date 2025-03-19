import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentEvaluationPage extends StatefulWidget {
 final String selectedClass;
  final String selectedMatiere;

  StudentEvaluationPage({required this.selectedClass, required this.selectedMatiere});

  @override
  _StudentEvaluationPageState createState() => _StudentEvaluationPageState();
}

class _StudentEvaluationPageState extends State<StudentEvaluationPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> baremes = [];
  List<Map<String, dynamic>> sousBaremes = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _fetchBaremes();
  }

  Future<void> _fetchStudents() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(widget.selectedClass)
          .collection('students')
          .get();

      setState(() {
        students = studentsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors de la récupération des étudiants : $e");
    }
  }
  
  Future<void> _fetchBaremes() async {
  try {
    final baremesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('selections')
        .doc(widget.selectedClass)
        .collection(widget.selectedMatiere)
        .get();

    List<Map<String, dynamic>> baremesWithValue = [];
    List<Map<String, dynamic>> baremesWithoutValue = [];

    for (var baremeDoc in baremesSnapshot.docs) {
      final baremeId = baremeDoc.id;
      final baremeName = baremeDoc['baremeName'];

      // Vérifier si le barème a une valeur
      final evaluation = await _getEvaluation('dummyStudentId', baremeId); // Utilisez un étudiant fictif pour vérifier
      if (evaluation != null) {
        // Barème avec une valeur
        baremesWithValue.add({
          'id': baremeId,
          'baremeName': baremeName,
          'value': evaluation,
        });
      } else {
        // Barème sans valeur, vérifiez s'il a des sous-barèmes
        final sousBaremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('selections')
            .doc(widget.selectedClass)
            .collection(widget.selectedMatiere)
            .doc(baremeId)
            .collection('sousBaremes')
            .get();

        if (sousBaremesSnapshot.docs.isNotEmpty) {
          // Barème sans valeur mais avec des sous-barèmes
          baremesWithoutValue.add({
            'id': baremeId,
            'baremeName': baremeName,
          });

          // Ajouter les sous-barèmes
          setState(() {
            sousBaremes.addAll(sousBaremesSnapshot.docs.map((doc) {
              return {
                'id': doc.id,
                'sousBaremeName': doc['sousBaremeName'],
                'baremeId': baremeId,
              };
            }).toList());
          });
        }
      }
    }

    setState(() {
      baremes = [...baremesWithValue, ...baremesWithoutValue];
    });
  } catch (e) {
    print("Erreur lors de la récupération des barèmes : $e");
  }
}
  Future<String?> _getEvaluation(String studentId, String baremeId, {String? sousBaremeId}) async {
  try {
    var docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('user_classes')
        .doc(widget.selectedClass)
        .collection('students')
        .doc(studentId)
        .collection('baremes')
        .doc(baremeId);

    if (sousBaremeId != null) {
      docRef = docRef.collection('sousBaremes').doc(sousBaremeId);
    }

    var doc = await docRef.get();
    if (doc.exists && doc.data()?.containsKey('value') == true) {
      return doc['value'] as String?;
    }
    return null; // Retourne null si le document ou le champ 'value' n'existe pas
  } catch (e) {
    print('Erreur lors de la récupération de l\'évaluation: $e');
    return null;
  }
}
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Évaluations des étudiants'),
    ),
    body: students.isEmpty || baremes.isEmpty
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Étudiant')),
                // Colonnes pour les barèmes avec une valeur
                ...baremes.where((bareme) => bareme['value'] != null).map((bareme) {
                  return DataColumn(label: Text(bareme['baremeName']));
                }).toList(),
                // Colonnes pour les sous-barèmes des barèmes sans valeur
                ...sousBaremes.map((sousBareme) {
                  return DataColumn(label: Text(sousBareme['sousBaremeName']));
                }).toList(),
              ],
              rows: students.map((student) {
                return DataRow(
                  cells: [
                    DataCell(Text(student['name'])),
                    // Cellules pour les barèmes avec une valeur
                    ...baremes.where((bareme) => bareme['value'] != null).map((bareme) {
                      return DataCell(
                        FutureBuilder<String?>(
                          future: _getEvaluation(student['id'], bareme['id']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Erreur');
                            } else {
                              return Text(snapshot.data ?? 'Non évalué');
                            }
                          },
                        ),
                      );
                    }).toList(),
                    // Cellules pour les sous-barèmes des barèmes sans valeur
                    ...sousBaremes.map((sousBareme) {
                      return DataCell(
                        FutureBuilder<String?>(
                          future: _getEvaluation(student['id'], sousBareme['baremeId'], sousBaremeId: sousBareme['id']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Erreur');
                            } else {
                              return Text(snapshot.data ?? 'Non évalué');
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
          ),
  );
}}