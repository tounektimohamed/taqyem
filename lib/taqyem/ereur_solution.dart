import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ErrorOrigin extends StatefulWidget {
  @override
  _ErrorOriginState createState() => _ErrorOriginState();
}

class _ErrorOriginState extends State<ErrorOrigin> {
  String? selectedClass;
  String? selectedMatiere;
  String? selectedBareme;

  // --- Contrôleurs pour خطة العلاج (treatmentPlan) ---
  TextEditingController treatmentPlanTitleController = TextEditingController();
  TextEditingController treatmentPlanContentController = TextEditingController();

  // --- Contrôleurs pour أصل الخطأ (errorOrigin) ---
  TextEditingController errorOriginTitleController = TextEditingController();
  TextEditingController errorOriginContentController = TextEditingController();

  // =================== Sélection hiérarchique ===================

  Widget _buildClassDropdown() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('classes').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            var classes = snapshot.data!.docs;
            return DropdownButton<String>(
              hint: const Text('Sélectionnez une classe', style: TextStyle(color: Colors.teal)),
              value: selectedClass,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedClass = newValue;
                  selectedMatiere = null;
                  selectedBareme = null;
                });
              },
              items: classes.map((classDoc) {
                return DropdownMenuItem<String>(
                  value: classDoc.id,
                  child: Text(classDoc['name'], style: const TextStyle(color: Colors.teal)),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatiereDropdown() {
    if (selectedClass == null) return const SizedBox();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .doc(selectedClass)
              .collection('matieres')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            var matieres = snapshot.data!.docs;
            return DropdownButton<String>(
              hint: const Text('Sélectionnez une matière', style: TextStyle(color: Colors.teal)),
              value: selectedMatiere,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedMatiere = newValue;
                  selectedBareme = null;
                });
              },
              items: matieres.map((matiereDoc) {
                return DropdownMenuItem<String>(
                  value: matiereDoc.id,
                  child: Text(matiereDoc['name'], style: const TextStyle(color: Colors.teal)),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBaremeDropdown() {
    if (selectedMatiere == null) return const SizedBox();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            var baremes = snapshot.data!.docs;
            return DropdownButton<String>(
              hint: const Text('Sélectionnez un barème', style: TextStyle(color: Colors.teal)),
              value: selectedBareme,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedBareme = newValue;
                });
              },
              items: baremes.map((baremeDoc) {
                return DropdownMenuItem<String>(
                  value: baremeDoc.id,
                  child: Text(baremeDoc['value'], style: const TextStyle(color: Colors.teal)),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  // =================== Ajout d'entrées ===================

  void addTreatmentPlan() async {
    if (selectedBareme == null) {
      _showSnackBar('Veuillez sélectionner un barème', Colors.red);
      return;
    }
    if (treatmentPlanTitleController.text.isEmpty ||
        treatmentPlanContentController.text.isEmpty) {
      _showSnackBar('Veuillez saisir le titre et le contenu pour خطة العلاج', Colors.red);
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
          .collection('treatmentPlans')
          .add({
        'title': treatmentPlanTitleController.text,
        'content': treatmentPlanContentController.text,
      });
      treatmentPlanTitleController.clear();
      treatmentPlanContentController.clear();
      _showSnackBar('خطة العلاج ajoutée avec succès !', Colors.green);
    } catch (e) {
      _showSnackBar("Erreur lors de l’ajout de خطة العلاج: ${e.toString()}", Colors.red);
    }
  }

  void addErrorOrigin() async {
    if (selectedBareme == null) {
      _showSnackBar('Veuillez sélectionner un barème', Colors.red);
      return;
    }
    if (errorOriginTitleController.text.isEmpty ||
        errorOriginContentController.text.isEmpty) {
      _showSnackBar('Veuillez saisir le titre et le contenu pour أصل الخطأ', Colors.red);
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
          .collection('errorOrigins')
          .add({
        'title': errorOriginTitleController.text,
        'content': errorOriginContentController.text,
      });
      errorOriginTitleController.clear();
      errorOriginContentController.clear();
      _showSnackBar('أصل الخطأ ajoutée avec succès !', Colors.green);
    } catch (e) {
      _showSnackBar("Erreur lors de l’ajout de أصل الخطأ: ${e.toString()}", Colors.red);
    }
  }

  // =================== Modification & Suppression ===================

  Future<void> _deleteDocument(String collectionPath, String docId) async {
    try {
      await FirebaseFirestore.instance.collection(collectionPath).doc(docId).delete();
      _showSnackBar('Suppression effectuée avec succès !', Colors.green);
    } catch (e) {
      _showSnackBar("Erreur lors de la suppression: ${e.toString()}", Colors.red);
    }
  }

  void _showEditDialog({
    required String collectionPath,
    required DocumentSnapshot doc,
  }) {
    TextEditingController titleController = TextEditingController(text: doc['title']);
    TextEditingController contentController = TextEditingController(text: doc['content']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Contenu'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection(collectionPath)
                      .doc(doc.id)
                      .update({
                    'title': titleController.text,
                    'content': contentController.text,
                  });
                  Navigator.pop(context);
                  _showSnackBar('Modification effectuée avec succès !', Colors.green);
                } catch (e) {
                  _showSnackBar("Erreur lors de la modification: ${e.toString()}", Colors.red);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  // =================== Feedback ===================

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // =================== Cartes d'Input ===================

  Widget _buildTreatmentPlanInputCard() {
    if (selectedBareme == null) return const SizedBox();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter خطة العلاج',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: treatmentPlanTitleController,
              decoration: InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: treatmentPlanContentController,
              decoration: InputDecoration(
                labelText: 'Contenu',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addTreatmentPlan,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOriginInputCard() {
    if (selectedBareme == null) return const SizedBox();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter أصل الخطأ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: errorOriginTitleController,
              decoration: InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: errorOriginContentController,
              decoration: InputDecoration(
                labelText: 'Contenu',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addErrorOrigin,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== Liste des documents ===================

  Widget _buildAddedList({
    required String title,
    required Stream<QuerySnapshot> stream,
    required String collectionPath,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            var docs = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var doc = docs[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: Icon(icon, color: Colors.teal),
                    title: Text(doc['title'] ?? '', style: const TextStyle(color: Colors.teal)),
                    subtitle: Text(
                      doc['content'] ?? '',
                      style: TextStyle(color: Colors.teal.withOpacity(0.7)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _showEditDialog(
                              collectionPath: collectionPath,
                              doc: doc,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteDocument(collectionPath, doc.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // =================== Construction de l'écran ===================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildSectionTitle('Sélectionnez une classe'),
            _buildClassDropdown(),
            const SizedBox(height: 16),
            _buildSectionTitle('Sélectionnez une matière'),
            _buildMatiereDropdown(),
            const SizedBox(height: 16),
            _buildSectionTitle('Sélectionnez un barème'),
            _buildBaremeDropdown(),
            const SizedBox(height: 24),
            if (selectedBareme != null) _buildTreatmentPlanInputCard(),
            const SizedBox(height: 16),
            if (selectedBareme != null)
              _buildAddedList(
                title: 'Liste des خطة العلاج',
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(selectedClass)
                    .collection('matieres')
                    .doc(selectedMatiere)
                    .collection('baremes')
                    .doc(selectedBareme)
                    .collection('treatmentPlans')
                    .snapshots(),
                collectionPath:
                    'classes/$selectedClass/matieres/$selectedMatiere/baremes/$selectedBareme/treatmentPlans',
                icon: Icons.build,
              ),
            const SizedBox(height: 24),
            if (selectedBareme != null) _buildErrorOriginInputCard(),
            const SizedBox(height: 16),
            if (selectedBareme != null)
              _buildAddedList(
                title: 'Liste des أصل الخطأ',
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(selectedClass)
                    .collection('matieres')
                    .doc(selectedMatiere)
                    .collection('baremes')
                    .doc(selectedBareme)
                    .collection('errorOrigins')
                    .snapshots(),
                collectionPath:
                    'classes/$selectedClass/matieres/$selectedMatiere/baremes/$selectedBareme/errorOrigins',
                icon: Icons.error,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  }
}
