import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingPage extends StatefulWidget {
  final String classId;
  final String subjectName;

  const RatingPage({
    Key? key,
    required this.classId,
    required this.subjectName,
  }) : super(key: key);

  @override
  _DynamicRatingPageState createState() => _DynamicRatingPageState();
}

class _DynamicRatingPageState extends State<RatingPage> {
  String? selectedSubject;
  Map<String, dynamic> ratings = {};
  List<String> criteria = [];
  final List<String> levels = [
    'انعدام التملك (- - -)',
    'دون التملك الأدنى (+ - -)',
    'التملك الأدنى (+ + -)',
    'التملك الأقصى (+ + +)',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCriteria();
  }

  void _initializeCriteria() {
    if (widget.subjectName == 'تواصل شفوي') {
      criteria = [
        'الملاءمة',
        'التّنغيم',
        'الانسجام',
        'الاتّساق',
        'الثـّراء',
      ];
    } else if (widget.subjectName == 'Autre matière') {
      criteria = ['Critère 1', 'Critère 2'];
    } else {
      criteria = [];
    }
  }

  Future<void> fetchRatings() async {
    try {
      String userId = 'exampleUserId'; // Replace with the actual user ID retrieval method
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('classes')
          .doc(widget.classId)
          .collection('subjects')
          .doc(widget.subjectName)
          .get();

      if (snapshot.exists) {
  setState(() {
    final data = snapshot.data() as Map<String, dynamic>?; // Cast explicite
    ratings = data?['ratings'] ?? {};
  });
} else {
  setState(() {
    ratings = {};
  });
}

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des évaluations : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau d\'évaluation'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Matière: ${widget.subjectName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: criteria.isNotEmpty
                  ? Table(
                      border: TableBorder.all(),
                      children: [
                        TableRow(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('المعايير'),
                            ),
                            ...levels.map((level) => Container(
                                  padding: EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: Text(level),
                                )),
                          ],
                        ),
                        ...criteria.map((criterion) {
                          return TableRow(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                child: Text(criterion),
                              ),
                              ...levels.map((level) {
                                String key = '${criterion}_$level';
                                return Container(
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Checkbox(
                                        value: ratings[key]?['checked'] ?? false,
                                        onChanged: (value) {
                                          setState(() {
                                            ratings[key] ??= {};
                                            ratings[key]['checked'] = value;
                                          });
                                        },
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue: ratings[key]?['note']?.toString() ?? '',
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(hintText: 'Note'),
                                          onChanged: (value) {
                                            setState(() {
                                              ratings[key] ??= {};
                                              ratings[key]['note'] = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ],
                    )
                  : Center(
                      child: Text(
                        'Aucun critère défini pour cette matière',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                String userId = 'exampleUserId'; // Replace with actual user ID retrieval
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('classes')
                    .doc(widget.classId)
                    .collection('subjects')
                    .doc(widget.subjectName)
                    .set({'ratings': ratings});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Évaluations enregistrées avec succès')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
                );
              }
            },
            child: Text('Soumettre'),
          ),
        ],
      ),
    );
  }
}
