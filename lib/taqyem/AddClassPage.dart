import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddClassPage extends StatefulWidget {
  @override
  _AddClassPageState createState() => _AddClassPageState();
}

class _AddClassPageState extends State<AddClassPage> {
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();

  String? _currentClassId;
  final List<Map<String, String>> _subjects = [];
  final List<Map<String, String>> _students = [];

  Future<void> _addClass() async {
    final className = _classNameController.text.trim();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (className.isNotEmpty && userId != null) {
      final classRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('classes')
          .add({'name': className});
      setState(() {
        _currentClassId = classRef.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Classe ajoutée avec succès !')),
      );
      _classNameController.clear();
    }
  }

  Future<void> _addSubject() async {
    final subjectName = _subjectNameController.text.trim();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (subjectName.isNotEmpty && _currentClassId != null && userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('classes')
          .doc(_currentClassId)
          .collection('subjects')
          .add({'name': subjectName});
      setState(() {
        _subjects.add({'name': subjectName});
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Matière ajoutée avec succès !')),
      );
      _subjectNameController.clear();
    }
  }

  Future<void> _addStudent() async {
    final studentName = _studentNameController.text.trim();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (studentName.isNotEmpty && _currentClassId != null && userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('classes')
          .doc(_currentClassId)
          .collection('students')
          .add({'name': studentName});
      setState(() {
        _students.add({'name': studentName});
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Élève ajouté avec succès !')),
      );
      _studentNameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter une classe et ses détails'),
        backgroundColor: Color.fromARGB(255, 203, 230, 227),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section pour ajouter une classe
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                '1. Ajouter une classe',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _classNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom de la classe',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _addClass,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Ajouter Classe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 7, 82, 96),  // Couleur du texte lorsque le bouton est actif
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_currentClassId != null) ...[
              Divider(),
              // Section pour ajouter des matières
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                child: Text(
                  '2. Ajouter des matières à la classe',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _subjectNameController,
                        decoration: InputDecoration(
                          labelText: 'Nom de la matière',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: _addSubject,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Ajouter Matière',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 7, 82, 96),
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      if (_subjects.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(_subjects[index]['name']!),
                              leading: Icon(Icons.book, color: Colors.blueAccent),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _subjects.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              Divider(),
              // Section pour ajouter des élèves
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                child: Text(
                  '3. Ajouter des élèves à la classe',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _studentNameController,
                        decoration: InputDecoration(
                          labelText: 'Nom de l\'élève',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: _addStudent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Ajouter Élève',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 7, 82, 96),
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      if (_students.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(_students[index]['name']!),
                              leading: Icon(Icons.person, color: Colors.blueAccent),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _students.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
