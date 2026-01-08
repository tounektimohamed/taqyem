import 'dart:async';
import 'dart:io';

import 'package:Taqyem/taqyem/header.dart';
import 'package:Taqyem/taqyem/pdf_generator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert' as json;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import 'dart:html' as html;

// Classe utilitaire pour la traduction et la détection de langue
class DataTranslator {
  static final Map<String, String> _classTranslations = {
    "السنة الأولى ابتدائي": "1ère année primaire",
    "السنة الأولى ابتدائي أ": "1ère année primaire A",
    "السنة الأولى ابتدائي ب": "1ère année primaire B",
    "السنة الأولى ابتدائي ج": "1ère année primaire C",
    "السنة الأولى ابتدائي د": "1ère année primaire D",
    "السنة الثانية ابتدائي": "2ème année primaire",
    "السنة الثانية ابتدائي أ": "2ème année primaire A",
    "السنة الثانية ابتدائي ب": "2ème année primaire B",
    "السنة الثانية ابتدائي ج": "2ème année primaire C",
    "السنة الثانية ابتدائي د": "2ème année primaire D",
    "السنة الثالثة ابتدائي": "3ème année primaire",
    "السنة الثالثة ابتدائي أ": "3ème année primaire A",
    "السنة الثالثة ابتدائي ب": "3ème année primaire B",
    "السنة الثالثة ابتدائي ج": "3ème année primaire C",
    "السنة الثالثة ابتدائي د": "3ème année primaire D",
    "السنة الرابعة ابتدائي": "4ème année primaire",
    "السنة الرابعة ابتدائي أ": "4ème année primaire A",
    "السنة الرابعة ابتدائي ب": "4ème année primaire B",
    "السنة الرابعة ابتدائي ج": "4ème année primaire C",
    "السنة الرابعة ابتدائي د": "4ème année primaire D",
    "السنة الخامسة ابتدائي": "5ème année primaire",
    "السنة الخامسة ابتدائي أ": "5ème année primaire A",
    "السنة الخامسة ابتدائي ب": "5ème année primaire B",
    "السنة الخامسة ابتدائي ج": "5ème année primaire C",
    "السنة الخامسة ابتدائي د": "5ème année primaire D",
    "السنة السادسة ابتدائي": "6ème année primaire",
    "السنة السادسة ابتدائي أ": "6ème année primaire A",
    "السنة السادسة ابتدائي ب": "6ème année primaire B",
    "السنة السادسة ابتدائي ج": "6ème année primaire C",
    "السنة السادسة ابتدائي د": "6ème année primaire D"
  };

  static final Map<String, String> _matiereTranslations = {
    "التواصل الشفوي": "Communication orale",
    "قراءة": "Lecture",
    "انتاج كتابي": "Production écrite",
    "رياضيات": "Mathématiques",
    "ايقاظ علمي": "Éveil scientifique",
    "تربية اسلامية": "Éducation islamique",
    "تربية تكنولوجية": "Éducation technologique",
    "تربية موسيقية": "Éducation musicale",
    "تربية تشكيلية": "Éducation artistique",
    "تربية بدنية": "Éducation physique",
    "قواعد لغة": "Grammaire",
    "Expression orale et récitation": "Expression orale et récitation",
    "Lecture": "Lecture",
    "Production écrite": "Production écrite",
    "écriture": "Écriture",
    "dictée": "Dictée",
    "langue": "Langue",
    "Langue": "Langue",
    "لغة انقليزية": "Anglais",
    "التاريخ": "Histoire",
    "الجغرافيا": "Géographie",
    "التربية المدنية": "Éducation civique"
  };
 static final Map<String, String> _baremeTranslations = {
    "مع 1": "C1",
    "مع 2": "C2",
    "مع 3": "C3",
    "مع 4": "C4",
    "مع 5": "C5",
    // Ajoutez ces nouvelles traductions pour les sous-barèmes avec lettres arabes
    "مع 1.ا": "C1.a",
    "مع 1.ب": "C1.b", 
    "مع 1.ج": "C1.c",
    "مع 2.ا": "C2.a",
    "مع 2.ب": "C2.b",
    "مع 2.ج": "C2.c",
    "مع 3.ا": "C3.a",
    "مع 3.ب": "C3.b",
    "مع 3.ج": "C3.c",
    "مع 4.ا": "C4.a",
    "مع 4.ب": "C4.b",
    "مع 4.ج": "C4.c",
    "مع 5.ا": "C5.a",
    "مع 5.ب": "C5.b",
    "مع 5.ج": "C5.c",
    
    // Gardez aussi les anciennes traductions numériques au cas où
    "مع 1.1": "C1.1",
    "مع 1.2": "C1.2",
    "مع 1.3": "C1.3",
    "مع 2.1": "C2.1",
    "مع 2.2": "C2.2",
    "مع 2.3": "C2.3",
    "مع 3.1": "C3.1",
    "مع 3.2": "C3.2",
    "مع 3.3": "C3.3",
    "مع 4.1": "C4.1",
    "مع 4.2": "C4.2",
    "مع 4.3": "C4.3",
    "مع 5.1": "C5.1",
    "مع 5.2": "C5.2",
    "مع 5.3": "C5.3"
  };
 
