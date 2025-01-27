import 'package:Taqyem/taqyem/test.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaremesPage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;

  BaremesPage({required this.selectedClass, required this.selectedMatiere});

  @override
  _BaremesPageState createState() => _BaremesPageState();
}

class _BaremesPageState extends State<BaremesPage> {
  Map<String, bool> _selectedBaremes = {};
  Map<String, Map<String, bool>> _selectedSousBaremes = {};

  void _toggleBaremeSelection(String baremeId) {
    setState(() {
      _selectedBaremes[baremeId] = !(_selectedBaremes[baremeId] ?? false);
    });
  }

  Future<void> _loadExistingSelections() async {
    try {
      var selectionsRef = FirebaseFirestore.instance
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere);

      var baremesSnapshot = await selectionsRef.get();
      for (var baremeDoc in baremesSnapshot.docs) {
        var baremeId = baremeDoc['baremeId'];
        _selectedBaremes[baremeId] = true;

        var sousBaremesSnapshot =
            await baremeDoc.reference.collection('sousBaremes').get();
        for (var sousBaremeDoc in sousBaremesSnapshot.docs) {
          var sousBaremeId = sousBaremeDoc.id;
          if (!_selectedSousBaremes.containsKey(baremeId)) {
            _selectedSousBaremes[baremeId] = {};
          }
          _selectedSousBaremes[baremeId]![sousBaremeId] = true;
        }
      }

      setState(() {});
    } catch (e) {
      print('Erreur lors du chargement des sélections existantes: $e');
    }
  }

  void _toggleSousBaremeSelection(String baremeId, String sousBaremeId) {
    setState(() {
      if (!_selectedSousBaremes.containsKey(baremeId)) {
        _selectedSousBaremes[baremeId] = {};
      }
      _selectedSousBaremes[baremeId]![sousBaremeId] =
          !(_selectedSousBaremes[baremeId]![sousBaremeId] ?? false);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadExistingSelections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barèmes et Sous-Barèmes'),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Color.fromARGB(255, 23, 192, 23)),
            onPressed: _saveSelections,
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
            return Center(child: CircularProgressIndicator(color: Colors.blue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucun barème trouvé.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var bareme = snapshot.data!.docs[index];
              var baremeId = bareme.id;
              var baremeValue = bareme['value'];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Checkbox(
                        value: _selectedBaremes[baremeId] ?? false,
                        onChanged: (bool? value) {
                          _toggleBaremeSelection(baremeId);
                        },
                        activeColor: Colors.blue,
                      ),
                      Text('Barème: $baremeValue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  children: [
                    FutureBuilder<QuerySnapshot>(
                      future: bareme.reference.collection('sousBaremes').get(),
                      builder: (context, sousSnapshot) {
                        if (sousSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: Colors.blue));
                        }
                        if (sousSnapshot.hasError) {
                          return Center(child: Text('Erreur: ${sousSnapshot.error}', style: TextStyle(color: Colors.red)));
                        }
                        if (!sousSnapshot.hasData || sousSnapshot.data!.docs.isEmpty) {
                          return Center(child: Text('Aucun sous-barème trouvé.', style: TextStyle(color: Colors.grey)));
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: sousSnapshot.data!.docs.length,
                          itemBuilder: (context, sousIndex) {
                            var sousBareme = sousSnapshot.data!.docs[sousIndex];
                            var sousBaremeId = sousBareme.id;
                            var sousBaremeName = sousBareme['name'];

                            return ListTile(
                              title: Row(
                                children: [
                                  Checkbox(
                                    value: _selectedSousBaremes[baremeId]?[sousBaremeId] ?? false,
                                    onChanged: (bool? value) {
                                      _toggleSousBaremeSelection(baremeId, sousBaremeId);
                                    },
                                    activeColor: Colors.blue,
                                  ),
                                  Text('Sous-Barème: $sousBaremeName', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _saveSelections() async {
    try {
      CollectionReference selectionsRef = FirebaseFirestore.instance
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere);

      var oldSelections = await selectionsRef.get();
      for (var doc in oldSelections.docs) {
        var sousBaremesRef = doc.reference.collection('sousBaremes');
        var sousBaremesSnapshot = await sousBaremesRef.get();
        for (var sousDoc in sousBaremesSnapshot.docs) {
          await sousDoc.reference.delete();
        }
        await doc.reference.delete();
      }

      _selectedBaremes.forEach((baremeId, isSelected) async {
        if (isSelected) {
          await selectionsRef.add({
            'baremeId': baremeId,
            'classId': widget.selectedClass,
            'matiereId': widget.selectedMatiere,
            'selectedAt': DateTime.now(),
          });

          if (_selectedSousBaremes.containsKey(baremeId)) {
            var sousBaremesRef = selectionsRef.doc(baremeId).collection('sousBaremes');
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectedBaremesPage(
            selectedClass: widget.selectedClass,
            selectedMatiere: widget.selectedMatiere,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sélections enregistrées avec succès!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement: $e', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

//////////////////////////////////////////////
////////////////////////////////////////////////

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
    _showIntroDialog(); // Afficher la boîte de dialogue d'introduction
  }

  Future<void> fetchClasses() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('classes').get();
      setState(() {
        classes = snapshot.docs.map((doc) => {'id': doc.id, 'name': doc['name'] as String}).toList();
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
        matieres = snapshot.docs.map((doc) => {'id': doc.id, 'name': doc['name'] as String}).toList();
      });
    } catch (e) {
      print('Erreur lors de la récupération des matières: $e');
    }
  }

  Future<void> _showIntroDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastShownDate = prefs.getString('lastShownDate');
    DateTime now = DateTime.now();
    String today = "${now.year}-${now.month}-${now.day}";

    if (lastShownDate != today) {
      // Afficher la boîte de dialogue seulement si elle n'a pas été affichée aujourd'hui
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Bienvenue !', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            content: Text(
              'Cette page vous permet de sélectionner une classe et une matière pour afficher les barèmes correspondants. '
              'Utilisez les menus déroulants pour faire votre sélection, puis cliquez sur "Afficher les barèmes".',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );

      // Enregistrer la date d'aujourd'hui comme dernière date d'affichage
      await prefs.setString('lastShownDate', today);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionnez une classe et une matière', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 4, // Ombre sous l'AppBar
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Menu déroulant pour la classe
              Card(
                elevation: 4, // Ombre
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Bordures arrondies
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: DropdownButton<String>(
                    value: selectedClassName,
                    hint: Text('Sélectionnez une classe', style: TextStyle(color: Colors.grey)),
                    items: classes.map((Map<String, String> classe) {
                      return DropdownMenuItem<String>(
                        value: classe['name'],
                        child: Text(classe['name']!, style: TextStyle(color: Colors.black)),
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
                    isExpanded: true, // Prend toute la largeur disponible
                    underline: SizedBox(), // Supprime la ligne par défaut
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Menu déroulant pour la matière
              Card(
                elevation: 4, // Ombre
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Bordures arrondies
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: DropdownButton<String>(
                    value: selectedMatiereName,
                    hint: Text('Sélectionnez une matière', style: TextStyle(color: Colors.grey)),
                    items: matieres.map((Map<String, String> matiere) {
                      return DropdownMenuItem<String>(
                        value: matiere['name'],
                        child: Text(matiere['name']!, style: TextStyle(color: Colors.black)),
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
                    isExpanded: true, // Prend toute la largeur disponible
                    underline: SizedBox(), // Supprime la ligne par défaut
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Bouton avec icône d'œil
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_red_eye, color: Colors.blue, size: 30), // Icône d'œil
                    onPressed: () {
                      // Action à effectuer lorsque l'icône est cliquée
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectedBaremesPage(
                            selectedClass: selectedClassId ?? '',
                            selectedMatiere: selectedMatiereId ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 10), // Espace entre l'icône et le bouton
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedClassId != null && selectedMatiereId != null) {
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
                            content: Text('Veuillez sélectionner une classe et une matière', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating, // SnackBar flottante
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Bordures arrondies
                            ),
                          ),
                        );
                      }
                    },
                    child: Text('Programmer un barème', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Bordures arrondies
                      ),
                      elevation: 4, // Ombre
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}