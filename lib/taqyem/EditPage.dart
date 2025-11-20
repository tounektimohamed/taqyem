import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCrudPage extends StatefulWidget {
  @override
  _AdminCrudPageState createState() => _AdminCrudPageState();
}

class _AdminCrudPageState extends State<AdminCrudPage> {
  String? selectedClass;
  String? selectedMatiere;
  String? selectedBareme;
  String? selectedSousBareme;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _sousBaremeNomController = TextEditingController();
  final TextEditingController _sousBaremeValueController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _sousBaremeNomController.dispose();
    _sousBaremeValueController.dispose();
    super.dispose();
  }

  // Fonction pour vérifier si une classe existe déjà
  Future<bool> classExists(String className) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .where('name', isEqualTo: className)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Fonction pour vérifier si une matière existe déjà dans une classe
  Future<bool> matiereExists(String classId, String matiereName) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('matieres')
        .where('name', isEqualTo: matiereName)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Fonction pour vérifier si un barème existe déjà dans une matière
  Future<bool> baremeExists(String classId, String matiereId, String baremeValue) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('matieres')
        .doc(matiereId)
        .collection('baremes')
        .where('value', isEqualTo: baremeValue)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Fonction pour vérifier si un sous-barème existe déjà dans un barème
  Future<bool> sousBaremeExists(String classId, String matiereId, String baremeId, String sousBaremeName) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('matieres')
        .doc(matiereId)
        .collection('baremes')
        .doc(baremeId)
        .collection('sousBaremes')
        .where('name', isEqualTo: sousBaremeName)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Fonction pour ajouter toutes les données automatiquement
  Future<void> addAllDataAutomatically() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Liste des classes
      List<String> classes = [
        "السنة الأولى ابتدائي",
        "السنة الأولى ابتدائي أ",
        "السنة الأولى ابتدائي ب", 
        "السنة الأولى ابتدائي ج",
        "السنة الأولى ابتدائي د",
        "السنة الثانية ابتدائي",
        "السنة الثانية ابتدائي أ",
        "السنة الثانية ابتدائي ب",
        "السنة الثانية ابتدائي ج",
        "السنة الثانية ابتدائي د",
        "السنة الثالثة ابتدائي",
        "السنة الثالثة ابتدائي أ",
        "السنة الثالثة ابتدائي ب",
        "السنة الثالثة ابتدائي ج",
        "السنة الثالثة ابتدائي د",
        "السنة الرابعة ابتدائي",
        "السنة الرابعة ابتدائي أ",
        "السنة الرابعة ابتدائي ب",
        "السنة الرابعة ابتدائي ج",
        "السنة الرابعة ابتدائي د",
        "السنة الخامسة ابتدائي",
        "السنة الخامسة ابتدائي أ",
        "السنة الخامسة ابتدائي ب",
        "السنة الخامسة ابتدائي ج",
        "السنة الخامسة ابتدائي د",
        "السنة السادسة ابتدائي",
        "السنة السادسة ابتدائي أ",
        "السنة السادسة ابتدائي ب",
        "السنة السادسة ابتدائي ج",
        "السنة السادسة ابتدائي د"
      ];

      // Liste des matières
      List<String> matieres = [
        "التواصل الشفوي", "قراءة", "انتاج كتابي", "رياضيات", "ايقاظ علمي",
        "تربية اسلامية", "تربية تكنولوجية", "تربية موسيقية", "تربية تشكيلية", 
        "تربية بدنية", "قواعد لغة", "Expression orale et récitation", "Lecture",
        "Production écrite", "écriture", "dictée", "langue", "لغة انقليزية",
        "التاريخ", "الجغرافيا", "التربية المدنية"
      ];

      int totalClasses = 0;
      int totalMatieres = 0;
      int totalBaremes = 0;
      int totalSousBaremes = 0;
      int skippedClasses = 0;
      int skippedMatieres = 0;
      int skippedBaremes = 0;
      int skippedSousBaremes = 0;

      // Ajouter chaque classe
      for (String className in classes) {
        // Vérifier si la classe existe déjà
        if (await classExists(className)) {
          print('Classe déjà existante: $className');
          skippedClasses++;
          continue;
        }

        DocumentReference classRef = await FirebaseFirestore.instance
            .collection('classes')
            .add({
              'name': className,
              'createdAt': FieldValue.serverTimestamp()
            });
        totalClasses++;

        // Ajouter chaque matière pour cette classe
        for (String matiereName in matieres) {
          // Vérifier si la matière existe déjà dans cette classe
          if (await matiereExists(classRef.id, matiereName)) {
            print('Matière déjà existante: $matiereName dans $className');
            skippedMatieres++;
            continue;
          }

          DocumentReference matiereRef = await classRef
              .collection('matieres')
              .add({
                'name': matiereName,
                'createdAt': FieldValue.serverTimestamp()
              });
          totalMatieres++;

          // Ajouter 5 barèmes pour chaque matière
          for (int baremeNum = 1; baremeNum <= 5; baremeNum++) {
            String baremeValue = "مع $baremeNum";
            
            // Vérifier si le barème existe déjà
            if (await baremeExists(classRef.id, matiereRef.id, baremeValue)) {
              print('Barème déjà existant: $baremeValue dans $matiereName');
              skippedBaremes++;
              continue;
            }

            DocumentReference baremeRef = await matiereRef
                .collection('baremes')
                .add({
                  'value': baremeValue,
                  'createdAt': FieldValue.serverTimestamp()
                });
            totalBaremes++;

            // Ajouter 3 sous-barèmes pour chaque barème
            for (int sousBaremeNum = 1; sousBaremeNum <= 3; sousBaremeNum++) {
              String sousBaremeName = "مع $baremeNum.$sousBaremeNum";
              String sousBaremeValue = "valeur $baremeNum.$sousBaremeNum";
              
              // Vérifier si le sous-barème existe déjà
              if (await sousBaremeExists(classRef.id, matiereRef.id, baremeRef.id, sousBaremeName)) {
                print('Sous-barème déjà existant: $sousBaremeName');
                skippedSousBaremes++;
                continue;
              }
              
              await baremeRef
                  .collection('sousBaremes')
                  .add({
                    'name': sousBaremeName,
                    'value': sousBaremeValue,
                    'createdAt': FieldValue.serverTimestamp()
                  });
              totalSousBaremes++;
            }
          }
        }
      }

      String message = 'Données ajoutées avec succès!\n'
          'Nouvelles classes: $totalClasses\n'
          'Nouvelles matières: $totalMatieres\n'
          'Nouveaux barèmes: $totalBaremes\n'
          'Nouveaux sous-barèmes: $totalSousBaremes';

      if (skippedClasses > 0 || skippedMatieres > 0 || skippedBaremes > 0 || skippedSousBaremes > 0) {
        message += '\n\nÉléments ignorés (déjà existants):\n'
            'Classes: $skippedClasses\n'
            'Matières: $skippedMatieres\n'
            'Barèmes: $skippedBaremes\n'
            'Sous-barèmes: $skippedSousBaremes';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 8),
      ));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de l\'ajout automatique: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fonction pour supprimer toutes les données
  Future<void> deleteAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer toutes les classes
      QuerySnapshot classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .get();

      int deletedCount = 0;

      // Supprimer chaque classe et ses sous-collections
      for (var classDoc in classesSnapshot.docs) {
        await classDoc.reference.delete();
        deletedCount++;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$deletedCount classes supprimées avec succès!'),
        backgroundColor: Colors.green,
      ));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la suppression: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Edit class avec vérification
  void editClass(String classId) async {
    try {
      String newName = _controller.text.trim();
      if (newName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Le nom ne peut pas être vide'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Vérifier si le nouveau nom existe déjà (sauf pour le document actuel)
      QuerySnapshot existing = await FirebaseFirestore.instance
          .collection('classes')
          .where('name', isEqualTo: newName)
          .get();

      bool nameExists = existing.docs.any((doc) => doc.id != classId);

      if (nameExists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Une classe avec ce nom existe déjà'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .update({'name': newName});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Classe modifiée avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la modification de la classe'),
          backgroundColor: Colors.red));
    }
  }

  // Edit subject avec vérification
  void editMatiere(String matiereId) async {
    try {
      String newName = _controller.text.trim();
      if (newName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Le nom ne peut pas être vide'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Vérifier si le nouveau nom existe déjà dans la même classe
      QuerySnapshot existing = await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .where('name', isEqualTo: newName)
          .get();

      bool nameExists = existing.docs.any((doc) => doc.id != matiereId);

      if (nameExists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Une matière avec ce nom existe déjà dans cette classe'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(matiereId)
          .update({'name': newName});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Matière modifiée avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la modification de la matière'),
          backgroundColor: Colors.red));
    }
  }

  // Edit grade avec vérification
  void editBareme(String baremeId) async {
    try {
      String newValue = _controller.text.trim();
      if (newValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('La valeur ne peut pas être vide'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Vérifier si la nouvelle valeur existe déjà dans la même matière
      QuerySnapshot existing = await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .where('value', isEqualTo: newValue)
          .get();

      bool valueExists = existing.docs.any((doc) => doc.id != baremeId);

      if (valueExists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Un barème avec cette valeur existe déjà dans cette matière'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .doc(baremeId)
          .update({'value': newValue});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Barème modifié avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la modification du barème'),
          backgroundColor: Colors.red));
    }
  }

  // Edit sub-grade avec vérification
  void editSousBareme(String sousBaremeId) async {
    try {
      String newName = _controller.text.trim();
      if (newName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Le nom ne peut pas être vide'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Vérifier si le nouveau nom existe déjà dans le même barème
      QuerySnapshot existing = await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .doc(selectedBareme)
          .collection('sousBaremes')
          .where('name', isEqualTo: newName)
          .get();

      bool nameExists = existing.docs.any((doc) => doc.id != sousBaremeId);

      if (nameExists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Un sous-barème avec ce nom existe déjà dans ce barème'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .doc(selectedBareme)
          .collection('sousBaremes')
          .doc(sousBaremeId)
          .update({'name': newName});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sous-bareme modifié avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la modification du sous-bareme'),
          backgroundColor: Colors.red));
    }
  }

  // Delete class
  void deleteClass(String classId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Classe supprimée avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression de la classe'),
          backgroundColor: Colors.red));
    }
  }

  // Delete subject
  void deleteMatiere(String matiereId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(matiereId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Matière supprimée avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression de la matière'),
          backgroundColor: Colors.red));
    }
  }

  // Delete grade
  void deleteBareme(String baremeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .doc(baremeId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Barème supprimé avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression du barème'),
          backgroundColor: Colors.red));
    }
  }

  // Delete sub-grade
  void deleteSousBareme(String sousBaremeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .doc(selectedBareme)
          .collection('sousBaremes')
          .doc(sousBaremeId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sous-bareme supprimé avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression du sous-bareme'),
          backgroundColor: Colors.red));
    }
  }

  // Add new subject avec vérification
  void addMatiere() async {
    try {
      String matiereName = _controller.text.trim();
      if (matiereName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Le nom ne peut pas être vide'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Vérifier si la matière existe déjà
      if (await matiereExists(selectedClass!, matiereName)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Cette matière existe déjà dans cette classe'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .add({'name': matiereName});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Matière ajoutée avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de l\'ajout de la matière'),
          backgroundColor: Colors.red));
    }
  }

  // Add new grade avec vérification
  void addBareme() async {
    try {
      String baremeValue = _controller.text.trim();
      if (baremeValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('La valeur ne peut pas être vide'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Vérifier si le barème existe déjà
      if (await baremeExists(selectedClass!, selectedMatiere!, baremeValue)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ce barème existe déjà dans cette matière'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .add({'value': baremeValue});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Barème ajouté avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de l\'ajout du barème'),
          backgroundColor: Colors.red));
    }
  }

  // Add new sub-grade avec vérification
  void addSousBareme() async {
    try {
      String sousBaremeName = _sousBaremeNomController.text.trim();
      String sousBaremeValue = _sousBaremeValueController.text.trim();

      if (sousBaremeName.isEmpty || sousBaremeValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Le nom et la valeur ne peuvent pas être vides'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Vérifier si le sous-barème existe déjà
      if (await sousBaremeExists(selectedClass!, selectedMatiere!, selectedBareme!, sousBaremeName)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ce sous-barème existe déjà dans ce barème'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .doc(selectedBareme)
          .collection('sousBaremes')
          .add({
        'value': sousBaremeValue,
        'name': sousBaremeName,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sous-bareme ajouté avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de l\'ajout du sous-bareme'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestion des Données',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 10,
        centerTitle: true,
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Boutons d'administration globale
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Administration Globale',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('Ajouter Tout'),
                            onPressed: _isLoading ? null : addAllDataAutomatically,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.delete_outline),
                            label: Text('Tout Supprimer'),
                            onPressed: _isLoading ? null : deleteAllData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Attention: L\'ajout automatique vérifiera l\'existence de chaque élément avant de l\'ajouter.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Sélectionner une classe
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    var classes = snapshot.data!.docs;
                    return DropdownButton<String>(
                      hint: Text(
                        'Sélectionnez une classe',
                        style: TextStyle(color: Colors.teal),
                      ),
                      value: selectedClass,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedClass = newValue;
                          selectedMatiere = null;
                          selectedBareme = null;
                          selectedSousBareme = null;
                        });
                      },
                      isExpanded: true,
                      items: classes.map((classDoc) {
                        String className = classDoc['name'] ?? 'Nom inconnu';
                        return DropdownMenuItem<String>(
                          value: classDoc.id,
                          child: Text(
                            className,
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 24),

            // Afficher les matières de la classe
            if (selectedClass != null)
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Cliquez sur une matière pour afficher ses barèmes.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .doc(selectedClass)
                            .collection('matieres')
                            .orderBy('name')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          var matieres = snapshot.data!.docs;
                          if (matieres.isEmpty) {
                            return Text(
                              'Aucune matière disponible.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            );
                          }
                          return Column(
                            children: matieres.map((matiere) {
                              String matiereName = matiere['name'] ?? 'Nom inconnu';
                              return ListTile(
                                title: Text(
                                  matiereName,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedMatiere = matiere.id;
                                    selectedBareme = null;
                                    selectedSousBareme = null;
                                  });
                                },
                                leading: Icon(Icons.school, color: Colors.teal),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        _controller.text = matiereName;
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              'Modifier la matière',
                                              style: TextStyle(color: Colors.teal),
                                            ),
                                            content: TextField(
                                              controller: _controller,
                                              decoration: InputDecoration(
                                                labelText: 'Nom de la matière',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  editMatiere(matiere.id);
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  'Modifier',
                                                  style: TextStyle(color: Colors.teal),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteMatiere(matiere.id),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _controller.clear();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Ajouter une matière'),
                              content: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  labelText: 'Nom de la matière',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    addMatiere();
                                    Navigator.pop(context);
                                  },
                                  child: Text('Ajouter'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text('Ajouter une matière'),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 24),

            // Afficher les barèmes de la matière sélectionnée
            if (selectedMatiere != null)
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Cliquez sur un barème pour afficher ses sous-barèmes.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .doc(selectedClass)
                            .collection('matieres')
                            .doc(selectedMatiere)
                            .collection('baremes')
                            .orderBy('value')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          var baremes = snapshot.data!.docs;
                          if (baremes.isEmpty) {
                            return Text(
                              'Aucun barème disponible.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            );
                          }
                          return Column(
                            children: baremes.map((bareme) {
                              String baremeValue = bareme['value'] ?? 'Inconnu';
                              return ListTile(
                                title: Text(
                                  baremeValue,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedBareme = bareme.id;
                                    selectedSousBareme = null;
                                  });
                                },
                                leading: Icon(Icons.grade, color: Colors.teal),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        _controller.text = baremeValue;
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              'Modifier le barème',
                                              style: TextStyle(color: Colors.teal),
                                            ),
                                            content: TextField(
                                              controller: _controller,
                                              decoration: InputDecoration(
                                                labelText: 'Valeur du barème',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  editBareme(bareme.id);
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  'Modifier',
                                                  style: TextStyle(color: Colors.teal),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteBareme(bareme.id),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _controller.clear();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Ajouter un barème'),
                              content: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  labelText: 'Valeur du barème',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    addBareme();
                                    Navigator.pop(context);
                                  },
                                  child: Text('Ajouter'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text('Ajouter un barème'),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 24),

            // Afficher les sous-barèmes du barème sélectionné
            if (selectedBareme != null)
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Cliquez sur un sous-barème pour afficher ses détails.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .doc(selectedClass)
                            .collection('matieres')
                            .doc(selectedMatiere)
                            .collection('baremes')
                            .doc(selectedBareme)
                            .collection('sousBaremes')
                            .orderBy('name')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          var sousBaremes = snapshot.data!.docs;
                          if (sousBaremes.isEmpty) {
                            return Text(
                              'Aucun sous-barème disponible.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            );
                          }

                          return Column(
                            children: sousBaremes.map((sousBareme) {
                              String sousBaremeName = sousBareme['name'] ?? 'Nom inconnu';
                              String sousBaremeValue = sousBareme['value'] ?? 'Inconnu';
                              return ListTile(
                                title: Text(
                                  '$sousBaremeName - $sousBaremeValue',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedSousBareme = sousBareme.id;
                                  });
                                },
                                leading: Icon(Icons.format_list_bulleted, color: Colors.teal),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        _controller.text = sousBaremeName;
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              'Modifier le sous-bareme',
                                              style: TextStyle(color: Colors.teal),
                                            ),
                                            content: TextField(
                                              controller: _controller,
                                              decoration: InputDecoration(
                                                labelText: 'Nom du sous-bareme',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  editSousBareme(sousBareme.id);
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  'Modifier',
                                                  style: TextStyle(color: Colors.teal),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => deleteSousBareme(sousBareme.id),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _sousBaremeNomController.clear();
                          _sousBaremeValueController.clear();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Ajouter un sous-barème'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: _sousBaremeNomController,
                                    decoration: InputDecoration(
                                      labelText: 'Nom du sous-barème',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: _sousBaremeValueController,
                                    decoration: InputDecoration(
                                      labelText: 'Valeur du sous-barème',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    addSousBareme();
                                    Navigator.pop(context);
                                  },
                                  child: Text('Ajouter'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text('Ajouter un sous-barème'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}