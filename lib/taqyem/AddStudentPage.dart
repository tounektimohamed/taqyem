import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageClassesPage extends StatefulWidget {
  @override
  _ManageClassesPageState createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _showEditDialog(
      String collectionPath, String docId, String currentValue, String label) async {
    final controller = TextEditingController(text: currentValue);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier $label'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Nouveau $label',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newValue = controller.text.trim();
                if (newValue.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .doc(collectionPath)
                      .update({'name': newValue});
                  Navigator.of(context).pop();
                }
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteClass(String classId) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Delete all students in the class
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users/$_userId/classes/$classId/students')
        .get();
    for (final studentDoc in studentsSnapshot.docs) {
      batch.delete(studentDoc.reference);
    }
    
    // Delete all subjects in the class
    final subjectsSnapshot = await FirebaseFirestore.instance
        .collection('users/$_userId/classes/$classId/subjects')
        .get();
    for (final subjectDoc in subjectsSnapshot.docs) {
      batch.delete(subjectDoc.reference);
    }

    // Finally, delete the class document itself
    batch.delete(FirebaseFirestore.instance.doc('users/$_userId/classes/$classId'));

    // Commit the batch operation
    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Classe supprimée avec succès !')),
    );
  }

  Future<void> _showAddStudentDialog(String classId) async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajouter un étudiant'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nom de l\'étudiant',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users/$_userId/classes/$classId/students')
                      .add({'name': name});
                  Navigator.of(context).pop();
                }
              },
              child: Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddSubjectDialog(String classId) async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajouter une matière'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nom de la matière',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users/$_userId/classes/$classId/subjects')
                      .add({'name': name});
                  Navigator.of(context).pop();
                }
              },
              child: Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClassCard(QueryDocumentSnapshot<Map<String, dynamic>> classDoc) {
    final classId = classDoc.id;
    final className = classDoc['name'];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          className,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditDialog(
                'users/$_userId/classes/$classId',
                classId,
                className,
                'classe',
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteClass(classId),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Étudiants', style: TextStyle(fontWeight: FontWeight.bold)),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users/$_userId/classes/$classId/students')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    final students = snapshot.data!.docs;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            return ListTile(
                              title: Text(student['name']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditDialog(
                                      'users/$_userId/classes/$classId/students/${student.id}',
                                      student.id,
                                      student['name'],
                                      'étudiant',
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => FirebaseFirestore.instance
                                        .doc('users/$_userId/classes/$classId/students/${student.id}')
                                        .delete(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.add, color: Colors.green),
                          label: Text('Ajouter un étudiant'),
                          onPressed: () => _showAddStudentDialog(classId),
                        ),
                      ],
                    );
                  },
                ),
                Divider(),
                Text('Matières', style: TextStyle(fontWeight: FontWeight.bold)),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users/$_userId/classes/$classId/subjects')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    final subjects = snapshot.data!.docs;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            return ListTile(
                              title: Text(subject['name']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditDialog(
                                      'users/$_userId/classes/$classId/subjects/${subject.id}',
                                      subject.id,
                                      subject['name'],
                                      'matière',
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => FirebaseFirestore.instance
                                        .doc('users/$_userId/classes/$classId/subjects/${subject.id}')
                                        .delete(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.add, color: Colors.green),
                          label: Text('Ajouter une matière'),
                          onPressed: () => _showAddSubjectDialog(classId),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Classes'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users/$_userId/classes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune classe ajoutée.'));
          }

          final classDocs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: classDocs.length,
            itemBuilder: (context, index) {
              return _buildClassCard(classDocs[index]);
            },
          );
        },
      ),
    );
  }
}
