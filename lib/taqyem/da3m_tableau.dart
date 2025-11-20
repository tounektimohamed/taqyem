import 'dart:async';
import 'dart:io';

import 'package:Taqyem/taqyem/header.dart';
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

  // Liste des matières considérées comme étrangères (doivent être en français)
  // Version robuste avec différentes variantes
  static final List<String> _foreignMatieres = [
    // Variantes françaises
    "Expression orale et récitation",
    "expression orale et récitation",
    "Expression Orale et Récitation",
    "Lecture",
    "lecture", 
    "Production écrite",
    "production écrite",
    "Production Écrite",
    "écriture",
    "Ecriture",
    "ecriture",
    "Dictée",
    "dictée",
    "dictee",
    "Langue",
    "langue",
    "لغة انقليزية",
    
    // Variantes pour correspondance flexible
    "expression",
    "oral",
    "récitation", 
    "production",
    "écrit",
    "écriture",
  ];

  // Détection robuste qui ignore la casse et les accents
  static bool isForeignMatiere(String matiereName) {
    if (matiereName.isEmpty) {
      print('❌ Matière vide - considérée comme non française');
      return false;
    }
    
    // Normaliser le texte
    String normalized = _normalizeText(matiereName);
    
    // Vérifier la correspondance exacte d'abord
    bool isExactMatch = _foreignMatieres.any((matiere) => 
        _normalizeText(matiere) == normalized);
    
    // Vérifier aussi la correspondance partielle
    bool isPartialMatch = _foreignMatieres.any((matiere) => 
        normalized.contains(_normalizeText(matiere)) || 
        _normalizeText(matiere).contains(normalized));
    
    bool isForeign = isExactMatch || isPartialMatch;
    
    // Logs détaillés pour le débogage
    print('');
    print('🔍 === DÉTECTION LANGUE DÉTAILLÉE ===');
    print('📝 Matière originale: "$matiereName"');
    print('🔄 Matière normalisée: "$normalized"');
    print('✅ Correspondance exacte: $isExactMatch');
    print('🔍 Correspondance partielle: $isPartialMatch');
    print('🎯 Résultat final: $isForeign');
    print('📋 Liste matières étrangères:');
    _foreignMatieres.forEach((matiere) {
      print('   - "$matiere" -> "${_normalizeText(matiere)}"');
    });
    print('=== FIN DÉTECTION ===');
    print('');
    
    return isForeign;
  }

  // Méthode de normalisation robuste
  static String _normalizeText(String text) {
    if (text.isEmpty) return '';
    
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'\s+'), ' ') // remplacer les espaces multiples
        .replaceAll(RegExp(r'[^\w\s]'), ''); // supprimer la ponctuation
  }

  // Traduire le nom d'une classe
  static String translateClass(String arabicName) {
    String translated = _classTranslations[arabicName] ?? arabicName;
    print('🏫 Traduction classe: "$arabicName" -> "$translated"');
    return translated;
  }

  // Traduire le nom d'une matière
  static String translateMatiere(String arabicName) {
    String translated = _matiereTranslations[arabicName] ?? arabicName;
    print('📚 Traduction matière: "$arabicName" -> "$translated"');
    return translated;
  }

  // Traduire un critère/barème
  static String translateBareme(String arabicName) {
    String translated = _baremeTranslations[arabicName] ?? arabicName;
    print('📊 Traduction barème: "$arabicName" -> "$translated"');
    return translated;
  }

  // Traduire un sous-critère
  static String translateSousBareme(String arabicName) {
    String translated = _baremeTranslations[arabicName] ?? arabicName;
    print('📈 Traduction sous-barème: "$arabicName" -> "$translated"');
    return translated;
  }

  // Obtenir le nom original arabe à partir de la traduction française
  static String getArabicClassFromFrench(String frenchName) {
    String arabic = _classTranslations.entries
        .firstWhere((entry) => entry.value == frenchName, 
                   orElse: () => MapEntry(frenchName, frenchName))
        .key;
    print('🔄 Classe français->arabe: "$frenchName" -> "$arabic"');
    return arabic;
  }

  static String getArabicMatiereFromFrench(String frenchName) {
    String arabic = _matiereTranslations.entries
        .firstWhere((entry) => entry.value == frenchName,
                   orElse: () => MapEntry(frenchName, frenchName))
        .key;
    print('🔄 Matière français->arabe: "$frenchName" -> "$arabic"');
    return arabic;
  }

  // Méthode utilitaire pour debug
  static void debugMatiere(String matiereName) {
    print('');
    print('🐛 === DEBUG MATIERE ===');
    print('Matière: "$matiereName"');
    print('Longueur: ${matiereName.length}');
    print('Code units: ${matiereName.codeUnits}');
    print('Est française: ${isForeignMatiere(matiereName)}');
    print('=== FIN DEBUG ===');
    print('');
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

class _ClassificationPageState extends State<ClassificationPage> {
  List<dynamic> jsonData = [];
  bool _isGeneratingReport = false;
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  bool _isFrenchInterface = false;

  @override
  void initState() {
    super.initState();
    _detectLanguage();
    loadJsonData();
  }

  void _detectLanguage() {
    print('=== DÉTECTION LANGUE ClassificationPage ===');
    print('Matière: ${widget.matiereName}');
    print('Est française: ${DataTranslator.isForeignMatiere(widget.matiereName)}');
    print('=== FIN DÉTECTION ===');
    
    setState(() {
      _isFrenchInterface = DataTranslator.isForeignMatiere(widget.matiereName);
    });
  }

  // Méthode de traduction
  String _getTranslatedText(String arabicText, String frenchText) {
    return _isFrenchInterface ? frenchText : arabicText;
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
                          _getTranslatedText(
                            'خطة العلاج وأصل الخطأ لـ $groupName',
                            'Plan de traitement et origine de l\'erreur pour $groupName'
                          ),
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
                                    _getTranslatedText('الحل:', 'Solution:'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                result != null ? result['solution'] : _getTranslatedText('لا يوجد حل متاح', 'Aucune solution disponible'),
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
                                    _getTranslatedText('المشكلة:', 'Problème:'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                result != null ? result['probleme'] : _getTranslatedText('لا يوجد مشكلة محددة', 'Aucun problème spécifié'),
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
                                _getTranslatedText('مقترحاتك:', 'Vos propositions:'),
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
                                            _getTranslatedText(
                                              'الحل المقترح: ${proposal['solution']}',
                                              'Solution proposée: ${proposal['solution']}'
                                            ),
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
                                            _getTranslatedText(
                                              'أصل المشكلة المقترح: ${proposal['probleme']}',
                                              'Origine du problème proposée: ${proposal['probleme']}'
                                            ),
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
                                          tooltip: _getTranslatedText('حذف المقترح', 'Supprimer la proposition'),
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
                              _getTranslatedText('أضف مقترحات جديدة:', 'Ajouter de nouvelles propositions:'),
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
                              _getTranslatedText('الحل المقترح', 'Solution proposée'),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: solutionController,
                              decoration: InputDecoration(
                                hintText: _getTranslatedText('أدخل اقتراحك للحل...', 'Entrez votre suggestion de solution...'),
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
                              _getTranslatedText('أصل المشكلة المقترح', 'Origine du problème proposée'),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: problemeController,
                              decoration: InputDecoration(
                                hintText: _getTranslatedText('أدخل اقتراحك لأصل المشكلة...', 'Entrez votre suggestion pour l\'origine du problème...'),
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
                        child: Text(_getTranslatedText('إغلاق', 'Fermer'), style: TextStyle(fontSize: 16)),
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
                                content: Text(_getTranslatedText('تم حفظ المقترحات بنجاح', 'Propositions enregistrées avec succès')),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_getTranslatedText('يرجى إدخال حل أو مشكلة على الأقل', 'Veuillez entrer au moins une solution ou un problème')),
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
                          _getTranslatedText('حفظ المقترحات الجديدة', 'Enregistrer les nouvelles propositions'),
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
                  _getTranslatedText("جاري إنشاء التقرير...", "Génération du rapport en cours..."),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  _getTranslatedText("يرجى الانتظار، هذه العملية قد تستغرق بضع لحظات", "Veuillez patienter, cette opération peut prendre quelques instants"),
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
        throw Exception(_getTranslatedText('لم يتم العثور على أي طالب في القسم', 'Aucun étudiant trouvé dans la classe'));
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
          'treatment': groupedStudents[_getTranslatedText('مجموعة العلاج', 'Groupe de traitement')]
                  ?.map((s) => s['name'])
                  .whereType<String>()
                  .toList() ??
              [],
          'support': groupedStudents[_getTranslatedText('مجموعة الدعم', 'Groupe de soutien')]
                  ?.map((s) => s['name'])
                  .whereType<String>()
                  .toList() ??
              [],
          'excellence': groupedStudents[_getTranslatedText('مجموعة التميز', 'Groupe d\'excellence')]
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
            body: json.jsonEncode(reportData),
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
            content: Text(_getTranslatedText('تم إنشاء التقرير بنجاح', 'Rapport généré avec succès')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
            _getTranslatedText('خطأ في الخادم:', 'Erreur serveur:') + ' ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      debugPrint('[TreatmentPlan] ERREUR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText('خطأ في الإنشاء:', 'Erreur lors de la création:') + ' ${e.toString()}'),
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

  // Méthode pour obtenir les noms de groupes selon la langue
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

  // Méthode pour obtenir les noms courts des groupes
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
      String translatedGroup = _getGroupName(group);
      if (!groupedStudents.containsKey(translatedGroup)) {
        groupedStudents[translatedGroup] = [];
      }
      groupedStudents[translatedGroup]!.add(student);
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
                    '$groupName (${students.length} ${_getTranslatedText('طالب', 'élève' + (students.length > 1 ? 's' : ''))})',
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
                  label: Text(_getTranslatedText('عمل', 'Traiter')),
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
                          _getTranslatedText('لا توجد طلاب في هذه المجموعة', 'Aucun élève dans ce groupe'),
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
                            student['name'] ?? _getTranslatedText('غير معروف', 'Inconnu'),
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
@override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isFrenchInterface ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getTranslatedText('خطة العلاج وأصل الخطأ', 'Plan de traitement et origine de l\'erreur'),
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
                tooltip: _getTranslatedText('طباعة التقرير', 'Imprimer le rapport'),
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
                      _getTranslatedText('جاري تحميل البيانات...', 'Chargement des données...'),
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
                  // En-tête CORRIGÉ avec traduction
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
                        // REMPLACER PageHeader par un en-tête personnalisé traduit
                        _buildTranslatedHeader(),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
                          child: Column(
                            children: [
                              Text(
                                _getTranslatedText('خطة العلاج وأصل الخطأ', 'Plan de traitement et origine de l\'erreur'),
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
                                  'En ${widget.matiereName} dans le critère ${widget.sousBaremeName ?? widget.baremeName}'
                                ),
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
                                        _getTranslatedText(
                                          'يمكنك إضافة مقترحاتك الشخصية للحلول وأصل المشكلة بالضغط على زر "عمل"',
                                          'Vous pouvez ajouter vos propositions personnelles pour les solutions et l\'origine du problème en cliquant sur le bouton "Traiter"'
                                        ),
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
                                  _getTranslatedText('جاري تحميل قائمة الطلاب...', 'Chargement de la liste des élèves...'),
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
                                  _getTranslatedText('حدث خطأ في تحميل البيانات', 'Erreur lors du chargement des données'),
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
                                  _getTranslatedText('لا توجد بيانات للعرض', 'Aucune donnée à afficher'),
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
                          String translatedGroup = _getGroupName(group);
                          if (!groupedStudents.containsKey(translatedGroup)) {
                            groupedStudents[translatedGroup] = [];
                          }
                          groupedStudents[translatedGroup]!.add(student);
                        }

                        // Définir les groupes dans l'ordre souhaité
                        final groups = [
                          {
                            'name': _getTranslatedText('مجموعة العلاج', 'Groupe de traitement'),
                            'color': Colors.red,
                            'icon': Icons.medical_services_outlined,
                            'students': groupedStudents[_getTranslatedText('مجموعة العلاج', 'Groupe de traitement')] ?? [],
                          },
                          {
                            'name': _getTranslatedText('مجموعة الدعم', 'Groupe de soutien'),
                            'color': Colors.orange,
                            'icon': Icons.support_outlined,
                            'students': groupedStudents[_getTranslatedText('مجموعة الدعم', 'Groupe de soutien')] ?? [],
                          },
                          {
                            'name': _getTranslatedText('مجموعة التميز', 'Groupe d\'excellence'),
                            'color': Colors.green,
                            'icon': Icons.emoji_events_outlined,
                            'students': groupedStudents[_getTranslatedText('مجموعة التميز', 'Groupe d\'excellence')] ?? [],
                          },
                        ];

                        return DefaultTabController(
                          length: groups.length,
                          child: Column(
                            children: [
                              // Barre d'onglets
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
                                    return Tab(
                                      child: Container(
                                        constraints: BoxConstraints(minWidth: 120),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              group['icon'] as IconData,
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                _getShortGroupName(group['name'] as String),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
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
                                                  fontSize: 10,
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
 Widget _buildTranslatedHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade800,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslatedText('المدرسة:', 'École:') + ' ${widget.schoolName}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getTranslatedText('الأستاذ:', 'Professeur:') + ' ${widget.profName}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getTranslatedText('القسم:', 'Classe:') + ' ${widget.className}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getTranslatedText('المادة:', 'Matière:') + ' ${widget.matiereName}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assessment, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                _getTranslatedText(
                  'معيار: ${widget.sousBaremeName ?? widget.baremeName}',
                  'Critère: ${widget.sousBaremeName ?? widget.baremeName}'
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
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
      var studentName = studentDoc['name'] ?? _getTranslatedText('غير معروف', 'Inconnu');

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
          content: Text(_getTranslatedText('تم حذف المقترح بنجاح', 'Proposition supprimée avec succès')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText('خطأ في حذف المقترح:', 'Erreur lors de la suppression:') + ' $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}