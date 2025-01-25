import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BaremesPage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;

  BaremesPage({required this.selectedClass, required this.selectedMatiere});

  @override
  _BaremesPageState createState() => _BaremesPageState();
}

class _BaremesPageState extends State<BaremesPage> {
  // États pour gérer les sélections
  Map<String, bool> _selectedBaremes = {}; // Sélection des barèmes
  Map<String, Map<String, bool>> _selectedSousBaremes = {}; // Sélection des sous-barèmes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barèmes et Sous-Barèmes'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSelections, // Enregistrer les sélections
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.selectedClass)
            .collection('matieres')
            .doc(widget.selectedMatiere)
            .collection('baremes')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucun barème trouvé.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var bareme = snapshot.data!.docs[index];
              var baremeId = bareme.id;
              var baremeValue = bareme['value'];

              // Initialiser l'état de la checkbox pour le barème
              if (!_selectedBaremes.containsKey(baremeId)) {
                _selectedBaremes[baremeId] = false;
              }

              return ExpansionTile(
                title: Row(
                  children: [
                    Checkbox(
                      value: _selectedBaremes[baremeId],
                      onChanged: (bool? value) {
                        setState(() {
                          _selectedBaremes[baremeId] = value!;
                        });
                      },
                    ),
                    Text('Barème: $baremeValue'),
                  ],
                ),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        bareme.reference.collection('sousBaremes').snapshots(),
                    builder: (context, sousSnapshot) {
                      if (sousSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (sousSnapshot.hasError) {
                        return Center(
                            child: Text('Erreur: ${sousSnapshot.error}'));
                      }
                      if (!sousSnapshot.hasData ||
                          sousSnapshot.data!.docs.isEmpty) {
                        return Center(child: Text('Aucun sous-barème trouvé.'));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: sousSnapshot.data!.docs.length,
                        itemBuilder: (context, sousIndex) {
                          var sousBareme = sousSnapshot.data!.docs[sousIndex];
                          var sousBaremeId = sousBareme.id;
                          var sousBaremeName = sousBareme['name'];

                          // Initialiser l'état de la checkbox pour le sous-barème
                          if (!_selectedSousBaremes.containsKey(baremeId)) {
                            _selectedSousBaremes[baremeId] = {};
                          }
                          if (!_selectedSousBaremes[baremeId]!
                              .containsKey(sousBaremeId)) {
                            _selectedSousBaremes[baremeId]![sousBaremeId] =
                                false;
                          }

                          return ListTile(
                            title: Row(
                              children: [
                                Checkbox(
                                  value: _selectedSousBaremes[baremeId]![
                                      sousBaremeId],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _selectedSousBaremes[baremeId]![
                                          sousBaremeId] = value!;
                                    });
                                  },
                                ),
                                Text('Sous-Barème: $sousBaremeName'),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Fonction pour enregistrer les sélections
  Future<void> _saveSelections() async {
    try {
      // Référence à la collection "selections"
      CollectionReference selectionsRef = FirebaseFirestore.instance
          .collection('selections')
          .doc(widget.selectedClass) // Utiliser l'ID de la classe comme document
          .collection(widget.selectedMatiere); // Utiliser l'ID de la matière comme sous-collection

      // Enregistrer les barèmes sélectionnés
      _selectedBaremes.forEach((baremeId, isSelected) async {
        if (isSelected) {
          await selectionsRef.add({
            'baremeId': baremeId,
            'classId': widget.selectedClass,
            'matiereId': widget.selectedMatiere,
            'selectedAt': DateTime.now(),
          });

          // Enregistrer les sous-barèmes sélectionnés pour ce barème
          if (_selectedSousBaremes.containsKey(baremeId)) {
            var sousBaremesRef = selectionsRef
                .doc(baremeId)
                .collection('sousBaremes'); // Sous-collection pour les sous-barèmes
            _selectedSousBaremes[baremeId]!.forEach((sousBaremeId, isSelected) async {
              if (isSelected) {
                await sousBaremesRef.doc(sousBaremeId).set({
                  'selected': true,
                  'selectedAt': DateTime.now(),
                });
              }
            });
          }
        }
      });

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sélections enregistrées avec succès!'),
        ),
      );
    } catch (e) {
      // Afficher un message d'erreur en cas de problème
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement: $e'),
        ),
      );
    }
  }
}
class SelectionPage extends StatefulWidget {
  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String? selectedClassId;
  String? selectedClassName;
  String? selectedMatiereId;
  String? selectedMatiereName;
  List<Map<String, String>> classes = [];
  List<Map<String, String>> matieres = [];

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('classes').get();
      setState(() {
        classes = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] as String,
                })
            .toList();
      });
    } catch (e) {
      print('Erreur lors de la récupération des classes: $e');
    }
  }

  Future<void> fetchMatieres(String classId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('matieres')
          .get();
      setState(() {
        matieres = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] as String,
                })
            .toList();
      });
    } catch (e) {
      print('Erreur lors de la récupération des matières: $e');
    }
  }

  Future<void> addIndicationToSousBaremes(String classId, String matiereId) async {
    try {
      final baremesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('matieres')
          .doc(matiereId)
          .collection('baremes')
          .get();

      for (var bareme in baremesSnapshot.docs) {
        final sousBaremesSnapshot = await bareme.reference.collection('sousBaremes').get();

        for (var sousBareme in sousBaremesSnapshot.docs) {
          if (!sousBareme.data().containsKey('indication')) {
            await sousBareme.reference.update({
              'indication': 'انعدام التملك ( - - - )',
            });
          }
        }
      }

      print('Champ "indication" ajouté avec succès à tous les sous-barèmes.');
    } catch (e) {
      print('Erreur lors de l\'ajout du champ "indication": $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionnez une classe et une matière'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedClassName,
              hint: Text('Sélectionnez une classe'),
              items: classes.map((Map<String, String> classe) {
                return DropdownMenuItem<String>(
                  value: classe['name'],
                  child: Text(classe['name']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedClassName = newValue;
                  selectedClassId = classes.firstWhere(
                    (classe) => classe['name'] == newValue,
                    orElse: () => {'id': '', 'name': ''},
                  )['id'];
                  selectedMatiereId = null;
                  selectedMatiereName = null;
                  matieres.clear();
                });
                if (selectedClassId != null && selectedClassId!.isNotEmpty) {
                  fetchMatieres(selectedClassId!);
                }
              },
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedMatiereName,
              hint: Text('Sélectionnez une matière'),
              items: matieres.map((Map<String, String> matiere) {
                return DropdownMenuItem<String>(
                  value: matiere['name'],
                  child: Text(matiere['name']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedMatiereName = newValue;
                  selectedMatiereId = matieres.firstWhere(
                    (matiere) => matiere['name'] == newValue,
                    orElse: () => {'id': '', 'name': ''},
                  )['id'];
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (selectedClassId != null && selectedMatiereId != null) {
                  await addIndicationToSousBaremes(selectedClassId!, selectedMatiereId!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BaremesPage(
                        selectedClass: selectedClassId!,
                        selectedMatiere: selectedMatiereId!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Veuillez sélectionner une classe et une matière'),
                    ),
                  );
                }
              },
              child: Text('Afficher les barèmes'),
            ),
          ],
        ),
      ),
    );
  }
}