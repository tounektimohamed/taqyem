import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;
import 'dart:math';
import 'package:Taqyem/taqyem/PaymentPage.dart';
import 'package:http/http.dart' as http;
import 'package:Taqyem/taqyem/da3m_tableau.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class DynamicTablePage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;

  DynamicTablePage({
    required this.selectedClass,
    required this.selectedMatiere,
  });

  @override
  _DynamicTablePageState createState() => _DynamicTablePageState();
}

class _DynamicTablePageState extends State<DynamicTablePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _profName = '';
  String _schoolName = '';
  bool _isDialogCompleted = false;
  String? selectedBaremeId; // ID du barème sélectionné
  String? baremeName; // Nom du barème sélectionné
  String? sousBaremeName; // Nom du sous-barème sélectionné
  String? selectedSousBaremeId; // ID du sous-barème sélectionné

  // Variables pour stocker les marques
  Map<String, int> sumCriteriaMaxPerBareme = {};
  int totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Charger les données depuis Firestore
    fetchMarks(); // Récupérer les marques au chargement de la page
  }

  Future<List<Map<String, dynamic>>> _getBaremesValues(
      List<QueryDocumentSnapshot> selectedBaremes) async {
    final List<Map<String, dynamic>> result = [];
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    print('User ID: $userId');
    print('Selected Class: ${widget.selectedClass}');
    print('Selected Matiere: ${widget.selectedMatiere}');

    for (final baremeDoc in selectedBaremes) {
      final baremeId = baremeDoc['baremeId'];
      print('Processing baremeId: $baremeId');

      final baremeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .get();

      final isBaremeSelected = baremeSnapshot['selected'] ?? false;
      print('Bareme selected: $isBaremeSelected');

      final sousBaremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .collection('sousBaremes')
          .get();

      final selectedSousBaremes = sousBaremesSnapshot.docs
          .where((doc) => doc['selected'] == true)
          .toList();

      print('Number of selected sousBaremes: ${selectedSousBaremes.length}');

      if (isBaremeSelected) {
        final baremeName = baremeSnapshot['baremeName'] ?? 'غير معروف';
        print('Adding bareme: $baremeId - $baremeName');

        result.add({
          'id': baremeId,
          'value': baremeName,
          'sousBaremes': [],
        });
      } else if (selectedSousBaremes.isNotEmpty) {
        for (final sousBareme in selectedSousBaremes) {
          final sousBaremeName = sousBareme['sousBaremeName'] ?? 'غير معروف';
          print(
              'Adding sousBareme: ${sousBareme.id} - $sousBaremeName (Parent: $baremeId)');

          result.add({
            'id': sousBareme.id,
            'value': sousBaremeName,
            'parentBaremeId': baremeId, // Track parent bareme ID
          });
        }
      }
    }
    print('Final result: $result');
    return result;
  }

  void _navigateToClassificationPage(String baremeId,
      {String? sousBaremeId}) async {
    try {
      // Récupérer les noms de la classe et de la matière
      var classAndMatiereNames = await _getClassAndMatiereNames();

      // Récupérer les barèmes et sous-barèmes
      var selectedBaremes = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      // Récupérer les valeurs des barèmes et sous-barèmes
      List<Map<String, dynamic>> baremesValues =
          await _getBaremesValues(selectedBaremes.docs);

      // Trouver le barème correspondant
      var selectedBareme = baremesValues.firstWhere(
        (bareme) => bareme['id'] == baremeId,
        orElse: () => {'id': baremeId, 'value': 'غير معروف'},
      );

      // Récupérer le nom du barème
      String baremeName = selectedBareme['value'] ?? 'غير معروف';

      // Afficher le nom du barème dans la console
      print('Barème Name: $baremeName');

      // Récupérer le nom du sous-barème si sousBaremeId est fourni
      String? sousBaremeName;
      if (sousBaremeId != null) {
        // Trouver le sous-barème correspondant
        var selectedSousBareme = baremesValues.firstWhere(
          (bareme) =>
              bareme['id'] == sousBaremeId &&
              bareme['parentBaremeId'] == baremeId,
          orElse: () => {'id': sousBaremeId, 'value': 'غير معروف'},
        );

        // Récupérer le nom du sous-barème
        sousBaremeName = selectedSousBareme['value'] ?? 'غير معروف';

        // Afficher le nom du sous-barème dans la console
        print('Sous-Barème Name: $sousBaremeName');
      }

      // Naviguer vers la page de classification
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassificationPage(
            selectedClass: widget.selectedClass,
            selectedBaremeId: baremeId,
            selectedSousBaremeId: sousBaremeId, // Passez ce paramètre
            currentUser: currentUser!,
            profName: _profName,
            schoolName: _schoolName,
            className: classAndMatiereNames['className'] ?? 'غير معروف',
            matiereName: classAndMatiereNames['matiereName'] ?? 'غير معروف',
            baremeName: baremeName,
            sousBaremeName: sousBaremeName, // Passez ce paramètre
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de la navigation vers la page de classification : $e');
    }
  }

////////////////////////////////////
  Future<void> _generatePDF() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utilisateur non connecté.')),
      );
      return;
    }

    // Récupérer les informations nécessaires pour générer le PDF
    var data = {
      'profName': _profName,
      'matiereName': await _getMatiereName(),
      'className': await _getClassName(),
      'schoolName': _schoolName,
      'baremes': await _getBaremes(),
      'students': await _getStudents(),
      'sumCriteriaMaxPerBareme': sumCriteriaMaxPerBareme,
      'totalStudents': totalStudents,
      'selectedClass': widget.selectedClass,
      'selectedBaremeId': selectedBaremeId,
      'currentUser': currentUser?.uid,
      'baremeName': baremeName,
      'sousBaremeName': sousBaremeName,
      'selectedSousBaremeId': selectedSousBaremeId,
    };

    print('Données envoyées à Flask: ${json.encode(data)}');
    await _sendDataToFlask(data);
  }

  Future<void> _sendDataToFlask(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse(
          'https://imprission.onrender.com/generate_pdf'); // Remplacez par l'URL de votre serveur Flask
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        // Convertir la réponse en bytes
        final bytes = response.bodyBytes;

        // Créer un Blob à partir des bytes
        final blob = html.Blob([bytes], 'application/pdf');

        // Créer un lien de téléchargement
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'tableau_resultats.pdf')
          ..click();

        // Libérer l'URL de l'objet
        html.Url.revokeObjectUrl(url);
      } else {
        print('Erreur lors de l\'envoi des données: ${response.statusCode}');
        print('Réponse: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi des données: $e');
    }
  }
  // Méthode pour récupérer le nom de la matière

  Future<String> _getMatiereName() async {
    var matiereDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.selectedClass)
        .collection('matieres')
        .doc(widget.selectedMatiere)
        .get();

    return matiereDoc['name'] ?? 'غير معروف';
  }

  Future<String> _getClassName() async {
    var classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.selectedClass)
        .get();

    return classDoc['name'] ?? 'غير معروف';
  }

  // Méthode pour récupérer les barèmes
  Future<List<dynamic>> _getBaremes() async {
    try {
      // Récupérer les barèmes depuis Firestore
      final baremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      final List<dynamic> baremes = [];
      for (final baremeDoc in baremesSnapshot.docs) {
        final baremeId = baremeDoc['baremeId'];
        final baremeName = baremeDoc['baremeName'] ?? 'غير معروف';
        final isBaremeSelected = baremeDoc['selected'] ?? false;

        if (isBaremeSelected) {
          baremes.add({
            'id': baremeId,
            'value': baremeName,
            'type': 'bareme',
          });
        }

        // Récupérer les sous-barèmes pour ce barème
        final sousBaremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('selections')
            .doc(widget.selectedClass)
            .collection(widget.selectedMatiere)
            .doc(baremeId)
            .collection('sousBaremes')
            .get();

        for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
          final sousBaremeId = sousBaremeDoc.id;
          final sousBaremeName = sousBaremeDoc['sousBaremeName'] ?? 'غير معروف';
          final isSousBaremeSelected = sousBaremeDoc['selected'] ?? false;

          if (isSousBaremeSelected) {
            baremes.add({
              'id': sousBaremeId,
              'value': sousBaremeName,
              'type': 'sousBareme',
              'parentBaremeId': baremeId,
            });
          }
        }
      }

      return baremes;
    } catch (e) {
      print('Erreur lors de la récupération des barèmes: $e');
      return [];
    }
  }

  // Méthode pour récupérer la liste des élèves
  Future<List<dynamic>> _getStudents() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(widget.selectedClass)
          .collection('students')
          .get();

      print('Nombre d\'élèves récupérés: ${studentsSnapshot.docs.length}');

      final List<dynamic> students = [];
      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentName = studentDoc['name'] ?? 'Élève inconnu';
        print('Élève: $studentName (ID: $studentId)');

        // Récupérer les notes pour les barèmes et sous-barèmes
        final baremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(widget.selectedClass)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .get();

        print(
            'Nombre de barèmes pour l\'élève $studentName: ${baremesSnapshot.docs.length}');

        final Map<String, String> baremes = {};
        for (final baremeDoc in baremesSnapshot.docs) {
          final baremeId = baremeDoc.id;
          final marks = baremeDoc.data()?['Marks'] ??
              '( - - - )'; // Valeur par défaut si Marks est manquant
          print('Barème: $baremeId, Marks: $marks');
          baremes[baremeId] = marks;

          // Récupérer les notes pour les sous-barèmes
          final sousBaremesSnapshot =
              await baremeDoc.reference.collection('sous_baremes').get();

          print(
              'Nombre de sous-barèmes pour le barème $baremeId: ${sousBaremesSnapshot.docs.length}');

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousMarks = sousBaremeDoc.data()?['Marks'] ??
                '( - - - )'; // Valeur par défaut si Marks est manquant
            print('Sous-Barème: $sousBaremeId, Marks: $sousMarks');
            baremes['$baremeId-$sousBaremeId'] = sousMarks;
          }
        }

        students.add({
          'id': studentId,
          'name': studentName,
          'baremes': baremes,
        });
      }

      return students;
    } catch (e) {
      print('Erreur lors de la récupération des élèves: $e');
      return [];
    }
  }