  static bool isForeignMatiere(String matiereName) {
    if (matiereName.isEmpty) return false;

    final foreignKeywords = [
      'expression',
      'oral',
      'récitation',
      'lecture',
      'production',
      'écrit',
      'écriture',
      'dictée',
      'langue',
      'anglais',
      'français',
      'لغة انقليزية'
    ];

    String normalized = matiereName.toLowerCase().trim();

    bool isForeign =
        foreignKeywords.any((keyword) => normalized.contains(keyword));

    print('🔍 Détection: "$matiereName" -> $isForeign');

    return isForeign;
  }

  static String _normalizeText(String text) {
    if (text.isEmpty) return '';
    return text.trim().toLowerCase();
  }

  static String translateClass(String arabicName) {
    return _classTranslations[arabicName] ?? arabicName;
  }

  static String translateMatiere(String arabicName) {
    return _matiereTranslations[arabicName] ?? arabicName;
  }

  static String translateBareme(String arabicName) {
    return _baremeTranslations[arabicName] ?? arabicName;
  }

  static String translateSousBareme(String arabicName) {
    return _baremeTranslations[arabicName] ?? arabicName;
  }

  static String getArabicClassFromFrench(String frenchName) {
    return _classTranslations.entries
        .firstWhere((entry) => entry.value == frenchName,
            orElse: () => MapEntry(frenchName, frenchName))
        .key;
  }

  static String getArabicMatiereFromFrench(String frenchName) {
    return _matiereTranslations.entries
        .firstWhere((entry) => entry.value == frenchName,
            orElse: () => MapEntry(frenchName, frenchName))
        .key;
  }
}

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

class SolutionSelection {
  final String text;
  final String type; // 'json', 'global', 'personal', 'new'
  final bool isProblem; // true pour problème, false pour solution
  bool isSelected;

  SolutionSelection({
    required this.text,
    required this.type,
    required this.isProblem,
    this.isSelected = false,
  });
}

class _ClassificationPageState extends State<ClassificationPage> {
  List<dynamic> jsonData = [];
  bool _isGeneratingReport = false;
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  bool _isFrenchInterface = false;
  Map<String, List<SolutionSelection>> _groupSelections = {
    'treatment': [],
    'support': [],
    'excellence': [],
  };
  
  // Variables pour la gestion du crédit d'impression
  int _remainingPrints = 5;
  bool _isAccountActive = false;
  bool _isMounted = true;
  Timer? _accountStatusTimer;

  @override
  void initState() {
    super.initState();
    _detectLanguage();
    loadJsonData();
    _loadPrintCredit();
    _startTimer();
  }

  @override
  void dispose() {
    _isMounted = false;
    _accountStatusTimer?.cancel();
    super.dispose();
  }

