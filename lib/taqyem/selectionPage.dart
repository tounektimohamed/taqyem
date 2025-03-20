import 'package:Taqyem/taqyem/listedeselection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Taqyem/taqyem/tableau.dart';
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
  Map<String, bool> _selectedBaremes = {};
  Map<String, Map<String, bool>> _selectedSousBaremes = {};

  @override
  void initState() {
    super.initState();
    _loadExistingSelections();
    _showUtilityDialog(); // Afficher le dialogue d'utilité
  }

  Future<void> _showUtilityDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastShownDate = prefs.getString('lastShownUtilityDate');
    DateTime now = DateTime.now();
    String today = "${now.year}-${now.month}-${now.day}";

    if (lastShownDate != today) {
      // Afficher le dialogue seulement s'il n'a pas été affiché aujourd'hui
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('معلومات عن الواجهة',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            content: Text(
              'هذه الواجهة تتيح لك اختيار المعايير والمؤشرات للقسم والمادة المحددة. '
              'يمكنك تحديد المعايير والمؤشرات وحفظها للرجوع إليها لاحقًا.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('موافق', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );

      // Enregistrer la date d'aujourd'hui comme dernière date d'affichage
      await prefs.setString('lastShownUtilityDate', today);
    }
  }

  void _toggleBaremeSelection(String baremeId) {
    setState(() {
      // Si le barème est sélectionné, désélectionner tous ses sous-barèmes
      if (_selectedBaremes[baremeId] ?? false) {
        _selectedBaremes[baremeId] = false;
        if (_selectedSousBaremes.containsKey(baremeId)) {
          _selectedSousBaremes[baremeId]!.forEach((sousBaremeId, isSelected) {
            _selectedSousBaremes[baremeId]![sousBaremeId] = false;
          });
        }
      } else {
        _selectedBaremes[baremeId] = true;
      }
    });
  }

  Future<void> _loadExistingSelections() async {
    try {
      // Obtenir l'ID de l'utilisateur actuellement connecté
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      // Référence à la collection de sélections de l'utilisateur
      var selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
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

      // Si un sous-barème est sélectionné, désélectionner le barème parent
      if (_selectedSousBaremes[baremeId]![sousBaremeId] ?? false) {
        _selectedBaremes[baremeId] = false;
      } else {
        // Si tous les sous-barèmes sont désélectionnés, permettre la sélection du barème parent
        bool allSousBaremesUnselected = _selectedSousBaremes[baremeId]!
            .values
            .every((isSelected) => !isSelected);
        if (allSousBaremesUnselected) {
          _selectedBaremes[baremeId] = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المعايير و المؤشرات'),
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
            return Center(
                child: Text('خطأ: ${snapshot.error}',
                    style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('لم يتم العثور على أي برنامج.',
                    style: TextStyle(color: Colors.grey)));
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
                        onChanged: (_selectedSousBaremes[baremeId]
                                    ?.values
                                    .any((isSelected) => isSelected) ??
                                false)
                            ? null
                            : (bool? value) {
                                _toggleBaremeSelection(baremeId);
                              },
                        activeColor: Colors.blue,
                      ),
                      Text('المعيار: $baremeValue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  children: [
                    FutureBuilder<QuerySnapshot>(
                      future: bareme.reference.collection('sousBaremes').get(),
                      builder: (context, sousSnapshot) {
                        if (sousSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: Colors.blue));
                        }
                        if (sousSnapshot.hasError) {
                          return Center(
                              child: Text('خطأ: ${sousSnapshot.error}',
                                  style: TextStyle(color: Colors.red)));
                        }
                        if (!sousSnapshot.hasData ||
                            sousSnapshot.data!.docs.isEmpty) {
                          return Center(
                              child: Text('لم يتم العثور على أي مؤشر.',
                                  style: TextStyle(color: Colors.grey)));
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
                                    value: _selectedSousBaremes[baremeId]
                                            ?[sousBaremeId] ??
                                        false,
                                    onChanged: (bool? value) {
                                      _toggleSousBaremeSelection(
                                          baremeId, sousBaremeId);
                                    },
                                    activeColor: Colors.blue,
                                  ),
                                  Text('المؤشر: $sousBaremeName',
                                      style: TextStyle(fontSize: 14)),
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
      // Obtenir l'ID de l'utilisateur actuellement connecté
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      // Référence à la collection de sélections de l'utilisateur
      CollectionReference selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere);

      // Suppression des anciennes sélections
      var oldSelections = await selectionsRef.get();
      for (var doc in oldSelections.docs) {
        var sousBaremesRef = doc.reference.collection('sousBaremes');
        var sousBaremesSnapshot = await sousBaremesRef.get();
        for (var sousDoc in sousBaremesSnapshot.docs) {
          await sousDoc.reference.delete();
        }
        await doc.reference.delete();
      }

      // Sauvegarde des barèmes sélectionnés
      _selectedBaremes.forEach((baremeId, isSelected) async {
        if (isSelected) {
          String baremeName = await _getBaremeName(baremeId);
          await selectionsRef.doc(baremeId).set({
            'baremeId': baremeId,
            'baremeName': baremeName,
            'classId': widget.selectedClass,
            'matiereId': widget.selectedMatiere,
            'selected': true,
            'selectedAt': DateTime.now(),
          });
        }
      });

      // Sauvegarde des sous-barèmes sélectionnés (même sans parent)
      _selectedSousBaremes.forEach((baremeId, sousBaremesMap) async {
        sousBaremesMap.forEach((sousBaremeId, isSelected) async {
          if (isSelected) {
            DocumentReference baremeDocRef = selectionsRef.doc(baremeId);
            DocumentSnapshot baremeDoc = await baremeDocRef.get();

            if (!baremeDoc.exists) {
              String baremeName = await _getBaremeName(baremeId);
              await baremeDocRef.set({
                'baremeId': baremeId,
                'baremeName': baremeName,
                'classId': widget.selectedClass,
                'matiereId': widget.selectedMatiere,
                'selected': false,
                'selectedAt': DateTime.now(),
              });
            }

            String sousBaremeName =
                await _getSousBaremeName(baremeId, sousBaremeId);
            await baremeDocRef.collection('sousBaremes').doc(sousBaremeId).set({
              'sousBaremeId': sousBaremeId,
              'sousBaremeName': sousBaremeName,
              'selected': true,
              'selectedAt': DateTime.now(),
            });
          }
        });
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
          content: Text('Sélections enregistrées avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper function to fetch the name of the bareme
  Future<String> _getBaremeName(String baremeId) async {
    try {
      var baremeDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .collection('baremes')
          .doc(baremeId)
          .get();
      return baremeDoc[
          'value']; // Assuming 'value' contains the name of the bareme
    } catch (e) {
      print('Erreur lors de la récupération du nom du barème: $e');
      return ''; // Return an empty string if an error occurs
    }
  }

  // Helper function to fetch the name of the sous-bareme
  Future<String> _getSousBaremeName(
      String baremeId, String sousBaremeId) async {
    try {
      var sousBaremeDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .collection('baremes')
          .doc(baremeId)
          .collection('sousBaremes')
          .doc(sousBaremeId)
          .get();
      return sousBaremeDoc[
          'name']; // Assuming 'name' contains the name of the sous-bareme
    } catch (e) {
      print('Erreur lors de la récupération du nom du sous-barème: $e');
      return ''; // Return an empty string if an error occurs
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

  // Liste de couleurs pour les groupes de 5 classes
  final List<Color> groupColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.deepPurple,
    Colors.lightGreen,
  ];

  @override
  void initState() {
    super.initState();
    fetchClasses();
    _showIntroDialog(); // Afficher la boîte de dialogue d'introduction
  }

  Future<void> fetchClasses() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('classes').get();
      setState(() {
        // Récupérer les classes et les trier par ordre alphabétique
        classes = snapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
            .toList()
          ..sort((a, b) =>
              a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()));
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
            .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
            .toList();
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
            title: Text('مرحبًا!',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            content: Text(
              'هذه الصفحة تتيح لك اختيار قسم ومادة لعرض المعايير المقابلة. '
              'استخدم القوائم المنسدلة لإجراء الاختيار، ثم انقر على "عرض المعايير".',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('موافق', style: TextStyle(color: Colors.blue)),
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
        title: Text('اختر قسما ومادة', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dropdown amélioré pour les classes
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: DropdownButton<String>(
                    value: selectedClassName,
                    hint:
                        Text('اختر قسما', style: TextStyle(color: Colors.grey)),
                    items: classes.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, String> classe = entry.value;
                      Color color =
                          groupColors[(index ~/ 5) % groupColors.length];
                      return DropdownMenuItem<String>(
                        value: classe['name'],
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: color.withOpacity(
                                    0.3)), // Parenthèse fermante ajoutée ici
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.school,
                                  color: color), // Icône pour la classe
                              SizedBox(width: 10),
                              Text(
                                classe['name']!,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      if (selectedClassId != null &&
                          selectedClassId!.isNotEmpty) {
                        fetchMatieres(selectedClassId!);
                      }
                    },
                    isExpanded: true,
                    underline: SizedBox(),
                    icon: Icon(Icons.arrow_drop_down,
                        color: Colors.blue), // Icône personnalisée
                    dropdownColor: Colors.white, // Couleur de fond du dropdown
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Dropdown pour les matières
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: DropdownButton<String>(
                    value: selectedMatiereName,
                    hint:
                        Text('اختر مادة', style: TextStyle(color: Colors.grey)),
                    items: matieres.map((Map<String, String> matiere) {
                      return DropdownMenuItem<String>(
                        value: matiere['name'],
                        child: Text(matiere['name']!,
                            style: TextStyle(color: Colors.black)),
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
                    isExpanded: true,
                    underline: SizedBox(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedClassId != null &&
                          selectedMatiereId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectedBaremesPage(
                              selectedClass: selectedClassId ?? '',
                              selectedMatiere: selectedMatiereId ?? '',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('الرجاء اختيار قسم و مادة',
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text('عرض المعايير',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedClassId != null &&
                          selectedMatiereId != null) {
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
                            content: Text('الرجاء اختيار قسم و مادة',
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text('برمجة المعايير',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
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
/////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
class SelectedBaremesPage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;

  SelectedBaremesPage(
      {required this.selectedClass, required this.selectedMatiere});

  @override
  _SelectedBaremesPageState createState() => _SelectedBaremesPageState();
}

class _SelectedBaremesPageState extends State<SelectedBaremesPage> {
  @override
  void initState() {
    super.initState();
    _showUtilityDialog(); // Afficher le dialogue d'utilité
  }

  Future<void> _showUtilityDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastShownDate = prefs.getString('lastShownUtilityDate');
    DateTime now = DateTime.now();
    String today = "${now.year}-${now.month}-${now.day}";

    if (lastShownDate != today) {
      // Afficher le dialogue seulement s'il n'a pas été affiché aujourd'hui
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('معلومات عن الواجهة',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            content: Text(
              'هذه الواجهة تتيح لك عرض المعايير والمؤشرات المحددة للقسم والمادة المختارة. '
              'يمكنك أيضًا عرض جدول ديناميكي للمعايير والمؤشرات.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('موافق', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );

      // Enregistrer la date d'aujourd'hui comme dernière date d'affichage
      await prefs.setString('lastShownUtilityDate', today);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir l'ID de l'utilisateur actuellement connecté
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('البرامج والبرامج الفرعية المحددة'),
        ),
        body: Center(
          child: Text('المستخدم غير متصل. يرجى تسجيل الدخول.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('المعايير و المؤشرات المحددة'),
      ),
      body: Column(
        children: [
          // Bouton en haut de la liste
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DynamicTablePage(
                      selectedClass: widget.selectedClass,
                      selectedMatiere: widget.selectedMatiere,
                    ),
                  ),
                );
              },
              child: Text('عرض الجدول'), // Traduction en arabe
            ),
          ),
          // Liste des barèmes et sous-barèmes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('selections')
                  .doc(widget.selectedClass)
                  .collection(widget.selectedMatiere)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('لا يوجد عناصر محددة'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    bool isBaremeSelected = doc['selected'] ?? false;
                    String baremeName = doc['baremeName'] ?? '';

                    return Column(
                      children: [
                        // Affichage du barème si sélectionné
                        if (isBaremeSelected)
                          ListTile(
                            title: Text(
                              'المعيار: $baremeName',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),

                        // Affichage des sous-barèmes
                        StreamBuilder<QuerySnapshot>(
                          stream: doc.reference
                              .collection('sousBaremes')
                              .snapshots(),
                          builder: (context, sousSnapshot) {
                            if (sousSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (sousSnapshot.hasError) {
                              return Text('خطأ: ${sousSnapshot.error}');
                            }

                            var sousBaremes = sousSnapshot.data?.docs ?? [];

                            return Column(
                              children: sousBaremes.map((sousDoc) {
                                String sousBaremeName =
                                    sousDoc['sousBaremeName'] ?? '';
                                return ListTile(
                                  title: Text('المؤشر: $sousBaremeName'),
                                  subtitle: Text(
                                    isBaremeSelected
                                        ? 'المعيار الأب: $baremeName'
                                        : 'المعيار الأب غير محدد: $baremeName',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  leading: Icon(Icons.arrow_right),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}