/////////////////////////////////////////////////////////////////////
  // Charger les données depuis Firestore
  void _loadUserData() async {
    if (currentUser != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _profName = userDoc['profName'] ?? '';
          _schoolName = userDoc['schoolName'] ?? '';
          _isDialogCompleted = _profName.isNotEmpty && _schoolName.isNotEmpty;
        });
      }

      // Afficher la boîte de dialogue uniquement si les données ne sont pas déjà enregistrées
      if (!_isDialogCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showInputDialog();
        });
      }
    }
  }

  void _showEditDialog() {
    TextEditingController profController =
        TextEditingController(text: _profName);
    TextEditingController schoolController =
        TextEditingController(text: _schoolName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تعديل المعلومات', textDirection: TextDirection.rtl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: profController,
                decoration: InputDecoration(
                  labelText: 'اسم الأستاذ',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(
                  labelText: 'اسم المدرسة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('إلغاء', textDirection: TextDirection.rtl),
            ),
            TextButton(
              onPressed: () async {
                if (currentUser != null) {
                  // Enregistrer les données dans Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .set(
                    {
                      'profName': profController.text,
                      'schoolName': schoolController.text,
                    },
                    SetOptions(merge: true),
                  );

                  setState(() {
                    _profName = profController.text;
                    _schoolName = schoolController.text;
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('حفظ', textDirection: TextDirection.rtl),
            ),
          ],
        );
      },
    );
  }

  // Afficher la boîte de dialogue pour saisir les informations
  void _showInputDialog() {
    TextEditingController profController = TextEditingController();
    TextEditingController schoolController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('معلومات جديدة', textDirection: TextDirection.rtl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: profController,
                decoration: InputDecoration(
                  labelText: 'اسم الأستاذ',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(
                  labelText: 'اسم المدرسة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('إلغاء', textDirection: TextDirection.rtl),
            ),
            TextButton(
              onPressed: () async {
                if (currentUser != null) {
                  // Enregistrer les données dans Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .set(
                    {
                      'profName': profController.text,
                      'schoolName': schoolController.text,
                    },
                    SetOptions(merge: true),
                  );

                  setState(() {
                    _profName = profController.text;
                    _schoolName = schoolController.text;
                    _isDialogCompleted = true;
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('حفظ', textDirection: TextDirection.rtl),
            ),
          ],
        );
      },
    );
  }

  // Récupérer les marques depuis Firestore
  Future<void> fetchMarks() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Aucun utilisateur connecté");
      }

      // Récupérer tous les élèves de la classe
      var studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_classes')
          .doc(widget.selectedClass)
          .collection('students')
          .get();

      setState(() {
        totalStudents = studentsSnapshot.docs.length;
      });

      // Récupérer les barèmes et sous-barèmes sélectionnés
      var selectedBaremes = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      // Initialiser les compteurs pour chaque barème et sous-barème
      for (var baremeDoc in selectedBaremes.docs) {
        var baremeId = baremeDoc['baremeId'];
        sumCriteriaMaxPerBareme[baremeId] = 0;

        // Récupérer les sous-barèmes pour ce barème
        var sousBaremesSnapshot =
            await baremeDoc.reference.collection('sous_baremes').get();
        for (var sousBaremeDoc in sousBaremesSnapshot.docs) {
          var sousBaremeId = sousBaremeDoc['sousBaremeId'];
          sumCriteriaMaxPerBareme['$baremeId-$sousBaremeId'] = 0;
        }
      }

      // Parcourir chaque élève
      for (var studentDoc in studentsSnapshot.docs) {
        var studentId = studentDoc.id;

        for (var baremeDoc in selectedBaremes.docs) {
          var baremeId = baremeDoc['baremeId'];

          // Récupérer la valeur du barème pour l'élève
          var baremeSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('user_classes')
              .doc(widget.selectedClass)
              .collection('students')
              .doc(studentId)
              .collection('baremes')
              .doc(baremeId)
              .get();

          if (baremeSnapshot.exists &&
              baremeSnapshot.data()?.containsKey('Marks') == true) {
            var value = baremeSnapshot['Marks'];
            if (value == '( + + + )' || value == '( + + - )') {
              sumCriteriaMaxPerBareme[baremeId] =
                  (sumCriteriaMaxPerBareme[baremeId] ?? 0) + 1;
            }
          } else {
            // Vérifier dans les sous-barèmes
            var sousBaremesSnapshot =
                await baremeSnapshot.reference.collection('sous_baremes').get();
            for (var sousBaremeDoc in sousBaremesSnapshot.docs) {
              if (sousBaremeDoc.data().containsKey('Marks')) {
                var value = sousBaremeDoc['Marks'];
                if (value == '( + + + )' || value == '( + + - )') {
                  sumCriteriaMaxPerBareme[sousBaremeDoc.id] =
                      (sumCriteriaMaxPerBareme[sousBaremeDoc.id] ?? 0) + 1;
                }
              }
            }
          }
        }
      }

      setState(() {});
    } catch (e) {
      print('Erreur lors de la récupération des marques : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(child: Text('Utilisateur non connecté.'));
    }

    if (!_isDialogCompleted) {
      return Center(child: CircularProgressIndicator());
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontFamily: 'ArabicFont', fontSize: 14),
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('الجدول الجامع للنتائج',
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
          elevation: 4,
          iconTheme: IconThemeData(color: Colors.green),
          actions: [
            // Indicateur de compte activé ou non
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Icon(Icons.circle, color: Colors.grey); // En attente
                }
                if (snapshot.hasError) {
                  return Icon(Icons.error, color: Colors.red); // Erreur
                }
                final isActive = snapshot.data?['isActive'] ?? false;
                return Icon(
                  Icons.circle,
                  color: isActive
                      ? Colors.green
                      : Colors.red, // Vert si activé, rouge sinon
                );
              },
            ),
            SizedBox(width: 8), // Espacement
            IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ),
              onPressed: () {
                _showEditDialog();
              },
            ),
            IconButton(
              icon: Icon(Icons.print),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Utilisateur non connecté.')),
                  );
                  return;
                }

                // Récupérer les informations de l'utilisateur
                final userDoc = await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(user.uid)
                    .get();

                final isActive = userDoc['isActive'] ?? false;

                // Vérifier si le compte est activé
                if (isActive) {
                  // Si le compte est activé, générer le PDF
                  await _generatePDF();
                } else {
                  // Si le compte n'est pas activé, rediriger vers la page de paiement
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Votre compte n\'est pas activé. Veuillez effectuer un paiement pour activer votre compte.')),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentPage()),
                  );
                }
              },
            ),
          ],
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            children: [
              // En-tête professionnel
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    // Professeur, matière et classe à gauche (alignés verticalement)
                    FutureBuilder<Map<String, String>>(
                      future: _getClassAndMatiereNames(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('خطأ في تحميل البيانات',
                              textDirection: TextDirection.rtl);
                        }
                        if (!snapshot.hasData) {
                          return Text('لا توجد بيانات',
                              textDirection: TextDirection.rtl);
                        }

                        var classAndMatiereNames = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الأستاذ: $_profName',
                              style: TextStyle(fontSize: 10),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'المادة: ${classAndMatiereNames['matiereName']}',
                              style: TextStyle(fontSize: 10),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'القسم: ${classAndMatiereNames['className']}',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        );
                      },
                    ),
                    Spacer(),
                    // Logo et nom de l'école à droite
                    Column(
                      children: [
                        SizedBox(height: 5),
                        Text(
                          'الجدول الجامع للنتائج',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    Spacer(),
                    Column(
                      children: [
                        Image.asset(
                          'lib/assets/icons/me/ministere.png',
                          height: 70,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'مدرسة: $_schoolName',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildMainContent(),
              ),
              // Pied de page
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  'تاريخ الإصدار: ${DateTime.now().toString().substring(0, 10)}',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>> _getClassAndMatiereNames() async {
    try {
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();
      var className = classDoc['name'] ?? 'غير معروف';

      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();
      var matiereName = matiereDoc['name'] ?? 'غير معروف';
      var matiereId = matiereDoc.id;

      return {
        'className': className,
        'matiereName': matiereName,
        'matiereId': matiereId,
      };
    } catch (e) {
      print('Erreur lors de la récupération des noms: $e');
      return {
        'className': 'غير معروف',
        'matiereName': 'غير معروف',
        'matiereId': 'غير معروف',
      };
    }
  }

  Widget _buildMainContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .snapshots(),
      builder: (context, userClassesSnapshot) {
        if (userClassesSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (userClassesSnapshot.hasError) {
          return Center(
              child: Text('خطأ: ${userClassesSnapshot.error}',
                  textDirection: TextDirection.rtl));
        }
        if (!userClassesSnapshot.hasData ||
            userClassesSnapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('لم يتم العثور على أي قسم.',
                  textDirection: TextDirection.rtl));
        }

        for (var classDoc in userClassesSnapshot.data!.docs) {
          var classData = classDoc.data() as Map<String, dynamic>;
          var classIdFromFirestore = classData['class_id'] ?? '';

          if (widget.selectedClass == classIdFromFirestore) {
            return StudentsTable(
              classDocId: classDoc.id,
              selectedClass: widget.selectedClass,
              selectedMatiere: widget.selectedMatiere,
              currentUser: currentUser!,
              sumCriteriaMaxPerBareme: sumCriteriaMaxPerBareme,
              totalStudents: totalStudents,
              navigateToClassificationPage: _navigateToClassificationPage,
            );
          }
        }

        return Center(
            child: Text('لم يتم العثور على أي قسم مطابق.',
                textDirection: TextDirection.rtl));
      },
    );
  }
}

class StudentsTable extends StatefulWidget {
  final String classDocId;
  final String selectedClass;
  final String selectedMatiere;
  final User currentUser;
  final Map<String, int> sumCriteriaMaxPerBareme;
  final int totalStudents;
  final Function(String, {String? sousBaremeId})
      navigateToClassificationPage; // Modifier ici

  const StudentsTable({
    Key? key,
    required this.classDocId,
    required this.selectedClass,
    required this.selectedMatiere,
    required this.currentUser,
    required this.sumCriteriaMaxPerBareme,
    required this.totalStudents,
    required this.navigateToClassificationPage, // Modifier ici
  }) : super(key: key);

  @override
  _StudentsTableState createState() => _StudentsTableState();
}

class _StudentsTableState extends State<StudentsTable> {
  final List<String> _dropdownValues = [
    '( - - - )',
    '( + - - )',
    '( + + - )',
    '( + + + )'
  ];
  final Map<String, Map<String, String>> _selectedValues = {};

  // Map pour stocker les couleurs aléatoires des en-têtes
  final Map<String, Color> _headerColors = {};

  // Fonction pour générer une couleur aléatoire
  Color _getRandomColor() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0)
        .withOpacity(1);
  }

  // Fonction pour regrouper les barèmes par leurs 4 premiers caractères
  Map<String, List<Map<String, dynamic>>> groupBaremes(
      List<Map<String, dynamic>> baremesValues) {
    Map<String, List<Map<String, dynamic>>> groupedBaremes = {};

    for (var bareme in baremesValues) {
      String key =
          bareme['value'].substring(0, 4); // Prendre les 4 premiers caractères
      if (!groupedBaremes.containsKey(key)) {
        groupedBaremes[key] = [];
      }
      groupedBaremes[key]!.add(bareme);
    }

    return groupedBaremes;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.currentUser.uid)
                .collection('user_classes')
                .doc(widget.classDocId)
                .collection('students')
                .snapshots(),
            builder: (context, studentsSnapshot) {
              if (studentsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (studentsSnapshot.hasError) {
                return Center(
                    child: Text('خطأ: ${studentsSnapshot.error}',
                        textDirection: TextDirection.rtl));
              }
              if (!studentsSnapshot.hasData ||
                  studentsSnapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('لم يتم العثور على أي طالب.',
                        textDirection: TextDirection.rtl));
              }

              return _buildSelectionsTable(studentsSnapshot.data!.docs);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionsTable(List<QueryDocumentSnapshot> studentsDocs) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .snapshots(),
      builder: (context, selectionsSnapshot) {
        if (selectionsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (selectionsSnapshot.hasError) {
          return Center(
              child: Text('خطأ: ${selectionsSnapshot.error}',
                  textDirection: TextDirection.rtl));
        }
        if (!selectionsSnapshot.hasData ||
            selectionsSnapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('لم يتم العثور على أي معيار.',
                  textDirection: TextDirection.rtl));
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getBaremesValues(selectionsSnapshot.data!.docs),
          builder: (context, baremesValuesSnapshot) {
            if (baremesValuesSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (baremesValuesSnapshot.hasError) {
              return Center(
                  child: Text('خطأ: ${baremesValuesSnapshot.error}',
                      textDirection: TextDirection.rtl));
            }
            if (!baremesValuesSnapshot.hasData ||
                baremesValuesSnapshot.data!.isEmpty) {
              return const Center(
                  child: Text('لم يتم العثور على أي معيار.',
                      textDirection: TextDirection.rtl));
            }

            return _buildDataTable(studentsDocs, baremesValuesSnapshot.data!);
          },
        );
      },
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> studentsDocs,
      List<Map<String, dynamic>> baremesValues) {
    // Regrouper les barèmes par leurs 4 premiers caractères
    Map<String, List<Map<String, dynamic>>> groupedBaremes =
        groupBaremes(baremesValues);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 12,
        columns: [
          const DataColumn(
            label: SizedBox(
              width: 150,
              child: Text('الاسم واللقب',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
          ),
          for (var entry in groupedBaremes.entries)
            for (final bareme in entry.value)
              for (final subEntry in [
                {'id': bareme['id'], 'value': bareme['value']},
                ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
              ])
                DataColumn(
                  label: Container(
                    width: 100,
                    color: _headerColors.putIfAbsent(
                        entry.key,
                        () =>
                            _getRandomColor()), // Couleur aléatoire pour l'en-tête
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                            entry
                                .key, // En-tête du groupe (4 premiers caractères)
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .white)), // Texte en blanc pour contraste
                        Text(subEntry['value'], // Nom du barème ou sous-barème
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .white)), // Texte en blanc pour contraste
                      ],
                    ),
                  ),
                ),
        ],
        rows: [
          ...studentsDocs.map((studentDoc) {
            final studentId = studentDoc.id;
            final studentName = studentDoc['name'] ?? 'غير معروف';

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(studentName,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: Colors.grey.shade800)),
                  ),
                ),
                for (var entry in groupedBaremes.entries)
                  for (final bareme in entry.value)
                    for (final subEntry in [
                      {'id': bareme['id'], 'type': 'bareme'},
                      ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
                          .map((s) => {'id': s['id'], 'type': 'sousBareme'})
                    ])
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: FutureBuilder<String>(
                            future:
                                _getSelectedValue(studentId, subEntry['id']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              return Text(
                                snapshot.data ?? _dropdownValues[0],
                                style: TextStyle(
                                    color: Colors
                                        .black), // Texte en noir pour contraste
                              );
                            },
                          ),
                        ),
                      ),
              ],
            );
          }).toList(),
          // Ligne des statistiques
          DataRow(
            cells: [
              const DataCell(Text('عدد التلاميذ المحققين',
                  style: TextStyle(fontWeight: FontWeight.bold))),
              for (final bareme in baremesValues)
                for (final entry in [
                  {'id': bareme['id']},
                  ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
                ])
                  DataCell(Text(
                    widget.sumCriteriaMaxPerBareme[entry['id']]?.toString() ??
                        '0',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
            ],
          ),
          // Ligne des pourcentages
          DataRow(
            cells: [
              const DataCell(Text('النسبة المئوية',
                  style: TextStyle(fontWeight: FontWeight.bold))),
              for (var entry in groupedBaremes.entries)
                for (final bareme in entry.value)
                  for (final subEntry in [
                    {'id': bareme['id']},
                    ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
                  ])
                    DataCell(Text(
                      widget.totalStudents == 0
                          ? 'لا توجد درجات'
                          : '${((widget.sumCriteriaMaxPerBareme[subEntry['id']] ?? 0) / widget.totalStudents * 100).toStringAsFixed(2)}٪',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black), // Texte en noir pour contraste
                    )),
            ],
          ),
          // Ligne des boutons "تصنيف"
          // Première DataRow pour le bouton "تصنيف" (Classer)
          DataRow(
            cells: [
              DataCell(Container()), // Cellule vide pour la colonne des noms
              for (var entry in groupedBaremes.entries)
                for (final bareme in entry.value)
                  for (final subEntry in [
                    {
                      'id': bareme['id'],
                      'type': 'bareme',
                      'name': bareme['value']
                    }, // Ajouter le nom du barème
                    ...(bareme['sousBaremes'] as List<dynamic>? ?? []).map(
                        (s) => {
                              'id': s['id'],
                              'type': 'sousBareme',
                              'name': s['value']
                            }) // Ajouter le nom du sous-barème
                  ])
                    DataCell(
                      Container(
                        width: 100,
                        height: 50, // Hauteur réduite pour un seul bouton
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            print(
                                'Bareme Name: ${bareme['value']}'); // Afficher le nom du barème
                            print(
                                'Sous-Bareme Name: ${subEntry['type'] == 'sousBareme' ? subEntry['name'] : 'N/A'}'); // Afficher le nom du sous-barème
                            _classifyStudentsByBarem(
                              bareme['id']!,
                              sousBaremeId: subEntry['type'] == 'sousBareme'
                                  ? subEntry['id']
                                  : null,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                          ),
                          child: Text(
                            'تصنيف',
                            style:
                                TextStyle(fontSize: 12, color: Colors.yellow),
                          ),
                        ),
                      ),
                    ),
            ],
          ),

