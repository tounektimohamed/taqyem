import 'dart:async';
import 'dart:io';

import 'package:Taqyem/taqyem/header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:url_launcher/url_launcher.dart'; // Pour Flutter Web seulement

class ClassificationPage extends StatefulWidget {
  final String selectedClass;
  final String selectedBaremeId;
  final User currentUser;
  final String profName;
  final String schoolName;
  final String className;
  final String matiereName;
  final String baremeName;
  final String? sousBaremeName;
  final String? selectedSousBaremeId;

  ClassificationPage({
    required this.selectedClass,
    required this.selectedBaremeId,
    required this.currentUser,
    required this.profName,
    required this.schoolName,
    required this.className,
    required this.matiereName,
    required this.baremeName,
    this.sousBaremeName,
    this.selectedSousBaremeId,
  });

  @override
  _ClassificationPageState createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
  List<dynamic> jsonData = [];
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    //  printVariables();
    loadJsonData();
  }

  // void printVariables() {
  //   print("Classe sélectionnée: ${widget.selectedClass}");
  //   print("ID du barème sélectionné: ${widget.selectedBaremeId}");
  //   print("Utilisateur actuel: ${widget.currentUser}");
  //   print("Nom du professeur: ${widget.profName}");
  //   print("Nom de l'école: ${widget.schoolName}");
  //   print("Nom de la classe: ${widget.className}");
  //   print("Nom de la matière: ${widget.matiereName}");
  //   print("Nom du barème: ${widget.baremeName ?? 'Non défini'}");
  //   print("ID du sous-barème sélectionné: ${widget.selectedBaremeId}");
  //   print("Nom du sous-barème: ${widget.baremeName ?? 'Non défini'}");
  // }

  Future<void> loadJsonData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/data.json');
      setState(() {
        jsonData = json.decode(jsonString);
      });
    } catch (e) {
      print("Erreur lors du chargement du fichier JSON: $e");
    }
  }

  Future<void> _saveUserProposal(
      String solution, String probleme, String groupName) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final proposalRef = FirebaseFirestore.instance
        .collection('users_proposals')
        .doc(userId)
        .collection('user_proposals')
        .doc();

    final globalProposalRef = FirebaseFirestore.instance
        .collection('users_proposals')
        .doc('global_proposals')
        .collection('approved_proposals')
        .doc(proposalRef.id);

    final batch = FirebaseFirestore.instance.batch();

    // 1. Ajout à la collection utilisateur
    batch.set(proposalRef, {
      'solution': solution,
      'probleme': probleme,
      'groupName': groupName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'userId': userId,
      'userName': FirebaseAuth.instance.currentUser!.displayName ?? 'Anonymous',
      'className': widget.className,
      'matiereName': widget.matiereName,
      'baremeName': widget.baremeName,
      'sousBaremeName': widget.sousBaremeName ?? '',
    });

    // 2. Ajout à la collection globale (en attente)
    batch.set(globalProposalRef, {
      'originalRef': proposalRef.path,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> _approveProposal(String proposalPath) async {
    final proposalRef = FirebaseFirestore.instance.doc(proposalPath);
    final globalRef = FirebaseFirestore.instance
        .collection('users_proposals')
        .doc('global_proposals')
        .collection('approved_proposals')
        .doc(proposalRef.id);

    final batch = FirebaseFirestore.instance.batch();

    // 1. Mettre à jour le statut dans la collection utilisateur
    batch.update(proposalRef, {
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': FirebaseAuth.instance.currentUser!.uid,
    });

    // 2. Mettre à jour le statut dans la collection globale
    batch.update(globalRef, {
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  void showSolutionAndProbleme(String groupName) {
    print("Classe sélectionnée: ${widget.className}");
    print("Matière sélectionnée: ${widget.matiereName}");
    print("Barème sélectionné: ${widget.baremeName}");
    print("Sous-barème sélectionné: ${widget.sousBaremeName ?? 'Non défini'}");

    var result = jsonData.firstWhere(
      (item) {
        String jsonClasse = item['classe'].trim().toLowerCase();
        String jsonMatiere = item['matiere'].trim().toLowerCase();
        String jsonBareme = item['bareme'].trim().toLowerCase();

        String selectedClasse = widget.className.trim().toLowerCase();
        String selectedMatiere = widget.matiereName.trim().toLowerCase();
        String selectedBareme =
            (widget.sousBaremeName ?? widget.baremeName).trim().toLowerCase();

        return jsonClasse == selectedClasse &&
            jsonMatiere == selectedMatiere &&
            jsonBareme == selectedBareme;
      },
      orElse: () => null,
    );

    // Contrôleurs pour les nouveaux champs de texte
    TextEditingController solutionController = TextEditingController();
    TextEditingController problemeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('خطة العلاج وأصل الخطأ لـ $groupName'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الحل:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(result != null ? result['solution'] : 'لا يوجد حل متاح'),
                SizedBox(height: 16),
                Text('المشكلة:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(result != null
                    ? result['probleme']
                    : 'لا يوجد مشكلة محددة'),
                SizedBox(height: 24),
                Text('أضف مقترحاتك:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                TextField(
                  controller: solutionController,
                  decoration: InputDecoration(
                    labelText: 'الحل المقترح',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: problemeController,
                  decoration: InputDecoration(
                    labelText: 'أصل المشكلة المقترح',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (solutionController.text.isNotEmpty ||
                    problemeController.text.isNotEmpty) {
                  await _saveUserProposal(solutionController.text,
                      problemeController.text, groupName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم حفظ المقترحات بنجاح')),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('حفظ المقترحات'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateAndSavePDF() async {
    try {
      final groupedStudents = await _getGroupedStudentsData();

      // Récupérer les données de solutions depuis jsonData (une seule fois)
      Map<String, dynamic> solutionsData = {};

      var result = jsonData.firstWhere(
        (item) {
          String jsonClasse = item['classe'].trim().toLowerCase();
          String jsonMatiere = item['matiere'].trim().toLowerCase();
          String jsonBareme = item['bareme'].trim().toLowerCase();

          String selectedClasse = widget.className.trim().toLowerCase();
          String selectedMatiere = widget.matiereName.trim().toLowerCase();
          String selectedBareme =
              (widget.sousBaremeName ?? widget.baremeName).trim().toLowerCase();

          return jsonClasse == selectedClasse &&
              jsonMatiere == selectedMatiere &&
              jsonBareme == selectedBareme;
        },
        orElse: () => null,
      );

      if (result != null) {
        solutionsData = {
          'solution': result['solution'],
          'probleme': result['probleme'],
        };
      }

      const serverUrl = 'http://localhost:5000/generate-pdf';

      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'groupedStudents': groupedStudents,
          'className': widget.className,
          'matiereName': widget.matiereName,
          'baremeName': widget.baremeName,
          'sousBaremeName': widget.sousBaremeName,
          'profName': widget.profName,
          'schoolName': widget.schoolName,
          'solutionsData': solutionsData, // Données uniques
        }),
      );

      if (response.statusCode == 200) {
        // Pour Flutter Web
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'classification.pdf')
          ..click();

        html.Url.revokeObjectUrl(url);
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  // Future<void> saveAndOpenPDF(Uint8List bytes) async {
  //   final directory = await getApplicationDocumentsDirectory();
  //   final file = File('${directory.path}/classification.pdf');
  //   await file.writeAsBytes(bytes);
  //   OpenFile.open(file.path);
  // }

  Future<Map<String, dynamic>> _getGroupedStudentsData() async {
    var students = await _getClassifiedStudents(
        widget.selectedClass, widget.selectedBaremeId);
    Map<String, List<Map<String, String>>> groupedStudents = {};

    for (var student in students) {
      String group = student['group'] ?? '';
      if (!groupedStudents.containsKey(group)) {
        groupedStudents[group] = [];
      }
      groupedStudents[group]!.add(student);
    }

    return groupedStudents;
  }

  Future<void> _saveAndLaunchPDF(Uint8List bytes, String fileName) async {
    final directory = await getExternalStorageDirectory();
    final file = File('${directory?.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    OpenFile.open(file.path);
  }
///////////////////////////////////////////

// Ajoutez cette nouvelle méthode à la fin de la classe _ClassificationPageState
 Future<void> generateAndOpenTreatmentPlan() async {
  // Début du chargement
  setState(() {
    _isGeneratingReport = true;
  });

  // Afficher le dialogue de chargement
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Génération du rapport en cours...",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Veuillez patienter, cette opération peut prendre quelques instants.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    },
  );

  try {
    debugPrint('[TreatmentPlan] Début de la génération du plan de traitement');

    // 1. Récupération des étudiants groupés
    final groupedStudents = await _getGroupedStudentsData();

    if (groupedStudents.isEmpty) {
      throw Exception('Aucun étudiant trouvé dans la classe');
    }

    // 2. Récupération des solutions unifiées
    final unifiedSolutions = await _getUnifiedSolutions();

    // 3. Préparation des données pour Flask
    final reportData = {
      'schoolName': widget.schoolName,
      'profName': widget.profName,
      'className': widget.className,
      'matiereName': widget.matiereName,
      'baremeName': widget.baremeName,
      'sousBaremeName': widget.sousBaremeName ?? '',
      'groups': {
        'treatment': groupedStudents['مجموعة العلاج']
                ?.map((s) => s['name'])
                .whereType<String>()
                .toList() ??
            [],
        'support': groupedStudents['مجموعة الدعم']
                ?.map((s) => s['name'])
                .whereType<String>()
                .toList() ??
            [],
        'excellence': groupedStudents['مجموعة التميز']
                ?.map((s) => s['name'])
                .whereType<String>()
                .toList() ??
            [],
      },
      'solutions': {
        'default': {
          'solution': unifiedSolutions['defaultSolution'] ?? '',
          'probleme': unifiedSolutions['defaultProbleme'] ?? '',
        },
        'userProposals': [
          ...(unifiedSolutions['userSolutions']
                  ?.map((s) => {'solution': s})
                  .toList() ??
              []),
          ...(unifiedSolutions['userProblems']
                  ?.map((p) => {'probleme': p})
                  .toList() ??
              []),
        ],
        'globalProposals': [
          ...(unifiedSolutions['globalSolutions']
                  ?.map((s) => {'solution': s})
                  .toList() ??
              []),
          ...(unifiedSolutions['globalProblems']
                  ?.map((p) => {'probleme': p})
                  .toList() ??
              []),
        ],
      },
    };

    debugPrint('[TreatmentPlan] Données envoyées: ${jsonEncode(reportData)}');

    // 4. Envoi au serveur Flask
    const serverUrl = 'http://localhost:5000/generate-treatment-plan';
    final response = await http
        .post(
          Uri.parse(serverUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(reportData),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      if (kIsWeb) {
        final blob = html.Blob([response.bodyBytes], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        html.Url.revokeObjectUrl(url);
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/treatment_plan.html');
        await file.writeAsBytes(response.bodyBytes);
        OpenFile.open(file.path);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rapport généré avec succès')),
      );
    } else {
      throw Exception(
          'Erreur serveur: ${response.statusCode}\n${response.body}');
    }
  } catch (e) {
    debugPrint('[TreatmentPlan] ERREUR: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Erreur lors de la génération: ${e.toString()}')),
    );
  } finally {
    // Fin du chargement
    setState(() {
      _isGeneratingReport = false;
    });
    Navigator.of(context).pop(); // Fermer le dialogue de chargement
  }
}
  Future<Map<String, dynamic>> _getUnifiedSolutions() async {
    // 1. Solutions par défaut depuis JSON
    final defaultSol = _getSolutionsData();

    // 2. Toutes les propositions utilisateur (sans filtre d'approbation)
    final userQuery = FirebaseFirestore.instance
        .collection('users_proposals')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('user_proposals')
        .where('className', isEqualTo: widget.className)
        .where('matiereName', isEqualTo: widget.matiereName)
        .where('baremeName', isEqualTo: widget.baremeName);

    if (widget.sousBaremeName != null) {
      userQuery.where('sousBaremeName', isEqualTo: widget.sousBaremeName);
    }

    final userProposals = await userQuery.get();

    // 3. Propositions globales (seulement approuvées)
    final globalQuery = FirebaseFirestore.instance
        .collection('users_proposals')
        .doc('global_proposals')
        .collection('approved_proposals')
        .where('status', isEqualTo: 'approved')
        .where('className', isEqualTo: widget.className)
        .where('matiereName', isEqualTo: widget.matiereName)
        .where('baremeName', isEqualTo: widget.baremeName);

    if (widget.sousBaremeName != null) {
      globalQuery.where('sousBaremeName', isEqualTo: widget.sousBaremeName);
    }

    final globalProposals = await globalQuery.get();

    // Préparation des listes
    final userSolutions = <String>[];
    final userProblems = <String>[];
    final globalSolutions = <String>[];
    final globalProblems = <String>[];

    // Ajout des propositions utilisateur (toutes)
    for (final doc in userProposals.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['solution'] != null && data['solution'].toString().isNotEmpty) {
        userSolutions.add(data['solution'].toString());
      }
      if (data['probleme'] != null && data['probleme'].toString().isNotEmpty) {
        userProblems.add(data['probleme'].toString());
      }
    }

    // Ajout des propositions globales (approuvées)
    for (final doc in globalProposals.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['solution'] != null && data['solution'].toString().isNotEmpty) {
        globalSolutions.add(data['solution'].toString());
      }
      if (data['probleme'] != null && data['probleme'].toString().isNotEmpty) {
        globalProblems.add(data['probleme'].toString());
      }
    }

    return {
      'defaultSolution': defaultSol['solution']?.toString() ?? '',
      'defaultProbleme': defaultSol['probleme']?.toString() ?? '',
      'userSolutions': userSolutions.where((s) => s.trim().isNotEmpty).toList(),
      'userProblems': userProblems.where((p) => p.trim().isNotEmpty).toList(),
      'globalSolutions':
          globalSolutions.where((s) => s.trim().isNotEmpty).toList(),
      'globalProblems':
          globalProblems.where((p) => p.trim().isNotEmpty).toList(),
    };
  }

  Future<List<Map<String, dynamic>>> _getUserProposals() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 1. Récupérer les propositions par défaut du JSON
      final defaultSolutions = _getSolutionsData();

      // 2. Récupérer les propositions personnelles approuvées
      final userApproved = await FirebaseFirestore.instance
          .collection('users_proposals')
          .doc(userId)
          .collection('user_proposals')
          .where('status', isEqualTo: 'approved')
          .get();

      // 3. Récupérer les propositions globales approuvées
      final globalApproved = await FirebaseFirestore.instance
          .collection('users_proposals')
          .doc('global_proposals')
          .collection('approved_proposals')
          .where('status', isEqualTo: 'approved')
          .get();

      // Préparer la liste finale
      final allProposals = <Map<String, dynamic>>[];

      // Ajouter les solutions par défaut en premier
      allProposals.add({
        'type': 'default',
        'solution': defaultSolutions['solution'],
        'probleme': defaultSolutions['probleme'],
        'className': widget.className,
        'matiereName': widget.matiereName,
        'baremeName': widget.baremeName,
        'sousBaremeName': widget.sousBaremeName ?? '',
        'groupName': 'all'
      });

      // Ajouter les propositions personnelles
      for (final doc in userApproved.docs) {
        final data = doc.data();
        allProposals.add({
          'type': 'user',
          ...data,
          'className': widget.className,
          'matiereName': widget.matiereName,
          'baremeName': widget.baremeName,
          'sousBaremeName': widget.sousBaremeName ?? '',
          'id': doc.id,
        });
      }

      // Ajouter les propositions globales
      for (final doc in globalApproved.docs) {
        final data = doc.data();
        allProposals.add({
          'type': 'global',
          ...data,
          'className': widget.className,
          'matiereName': widget.matiereName,
          'baremeName': widget.baremeName,
          'sousBaremeName': widget.sousBaremeName ?? '',
          'id': doc.id,
        });
      }

      return allProposals;
    } catch (e) {
      print('Error getting proposals: $e');
      return [];
    }
  }

// Méthode pour récupérer les données de solution
  Map<String, dynamic> _getSolutionsData() {
    var result = jsonData.firstWhere(
      (item) =>
          item['classe'].trim().toLowerCase() ==
              widget.className.trim().toLowerCase() &&
          item['matiere'].trim().toLowerCase() ==
              widget.matiereName.trim().toLowerCase() &&
          item['bareme'].trim().toLowerCase() ==
              (widget.sousBaremeName ?? widget.baremeName).trim().toLowerCase(),
      orElse: () => null,
    );

    return result != null
        ? {'solution': result['solution'], 'probleme': result['probleme']}
        : {'solution': '', 'probleme': ''};
  }

  /////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('خطة العلاج وأصل الخطأ'),
          centerTitle: true,
          actions: [
            IconButton(
            icon: Icon(Icons.print),
            onPressed: _isGeneratingReport ? null : generateAndOpenTreatmentPlan,
            tooltip: 'طباعة التقرير',
          ),
          ],
        ),
        body: Column(
          children: [
            PageHeader(
              profName: widget.profName,
              schoolName: widget.schoolName,
              className: widget.className,
              matiereName: widget.matiereName,
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    'خطة العلاج وأصل الخطأ',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                  ),
                  Text(
                    'في مادة ${widget.matiereName} في معيار ${widget.sousBaremeName ?? widget.baremeName}',
                    style: TextStyle(fontSize: 16),
                  ),
                  // Ajout de la notification fixe
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      //   border: Border.all(color: Colors.blue[100]),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'يمكنك إضافة مقترحاتك الشخصية للحلول وأصل المشكلة بالضغط على زر "عمل"',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildLegend(),
            Expanded(
              child: FutureBuilder<List<Map<String, String>>>(
                future: _getClassifiedStudents(
                    widget.selectedClass, widget.selectedBaremeId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('لا توجد بيانات'));
                  }

                  var students = snapshot.data!;
                  Map<String, List<Map<String, String>>> groupedStudents = {};

                  for (var student in students) {
                    String group = student['group'] ?? '';
                    if (!groupedStudents.containsKey(group)) {
                      groupedStudents[group] = [];
                    }
                    groupedStudents[group]!.add(student);
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(
                          label: Container(
                            alignment: Alignment.centerRight,
                            child: Text('اسم التلميذ'),
                          ),
                        ),
                        DataColumn(
                          label: Container(
                            alignment: Alignment.centerRight,
                            child: Text('العمل'),
                          ),
                        ),
                      ],
                      rows: groupedStudents.entries.map((groupEntry) {
                        String groupName = groupEntry.key;
                        List<Map<String, String>> groupStudents =
                            groupEntry.value;

                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                            Color rowColor;
                            switch (groupName) {
                              case 'مجموعة العلاج':
                                rowColor = Colors.red.withOpacity(0.7);
                                break;
                              case 'مجموعة الدعم':
                                rowColor = Colors.orange.withOpacity(0.7);
                                break;
                              case 'مجموعة التميز':
                                rowColor = Colors.green.withOpacity(0.7);
                                break;
                              default:
                                rowColor = Colors.transparent;
                            }
                            return rowColor;
                          }),
                          cells: [
                            DataCell(
                              Text(groupStudents
                                  .map((student) =>
                                      student['name'] ?? 'غير معروف')
                                  .join(", ")),
                            ),
                            DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  showSolutionAndProbleme(groupName);
                                },
                                child: Text('عمل لـ $groupName'),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('مجموعة العلاج', Colors.red.withOpacity(0.7)),
          SizedBox(width: 16),
          _buildLegendItem('مجموعة الدعم', Colors.orange.withOpacity(0.7)),
          SizedBox(width: 16),
          _buildLegendItem('مجموعة التميز', Colors.green.withOpacity(0.7)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        SizedBox(width: 8),
        Text(text, textDirection: TextDirection.rtl),
      ],
    );
  }

  Future<List<Map<String, String>>> _getClassifiedStudents(
      String classId, String baremeId) async {
    List<Map<String, String>> students = [];

    var studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
        .collection('user_classes')
        .doc(classId)
        .collection('students')
        .get();

    List<Future<void>> futures = [];

    for (var studentDoc in studentsSnapshot.docs) {
      var studentId = studentDoc.id;
      var studentName = studentDoc['name'] ?? 'غير معروف';

      futures.add(FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeId)
          .get()
          .then((baremeSnapshot) {
        if (baremeSnapshot.exists) {
          var baremeData = baremeSnapshot.data() as Map<String, dynamic>;
          var value = baremeData['Marks'] ?? '( - - - )';

          String group;
          if (value == '( + + + )') {
            group = 'مجموعة التميز';
          } else if (value == '( + + - )') {
            group = 'مجموعة الدعم';
          } else {
            group = 'مجموعة العلاج';
          }

          students.add({
            'name': studentName,
            'treatmentPlan': baremeData['treatmentPlan'] ?? '',
            'errorOrigin': baremeData['errorOrigin'] ?? '',
            'group': group,
          });
        }
      }));
    }

    await Future.wait(futures);
    return students;
  }
}
