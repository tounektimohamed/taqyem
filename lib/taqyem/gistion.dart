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
  TextEditingController sousBaremeNomController = TextEditingController(); // Nouveau contrôleur

  // Ajouter une matière à une classe
  void addMatiere() async {
    if (selectedClass == null) {
      showSnackBar('Veuillez sélectionner une classe', Colors.red);
      return;
    }
    if (matiereController.text.isEmpty) {
      showSnackBar('Veuillez entrer un nom de matière', Colors.red);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .add({'name': matiereController.text});
      matiereController.clear();
      showSnackBar('Matière ajoutée avec succès !', Colors.green);
    } catch (e) {
      showSnackBar('Erreur lors de l\'ajout de la matière: ${e.toString()}', Colors.red);
    }
  }

  // Ajouter un barème à une matière
  void addBareme() async {
    if (selectedMatiere == null) {
      showSnackBar('Veuillez sélectionner une matière', Colors.red);
      return;
    }
    if (baremeController.text.isEmpty) {
      showSnackBar('Veuillez entrer un barème', Colors.red);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClass)
          .collection('matieres')
          .doc(selectedMatiere)
          .collection('baremes')
          .add({'value': baremeController.text});
      baremeController.clear();
      showSnackBar('Barème ajouté avec succès !', Colors.green);
    } catch (e) {
      showSnackBar('Erreur lors de l\'ajout du barème: ${e.toString()}', Colors.red);
    }
  }

  // Ajouter un sous-bareme avec un nom personnalisé
  void addSousBareme() async {
    if (selectedBareme == null) {
      showSnackBar('Veuillez sélectionner un barème', Colors.red);
      return;
    }
    if (sousBaremeController.text.isEmpty) {
      showSnackBar('Veuillez entrer une valeur pour le sous-barème', Colors.red);
      return;
    }
    if (sousBaremeNomController.text.isEmpty) {
      showSnackBar('Veuillez entrer un nom pour le sous-barème', Colors.red);
      return;
    }

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
        'name': sousBaremeNomController.text, // Utilisez le nom saisi par l'utilisateur
      });
      sousBaremeController.clear();
      sousBaremeNomController.clear();
      showSnackBar('Sous-Bareme ajouté avec succès !', Colors.green);
    } catch (e) {
      showSnackBar('Erreur lors de l\'ajout du sous-bareme: ${e.toString()}', Colors.red);
    }
  }

  // Helper function to show SnackBar
  void showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Sélectionner une classe
            _buildSectionTitle('Sélectionner une classe'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('classes').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    var classes = snapshot.data!.docs;
                    return DropdownButton<String>(
                      hint: Text('Choisissez une classe', style: TextStyle(color: Colors.teal)),
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
                          child: Text(classDoc['name'], style: TextStyle(color: Colors.teal)),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 24),

            // Ajouter une matière
            _buildSectionTitle('Ajouter une matière'),
            InputCard(
              labelText: 'Nom de la matière',
              prefixIcon: Icons.school,
              controller: matiereController,
              onPressed: addMatiere,
              buttonText: 'Ajouter Matière',
            ),
            SizedBox(height: 24),

            // Afficher les matières ajoutées
            if (selectedClass != null) _buildSectionTitle('Matières disponibles'),
            if (selectedClass != null)
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
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: matieres.length,
                    itemBuilder: (context, index) {
                      var matiere = matieres[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(matiere['name'], style: TextStyle(color: Colors.teal)),
                          leading: Icon(Icons.school, color: Colors.teal),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                          onTap: () {
                            setState(() {
                              selectedMatiere = matiere.id;
                              selectedBareme = null;
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            SizedBox(height: 24),

            // Ajouter un barème
            if (selectedMatiere != null) _buildSectionTitle('Ajouter un barème'),
            if (selectedMatiere != null)
              InputCard(
                labelText: 'Valeur du barème',
                prefixIcon: Icons.assessment,
                controller: baremeController,
                onPressed: addBareme,
                buttonText: 'Ajouter Barème',
              ),
            SizedBox(height: 24),

            // Afficher les barèmes ajoutés
            if (selectedMatiere != null) _buildSectionTitle('Barèmes disponibles'),
            if (selectedMatiere != null)
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
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: baremes.length,
                    itemBuilder: (context, index) {
                      var bareme = baremes[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(bareme['value'], style: TextStyle(color: Colors.teal)),
                          leading: Icon(Icons.assessment, color: Colors.teal),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                          onTap: () {
                            setState(() {
                              selectedBareme = bareme.id;
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            SizedBox(height: 24),

            // Ajouter un sous-barème
            if (selectedBareme != null) _buildSectionTitle('Ajouter un sous-barème'),
            if (selectedBareme != null)
              InputCard(
                labelText: 'Valeur du sous-barème',
                prefixIcon: Icons.assignment,
                controller: sousBaremeController,
                onPressed: addSousBareme,
                buttonText: 'Ajouter Sous-Barème',
              ),
            SizedBox(height: 24),

            // Afficher les sous-barèmes ajoutés
            if (selectedBareme != null) _buildSectionTitle('Sous-barèmes disponibles'),
            if (selectedBareme != null)
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
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    
                    itemCount: sousBaremes.length,
                    itemBuilder: (context, index) {
                      var sousBareme = sousBaremes[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        
                        child: ListTile(
                          title: Text(sousBareme['name'], style: TextStyle(color: Colors.teal)),
                          subtitle: Text('Valeur: ${sousBareme['value']}', style: TextStyle(color: Colors.teal.withOpacity(0.7))),
                          leading: Icon(Icons.assignment, color: Colors.teal),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                        ),
                      );
                    },
                  );
                  
                },
              ),
          ],
        ),
      ),
    );
  }

  // Helper pour créer des titres de section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }
}

// Reusable InputCard Widget
class InputCard extends StatelessWidget {
  final String labelText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final VoidCallback onPressed;
  final String buttonText;

  const InputCard({
    required this.labelText,
    required this.prefixIcon,
    required this.controller,
    required this.onPressed,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: labelText,
                prefixIcon: Icon(prefixIcon, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
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
    );
  }
}