  // Méthodes pour la gestion du crédit d'impression
  Future<void> _loadPrintCredit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (_isMounted && userDoc.exists) {
        setState(() {
          _remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);
          _isAccountActive = _getFieldSafe(userDoc, 'isActive', false);
        });
      }
    } catch (e) {
      print('Erreur lors du chargement du crédit: $e');
    }
  }

  void _startTimer() {
    _accountStatusTimer?.cancel();
    _accountStatusTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isMounted) {
        _checkAccountStatus();
      } else {
        timer.cancel();
      }
    });
    _checkAccountStatus();
  }

  Future<void> _checkAccountStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_isMounted) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (_isMounted && userDoc.exists) {
        final isActive = _getFieldSafe(userDoc, 'isActive', false);

        setState(() {
          _isAccountActive = isActive;
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification du statut du compte: $e');
    }
  }

  // Méthode utilitaire pour obtenir les champs en sécurité
  dynamic _getFieldSafe(DocumentSnapshot doc, String field, dynamic defaultValue) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey(field)) {
        return defaultValue;
      }
      return data[field] ?? defaultValue;
    } catch (e) {
      print('Erreur lecture champ $field: $e');
      return defaultValue;
    }
  }

  // Condition de vérification du crédit (identique au code 1)
  Future<bool> _checkAndUpdatePrintCredit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final bool isActive = _getFieldSafe(userDoc, 'isActive', false);
      final int remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);

      print('Statut compte - Actif: $isActive, Credits: $remainingPrints');

      if (isActive) {
        print('Compte actif - Pas de déduction de crédit');
        return true;
      }

      if (remainingPrints > 0) {
        print('Crédits suffisants - Restant: $remainingPrints');
        return true;
      }

      print('Plus de crédits disponibles');
      return false;
    } catch (e) {
      print('Erreur lors de la vérification du crédit: $e');
      return false;
    }
  }

  // Méthode de déduction du crédit
  Future<void> _deductPrintCredit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final bool isActive = _getFieldSafe(userDoc, 'isActive', false);
      final int remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);

      // Ne déduire que si le compte est inactif et qu'il reste des crédits
      if (!isActive && remainingPrints > 0) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .update({'remainingPrints': FieldValue.increment(-1)});

        if (_isMounted) {
          setState(() {
            _remainingPrints = remainingPrints - 1;
          });
        }

        print('✅ Crédit déduit - Nouveau solde: ${remainingPrints - 1}');
      }
    } catch (e) {
      print('Erreur lors de la déduction du crédit: $e');
    }
  }

  void _detectLanguage() {
    bool isFrench = DataTranslator.isForeignMatiere(widget.matiereName);

    print('=== DÉTECTION LANGUE ClassificationPage ===');
    print('Matière: "${widget.matiereName}"');
    print('Est française: $isFrench');
    print('=== FIN DÉTECTION ===');

    setState(() {
      _isFrenchInterface = isFrench;
    });
  }

  String _getTranslatedText(String arabicText, String frenchText) {
    return _isFrenchInterface ? frenchText : arabicText;
  }

  String _getGroupName(String arabicName) {
    if (!_isFrenchInterface) return arabicName;

    switch (arabicName) {
      case 'مجموعة العلاج':
        return 'Groupe de traitement';
      case 'مجموعة الدعم':
        return 'Groupe de soutien';
      case 'مجموعة التميز':
        return 'Groupe d\'excellence';
      default:
        return arabicName;
    }
  }

  String _getShortGroupName(String fullName) {
    if (!_isFrenchInterface) {
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
    } else {
      switch (fullName) {
        case 'مجموعة العلاج':
        case 'Groupe de traitement':
          return 'Traitement';
        case 'مجموعة الدعم':
        case 'Groupe de soutien':
          return 'Soutien';
        case 'مجموعة التميز':
        case 'Groupe d\'excellence':
          return 'Excellence';
        default:
          return fullName;
      }
    }
  }

  Future<void> loadJsonData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/data.json');
      setState(() {
        jsonData = json.jsonDecode(jsonString);
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement du fichier JSON: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Méthode pour afficher le dialogue d'erreur de crédit
  void _showCreditErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.credit_card_off, color: Colors.orange),
            SizedBox(width: 10),
            Text(_getTranslatedText('انتهت الرصيد', 'Crédit Épuisé')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTranslatedText('لم يعد لديك رصيد طباعة متاح.',
                  'Vous n\'avez plus de crédits d\'impression disponibles.'),
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              _getTranslatedText('يرجى تفعيل حسابك للمواصلة في إنشاء التقارير.',
                  'Veuillez activer votre compte pour continuer à générer des rapports.'),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTranslatedText('الرصيد المتبقي: $_remainingPrints/5',
                          'Crédits restants: $_remainingPrints/5'),
                      style: TextStyle(fontSize: 14, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTranslatedText('لاحقاً', 'Plus tard')),
          ),
        ],
      ),
    );
  }

  // Méthode pour afficher le dialogue de chargement
  Widget _buildLoadingDialog({bool isPDF = false}) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    isPDF ? Colors.red : Colors.blue),
                strokeWidth: 3,
              ),
              Icon(
                isPDF ? Icons.picture_as_pdf : Icons.description,
                color: isPDF ? Colors.red : Colors.blue,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            isPDF
                ? _getTranslatedText(
                    "جاري إنشاء PDF...", "Génération du PDF en cours...")
                : _getTranslatedText("جاري إنشاء التقرير...",
                    "Génération du rapport en cours..."),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          Text(
            _getTranslatedText("يرجى الانتظار...", "Veuillez patienter..."),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 10),
          if (!_isAccountActive)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info, size: 16, color: Colors.orange),
                  SizedBox(width: 5),
                  Text(
                    _getTranslatedText(
                        'الرصيد المستخدم: ${_remainingPrints - 1}/5',
                        'Crédit utilisé: ${_remainingPrints - 1}/5'),
                    style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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

  Future<List<Map<String, dynamic>>> _getProposals() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    List<Map<String, dynamic>> allProposals = [];

    try {
      final userQuery = FirebaseFirestore.instance
          .collection('users_proposals')
          .doc(userId)
          .collection('user_proposals')
          .where('className', isEqualTo: widget.className)
          .where('matiereName', isEqualTo: widget.matiereName)
          .where('baremeName', isEqualTo: widget.baremeName);

      if (widget.sousBaremeName != null && widget.sousBaremeName!.isNotEmpty) {
        (userQuery as Query)
            .where('sousBaremeName', isEqualTo: widget.sousBaremeName);
      }

      final userSnapshot = await userQuery.get();

      for (var doc in userSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allProposals.add({
          'id': doc.id,
          ...data,
          'isUserProposal': true,
          'source': 'personal',
        });
      }

      Query globalQuery = FirebaseFirestore.instance
          .collection('users_proposals')
          .doc('global_proposals')
          .collection('approved_proposals')
          .where('status', isEqualTo: 'approved')
          .where('className', isEqualTo: widget.className)
          .where('matiereName', isEqualTo: widget.matiereName)
          .where('baremeName', isEqualTo: widget.baremeName);

      if (widget.sousBaremeName != null && widget.sousBaremeName!.isNotEmpty) {
        globalQuery = globalQuery.where('sousBaremeName',
            isEqualTo: widget.sousBaremeName);
      }

      final globalSnapshot = await globalQuery.get();

      for (var doc in globalSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allProposals.add({
          'id': doc.id,
          ...data,
          'isUserProposal': false,
          'source': 'global',
          'userName':
              data['userName'] ?? _getTranslatedText('مسؤول', 'Administrateur'),
        });
      }

      print('📋 Nombre total de propositions: ${allProposals.length}');
      print('📋 Personnelles: ${userSnapshot.docs.length}');
      print('📋 Globales: ${globalSnapshot.docs.length}');

      return allProposals;
    } catch (e) {
      print('❌ Erreur lors de la récupération des propositions: $e');
      return [];
    }
  }

  void showSolutionAndProbleme(String groupName, String groupKey) async {
    print('🔍 Chargement des propositions pour le groupe: $groupName ($groupKey)');
    
    final proposals = await _getProposals();
    
    List<SolutionSelection> currentSelections = _groupSelections[groupKey] ?? [];
    
    var jsonResult = jsonData.firstWhere(
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

    List<SolutionSelection> allSelections = [];

    if (jsonResult != null) {
      if (jsonResult['solution']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: jsonResult['solution'],
          type: 'json',
          isProblem: false,
          isSelected: currentSelections.any((s) => s.text == jsonResult['solution'] && s.type == 'json'),
        ));
      }
      if (jsonResult['probleme']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: jsonResult['probleme'],
          type: 'json',
          isProblem: true,
          isSelected: currentSelections.any((s) => s.text == jsonResult['probleme'] && s.type == 'json'),
        ));
      }
    }

    final globalProposals = proposals.where((p) => p['source'] == 'global').toList();
    for (var proposal in globalProposals) {
      if (proposal['solution']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: proposal['solution'],
          type: 'global',
          isProblem: false,
          isSelected: currentSelections.any((s) => s.text == proposal['solution'] && s.type == 'global'),
        ));
      }
      if (proposal['probleme']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: proposal['probleme'],
          type: 'global',
          isProblem: true,
          isSelected: currentSelections.any((s) => s.text == proposal['probleme'] && s.type == 'global'),
        ));
      }
    }

    final personalProposals = proposals.where((p) => p['source'] == 'personal').toList();
    for (var proposal in personalProposals) {
      if (proposal['solution']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: proposal['solution'],
          type: 'personal',
          isProblem: false,
          isSelected: currentSelections.any((s) => s.text == proposal['solution'] && s.type == 'personal'),
        ));
      }
      if (proposal['probleme']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: proposal['probleme'],
          type: 'personal',
          isProblem: true,
          isSelected: currentSelections.any((s) => s.text == proposal['probleme'] && s.type == 'personal'),
        ));
      }
    }

    TextEditingController solutionController = TextEditingController();
    TextEditingController problemeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                              _getTranslatedText(
                                'تحديد الحلول والمشاكل لـ $groupName',
                                'Sélection des solutions et problèmes pour $groupName'
                              ),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.select_all, color: Colors.blue.shade700),
                            onPressed: () {
                              bool allSelected = allSelections.every((s) => s.isSelected);
                              setState(() {
                                for (var selection in allSelections) {
                                  selection.isSelected = !allSelected;
                                }
                              });
                            },
                            tooltip: _getTranslatedText(
                              'تحديد/إلغاء الكل',
                              'Tout sélectionner/désélectionner'
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
                            Row(
                              children: [
                                Icon(Icons.checklist, color: Colors.blue.shade700, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  _getTranslatedText(
                                    'اختر ما يناسب هذا المجموعة:',
                                    'Sélectionnez ce qui convient à ce groupe:'
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${allSelections.where((s) => s.isSelected).length}/${allSelections.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            
                            ...allSelections.map((selection) {
                              Color color;
                              IconData icon;
                              String prefix;
                              
                              if (selection.type == 'json') {
                                color = Colors.orange;
                                icon = selection.isProblem 
                                    ? Icons.warning_amber_outlined 
                                    : Icons.lightbulb_outline;
                                prefix = _getTranslatedText('موصى به', 'Recommandé');
                              } else if (selection.type == 'global') {
                                color = Colors.green;
                                icon = selection.isProblem 
                                    ? Icons.analytics 
                                    : Icons.check_circle;
                                prefix = _getTranslatedText('معتمد', 'Approuvé');
                              } else {
                                color = Colors.blue;
                                icon = selection.isProblem 
                                    ? Icons.analytics_outlined 
                                    : Icons.check_circle_outline;
                                prefix = _getTranslatedText('شخصي', 'Personnel');
                              }
                              
                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: selection.isSelected ? color : Colors.grey.shade300,
                                    width: selection.isSelected ? 2 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selection.isSelected = !selection.isSelected;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: selection.isSelected,
                                          onChanged: (value) {
                                            setState(() {
                                              selection.isSelected = value!;
                                            });
                                          },
                                          activeColor: color,
                                          checkColor: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: color.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: color.withOpacity(0.3)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(icon, size: 12, color: color),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          '$prefix • ${selection.isProblem ? _getTranslatedText('مشكلة', 'Problème') : _getTranslatedText('حل', 'Solution')}',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: color,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                selection.text,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),

                            SizedBox(height: 24),
                            
                            Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: Colors.blue.shade700, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  _getTranslatedText('أضف مقترحات جديدة لهذا المجموعة:', 
                                      'Ajouter de nouvelles propositions pour ce groupe:'),
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
                                  _getTranslatedText('حل جديد:', 'Nouvelle solution:'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: solutionController,
                                  decoration: InputDecoration(
                                    hintText: _getTranslatedText('أدخل اقتراحك للحل...', 
                                        'Entrez votre suggestion de solution...'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade400),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.blue.shade600),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 16),
                            
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTranslatedText('مشكلة جديدة:', 'Nouveau problème:'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: problemeController,
                                  decoration: InputDecoration(
                                    hintText: _getTranslatedText('أدخل اقتراحك لأصل المشكلة...', 
                                        'Entrez votre suggestion pour l\'origine du problème...'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade400),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.blue.shade600),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  maxLines: 3,
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
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _groupSelections[groupKey] = allSelections.where((s) => s.isSelected).toList();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_getTranslatedText(
                                    'تم حفظ التحديدات لهذا المجموعة',
                                    'Sélections enregistrées pour ce groupe'
                                  )),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              
                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.save, size: 20),
                            label: Text(
                              _getTranslatedText('حفظ التحديدات', 'Enregistrer les sélections'),
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(width: 12),
                        
                        Expanded(
                          child: ElevatedButton.icon(
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
                                    content: Text(_getTranslatedText(
                                      'تم حفظ المقترحات بنجاح',
                                      'Propositions enregistrées avec succès'
                                    )),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                
                                Navigator.of(context).pop();
                                showSolutionAndProbleme(groupName, groupKey);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_getTranslatedText(
                                      'يرجى إدخال حل أو مشكلة على الأقل',
                                      'Veuillez entrer au moins une solution ou un problème'
                                    )),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.add, size: 20),
                            label: Text(
                              _getTranslatedText('حفظ الجديد', 'Sauvegarder nouveau'),
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
      },
    );
  }

  // Méthodes modifiées avec la condition d'impression
Future<void> _generateSingleGroupReport(String groupName, String groupKey) async {
  // Vérifier le crédit d'impression
  if (!await _checkAndUpdatePrintCredit()) {
    _showCreditErrorDialog();
    return;
  }

  setState(() {
    _isGeneratingReport = true;
  });

  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _buildLoadingDialog(isPDF: true),
    );

    final groupedStudents = await _getGroupedStudentsData();
    
    if (groupedStudents.isEmpty) {
      throw Exception(_getTranslatedText(
        'لم يتم العثور على أي تلميذ في القسم',
        'Aucun étudiant trouvé dans la classe'
      ));
    }

    // Préparer les données pour le PDF
    final Map<String, List<Map<String, dynamic>>> pdfGroupSelections = {
      groupKey: _groupSelections[groupKey]?.map((selection) {
        return {
          'text': selection.text,
          'source': selection.type,
          'isProblem': selection.isProblem,
          'isSelected': selection.isSelected,
        };
      }).toList() ?? [],
    };

    await PDFClassificationGenerator.generateAndDownloadClassificationReport(
      context: context,
      profName: widget.profName,
      matiereName: widget.matiereName,
      className: widget.className,
      schoolName: widget.schoolName,
      baremeName: widget.baremeName,
      sousBaremeName: widget.sousBaremeName ?? '',
      groupedStudents: groupedStudents,
      groupSelections: pdfGroupSelections,
      isFrenchInterface: _isFrenchInterface,
      isCompleteReport: false,
      singleGroupName: groupName,
      singleGroupKey: groupKey,
    );

    // Dédure le crédit
    await _deductPrintCredit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getTranslatedText(
          'تم إنشاء التقرير للمجموعة $groupName بنجاح',
          'Rapport pour le groupe $groupName généré avec succès'
        )),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    debugPrint('[SingleGroupReport] ERREUR: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getTranslatedText(
          'خطأ في الإنشاء:',
          'Erreur lors de la création:'
        ) + ' ${e.toString()}'),
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

Future<void> _generateCompleteReport() async {
  // Vérifier le crédit d'impression
  if (!await _checkAndUpdatePrintCredit()) {
    _showCreditErrorDialog();
    return;
  }

  bool allGroupsHaveSelections = _groupSelections['treatment']!.isNotEmpty ||
                               _groupSelections['support']!.isNotEmpty ||
                               _groupSelections['excellence']!.isNotEmpty;

  if (!allGroupsHaveSelections) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getTranslatedText(
          'يرجى تحديد حلول ومشاكل على الأقل لمجموعة واحدة',
          'Veuillez sélectionner des solutions et problèmes pour au moins un groupe'
        )),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() {
    _isGeneratingReport = true;
  });

  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _buildLoadingDialog(isPDF: true),
    );

    final groupedStudents = await _getGroupedStudentsData();

    if (groupedStudents.isEmpty) {
      throw Exception(_getTranslatedText(
        'لم يتم العثور على أي تلميذ في القسم',
        'Aucun étudiant trouvé dans la classe'
      ));
    }

    // Préparer les données pour le PDF
    final Map<String, List<Map<String, dynamic>>> pdfGroupSelections = {};
    
    for (final groupKey in ['treatment', 'support', 'excellence']) {
      pdfGroupSelections[groupKey] = _groupSelections[groupKey]?.map((selection) {
        return {
          'text': selection.text,
          'source': selection.type,
          'isProblem': selection.isProblem,
          'isSelected': selection.isSelected,
        };
      }).toList() ?? [];
    }

    await PDFClassificationGenerator.generateAndDownloadClassificationReport(
      context: context,
      profName: widget.profName,
      matiereName: widget.matiereName,
      className: widget.className,
      schoolName: widget.schoolName,
      baremeName: widget.baremeName,
      sousBaremeName: widget.sousBaremeName ?? '',
      groupedStudents: groupedStudents,
      groupSelections: pdfGroupSelections,
      isFrenchInterface: _isFrenchInterface,
      isCompleteReport: true,
    );

    // Dédure le crédit
    await _deductPrintCredit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getTranslatedText(
          'تم إنشاء التقرير الكامل بنجاح',
          'Rapport complet généré avec succès'
        )),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    debugPrint('[CompleteReport] ERREUR: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getTranslatedText(
          'خطأ في الإنشاء:',
          'Erreur lors de la création:'
        ) + ' ${e.toString()}'),
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

  Future<Map<String, dynamic>> _getUnifiedSolutions() async {
    final defaultSol = _getSolutionsData();

    Query userQuery = FirebaseFirestore.instance
        .collection('users_proposals')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('user_proposals')
        .where('className', isEqualTo: widget.className)
        .where('matieneName', isEqualTo: widget.matiereName)
        .where('baremeName', isEqualTo: widget.baremeName);

    if (widget.sousBaremeName != null && widget.sousBaremeName!.isNotEmpty) {
      userQuery =
          userQuery.where('sousBaremeName', isEqualTo: widget.sousBaremeName);
    }

    final userProposals = await userQuery.get();

    Query globalQuery = FirebaseFirestore.instance
        .collection('users_proposals')
        .doc('global_proposals')
        .collection('approved_proposals')
        .where('status', isEqualTo: 'approved')
        .where('className', isEqualTo: widget.className)
        .where('matieneName', isEqualTo: widget.matiereName)
        .where('baremeName', isEqualTo: widget.baremeName);

    if (widget.sousBaremeName != null && widget.sousBaremeName!.isNotEmpty) {
      globalQuery =
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

Future<Map<String, List<Map<String, dynamic>>>> _getGroupedStudentsData() async {
  var students = await _getClassifiedStudents(
      widget.selectedClass, widget.selectedBaremeId);
  
  Map<String, List<Map<String, dynamic>>> groupedStudents = {};

  for (var student in students) {
    String group = student['group'] ?? '';
    String translatedGroup = _getGroupName(group);
    
    if (!groupedStudents.containsKey(translatedGroup)) {
      groupedStudents[translatedGroup] = [];
    }
    
    groupedStudents[translatedGroup]!.add({
      'name': student['name'] ?? _getTranslatedText('غير معروف', 'Inconnu'),
      'treatmentPlan': student['treatmentPlan'] ?? '',
      'errorOrigin': student['errorOrigin'] ?? '',
      'group': translatedGroup,
    });
  }

  return groupedStudents;
}

  Widget _buildGroupTab(String groupName, Color color, IconData icon,
      List<Map<String, String>> students) {
    
    // Déterminer la clé du groupe
    String groupKey = '';
    if (groupName.contains(_getTranslatedText('العلاج', 'traitement'))) {
      groupKey = 'treatment';
    } else if (groupName.contains(
        _getTranslatedText('الدعم', 'soutien'))) {
      groupKey = 'support';
    } else {
      groupKey = 'excellence';
    }
    
    // Compter les sélections pour ce groupe
    int selectionCount = _groupSelections[groupKey]?.length ?? 0;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$groupName (${students.length} ${_getTranslatedText('تلميذ', students.length > 1 ? 'élèves' : 'élève')})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (selectionCount > 0)
                        Text(
                          '$selectionCount ${_getTranslatedText('عنصر', selectionCount > 1 ? 'éléments' : 'élément')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Bouton pour sélectionner les solutions/problèmes
                    ElevatedButton.icon(
                      onPressed: () {
                        showSolutionAndProbleme(groupName, groupKey);
                      },
                      icon: Icon(Icons.checklist, size: 20),
                      label: Text(_getTranslatedText('تحديد', 'Sélectionner')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Bouton pour imprimer ce groupe spécifique
                    ElevatedButton.icon(
                      onPressed: () {
                        _generateSingleGroupReport(groupName, groupKey);
                      },
                      icon: Icon(Icons.print, size: 18),
                      label: Text(_getTranslatedText('طباعة', 'Imprimer')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 64, color: color.withOpacity(0.3)),
                        SizedBox(height: 16),
                        Text(
                          _getTranslatedText('لا توجد طلاب في هذه المجموعة',
                              'Aucun élève dans ce groupe'),
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
                            student['name'] ??
                                _getTranslatedText('غير معروف', 'Inconnu'),
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
                                  '${_getTranslatedText('خطة العلاج:', 'Plan de traitement:')} ${student['treatmentPlan']}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              if (student['errorOrigin']?.isNotEmpty == true)
                                Text(
                                  '${_getTranslatedText('أصل الخطأ:', 'Origine de l\'erreur:')} ${student['errorOrigin']}',
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

  void _showPrintGroupSelection() async {
    final students = await _getClassifiedStudents(
        widget.selectedClass, widget.selectedBaremeId);

    Map<String, List<Map<String, String>>> groupedStudents = {};

    for (var student in students) {
      String group = student['group'] ?? '';
      String translatedGroup = _getGroupName(group);
      if (!groupedStudents.containsKey(translatedGroup)) {
        groupedStudents[translatedGroup] = [];
      }
      groupedStudents[translatedGroup]!.add(student);
    }

    final groups = [
      _getTranslatedText('مجموعة العلاج', 'Groupe de traitement'),
      _getTranslatedText('مجموعة الدعم', 'Groupe de soutien'),
      _getTranslatedText('مجموعة التميز', 'Groupe d\'excellence'),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Text(
                      _getTranslatedText('اختر مجموعة للطباعة',
                          'Choisissez un groupe pour l\'impression'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ...groups.map((groupName) {
                  final count = groupedStudents[groupName]?.length ?? 0;
                  final selectionCount = groupName.contains(
                              _getTranslatedText('العلاج', 'traitement'))
                          ? _groupSelections['treatment']?.length ?? 0
                          : groupName.contains(
                                  _getTranslatedText('الدعم', 'soutien'))
                              ? _groupSelections['support']?.length ?? 0
                              : _groupSelections['excellence']?.length ?? 0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          groupName.contains(_getTranslatedText('العلاج', 'traitement'))
                              ? Colors.red.shade100
                              : groupName.contains(
                                      _getTranslatedText('الدعم', 'soutien'))
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                      child: Icon(
                        groupName.contains(
                                _getTranslatedText('العلاج', 'traitement'))
                            ? Icons.medical_services
                            : groupName.contains(
                                    _getTranslatedText('الدعم', 'soutien'))
                                ? Icons.support
                                : Icons.emoji_events,
                        size: 20,
                        color: groupName.contains(
                                _getTranslatedText('العلاج', 'traitement'))
                            ? Colors.red
                            : groupName.contains(
                                    _getTranslatedText('الدعم', 'soutien'))
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                    title: Text(groupName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$count ${_getTranslatedText('تلميذ', count > 1 ? 'élèves' : 'élève')}'),
                        if (selectionCount > 0)
                          Text(
                            '$selectionCount ${_getTranslatedText('محدد', selectionCount > 1 ? 'sélectionnés' : 'sélectionné')}',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      String groupKey = '';
                      if (groupName.contains(_getTranslatedText('العلاج', 'traitement'))) {
                        groupKey = 'treatment';
                      } else if (groupName.contains(
                          _getTranslatedText('الدعم', 'soutien'))) {
                        groupKey = 'support';
                      } else {
                        groupKey = 'excellence';
                      }
                      
                      Navigator.of(context).pop();
                      _generateSingleGroupReport(groupName, groupKey);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
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
      var studentData = studentDoc.data() as Map<String, dynamic>;
      var studentName = studentData['name'] ?? _getTranslatedText('غير معروف', 'Inconnu');

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
            group = _getTranslatedText('مجموعة التميز', 'Groupe d\'excellence');
          } else if (value == '( + + - )') {
            group = _getTranslatedText('مجموعة الدعم', 'Groupe de soutien');
          } else {
            group = _getTranslatedText('مجموعة العلاج', 'Groupe de traitement');
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
          content: Text(_getTranslatedText(
              'تم حذف المقترح بنجاح', 'Proposition supprimée avec succès')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText(
                  'خطأ في حذف المقترح:', 'Erreur lors de la suppression:') +
              ' $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget _buildTranslatedHeader() {
  //   return Container(
  //     padding: EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topRight,
  //         end: Alignment.bottomLeft,
  //         colors: [
  //           Colors.blue.shade700,
  //           Colors.blue.shade800,
  //         ],
  //       ),
  //     ),
  //     child: Column(
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     _getTranslatedText('المدرسة:', 'École:') +
  //                         ' ${widget.schoolName}',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   SizedBox(height: 4),
  //                   Text(
  //                     _getTranslatedText('الأستاذ:', 'Professeur:') +
  //                         ' ${widget.profName}',
  //                     style: TextStyle(
  //                       color: Colors.white.withOpacity(0.9),
  //                       fontSize: 14,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             SizedBox(width: 16),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.end,
  //                 children: [
  //                   Text(
  //                     _getTranslatedText('القسم:', 'Classe:') +
  //                         ' ${widget.className}',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   SizedBox(height: 4),
  //                   Text(
  //                     _getTranslatedText('المادة:', 'Matière:') +
  //                         ' ${widget.matiereName}',
  //                     style: TextStyle(
  //                       color: Colors.white.withOpacity(0.9),
  //                       fontSize: 14,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 12),
  //         Container(
  //           height: 1,
  //           color: Colors.white.withOpacity(0.3),
  //         ),
  //         SizedBox(height: 8),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.assessment, color: Colors.white, size: 20),
  //             SizedBox(width: 8),
  //             Text(
  //               _getTranslatedText(
  //                   'معيار: ${widget.sousBaremeName ?? widget.baremeName}',
  //                   'Critère: ${widget.sousBaremeName ?? widget.baremeName}'),
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isFrenchInterface ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getTranslatedText('خطة العلاج وأصل الخطأ',
                'Plan de traitement et origine de l\'erreur'),
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
            // Afficher l'état du crédit d'impression
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _remainingPrints == 0
                    ? Colors.red
                    : _remainingPrints <= 2
                        ? Colors.orange
                        : Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '$_remainingPrints/5',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 8),
              child: PopupMenuButton<String>(
                icon: _isGeneratingReport
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.print_outlined),
                onSelected: (value) {
                  if (value == 'single') {
                    _showPrintGroupSelection();
                  } else if (value == 'complete') {
                    _generateCompleteReport();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'single',
                    child: Row(
                      children: [
                        Icon(Icons.group, color: Colors.blue.shade700),
                        SizedBox(width: 8),
                        Text(_getTranslatedText(
                            'تقرير مجموعة واحدة', 'Rapport groupe unique')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.description, color: Colors.green.shade700),
                        SizedBox(width: 8),
                        Text(_getTranslatedText('تقرير كامل', 'Rapport complet')),
                      ],
                    ),
                  ),
                ],
                tooltip:
                    _getTranslatedText('طباعة التقرير', 'Imprimer le rapport'),
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _getTranslatedText('جاري تحميل البيانات...',
                          'Chargement des données...'),
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
                     //   _buildTranslatedHeader(),
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 20),
                          child: Column(
                            children: [
                              Text(
                                _getTranslatedText('تصنيف الأخطاء',
                                    'Plan de traitement et origine de l\'erreur'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _getTranslatedText(
                                    'في مادة ${widget.matiereName} في معيار ${widget.sousBaremeName ?? widget.baremeName}',
                                    'En ${widget.matiereName} dans le critère ${widget.sousBaremeName ?? widget.baremeName}'),
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
                                  border:
                                      Border.all(color: Colors.blue.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        color: Colors.blue.shade700, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getTranslatedText(
                                                'حدد حلول ومشاكل لكل مجموعة ثم اختر نوع التقرير:',
                                                'Sélectionnez des solutions et problèmes pour chaque groupe puis choisissez le type de rapport:'),
                                            style: TextStyle(
                                              color: Colors.blue.shade800,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            _getTranslatedText(
                                                '• تقرير مجموعة واحدة: يطبع مجموعة محددة مع طلابها وحلولها',
                                                '• Rapport groupe unique: imprime un groupe spécifique avec ses élèves et solutions'),
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _getTranslatedText(
                                                '• تقرير كامل: يطبع جميع المجموعات مع طلابها وحلولها',
                                                '• Rapport complet: imprime tous les groupes avec leurs élèves et solutions'),
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 12,
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
                      ],
                    ),
                  ),

                  Expanded(
                    child: FutureBuilder<List<Map<String, String>>>(
                      future: _getClassifiedStudents(
                          widget.selectedClass, widget.selectedBaremeId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                                  _getTranslatedText(
                                      'جاري تحميل قائمة الطلاب...',
                                      'Chargement de la liste des élèves...'),
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
                                  _getTranslatedText(
                                      'حدث خطأ في تحميل البيانات',
                                      'Erreur lors du chargement des données'),
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
                                  _getTranslatedText('لا توجد بيانات للعرض',
                                      'Aucune donnée à afficher'),
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
                        Map<String, List<Map<String, String>>> groupedStudents =
                            {};

                        for (var student in students) {
                          String group = student['group'] ?? '';
                          String translatedGroup = _getGroupName(group);
                          if (!groupedStudents.containsKey(translatedGroup)) {
                            groupedStudents[translatedGroup] = [];
                          }
                          groupedStudents[translatedGroup]!.add(student);
                        }

                        final groups = [
                          {
                            'name': _getTranslatedText(
                                'مجموعة العلاج', 'Groupe de traitement'),
                            'color': Colors.red,
                            'icon': Icons.medical_services_outlined,
                            'students': groupedStudents[_getTranslatedText(
                                    'مجموعة العلاج', 'Groupe de traitement')] ??
                                [],
                          },
                          {
                            'name': _getTranslatedText(
                                'مجموعة الدعم', 'Groupe de soutien'),
                            'color': Colors.orange,
                            'icon': Icons.support_outlined,
                            'students': groupedStudents[_getTranslatedText(
                                    'مجموعة الدعم', 'Groupe de soutien')] ??
                                [],
                          },
                          {
                            'name': _getTranslatedText(
                                'مجموعة التميز', 'Groupe d\'excellence'),
                            'color': Colors.green,
                            'icon': Icons.emoji_events_outlined,
                            'students': groupedStudents[_getTranslatedText(
                                    'مجموعة التميز', 'Groupe d\'excellence')] ??
                                [],
                          },
                        ];

                        return DefaultTabController(
                          length: groups.length,
                          child: Column(
                            children: [
                              Container(
                                color: Colors.white,
                                child: TabBar(
                                  isScrollable: true,
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
                                    String groupKey = '';
                                    if (group['name'].toString().contains(
                                        _getTranslatedText('العلاج', 'traitement'))) {
                                      groupKey = 'treatment';
                                    } else if (group['name'].toString().contains(
                                        _getTranslatedText('الدعم', 'soutien'))) {
                                      groupKey = 'support';
                                    } else {
                                      groupKey = 'excellence';
                                    }
                                    
                                    int selectionCount = _groupSelections[groupKey]?.length ?? 0;
                                    
                                    return Tab(
                                      child: Container(
                                        constraints:
                                            BoxConstraints(minWidth: 120),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              group['icon'] as IconData,
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                _getShortGroupName(
                                                    group['name'] as String),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (group['color'] as Color)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${(group['students'] as List).length}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (selectionCount > 0)
                                                    Text(
                                                      '$selectionCount✓',
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              
                              Expanded(
                                child: TabBarView(
                                  children: groups.map((group) {
                                    return _buildGroupTab(
                                      group['name'] as String,
                                      group['color'] as Color,
                                      group['icon'] as IconData,
                                      group['students']
                                          as List<Map<String, String>>,
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
}