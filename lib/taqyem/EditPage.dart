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
  TextEditingController _controller = TextEditingController();

  // Edit class
  void editClass(String classId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .update({'name': _controller.text});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Classe modifiée avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la modification de la classe'),
          backgroundColor: Colors.red));
    }
  }

  // Edit subject
  void editMatiere(String matiereId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(matiereId)
          .update({'name': _controller.text});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Matière modifiée avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la modification de la matière'),
          backgroundColor: Colors.red));
    }
  }

  // Edit grade
  void editBareme(String baremeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .doc(baremeId)
          .update({'value': _controller.text});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Barème modifié avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la modification du barème'),
          backgroundColor: Colors.red));
    }
  }

  // Edit sub-grade (Sous-bareme)
  void editSousBareme(String sousBaremeId) async {
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
          .update({'name': _controller.text});
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

  // Delete sub-grade (Sous-bareme)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Données'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Sélectionner une classe
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    var classes = snapshot.data!.docs;
                    return DropdownButton<String>(
                      hint: Text('Sélectionnez une classe'),
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
                          child: Text(className),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),

            // Afficher les matières de la classe
            selectedClass == null
                ? Container()
                : Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .doc(selectedClass)
                            .collection('matieres')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          var matieres = snapshot.data!.docs;
                          return Column(
                            children: matieres.map((matiere) {
                              String matiereName =
                                  matiere['name'] ?? 'Nom inconnu';
                              return ListTile(
                                title: Text(matiereName),
                                onTap: () {
                                  setState(() {
                                    selectedMatiere = matiere.id;
                                    selectedBareme = null;
                                    selectedSousBareme = null;
                                  });
                                },
                                leading: Icon(Icons.school),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {
                                        _controller.text = matiereName;
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('Modifier la matière'),
                                              content: TextField(
                                                controller: _controller,
                                                decoration: InputDecoration(
                                                    labelText: 'Nom de la matière'),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    editMatiere(matiere.id);
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text('Modifier'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () => deleteMatiere(matiere.id),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
            SizedBox(height: 20),

            // Afficher les barèmes de la matière sélectionnée
            selectedMatiere == null
                ? Container()
                : Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .doc(selectedClass)
                            .collection('matieres')
                            .doc(selectedMatiere)
                            .collection('baremes')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          var baremes = snapshot.data!.docs;
                          return Column(
                            children: baremes.map((bareme) {
                              String baremeValue = bareme['value'] ?? 'Inconnu';
                              return ListTile(
                                title: Text(baremeValue),
                                onTap: () {
                                  setState(() {
                                    selectedBareme = bareme.id;
                                    selectedSousBareme = null;
                                  });
                                },
                                leading: Icon(Icons.grade),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {
                                        _controller.text = baremeValue;
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('Modifier le barème'),
                                              content: TextField(
                                                controller: _controller,
                                                decoration: InputDecoration(
                                                    labelText: 'Valeur du barème'),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    editBareme(bareme.id);
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text('Modifier'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () => deleteBareme(bareme.id),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
            SizedBox(height: 20),

            // Afficher les sous-barèmes du barème sélectionné
            selectedBareme == null
                ? Container()
                : Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .doc(selectedClass)
                            .collection('matieres')
                            .doc(selectedMatiere)
                            .collection('baremes')
                            .doc(selectedBareme)
                            .collection('sousBaremes')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          var sousBaremes = snapshot.data!.docs;
                          return Column(
                            children: sousBaremes.map((sousBareme) {
                              String sousBaremeName =
                                  sousBareme['name'] ?? 'Nom inconnu';
                              return ListTile(
                                title: Text(sousBaremeName),
                                onTap: () {
                                  setState(() {
                                    selectedSousBareme = sousBareme.id;
                                  });
                                },
                                leading: Icon(Icons.format_list_bulleted),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {
                                        _controller.text = sousBaremeName;
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('Modifier le sous-bareme'),
                                              content: TextField(
                                                controller: _controller,
                                                decoration: InputDecoration(
                                                    labelText: 'Nom du sous-bareme'),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    editSousBareme(
                                                        sousBareme.id);
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text('Modifier'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () => deleteSousBareme(
                                          sousBareme.id),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