// Deuxième DataRow pour le bouton "تصنيف آخر" (Autre classement)
          DataRow(
            cells: [
              DataCell(Container()), // Cellule vide pour la colonne des noms
              for (var entry in groupedBaremes.entries)
                for (final bareme in entry.value)
                  for (final subEntry in [
                    {
                      'id': bareme['id'],
                      'type': 'bareme',
                      'name': bareme['value']
                    }, // Ajouter le nom du barème
                    ...(bareme['sousBaremes'] as List<dynamic>? ?? []).map(
                        (s) => {
                              'id': s['id'],
                              'type': 'sousBareme',
                              'name': s['value']
                            }) // Ajouter le nom du sous-barème
                  ])
                    DataCell(
                      Container(
                        width: 100,
                        height: 50, // Hauteur réduite pour un seul bouton
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            print(
                                'Bareme Name: ${bareme['value']}'); // Afficher le nom du barème
                            print(
                                'Sous-Bareme Name: ${subEntry['type'] == 'sousBareme' ? subEntry['name'] : 'N/A'}'); // Afficher le nom du sous-barème
                            widget.navigateToClassificationPage(
                              bareme['id']!,
                              sousBaremeId: subEntry['type'] == 'sousBareme'
                                  ? subEntry['id']
                                  : null,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                          ),
                          child: Text(
                            'خطة العلاج',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getBaremesValues(
      List<QueryDocumentSnapshot> selectedBaremes) async {
    final List<Map<String, dynamic>> result = [];
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    print('User ID: $userId');
    print('Selected Class: ${widget.selectedClass}');
    print('Selected Matiere: ${widget.selectedMatiere}');

    for (final baremeDoc in selectedBaremes) {
      final baremeId = baremeDoc['baremeId'];
      print('Processing baremeId: $baremeId');

      final baremeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .get();

      final isBaremeSelected = baremeSnapshot['selected'] ?? false;
      print('Bareme selected: $isBaremeSelected');

      final sousBaremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .collection('sousBaremes')
          .get();

      final selectedSousBaremes = sousBaremesSnapshot.docs
          .where((doc) => doc['selected'] == true)
          .toList();

      print('Number of selected sousBaremes: ${selectedSousBaremes.length}');

      if (isBaremeSelected) {
        final baremeName = baremeSnapshot['baremeName'] ?? 'غير معروف';
        print('Adding bareme: $baremeId - $baremeName');

        result.add({
          'id': baremeId,
          'value': baremeName,
          'sousBaremes': [],
        });
      } else if (selectedSousBaremes.isNotEmpty) {
        for (final sousBareme in selectedSousBaremes) {
          final sousBaremeName = sousBareme['sousBaremeName'] ?? 'غير معروف';
          print(
              'Adding sousBareme: ${sousBareme.id} - $sousBaremeName (Parent: $baremeId)');

          result.add({
            'id': sousBareme.id,
            'value': sousBaremeName,
            'parentBaremeId': baremeId, // Track parent bareme ID
          });
        }
      }
    }
    print('Final result: $result');
    return result;
  }

  // Future<void> _saveAllChanges() async {
  //   final batch = FirebaseFirestore.instance.batch();

  //   for (final studentId in _selectedValues.keys) {
  //     final studentBaremes = _selectedValues[studentId]!;
  //     for (final baremeKey in studentBaremes.keys) {
  //       final value = studentBaremes[baremeKey]!;

  //       // Vérifier si la clé est pour un barème ou un sous-barème
  //       final isSousBareme = baremeKey.contains('-');
  //       final baremeId = isSousBareme ? baremeKey.split('-')[0] : baremeKey;
  //       final sousBaremeId = isSousBareme ? baremeKey.split('-')[1] : null;

  //       // Référence à la collection baremes
  //       var baremesCollectionRef = FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(widget.currentUser.uid)
  //           .collection('user_classes')
  //           .doc(widget.classDocId)
  //           .collection('students')
  //           .doc(studentId)
  //           .collection('baremes');

  //       // Référence au document du barème principal
  //       var baremeRef = baremesCollectionRef.doc(baremeId);

  //       // Si c'est un sous-barème, modifier dans les deux emplacements
  //       if (isSousBareme) {
  //         // 1. Modifier dans le sous-barème directement dans la collection baremes
  //         var sousBaremeDirectRef = baremesCollectionRef.doc(baremeKey);
  //         if (value != null) {
  //           batch.set(
  //               sousBaremeDirectRef, {'Marks': value}, SetOptions(merge: true));
  //         } else {
  //           batch.update(sousBaremeDirectRef, {'Marks': FieldValue.delete()});
  //         }

  //         // 2. Modifier dans la collection sous_baremes du barème principal
  //         var sousBaremeNestedRef =
  //             baremeRef.collection('sous_baremes').doc(sousBaremeId);
  //         if (value != null) {
  //           batch.set(
  //               sousBaremeNestedRef, {'Marks': value}, SetOptions(merge: true));
  //         } else {
  //           batch.update(sousBaremeNestedRef, {'Marks': FieldValue.delete()});
  //         }

  //         // 3. Mettre à jour haveSoubarem dans le barème principal
  //         batch.set(baremeRef, {'haveSoubarem': true}, SetOptions(merge: true));
  //       } else {
  //         // Si c'est un barème principal, modifier uniquement dans le barème principal
  //         if (value != null) {
  //           batch.set(baremeRef, {'Marks': value}, SetOptions(merge: true));
  //         } else {
  //           batch.update(baremeRef, {'Marks': FieldValue.delete()});
  //         }
  //       }
  //     }
  //   }

  //   // Appliquer toutes les modifications en une seule transaction
  //   await batch.commit();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
  //   );

  //   await batch.commit();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
  //   );
  // }
  Future<String> _getSelectedValue(String studentId, String baremeKey) async {
    try {
      debugPrint(
          'Début de _getSelectedValue pour l\'étudiant $studentId et le barème $baremeKey');

      // Référence au barème principal
      var docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(widget.classDocId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeKey);

      // Vérifier si le barème existe
      final parentDoc = await docRef.get();
      if (!parentDoc.exists) {
        debugPrint('Le document pour le barème $baremeKey n\'existe pas');
        return _dropdownValues[0]; // Valeur par défaut
      }

      // Vérifier si le barème principal a des sous-barèmes
      final haveSoubarem = parentDoc.data()?['haveSoubarem'] ?? false;
      debugPrint(
          'Le barème $baremeKey a-t-il des sous-barèmes ? $haveSoubarem');

      // Si le barème a des sous-barèmes, chercher dans la collection "sous_baremes"
      if (haveSoubarem) {
        final sousBaremesSnapshot =
            await docRef.collection('sous_baremes').get();
        if (sousBaremesSnapshot.docs.isNotEmpty) {
          // Prendre le premier sous-barème (ou celui que vous voulez)
          final sousBaremeDocRef = sousBaremesSnapshot.docs.first;
          final sousBaremeData = sousBaremeDocRef.data();
          debugPrint(
              'Sous-barème trouvé avec la valeur: ${sousBaremeData?['Marks']}');
          return sousBaremeData?['Marks']?.toString() ?? _dropdownValues[0];
        } else {
          debugPrint('Aucun sous-barème trouvé');
        }
      }

      // Retourner la valeur principale si pas de sous-barème ou sous-barème non trouvé
      final marks =
          parentDoc.data()?['Marks']?.toString() ?? _dropdownValues[0];
      debugPrint('Valeur principale récupérée: $marks');
      return marks;
    } catch (e) {
      debugPrint("Erreur: $e");
      return _dropdownValues[0]; // Valeur par défaut en cas d'erreur
    }
  }

  // Fonction pour classer les élèves en groupes selon un barème spécifique
  void _classifyStudentsByBarem(String baremeId, {String? sousBaremeId}) async {
    try {
      // Récupérer tous les élèves de la classe
      var studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(widget.classDocId)
          .collection('students')
          .get();

      // Initialiser les groupes
      Map<String, List<String>> studentGroups = {
        'مجموعة العلاج': [],
        'مجموعة الدعم': [],
        'مجموعة التميز': [],
      };

      // Parcourir chaque élève
      for (var studentDoc in studentsSnapshot.docs) {
        var studentId = studentDoc.id;
        var studentName = studentDoc['name'] ?? 'اسم غير معروف';

        // Récupérer la valeur du barème ou sous-barème pour l'élève
        var baremeRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .collection('user_classes')
            .doc(widget.classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeId);

        var snapshot = sousBaremeId != null
            ? await baremeRef.collection('sous_baremes').doc(sousBaremeId).get()
            : await baremeRef.get();

        if (snapshot.exists) {
          var value = snapshot['Marks'];

          // Classer l'élève dans un groupe
          if (value == '( + + + )') {
            studentGroups['مجموعة التميز']!.add(studentName);
          } else if (value == '( + + - )') {
            studentGroups['مجموعة الدعم']!.add(studentName);
          } else if (value == '( + - - )' || value == '( - - - )') {
            studentGroups['مجموعة العلاج']!.add(studentName);
          }
        }
      }

      // Afficher les groupes dans une boîte de dialogue
      _showClassificationDialog(studentGroups);
    } catch (e) {
      print('Erreur lors de la classification des élèves: $e');
    }
  }

  // Afficher les groupes dans une boîte de dialogue
  void _showClassificationDialog(Map<String, List<String>> studentGroups) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تصنيف التلاميذ', textDirection: TextDirection.rtl),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGroupList(
                    'مجموعة العلاج',
                    const Color.fromARGB(255, 236, 19, 3),
                    studentGroups['مجموعة العلاج']!),
                _buildGroupList('مجموعة الدعم', Colors.orange,
                    studentGroups['مجموعة الدعم']!),
                _buildGroupList(
                    'مجموعة التميز',
                    const Color.fromARGB(255, 11, 240, 19),
                    studentGroups['مجموعة التميز']!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('إغلاق', textDirection: TextDirection.rtl),
            ),
          ],
        );
      },
    );
  }

  // Afficher un groupe d'élèves dans une carte
  Widget _buildGroupList(String groupName, Color color, List<String> students) {
    return Card(
      color: color.withOpacity(1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...students.map((studentName) {
              return Text(studentName);
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class StudentDropdown extends StatefulWidget {
  final String studentId;
  final String baremeId;
  final String initialValue;
  final List<String> dropdownValues;
  final Function(String, String, String) onChanged;

  const StudentDropdown({
    Key? key,
    required this.studentId,
    required this.baremeId,
    required this.initialValue,
    required this.dropdownValues,
    required this.onChanged,
  }) : super(key: key);

  @override
  _StudentDropdownState createState() => _StudentDropdownState();
}

class _StudentDropdownState extends State<StudentDropdown> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _currentValue,
      alignment: Alignment.center,
      dropdownColor: Colors.white,
      items: widget.dropdownValues
          .map((value) => DropdownMenuItem(
                value: value,
                child: Text(value, textDirection: TextDirection.rtl),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _currentValue = value);
          widget.onChanged(widget.studentId, widget.baremeId, value);
        }
      },
    );
  }
}
