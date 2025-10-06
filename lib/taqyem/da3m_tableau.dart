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
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    loadJsonData();
  }

  Future<void> loadJsonData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/data.json');
      setState(() {
        jsonData = json.decode(jsonString);
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement du fichier JSON: $e");
      setState(() {
        _isLoading = false;
      });
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
      'isUserProposal': true,
    });

    batch.set(globalProposalRef, {
      'originalRef': proposalRef.path,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'isGlobalProposal': false,
    });

    await batch.commit();
  }

  void showSolutionAndProbleme(String groupName) async {
    final userProposals = await _getUserProposal();
    
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

    TextEditingController solutionController = TextEditingController();
    TextEditingController problemeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(20.0),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment, color: Colors.blue.shade700),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'خطة العلاج وأصل الخطأ لـ $groupName',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, color: Colors.orange.shade700, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'الحل:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                result != null ? result['solution'] : 'لا يوجد حل متاح',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_outlined, color: Colors.red.shade700, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'المشكلة:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                result != null ? result['probleme'] : 'لا يوجد مشكلة محددة',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        if (userProposals.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.history, color: Colors.blue.shade700, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'مقترحاتك:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          ...userProposals.map((proposal) => Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (proposal['solution']?.isNotEmpty == true) ...[
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.check_circle_outline,
                                            color: Colors.green.shade600, size: 16),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'الحل المقترح: ${proposal['solution']}',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                  ],
                                  if (proposal['probleme']?.isNotEmpty == true) ...[
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.analytics_outlined,
                                            color: Colors.blue.shade600, size: 16),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'أصل المشكلة المقترح: ${proposal['probleme']}',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                  ],
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (proposal['isUserProposal'] == true)
                                        IconButton(
                                          icon: Icon(Icons.delete_outline,
                                                    color: Colors.red.shade600, size: 20),
                                          onPressed: () {
                                            _deleteUserProposal(proposal['id']);
                                            Navigator.of(context).pop();
                                          },
                                          tooltip: 'حذف المقترح',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                          SizedBox(height: 16),
                        ],
                        
                        Row(
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.blue.shade700, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'أضف مقترحات جديدة:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الحل المقترح',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: solutionController,
                              decoration: InputDecoration(
                                hintText: 'أدخل اقتراحك للحل...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue.shade600),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                prefixIcon: Icon(Icons.lightbulb, color: Colors.grey.shade600),
                              ),
                              maxLines: 3,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أصل المشكلة المقترح',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: problemeController,
                              decoration: InputDecoration(
                                hintText: 'أدخل اقتراحك لأصل المشكلة...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue.shade600),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                prefixIcon: Icon(Icons.psychology, color: Colors.grey.shade600),
                              ),
                              maxLines: 3,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('إغلاق', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (solutionController.text.isNotEmpty ||
                              problemeController.text.isNotEmpty) {
                            await _saveUserProposal(
                              solutionController.text,
                              problemeController.text,
                              groupName,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم حفظ المقترحات بنجاح'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('يرجى إدخال حل أو مشكلة على الأقل'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'حفظ المقترحات الجديدة',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> generateAndOpenTreatmentPlan() async {
    setState(() {
      _isGeneratingReport = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                ),
                SizedBox(height: 20),
                Text(
                  "جاري إنشاء التقرير...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "يرجى الانتظار، هذه العملية قد تستغرق بضع لحظات",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final groupedStudents = await _getGroupedStudentsData();

      if (groupedStudents.isEmpty) {
        throw Exception('Aucun étudiant trouvé dans la classe');
      }

      final unifiedSolutions = await _getUnifiedSolutions();

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

      const serverUrl = 'https://print-maker.onrender.com/generate-treatment-plan';
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
          SnackBar(
            content: Text('تم إنشاء التقرير بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
            'Erreur serveur: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      debugPrint('[TreatmentPlan] ERREUR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الإنشاء: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
      Navigator.of(context).pop();
    }
  }

// Ajoutez cette méthode helper pour obtenir des noms courts
String _getShortGroupName(String fullName) {
  switch (fullName) {
    case 'مجموعة العلاج':
      return 'العلاج';
    case 'مجموعة الدعم':
      return 'الدعم';
    case 'مجموعة التميز':
      return 'التميز';
    default:
      return fullName;
  }
}
  Future<Map<String, dynamic>> _getUnifiedSolutions() async {
    final defaultSol = _getSolutionsData();

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

    final userSolutions = <String>[];
    final userProblems = <String>[];
    final globalSolutions = <String>[];
    final globalProblems = <String>[];

    for (final doc in userProposals.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['solution'] != null && data['solution'].toString().isNotEmpty) {
        userSolutions.add(data['solution'].toString());
      }
      if (data['probleme'] != null && data['probleme'].toString().isNotEmpty) {
        userProblems.add(data['probleme'].toString());
      }
    }

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

  Widget _buildGroupTab(String groupName, Color color, IconData icon, List<Map<String, String>> students) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header avec le bouton عمل
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$groupName (${students.length} طالب)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showSolutionAndProbleme(groupName);
                  },
                  icon: Icon(Icons.work_outline, size: 20),
                  label: Text('عمل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des étudiants avec défilement
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 64, color: color.withOpacity(0.3)),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد طلاب في هذه المجموعة',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              color: color,
                            ),
                          ),
                          title: Text(
                            student['name'] ?? 'غير معروف',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (student['treatmentPlan']?.isNotEmpty == true)
                                Text(
                                  'خطة العلاج: ${student['treatmentPlan']}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              if (student['errorOrigin']?.isNotEmpty == true)
                                Text(
                                  'أصل الخطأ: ${student['errorOrigin']}',
                                  style: TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: Icon(Icons.school, color: color),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'خطة العلاج وأصل الخطأ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            Container(
              margin: EdgeInsets.only(left: 8),
              child: IconButton(
                icon: _isGeneratingReport
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.print_outlined),
                onPressed: _isGeneratingReport ? null : generateAndOpenTreatmentPlan,
                tooltip: 'طباعة التقرير',
              ),
            ),
          ],
        ),

        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل البيانات...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // En-tête
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.blue.shade50,
                          Colors.white,
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      children: [
                        PageHeader(
                          profName: widget.profName,
                          schoolName: widget.schoolName,
                          className: widget.className,
                          matiereName: widget.matiereName,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
                          child: Column(
                            children: [
                              Text(
                                'خطة العلاج وأصل الخطأ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'في مادة ${widget.matiereName} في معيار ${widget.sousBaremeName ?? widget.baremeName}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        color: Colors.blue.shade700, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'يمكنك إضافة مقترحاتك الشخصية للحلول وأصل المشكلة بالضغط على زر "عمل"',
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenu principal avec onglets
                  Expanded(
                    child: FutureBuilder<List<Map<String, String>>>(
                      future: _getClassifiedStudents(
                          widget.selectedClass, widget.selectedBaremeId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue.shade700),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'جاري تحميل قائمة الطلاب...',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'حدث خطأ في تحميل البيانات',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off,
                                    color: Colors.grey, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'لا توجد بيانات للعرض',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
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

                        // Définir les groupes dans l'ordre souhaité
                        final groups = [
                          {
                            'name': 'مجموعة العلاج',
                            'color': Colors.red,
                            'icon': Icons.medical_services_outlined,
                            'students': groupedStudents['مجموعة العلاج'] ?? [],
                          },
                          {
                            'name': 'مجموعة الدعم',
                            'color': Colors.orange,
                            'icon': Icons.support_outlined,
                            'students': groupedStudents['مجموعة الدعم'] ?? [],
                          },
                          {
                            'name': 'مجموعة التميز',
                            'color': Colors.green,
                            'icon': Icons.emoji_events_outlined,
                            'students': groupedStudents['مجموعة التميز'] ?? [],
                          },
                        ];

                        return DefaultTabController(
                          length: groups.length,
                          child: Column(
                            children: [
                              // Barre d'onglets
                              Container(
                                color: Colors.white,
                                child: // Dans la méthode build, remplacez la partie TabBar par ceci :

// Barre d'onglets
Container(
  color: Colors.white,
  child: TabBar(
    isScrollable: true, // Ajout de cette ligne pour permettre le défilement horizontal
    labelColor: Colors.blue.shade800,
    unselectedLabelColor: Colors.grey.shade600,
    indicatorColor: Colors.blue.shade700,
    indicatorWeight: 3,
    labelStyle: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    ),
    unselectedLabelStyle: TextStyle(
      fontWeight: FontWeight.normal,
    ),
    tabs: groups.map((group) {
      return Tab(
        child: Container(
          constraints: BoxConstraints(minWidth: 120), // Largeur minimale pour chaque onglet
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Utiliser min pour éviter le débordement
            children: [
              Icon(
                group['icon'] as IconData,
                size: 18, // Réduire légèrement la taille de l'icône
              ),
              SizedBox(width: 6),
              Flexible( // Utiliser Flexible pour le texte
                child: Text(
                  _getShortGroupName(group['name'] as String), // Nom court
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12, // Réduire la taille de police
                  ),
                ),
              ),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (group['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(group['students'] as List).length}',
                  style: TextStyle(
                    fontSize: 10, // Réduire la taille de police du compteur
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  ),
),

                              ),
                              
                              // Contenu des onglets
                              Expanded(
                                child: TabBarView(
                                  children: groups.map((group) {
                                    return _buildGroupTab(
                                      group['name'] as String,
                                      group['color'] as Color,
                                      group['icon'] as IconData,
                                      group['students'] as List<Map<String, String>>,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
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

  Future<List<Map<String, dynamic>>> _getUserProposal() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final query = FirebaseFirestore.instance
          .collection('users_proposals')
          .doc(userId)
          .collection('user_proposals')
          .where('className', isEqualTo: widget.className)
          .where('matiereName', isEqualTo: widget.matiereName)
          .where('baremeName', isEqualTo: widget.baremeName);

      if (widget.sousBaremeName != null) {
        query.where('sousBaremeName', isEqualTo: widget.sousBaremeName);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'isUserProposal': true,
        };
      }).toList();
    } catch (e) {
      print('Error getting user proposals: $e');
      return [];
    }
  }

  Future<void> _deleteUserProposal(String proposalId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('users_proposals')
          .doc(userId)
          .collection('user_proposals')
          .doc(proposalId)
          .delete();

      await FirebaseFirestore.instance
          .collection('users_proposals')
          .doc('global_proposals')
          .collection('approved_proposals')
          .doc(proposalId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف المقترح بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حذف المقترح: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}