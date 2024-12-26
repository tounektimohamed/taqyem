import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? selectedClass;
  String? selectedMatiere;
  String? selectedBareme;
  TextEditingController matiereController = TextEditingController();
  TextEditingController baremeController = TextEditingController();
  TextEditingController sousBaremeController = TextEditingController();

  // Ajouter une matière à une classe
  void addMatiere() async {
    if (selectedClass != null && matiereController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(selectedClass)
            .collection('matieres')
            .add({'name': matiereController.text});
        matiereController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Matière ajoutée avec succès !'),
            backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur lors de l\'ajout de la matière'),
            backgroundColor: Colors.red));
      }
    }
  }

  // Ajouter un barème à une matière
  void addBareme() async {
    if (selectedMatiere != null && baremeController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(selectedClass)
            .collection('matieres')
            .doc(selectedMatiere)
            .collection('baremes')
            .add({'value': baremeController.text});
        baremeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Barème ajouté avec succès !'),
            backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur lors de l\'ajout du barème'),
            backgroundColor: Colors.red));
      }
    }
  }

  // Ajouter un sous-bareme
  void addSousBareme() async {
    if (selectedBareme != null && sousBaremeController.text.isNotEmpty) {
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
          'value': sousBaremeController.text,
          'name': 'Default Name', // Add a name or get it from user input
        });
        sousBaremeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Sous-Bareme ajouté avec succès !'),
            backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur lors de l\'ajout du sous-bareme'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
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
                      return CircularProgressIndicator();
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
                        });
                      },
                      isExpanded: true,
                      items: classes.map((classDoc) {
                        return DropdownMenuItem<String>(
                          value: classDoc.id,
                          child: Text(classDoc['name']),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),

            // Ajouter une matière
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: matiereController,
                      decoration: InputDecoration(
                        labelText: 'Ajouter une matière',
                        prefixIcon: Icon(Icons.add_circle),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: addMatiere,
                      child: Text('Ajouter Matière'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Afficher les matières ajoutées
            Card(
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
                        return ListTile(
                          title: Text(matiere['name']),
                          onTap: () {
                            setState(() {
                              selectedMatiere = matiere.id;
                              selectedBareme = null;
                            });
                          },
                          leading: Icon(Icons.school),
                          trailing: Icon(Icons.arrow_forward_ios),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),

            // Ajouter un barème
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: baremeController,
                      decoration: InputDecoration(
                        labelText: 'Ajouter un barème',
                        prefixIcon: Icon(Icons.assessment),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: addBareme,
                      child: Text('Ajouter Barème'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Afficher les barèmes ajoutés
            Card(
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
                        return ListTile(
                          title: Text(bareme['value']),
                          onTap: () {
                            setState(() {
                              selectedBareme = bareme.id;
                            });
                          },
                          leading: Icon(Icons.insert_chart),
                          trailing: Icon(Icons.arrow_forward_ios),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),

            // Ajouter un sous-bareme
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: sousBaremeController,
                      decoration: InputDecoration(
                        labelText: 'Ajouter un sous-bareme',
                        prefixIcon: Icon(Icons.assignment),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: addSousBareme,
                      child: Text('Ajouter Sous-Bareme'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Afficher les sous-baremes ajoutés
            Card(
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
                        return ListTile(
                          title: Text(sousBareme['value']),
                          onTap: () {
                            setState(() {
                              selectedBareme = sousBareme
                                  .id; // Stocker l'ID du sous-bareme sélectionné
                            });
                          },
                          leading: Icon(Icons.assignment),
                          trailing: Icon(Icons.arrow_forward_ios),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
