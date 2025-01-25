import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:url_launcher/url_launcher.dart';

class ManageClassesPage extends StatefulWidget {
  @override
  _ManageClassesPageState createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = []; // Liste des matières disponibles
  Uint8List? _imageBytes;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _fetchClasses();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  String? _selectedSubject; // Variable pour stocker la matière sélectionnée

  Future<void> _addSubjectDialog(Map<String, dynamic> classData) async {
    await _loadSubjects(classData['class_id']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter une matière'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: _selectedSubject,
              hint: Text('Sélectionnez une matière'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSubject = newValue;
                });
              },
              items: _subjects.map<DropdownMenuItem<String>>((subject) {
                return DropdownMenuItem<String>(
                  value: subject['name'],
                  child: Text(subject['name']),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_selectedSubject != null) {
                await _addSubjectToClass(classData, _selectedSubject!);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Veuillez sélectionner une matière')));
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSubjectToClass(
      Map<String, dynamic> classData, String subjectName) async {
    try {
      List<String> updatedSubjects = List.from(classData['subjects']);
      if (!updatedSubjects.contains(subjectName)) {
        updatedSubjects.add(subjectName);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classData['id'])
            .update({
          'subjects': updatedSubjects,
        });

        setState(() {
          classData['subjects'] = updatedSubjects;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Matière ajoutée avec succès')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cette matière est déjà dans la classe')));
      }
    } catch (e) {
      print("Erreur lors de l'ajout de la matière : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de la matière')));
    }
  }

  Future<void> _loadSubjects(String classId) async {
    try {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('matieres')
          .get();

      setState(() {
        _subjects = classDoc.docs.map((doc) {
          return {'id': doc.id, 'name': doc['name'] as String};
        }).toList();
      });
    } catch (e) {
      print("Erreur lors de la récupération des matières : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la récupération des matières')));
    }
  }

  Future<void> _fetchClasses() async {
    try {
      final classDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .get();

      setState(() {
        _classes = classDocs.docs.map((doc) {
          return {
            'id': doc.id,
            'class_id': doc['class_id'],
            'class_name': doc['class_name'],
            'subjects': List<String>.from(doc['subjects']),
            'students': List<String>.from(doc['students']),
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des classes')));
    }
  }

  Future<void> _deleteClass(String classId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .delete();

      setState(() {
        _classes.removeWhere((classData) => classData['id'] == classId);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Classe supprimée')));
    } catch (e) {
      print("Erreur lors de la suppression : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression de la classe')));
    }
  }

  Future<void> _confirmDeleteClass(String classId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette classe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteClass(classId);
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }
Future<void> _deleteStudent(
    Map<String, dynamic> classData, String studentId) async {
  try {
    // Étape 1 : Supprimer l'élève de la liste `students` dans le document de la classe
    List<String> updatedStudents = List.from(classData['students']);
    updatedStudents.remove(studentId);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('user_classes')
        .doc(classData['id'])
        .update({
      'students': updatedStudents,
    });

    // Étape 2 : Supprimer le document de l'élève dans la sous-collection `students`
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('user_classes')
        .doc(classData['id'])
        .collection('students')
        .doc(studentId)
        .delete();

    // Mettre à jour l'état local
    setState(() {
      classData['students'] = updatedStudents;
    });

    // Afficher un message de succès
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Élève supprimé')));
  } catch (e) {
    // Gérer les erreurs
    print("Erreur lors de la suppression de l'élève : $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la suppression de l\'élève')),
    );
  }
}

  Future<void> _confirmDeleteStudent(
      Map<String, dynamic> classData, String studentId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer cet élève ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent(classData, studentId);
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(
      Map<String, dynamic> classData, String subject) async {
    try {
      List<String> updatedSubjects = List.from(classData['subjects']);
      updatedSubjects.remove(subject);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id'])
          .update({
        'subjects': updatedSubjects,
      });

      setState(() {
        classData['subjects'] = updatedSubjects;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Matière supprimée')));
    } catch (e) {
      print("Erreur lors de la suppression de la matière : $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression de la matière')));
    }
  }

  Future<void> _confirmDeleteSubject(
      Map<String, dynamic> classData, String subject) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette matière ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSubject(classData, subject);
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudent(Map<String, dynamic> classData) async {
    TextEditingController studentNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un élève'),
        content: TextField(
          controller: studentNameController,
          decoration: InputDecoration(labelText: 'Nom de l\'élève'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final studentsCollection = FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(classData['id'])
                    .collection('students');

                final studentRef = await studentsCollection.add({
                  'name': studentNameController.text,
                  'parentName': '',
                  'parentPhone': '',
                  'birthDate': '',
                  'remarks': '',
                  'photoUrl': '',
                });

                List<String> updatedStudents = List.from(classData['students']);
                updatedStudents.add(studentRef.id);

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(classData['id'])
                    .update({
                  'students': updatedStudents,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Élève ajouté avec succès')));
                _fetchClasses();
              } catch (e) {
                print("Erreur lors de l'ajout de l'élève : $e");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur lors de l\'ajout de l\'élève')));
              }
            },
            child: Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _editStudent(
      Map<String, dynamic> classData, String studentId) async {
    TextEditingController studentNameController = TextEditingController();

    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .get();

    if (studentDoc.exists) {
      studentNameController.text = studentDoc['name'];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le nom de l\'élève'),
        content: TextField(
          controller: studentNameController,
          decoration: InputDecoration(labelText: 'Nouveau nom de l\'élève'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('students')
                    .doc(studentId)
                    .update({
                  'name': studentNameController.text,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nom de l\'élève modifié')));
                _fetchClasses();
              } catch (e) {
                print("Erreur lors de la modification de l'élève : $e");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Erreur lors de la modification de l\'élève')));
              }
            },
            child: Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<String?> _getStudentName(String studentId) async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        return studentDoc['name'];
      }
      return null;
    } catch (e) {
      print("Erreur lors de la récupération du nom de l'élève : $e");
      return null;
    }
  }

  Widget _buildClassList() {
    return ListView.builder(
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        var classData = _classes[index];
        return ExpansionTile(
          title: Text(classData['class_name']),
          subtitle: Text(
              'Élèves: ${classData['students'].length} | Matières: ${classData['subjects'].length}'),
          children: [
            ...classData['subjects'].map<Widget>((subject) {
              return ListTile(
                title: Text(subject),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _confirmDeleteSubject(classData, subject),
                ),
              );
            }).toList(),
            ...classData['students'].map<Widget>((studentId) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(classData['id'])
                    .collection('students')
                    .doc(studentId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Chargement...'),
                    );
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return ListTile(
                      title: Text('Élève inconnu'),
                    );
                  } else {
                    final studentData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final photoUrl = studentData['photoUrl'];
                    final parentPhone = studentData['parentPhone'];
                    final birthDate = studentData['birthDate'];

                    return ListTile(
                      leading: photoUrl != null && photoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              placeholder: (context, url) => CircleAvatar(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) {
                                print(
                                    'Erreur de chargement de l\'image: $error');
                                return CircleAvatar(
                                  child: Icon(Icons.error),
                                );
                              },
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                backgroundImage: imageProvider,
                              ),
                            )
                          : CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                      title: Text(studentData['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Parent: ${studentData['parentName']}'),
                          Text(
                              'Date de naissance: ${birthDate ?? "Non renseignée"}'),
                          if (parentPhone != null && parentPhone.isNotEmpty)
                            Text('Téléphone: $parentPhone'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bouton pour modifier les détails de l'élève
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                _showStudentDetails(classData, studentId),
                          ),
                          // Bouton pour supprimer l'élève
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () =>
                                _confirmDeleteStudent(classData, studentId),
                          ),
                          // Bouton pour appeler le parent
                          if (parentPhone != null && parentPhone.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.phone),
                              onPressed: () async {
                                final url = 'tel:$parentPhone';
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Impossible de passer un appel')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  }
                },
              );
            }).toList(),
            ListTile(
              title: Text('Ajouter une matière'),
              trailing: IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _addSubjectDialog(classData),
              ),
            ),
            ListTile(
              title: Text('Ajouter un élève'),
              trailing: IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _addStudent(classData),
              ),
            ),
          ],
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDeleteClass(classData['id']),
          ),
        );
      },
    );
  }

