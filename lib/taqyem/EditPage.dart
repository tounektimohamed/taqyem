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

  @override
  void dispose() {
    _controller.dispose();
    _sousBaremeNomController.dispose();
    _sousBaremeValueController.dispose();
    super.dispose();
  }

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

  // Add new subject
  void addMatiere() async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .add({'name': _controller.text});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Matière ajoutée avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de l\'ajout de la matière'),
          backgroundColor: Colors.red));
    }
  }

  // Add new grade
  void addBareme() async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .add({'value': _controller.text});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Barème ajouté avec succès !'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de l\'ajout du barème'),
          backgroundColor: Colors.red));
    }
  }

  // Add new sub-grade (Sous-bareme)
  void addSousBareme() async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .doc(selectedBareme)
          .collection('sousBaremes')
          .add({
        'value': _sousBaremeValueController.text,
        'name': _sousBaremeNomController.text, // Utilisez le nom saisi par l'utilisateur
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
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Sélectionner une classe
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('classes').snapshots(),
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