  Future<void> _showStudentDetails(
      Map<String, dynamic> classData, String studentId) async {
    TextEditingController parentNameController = TextEditingController();
    TextEditingController parentPhoneController = TextEditingController();
    TextEditingController birthDateController = TextEditingController();
    TextEditingController remarksController = TextEditingController();

    final studentsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('user_classes')
        .doc(classData['id'])
        .collection('students');

    final studentDoc = await studentsCollection.doc(studentId).get();

    if (studentDoc.exists) {
      parentNameController.text = studentDoc.get('parentName') ?? '';
      parentPhoneController.text = studentDoc.get('parentPhone') ?? '';
      birthDateController.text = studentDoc.get('birthDate') ?? '';
      remarksController.text = studentDoc.get('remarks') ?? '';
      _photoUrl = studentDoc.get('photoUrl') ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de l\'élève'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_imageBytes != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: MemoryImage(_imageBytes!),
                )
              else if (_photoUrl != null && _photoUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: _photoUrl!,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 50,
                    backgroundImage: imageProvider,
                  ),
                )
              else
                CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: Text('Prendre une photo'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: Text('Choisir une photo'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: parentNameController,
                decoration: InputDecoration(labelText: 'Nom du parent'),
              ),
              TextField(
                controller: parentPhoneController,
                decoration: InputDecoration(labelText: 'Numéro du parent'),
              ),
              TextField(
                controller: birthDateController,
                decoration: InputDecoration(labelText: 'Date de naissance'),
              ),
              TextField(
                controller: remarksController,
                decoration: InputDecoration(labelText: 'Remarques'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                String? photoUrl = _photoUrl;

                if (_imageBytes != null) {
                  final storageRef = FirebaseStorage.instance.ref().child(
                      'students/${currentUser!.uid}/${classData['id']}/$studentId.jpg');

                  await storageRef.putData(_imageBytes!);
                  photoUrl = await storageRef.getDownloadURL();
                }

                await studentsCollection.doc(studentId).update({
                  'parentName': parentNameController.text,
                  'parentPhone': parentPhoneController.text,
                  'birthDate': birthDateController.text,
                  'remarks': remarksController.text,
                  'photoUrl': photoUrl ?? '',
                });

                setState(() {
                  _photoUrl = photoUrl;
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Informations mises à jour')),
                );

                await _fetchClasses();
              } catch (e) {
                print("Erreur lors de la mise à jour des informations : $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Erreur lors de la mise à jour des informations')),
                );
              }
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestion des classes')),
      body: _classes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _buildClassList(),
    );
  }
}
