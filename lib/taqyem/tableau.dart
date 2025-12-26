import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:Taqyem/taqyem/payment/PaymentPage.dart';
import 'package:Taqyem/taqyem/pdf_report_generator.dart';
import 'package:Taqyem/taqyem/tableau_pdf.dart';
import 'package:Taqyem/taqyem/word_report_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:Taqyem/taqyem/da3m_tableau.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

// Classe utilitaire pour la traduction et la détection de langue
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

  // Ordre numérique des classes
  static int _getClassOrder(String className) {
    final Map<String, int> classOrder = {
      "السنة الأولى ابتدائي": 1,
      "السنة الأولى ابتدائي أ": 1,
      "السنة الأولى ابتدائي ب": 1,
      "السنة الأولى ابتدائي ج": 1,
      "السنة الأولى ابتدائي د": 1,
      "السنة الثانية ابتدائي": 2,
      "السنة الثانية ابتدائي أ": 2,
      "السنة الثانية ابتدائي ب": 2,
      "السنة الثانية ابتدائي ج": 2,
      "السنة الثانية ابتدائي د": 2,
      "السنة الثالثة ابتدائي": 3,
      "السنة الثالثة ابتدائي أ": 3,
      "السنة الثالثة ابتدائي ب": 3,
      "السنة الثالثة ابتدائي ج": 3,
      "السنة الثالثة ابتدائي د": 3,
      "السنة الرابعة ابتدائي": 4,
      "السنة الرابعة ابتدائي أ": 4,
      "السنة الرابعة ابتدائي ب": 4,
      "السنة الرابعة ابتدائي ج": 4,
      "السنة الرابعة ابتدائي د": 4,
      "السنة الخامسة ابتدائي": 5,
      "السنة الخامسة ابتدائي أ": 5,
      "السنة الخامسة ابتدائي ب": 5,
      "السنة الخامسة ابتدائي ج": 5,
      "السنة الخامسة ابتدائي د": 5,
      "السنة السادسة ابتدائي": 6,
      "السنة السادسة ابتدائي أ": 6,
      "السنة السادسة ابتدائي ب": 6,
      "السنة السادسة ابتدائي ج": 6,
      "السنة السادسة ابتدائي د": 6
    };

    return classOrder[className] ?? 999;
  }
// Méthode pour mapper les classes avec sections aux classes de base du JSON

  static List<String> sortClassesByNumericalOrder(List<String> classes) {
    return List<String>.from(classes)
      ..sort((a, b) {
        final orderA = _getClassOrder(a);
        final orderB = _getClassOrder(b);

        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }

        // Si même année, trier par section
        return _compareClassSections(a, b);
      });
  }

  static int _compareClassSections(String a, String b) {
    final sections = ['أ', 'ب', 'ج', 'د'];

    for (final section in sections) {
      if (a.contains(section) && !b.contains(section)) return -1;
      if (!a.contains(section) && b.contains(section)) return 1;
      if (a.contains(section) && b.contains(section)) {
        final indexA = sections.indexOf(section);
        final indexB = sections.indexOf(section);
        return indexA.compareTo(indexB);
      }
    }

    return a.compareTo(b);
  }

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
  static final List<String> _foreignMatieres = [
    "Expression orale et récitation",
    "Lecture",
    "Production écrite",
    "écriture",
    "dictée",
    "langue",
    "لغة انقليزية"
  ];

  // Détecter si une matière est étrangère
  static bool isForeignMatiere(String matiereName) {
    return _foreignMatieres.contains(matiereName);
  }

  // Traduire le nom d'une classe (uniquement pour l'affichage)
  static String translateClass(String arabicName) {
    return _classTranslations[arabicName] ?? arabicName;
  }

  // Traduire le nom d'une matière (uniquement pour l'affichage)
  static String translateMatiere(String arabicName) {
    return _matiereTranslations[arabicName] ?? arabicName;
  }

  // Traduire un critère/barème (uniquement pour l'affichage)
  static String translateBareme(String arabicName) {
    return _baremeTranslations[arabicName] ?? arabicName;
  }

  // Traduire un sous-critère (uniquement pour l'affichage)
  static String translateSousBareme(String arabicName) {
    return _baremeTranslations[arabicName] ?? arabicName;
  }

  // Obtenir le nom original arabe à partir de la traduction française (pour la recherche)
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
  String? selectedBaremeId;
  String? baremeName;
  String? sousBaremeName;
  String? selectedSousBaremeId;
  int _remainingPrints = 5;
  Map<String, int> sumCriteriaMaxPerBareme = {};
  int totalStudents = 0;
  Duration _remainingTime = Duration.zero;
  bool _isAccountActive = false;
  bool _isGeneratingReport = false;
  bool _isMounted = false;
  Timer? _accountStatusTimer;
  StreamSubscription? _userSubscription;
  bool _isFrenchInterface = false;
  String _matiereName = '';
  String _selectedTrimestre = 'الأول';
  String _selectedPeriode = '';
  String _selectedEvaluationType = 'تقييم';
  String _getDomaineForMatiere(String matiereName, bool isFrenchInterface) {
    // Définir les domaines en arabe
    final Map<String, String> domainesArabic = {
      'التواصل الشفوي': 'مجال اللغة العربية',
      'قراءة': 'مجال اللغة العربية',
      'قواعد لغة': 'مجال اللغة العربية',
      'انتاج كتابي': 'مجال اللغة العربية',
      'إنتاج كتابي': 'مجال اللغة العربية',
      'رياضيات': 'مجال العلوم والتكنولوجيا',
      'ايقاظ علمي': 'مجال العلوم والتكنولوجيا',
      'التربية التكنولوجية': 'مجال العلوم والتكنولوجيا',
      'تاريخ': 'مجال التنشئة',
      'التاريخ': 'مجال التنشئة',
      'الجغرافيا': 'مجال التنشئة',
      'التربية المدنية': 'مجال التنشئة',
      'التربية التشكيلية': 'مجال التنشئة',
      'التربية الموسيقية': 'مجال التنشئة',
      'تربية بدنية': 'مجال التنشئة',
      'تربية تشكيلية': 'مجال التنشئة',
      'تربية موسيقية': 'مجال التنشئة',
      'تربية تكنولوجية': 'مجال العلوم والتكنولوجيا',
      'تربية اسلامية': 'مجال التنشئة',
      'لغة فرنسية': 'مجال اللغة الفرنسية',
      'فرنسية': 'مجال اللغة الفرنسية',
      'لغة انقليزية': 'مجال اللغة الإنجليزية',
      'انجليزي': 'مجال اللغة الإنجليزية',
      'لغة إنجليزية': 'مجال اللغة الإنجليزية',
      'Expression orale et récitation': 'مجال اللغة العربية',
      'Lecture': 'مجال اللغة العربية',
      'Production écrite': 'مجال اللغة العربية',
      'écriture': 'مجال اللغة العربية',
      'dictée': 'مجال اللغة العربية',
      'langue': 'مجال اللغة العربية',
    };

    // Définir les domaines en français
    final Map<String, String> domainesFrench = {
      'Communication orale': 'Domaine Langue Arabe',
      'Lecture': 'Domaine Langue Arabe',
      'Grammaire': 'Domaine Langue Arabe',
      'Production écrite': 'Domaine Langue Arabe',
      'Écriture': 'Domaine Langue Arabe',
      'Dictée': 'Domaine Langue Arabe',
      'Mathématiques': 'Domaine Sciences et Technologie',
      'Éveil scientifique': 'Domaine Sciences et Technologie',
      'Éducation technologique': 'Domaine Sciences et Technologie',
      'Histoire': 'Domaine Socialisation',
      'Géographie': 'Domaine Socialisation',
      'Éducation civique': 'Domaine Socialisation',
      'Éducation artistique': 'Domaine Socialisation',
      'Éducation musicale': 'Domaine Socialisation',
      'Éducation physique': 'Domaine Socialisation',
      'Éducation islamique': 'Domaine Socialisation',
      'Français': 'Domaine Langue Française',
      'Langue française': 'Domaine Langue Française',
      'Anglais': 'Domaine Langue Anglaise',
      'Langue anglaise': 'Domaine Langue Anglaise',
      'Expression orale et récitation': 'Domaine Langue Arabe',
    };

    // Sélectionner la map appropriée selon la langue
    final domaines = isFrenchInterface ? domainesFrench : domainesArabic;

    // Chercher le domaine correspondant
    for (var key in domaines.keys) {
      if (matiereName.contains(key) || key.contains(matiereName)) {
        return domaines[key]!;
      }
    }

    // Retourner un domaine par défaut
    return isFrenchInterface ? 'Domaine Général' : 'المجال العام';
  }

// Nouvelle méthode pour le rapport complet

void _showCompleteReportDialog() {
  // Contrôleurs pour les champs
  TextEditingController periodeController =
      TextEditingController(text: _selectedPeriode);
  // NOUVEAU: Contrôleur pour la performance attendue
  TextEditingController performanceAttendueController = TextEditingController();

  // Options pour le trimestre
  final trimestreOptions = ['الأول', 'الثاني', 'الثالث'];
  final trimestreTranslations = {
    'الأول': 'Premier',
    'الثاني': 'Deuxième',
    'الثالث': 'Troisième'
  };

  // Options pour le type d'évaluation
  final evaluationOptions = ['تقييم', 'امتحان'];
  final evaluationTranslations = {'تقييم': 'Évaluation', 'امتحان': 'Examen'};

  // Variables pour stocker les noms de classe et matière
  String className = '';
  String matiereName = '';

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Charger les noms de classe et matière
          Future<void> loadClassAndMatiereNames() async {
            try {
              // Récupérer le nom de la classe
              var classDoc = await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.selectedClass)
                  .get();
              String arabicClassName = classDoc['name'] ?? 'غير معروف';
              className = _isFrenchInterface
                  ? DataTranslator.translateClass(arabicClassName)
                  : arabicClassName;

              // Récupérer le nom de la matière
              var matiereDoc = await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.selectedClass)
                  .collection('matieres')
                  .doc(widget.selectedMatiere)
                  .get();
              String arabicMatiereName = matiereDoc['name'] ?? 'غير معروف';
              matiereName = _isFrenchInterface
                  ? DataTranslator.translateMatiere(arabicMatiereName)
                  : arabicMatiereName;

              if (mounted) {
                setState(() {});
              }
            } catch (e) {
              print('Erreur chargement noms: $e');
              className = _isFrenchInterface ? 'Inconnu' : 'غير معروف';
              matiereName = _isFrenchInterface ? 'Inconnu' : 'غير معروف';
              if (mounted) {
                setState(() {});
              }
            }
          }

          // Charger les données au début
          WidgetsBinding.instance.addPostFrameCallback((_) {
            loadClassAndMatiereNames();
          });

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.book, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  _getTranslatedText('تقرير كامل', 'Rapport Complet'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Section 1: Sélection du trimestre et période
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                _getTranslatedText('الفترة والتقييم',
                                    'Période et Évaluation'),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          // الثلاثي
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTranslatedText(
                                      'الثلاثي:', 'Trimestre:'),
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500),
                                ),
                                SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedTrimestre,
                                  items: trimestreOptions
                                      .map((t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(
                                              _isFrenchInterface
                                                  ? trimestreTranslations[
                                                          t] ??
                                                      t
                                                  : t,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() {
                                        _selectedTrimestre = v;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  isExpanded: true,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),

                          // الوحدة / الفترة
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTranslatedText(
                                      'الوحدة / الفترة:', 'Unité / Période:'),
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: periodeController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: _getTranslatedText(
                                        'مثال: الوحدة 1', 'Ex: Unité 1'),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),

                          // نوع التقييم
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTranslatedText(
                                      'نوع التقييم:', 'Type d\'évaluation:'),
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500),
                                ),
                                SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedEvaluationType,
                                  items: evaluationOptions
                                      .map((t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(
                                              _isFrenchInterface
                                                  ? evaluationTranslations[
                                                          t] ??
                                                      t
                                                  : t,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() {
                                        _selectedEvaluationType = v;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  isExpanded: true,
                                ),
                              ],
                            ),
                          ),

                          // NOUVEAU: Champ pour la performance attendue
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTranslatedText('الأداء المنتظر',
                                      'Performance attendue:'),
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: performanceAttendueController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: _getTranslatedText(
                                        'أدخل الأداء المنتظر للتلاميذ...',
                                        'Entrez la performance attendue pour les élèves...'),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Section 2: Affichage de la classe (en lecture seule)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school,
                                  size: 20, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                _getTranslatedText(
                                    'القسم المحدد', 'Classe sélectionnée'),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.class_, color: Colors.green),
                                SizedBox(width: 12),
                                Expanded(
                                  child: className.isEmpty
                                      ? Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              _getTranslatedText(
                                                  'جاري التحميل...',
                                                  'Chargement...'),
                                              style: TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          className,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                ),
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              _getTranslatedText('(محدد تلقائياً من الصفحة الحالية)',
                                  '(Sélectionné automatiquement depuis la page actuelle)'),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[600],
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Section 3: Affichage de la matière (en lecture seule)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.book,
                                  size: 20, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                _getTranslatedText(
                                    'المادة المحددة', 'Matière sélectionnée'),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.menu_book, color: Colors.orange),
                                SizedBox(width: 12),
                                Expanded(
                                  child: matiereName.isEmpty
                                      ? Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.orange,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              _getTranslatedText(
                                                  'جاري التحميل...',
                                                  'Chargement...'),
                                              style: TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          matiereName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.orange[800],
                                          ),
                                        ),
                                ),
                                Icon(Icons.check_circle,
                                    color: Colors.orange, size: 20),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              _getTranslatedText('(محدد تلقائياً من الصفحة الحالية)',
                                  '(Sélectionné automatiquement depuis la page actuelle)'),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[600],
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Résumé de la sélection
                    SizedBox(height: 16),
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.summarize, color: Colors.purple),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTranslatedText('ملخص التقرير:',
                                      'Résumé du Rapport:'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${_getTranslatedText('الثلاثي', 'Trimestre')}: ${_isFrenchInterface ? trimestreTranslations[_selectedTrimestre] ?? _selectedTrimestre : _selectedTrimestre}',
                                  style:
                                      TextStyle(color: Colors.purple[800]),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${_getTranslatedText('الفترة', 'Période')}: ${periodeController.text.isNotEmpty ? periodeController.text : _getTranslatedText('غير محدد', 'Non spécifié')}',
                                  style:
                                      TextStyle(color: Colors.purple[800]),
                                ),
                                SizedBox(height: 2),
                                if (performanceAttendueController.text.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_getTranslatedText('الأداء المنتظر', 'Performance attendue')}:',
                                        style: TextStyle(
                                            color: Colors.purple[800],
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        performanceAttendueController.text,
                                        style: TextStyle(
                                            color: Colors.purple[800],
                                            fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                SizedBox(height: 2),
                                Text(
                                  '$className - $matiereName',
                                  style: TextStyle(
                                    color: Colors.purple[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Aperçu du contenu du rapport
                    if (className.isNotEmpty && matiereName.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.description, color: Colors.teal),
                                SizedBox(width: 8),
                                Text(
                                  _getTranslatedText('محتوى التقرير:',
                                      'Contenu du Rapport:'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            _buildReportContentItem(
                                '1. صفحة الغلاف', '1. Page de garde'),
                            _buildReportContentItem(
                                '2. جدول المعايير والباريمات',
                                '2. Tableau des critères et barèmes'),
                            _buildReportContentItem(
                                '3. الجدول الكامل للنتائج',
                                '3. Tableau complet des résultats'),
                            _buildReportContentItem('4. الإحصائيات والنسب',
                                '4. Statistiques et pourcentages'),
                            // NOUVEAU: Ajout de la performance attendue dans l'aperçu
                            if (performanceAttendueController.text.isNotEmpty)
                              _buildReportContentItem(
                                  '5. الأداء المنتظر', '5. Performance attendue'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_getTranslatedText('إلغاء', 'Annuler')),
              ),
              ElevatedButton(
                onPressed: className.isNotEmpty && matiereName.isNotEmpty
                    ? () {
                        setState(() {
                          _selectedPeriode = periodeController.text.trim();
                        });
                        Navigator.pop(context);
                        _generateCompleteReport(
                          widget.selectedClass,
                          widget.selectedMatiere,
                          className,
                          matiereName,
                          performanceAttendue: performanceAttendueController.text.trim(), // NOUVEAU: Passer la performance attendue
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: Text(_getTranslatedText(
                    'إنشاء التقرير', 'Générer le Rapport')),
              ),
            ],
          );
        },
      );
    },
  );
}

// Méthode pour générer le rapport complet

// Méthode pour générer le rapport complet

Future<void> _generateCompleteReport(
  String classId,
  String matiereId,
  String className,
  String matiereName, {
  String performanceAttendue = '', // NOUVEAU: paramètre optionnel
}) async {
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

    // 1. Récupérer les critères (barèmes) depuis le JSON
    final criteria = await _getCriteriaFromJson(
        classId, matiereId, className, matiereName);

    // 2. Récupérer les données COMPLÈTES comme dans le tableau normal
    final matiereDisplayName = _isFrenchInterface
        ? DataTranslator.translateMatiere(matiereName)
        : matiereName;
    final classDisplayName = _isFrenchInterface
        ? DataTranslator.translateClass(className)
        : className;

    // RÉCUPÉRER LES MÊMES DONNÉES QUE POUR L'IMPRESSION NORMALE
    final baremes = await _getBaremesForCompleteReport(classId, matiereId);
    final students = await _getStudentsForCompleteReport(classId, matiereId);

    // CALCULER LES STATISTIQUES CORRECTEMENT
    final Map<String, int> sumCriteriaMaxPerBareme = {};
    int totalStudents = students.length;

    // Initialiser les compteurs
    for (var bareme in baremes) {
      final baremeId = bareme['id'].toString();
      sumCriteriaMaxPerBareme[baremeId] = 0;
    }

    // Compter les étudiants qui ont atteint chaque critère
    for (var student in students) {
      final studentBaremes = student['baremes'] as Map<String, dynamic>;

      for (var bareme in baremes) {
        final baremeId = bareme['id'].toString();
        final mark = studentBaremes[baremeId]?.toString() ?? '( - - - )';

        if (mark == '( + + + )' || mark == '( + + - )') {
          sumCriteriaMaxPerBareme[baremeId] =
              (sumCriteriaMaxPerBareme[baremeId] ?? 0) + 1;
        }
      }
    }

    // DEBUG: Afficher les statistiques
    print('=== STATISTIQUES RAPPORT COMPLET ===');
    print('Total étudiants: $totalStudents');
    sumCriteriaMaxPerBareme.forEach((key, value) {
      if (totalStudents > 0) {
        final percentage = (value / totalStudents * 100).toStringAsFixed(2);
        print('$key: $value/$totalStudents = $percentage%');
      }
    });

    // 3. Générer le rapport HTML complet avec la performance attendue
    await HTMLReportGenerator.generateAndDownloadReport(
      profName: _profName,
      matiereName: matiereDisplayName,
      className: classDisplayName,
      schoolName: _schoolName,
      baremes: baremes,
      students: students,
      sumCriteriaMaxPerBareme: sumCriteriaMaxPerBareme,
      totalStudents: totalStudents,
      isFrenchInterface: _isFrenchInterface,
      downloadAsPDF: true,
      trimestre: _selectedTrimestre,
      periode: _selectedPeriode,
      evaluationType: _selectedEvaluationType,
      selectedClass: classId,
      criteria: criteria,
      performanceAttendue: performanceAttendue, // NOUVEAU: Ajouter le paramètre
    );

    // Dédure le crédit
    await _deductPrintCredit();

    _showSuccessSnackbar(_getTranslatedText('تم إنشاء التقرير الكامل بنجاح',
        'Rapport complet généré avec succès'));
  } catch (e) {
    _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء التقرير الكامل',
            'Erreur lors de la génération du rapport complet') +
        ': $e');
  } finally {
    setState(() {
      _isGeneratingReport = false;
    });
    Navigator.of(context).pop();
  }
}

// Méthode pour récupérer les barèmes POUR LE RAPPORT COMPLET
  Future<List<dynamic>> _getBaremesForCompleteReport(
      String classId, String matiereId) async {
    try {
      final baremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(matiereId)
          .get();

      final List<dynamic> baremes = [];
      for (final baremeDoc in baremesSnapshot.docs) {
        final baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
        final baremeName = _getFieldSafe(baremeDoc, 'baremeName', 'غير معروف');
        final isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

        final displayedBaremeName = _isFrenchInterface
            ? DataTranslator.translateBareme(baremeName)
            : baremeName;

        if (isBaremeSelected) {
          baremes.add({
            'id': baremeId,
            'value': displayedBaremeName,
            'originalValue': baremeName,
            'type': 'bareme',
            'parentBaremeId': null, // Barème principal
          });
        }

        final sousBaremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('selections')
            .doc(classId)
            .collection(matiereId)
            .doc(baremeId)
            .collection('sousBaremes')
            .get();

        for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
          final sousBaremeId = sousBaremeDoc.id;
          final sousBaremeName =
              _getFieldSafe(sousBaremeDoc, 'sousBaremeName', 'غير معروف');
          final isSousBaremeSelected =
              _getFieldSafe(sousBaremeDoc, 'selected', false);

          final displayedSousBaremeName = _isFrenchInterface
              ? DataTranslator.translateSousBareme(sousBaremeName)
              : sousBaremeName;

          if (isSousBaremeSelected) {
            baremes.add({
              'id': sousBaremeId,
              'value': displayedSousBaremeName,
              'originalValue': sousBaremeName,
              'type': 'sousBareme',
              'parentBaremeId': baremeId,
            });
          }
        }
      }

      return baremes;
    } catch (e) {
      print('Erreur récupération barèmes rapport complet: $e');
      return [];
    }
  }

// Méthode pour récupérer les étudiants POUR LE RAPPORT COMPLET
  Future<List<dynamic>> _getStudentsForCompleteReport(
      String classId, String matiereId) async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .get();

      final List<dynamic> students = [];
      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentName = _getFieldSafe(studentDoc, 'name',
            _isFrenchInterface ? 'Élève inconnu' : 'تلميذ غير معروف');

        final baremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .get();

        final Map<String, String> baremes = {};
        for (final baremeDoc in baremesSnapshot.docs) {
          final baremeId = baremeDoc.id;
          final marks = _getFieldSafe(baremeDoc, 'Marks', '( - - - )');
          baremes[baremeId] = marks;

          // Ajouter les sous-barèmes avec leur clé complète
          final sousBaremesSnapshot =
              await baremeDoc.reference.collection('sous_baremes').get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousMarks =
                _getFieldSafe(sousBaremeDoc, 'Marks', '( - - - )');
            // IMPORTANT: Créer la clé au format "baremeId-sousBaremeId"
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
      print('Erreur récupération étudiants rapport complet: $e');
      return [];
    }
  }

// Méthodes auxiliaires pour récupérer les données
  Future<Map<String, dynamic>> _getStudentsForReport(
      String classId, String matiereId) async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .get();

      final List<dynamic> students = [];
      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentName = _getFieldSafe(studentDoc, 'name',
            _isFrenchInterface ? 'Élève inconnu' : 'تلميذ غير معروف');

        final baremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .get();

        final Map<String, String> baremes = {};
        for (final baremeDoc in baremesSnapshot.docs) {
          final baremeId = baremeDoc.id;
          final marks = _getFieldSafe(baremeDoc, 'Marks', '( - - - )');
          baremes[baremeId] = marks;

          final sousBaremesSnapshot =
              await baremeDoc.reference.collection('sous_baremes').get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousMarks =
                _getFieldSafe(sousBaremeDoc, 'Marks', '( - - - )');
            baremes['$baremeId-$sousBaremeId'] = sousMarks;
          }
        }

        students.add({
          'id': studentId,
          'name': studentName,
          'baremes': baremes,
        });
      }

      return {'students': students};
    } catch (e) {
      print('Erreur récupération étudiants: $e');
      return {'students': []};
    }
  }

  Future<Map<String, dynamic>> _getBaremesForReport(
      String classId, String matiereId) async {
    try {
      final baremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(matiereId)
          .get();

      final List<dynamic> baremes = [];
      for (final baremeDoc in baremesSnapshot.docs) {
        final baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
        final baremeName = _getFieldSafe(baremeDoc, 'baremeName', 'غير معروف');
        final isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

        final displayedBaremeName = _isFrenchInterface
            ? DataTranslator.translateBareme(baremeName)
            : baremeName;

        if (isBaremeSelected) {
          baremes.add({
            'id': baremeId,
            'value': displayedBaremeName,
            'originalValue': baremeName,
            'type': 'bareme',
          });
        }

        final sousBaremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('selections')
            .doc(classId)
            .collection(matiereId)
            .doc(baremeId)
            .collection('sousBaremes')
            .get();

        for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
          final sousBaremeId = sousBaremeDoc.id;
          final sousBaremeName =
              _getFieldSafe(sousBaremeDoc, 'sousBaremeName', 'غير معروف');
          final isSousBaremeSelected =
              _getFieldSafe(sousBaremeDoc, 'selected', false);

          final displayedSousBaremeName = _isFrenchInterface
              ? DataTranslator.translateSousBareme(sousBaremeName)
              : sousBaremeName;

          if (isSousBaremeSelected) {
            baremes.add({
              'id': sousBaremeId,
              'value': displayedSousBaremeName,
              'originalValue': sousBaremeName,
              'type': 'sousBareme',
              'parentBaremeId': baremeId,
            });
          }
        }
      }

      return {'baremes': baremes};
    } catch (e) {
      print('Erreur récupération barèmes: $e');
      return {'baremes': []};
    }
  }

  Future<Map<String, dynamic>> _getSummaryForReport(
      String classId, String matiereId) async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .get();

      final totalStudents = studentsSnapshot.docs.length;
      final Map<String, int> sumCriteriaMaxPerBareme = {};

      // Logique pour calculer les statistiques (similaire à fetchMarks)
      // ... (vous pouvez adapter la logique de fetchMarks ici)

      return {
        'totalStudents': totalStudents,
        'sumCriteriaMaxPerBareme': sumCriteriaMaxPerBareme,
      };
    } catch (e) {
      print('Erreur récupération résumé: $e');
      return {
        'totalStudents': 0,
        'sumCriteriaMaxPerBareme': {},
      };
    }
  }

// Widget pour afficher un élément du contenu du rapport
  Widget _buildReportContentItem(String arabicText, String frenchText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.teal),
          SizedBox(width: 8),
          Text(
            _isFrenchInterface ? frenchText : arabicText,
            style: TextStyle(color: Colors.teal[800]),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadUserData();
    fetchMarks();
    _startTimer();
    _setupUserListener();
    _detectLanguage();
  }

  void _showClassAndMatiereSelectionDialog() {
    // Contrôleurs pour les champs de recherche
    TextEditingController classSearchController = TextEditingController();
    TextEditingController matiereSearchController = TextEditingController();

    // États pour les listes filtrées
    List<Map<String, dynamic>> filteredClasses = [];
    List<Map<String, dynamic>> filteredMatieres = [];

    // États pour les sélections
    Map<String, dynamic>? selectedClass;
    Map<String, dynamic>? selectedMatiere;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Charger les classes depuis Firestore
            Future<void> loadClasses() async {
              try {
                final classesSnapshot = await FirebaseFirestore.instance
                    .collection('classes')
                    .get();

                List<Map<String, dynamic>> classes = [];
                for (var classDoc in classesSnapshot.docs) {
                  classes.add({
                    'id': classDoc.id,
                    'name': classDoc['name'] ?? 'غير معروف',
                    'frenchName': DataTranslator.translateClass(
                        classDoc['name'] ?? 'غير معروف'),
                    'order': _getClassOrder(classDoc['name'] ?? 'غير معروف'),
                  });
                }

                // Trier par ordre numérique
                classes.sort((a, b) {
                  final orderA = a['order'] as int;
                  final orderB = b['order'] as int;
                  return orderA.compareTo(orderB);
                });

                setState(() {
                  filteredClasses = classes;
                });
              } catch (e) {
                print('Erreur chargement classes: $e');
              }
            }

            // Charger les matières pour une classe
            Future<void> loadMatieres(String classId) async {
              try {
                final matieresSnapshot = await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('matieres')
                    .get();

                List<Map<String, dynamic>> matieres = [];
                for (var matiereDoc in matieresSnapshot.docs) {
                  matieres.add({
                    'id': matiereDoc.id,
                    'name': matiereDoc['name'] ?? 'غير معروف',
                    'frenchName': DataTranslator.translateMatiere(
                        matiereDoc['name'] ?? 'غير معروف'),
                  });
                }

                setState(() {
                  filteredMatieres = matieres;
                });
              } catch (e) {
                print('Erreur chargement matières: $e');
              }
            }

            // Initialisation
            if (filteredClasses.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                loadClasses();
              });
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.table_chart, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    _getTranslatedText(
                        'طباعة جدول المعايير', 'Imprimer tableau des critères'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    // Recherche de classe
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTranslatedText(
                                'اختر القسم:', 'Sélectionnez la classe:'),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: classSearchController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: _getTranslatedText(
                                  'بحث عن قسم...', 'Rechercher une classe...'),
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onChanged: (value) {
                              setState(() {
                                // Filtrer les classes selon la recherche
                                // Cette fonctionnalité nécessiterait une liste complète des classes
                              });
                            },
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: filteredClasses.isEmpty
                                ? Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ListView.builder(
                                    itemCount: filteredClasses.length,
                                    itemBuilder: (context, index) {
                                      final classe = filteredClasses[index];
                                      return ListTile(
                                        leading: Icon(Icons.class_,
                                            color: selectedClass?['id'] ==
                                                    classe['id']
                                                ? Colors.blue
                                                : Colors.grey),
                                        title: Text(
                                          _isFrenchInterface
                                              ? classe['frenchName']
                                              : classe['name'],
                                        ),
                                        trailing:
                                            selectedClass?['id'] == classe['id']
                                                ? Icon(Icons.check,
                                                    color: Colors.green)
                                                : null,
                                        onTap: () {
                                          setState(() {
                                            selectedClass = classe;
                                            selectedMatiere = null;
                                            filteredMatieres.clear();
                                            loadMatieres(classe['id']);
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Recherche de matière
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTranslatedText(
                                'اختر المادة:', 'Sélectionnez la matière:'),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: matiereSearchController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: _getTranslatedText('بحث عن مادة...',
                                  'Rechercher une matière...'),
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              enabled: selectedClass != null,
                            ),
                            enabled: selectedClass != null,
                            onChanged: (value) {
                              setState(() {
                                // Filtrer les matières selon la recherche
                              });
                            },
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: selectedClass == null
                                ? Center(
                                    child: Text(
                                      _getTranslatedText('اختر قسمًا أولاً',
                                          'Sélectionnez d\'abord une classe'),
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : filteredMatieres.isEmpty
                                    ? Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : ListView.builder(
                                        itemCount: filteredMatieres.length,
                                        itemBuilder: (context, index) {
                                          final matiere =
                                              filteredMatieres[index];
                                          return ListTile(
                                            leading: Icon(Icons.book,
                                                color: selectedMatiere?['id'] ==
                                                        matiere['id']
                                                    ? Colors.blue
                                                    : Colors.grey),
                                            title: Text(
                                              _isFrenchInterface
                                                  ? matiere['frenchName']
                                                  : matiere['name'],
                                            ),
                                            trailing: selectedMatiere?['id'] ==
                                                    matiere['id']
                                                ? Icon(Icons.check,
                                                    color: Colors.green)
                                                : null,
                                            onTap: () {
                                              setState(() {
                                                selectedMatiere = matiere;
                                              });
                                            },
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),

                    // Résumé de la sélection
                    if (selectedClass != null && selectedMatiere != null)
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTranslatedText(
                                        'تم الاختيار:', 'Sélection:'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  Text(
                                    '${_isFrenchInterface ? selectedClass!['frenchName'] : selectedClass!['name']} - '
                                    '${_isFrenchInterface ? selectedMatiere!['frenchName'] : selectedMatiere!['name']}',
                                    style: TextStyle(color: Colors.green[800]),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_getTranslatedText('إلغاء', 'Annuler')),
                ),
                ElevatedButton(
                  onPressed: selectedClass != null && selectedMatiere != null
                      ? () {
                          Navigator.pop(context);
                          _generateBaremesTableReport(
                            selectedClass!['id'],
                            selectedMatiere!['id'],
                            selectedClass!['name'],
                            selectedMatiere!['name'],
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(_getTranslatedText(
                      'طباعة الجدول', 'Imprimer le tableau')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _getClassOrder(String className) {
    if (className.contains('الأولى')) return 1;
    if (className.contains('الثانية')) return 2;
    if (className.contains('الثالثة')) return 3;
    if (className.contains('الرابعة')) return 4;
    if (className.contains('الخامسة')) return 5;
    if (className.contains('السادسة')) return 6;
    return 999;
  }

// Nouvelle méthode pour générer le rapport de barèmes
  Future<void> _generateBaremesTableReport(
    String classId,
    String matiereId,
    String className,
    String matiereName,
  ) async {
    // Normaliser le nom de la classe
    final normalizedClassName = _mapClassToJsonBase(className);

    // Récupérer les critères depuis le JSON avec la classe normalisée
    final criteria = await _getCriteriaFromJson(
        classId, matiereId, normalizedClassName, matiereName);

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

      // Récupérer les critères depuis le code 3
      final criteria = await _getCriteriaFromJson(
          classId, matiereId, className, matiereName);

      // Générer le rapport HTML
      await HTMLReportGenerator.generateAndDownloadReport(
        profName: _profName,
        matiereName: matiereName,
        className: className,
        schoolName: _schoolName,
        baremes: [], // Vide car on affiche seulement les critères
        students: [], // Vide
        sumCriteriaMaxPerBareme: {},
        totalStudents: 0,
        isFrenchInterface: _isFrenchInterface,
        downloadAsPDF: true,
        trimestre: _selectedTrimestre,
        periode: _selectedPeriode,
        evaluationType: _selectedEvaluationType,
        selectedClass: classId,
        criteria: criteria, // Nouveau paramètre pour les critères
      );

      // Dédure le crédit
      await _deductPrintCredit();

      _showSuccessSnackbar(_getTranslatedText('تم إنشاء جدول المعايير بنجاح',
          'Tableau des critères généré avec succès'));
    } catch (e) {
      _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء جدول المعايير',
              'Erreur lors de la génération du tableau des critères') +
          ': $e');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
      Navigator.of(context).pop();
    }
  }

// Méthode pour récupérer les critères depuis le JSON
// Méthode pour normaliser le nom de classe

// Méthode pour mapper les classes avec sections aux classes de base du JSON
  String _mapClassToJsonBase(String classNameWithSection) {
    // Dictionnaire de mapping complet
    final Map<String, String> classMapping = {
      // Première année
      'السنة الأولى ابتدائي': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي أ': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي ب': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي ج': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي د': 'السنة الأولى ابتدائي',

      // Deuxième année
      'السنة الثانية ابتدائي': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي أ': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي ب': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي ج': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي د': 'السنة الثانية ابتدائي',

      // Troisième année
      'السنة الثالثة ابتدائي': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي أ': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي ب': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي ج': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي د': 'السنة الثالثة ابتدائي',

      // Quatrième année
      'السنة الرابعة ابتدائي': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي أ': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي ب': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي ج': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي د': 'السنة الرابعة ابتدائي',

      // Cinquième année
      'السنة الخامسة ابتدائي': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي أ': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي ب': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي ج': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي د': 'السنة الخامسة ابتدائي',

      // Sixième année
      'السنة السادسة ابتدائي': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي أ': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي ب': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي ج': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي د': 'السنة السادسة ابتدائي',
    };

    // Retourner la classe de base ou la classe originale si non trouvée
    return classMapping[classNameWithSection] ?? classNameWithSection;
  }

// Utilisez cette méthode dans _getCriteriaFromJson

  Future<List<Map<String, dynamic>>> _getCriteriaFromJson(
    String classId,
    String matiereId,
    String className,
    String matiereName,
  ) async {
    try {
      print('🎯 ===== DEBUT RECHERCHE CRITERES JSON =====');
      print('📌 Paramètres d\'entrée:');
      print('   • Classe originale: "$className"');
      print('   • Matière: "$matiereName"');

      // 1. Mapper la classe avec section vers la classe de base du JSON
      final String jsonClassName = _mapClassToJsonBase(className);
      print('🔄 Classe mappée pour JSON: "$jsonClassName"');

      // 2. Charger le JSON
      final jsonString =
          await rootBundle.loadString('assets/evaluation_excel.json');
      final jsonData = json.decode(jsonString);

      // 3. Vérifier la structure
      if (!jsonData.containsKey('classes')) {
        print('❌ ERREUR: Clé "classes" non trouvée dans JSON');
        return [];
      }

      final classes = jsonData['classes'] as Map<String, dynamic>;
      print('📚 Classes disponibles dans JSON: ${classes.keys.length}');

      // Afficher toutes les classes disponibles pour le débogage
      print('   Liste des classes JSON:');
      classes.keys.toList().sort();
      for (final key in classes.keys) {
        print('   • $key');
      }

      // 4. Chercher la classe dans le JSON
      if (!classes.containsKey(jsonClassName)) {
        print('❌ ERREUR: Classe "$jsonClassName" non trouvée dans JSON');

        // Chercher des correspondances partielles
        for (final key in classes.keys) {
          if (key.contains(jsonClassName) || jsonClassName.contains(key)) {
            print('   🔍 Correspondance trouvée: "$key"');
            return _extractCriteriaForClass(classes[key], matiereName);
          }
        }

        print('   ❌ Aucune correspondance trouvée');
        return [];
      }

      print('✅ SUCCES: Classe "$jsonClassName" trouvée dans JSON');

      // 5. Extraire les critères
      final classData = classes[jsonClassName];
      return _extractCriteriaForClass(classData, matiereName);
    } catch (e) {
      print('💥 ERREUR FATALE dans _getCriteriaFromJson: $e');
      return [];
    } finally {
      print('===== FIN RECHERCHE CRITERES JSON =====\n');
    }
  }

  List<Map<String, dynamic>> _extractCriteriaForClass(
      dynamic classData, String matiereName) {
    try {
      print('🔍 Extraction critères pour matière: "$matiereName"');

      if (classData is! Map<String, dynamic>) {
        print('❌ Données de classe invalides');
        return [];
      }

      // Vérifier la structure subjects
      if (!classData.containsKey('subjects') ||
          classData['subjects'] is! Map<String, dynamic>) {
        print('❌ Clé "subjects" non trouvée ou invalide');
        return [];
      }

      final subjects = classData['subjects'] as Map<String, dynamic>;
      print('📖 Matières disponibles dans la classe: ${subjects.keys.length}');

      // Afficher toutes les matières pour le débogage
      print('   Liste des matières:');
      for (final key in subjects.keys) {
        print('   • $key');
      }

      // Chercher la matière exacte
      if (!subjects.containsKey(matiereName)) {
        print('❌ Matière "$matiereName" non trouvée');
        print('   Chercher des correspondances...');

        // Chercher par nom partiel
        for (final key in subjects.keys) {
          if (key.contains(matiereName) || matiereName.contains(key)) {
            print('   ✅ Matière trouvée par correspondance: "$key"');
            return _processSubjectData(subjects[key], key);
          }
        }

        // Chercher par traduction
        if (_isFrenchInterface) {
          final arabicMatiereName =
              DataTranslator.getArabicMatiereFromFrench(matiereName);
          print('   🔍 Chercher version arabe: "$arabicMatiereName"');

          if (subjects.containsKey(arabicMatiereName)) {
            print('   ✅ Matière trouvée par traduction: "$arabicMatiereName"');
            return _processSubjectData(
                subjects[arabicMatiereName], arabicMatiereName);
          }
        }

        print('❌ Matière non trouvée après toutes les recherches');
        return [];
      }

      print('✅ Matière trouvée: "$matiereName"');
      return _processSubjectData(subjects[matiereName], matiereName);
    } catch (e) {
      print('❌ Erreur extraction critères: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _processSubjectData(
      dynamic subjectData, String originalMatiereName) {
    try {
      if (subjectData is! Map<String, dynamic>) {
        print('❌ Données matière invalides');
        return [];
      }

      print('📊 Vérification données matière:');
      print('   • has_criteria: ${subjectData['has_criteria']}');
      print('   • criteria_count: ${subjectData['criteria_count']}');

      if (subjectData['has_criteria'] != true) {
        print('⚠️ Matière sans critères (has_criteria = false)');
        return [];
      }

      final criteriaList = subjectData['criteria'] as List<dynamic>?;
      if (criteriaList == null || criteriaList.isEmpty) {
        print('⚠️ Liste de critères vide ou null');
        return [];
      }

      print('✅ ${criteriaList.length} critères trouvés');

      // Afficher les noms des critères pour le débogage
      for (int i = 0; i < criteriaList.length; i++) {
        final criterion = criteriaList[i] as Map<String, dynamic>;
        print(
            '   ${i + 1}. ${criterion['name']} (${criterion['indicators_count'] ?? 0} indicateurs)');
      }

      // Traiter et trier les critères
      return _createCriteriaList(criteriaList, originalMatiereName);
    } catch (e) {
      print('❌ Erreur traitement données matière: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _createCriteriaList(
      List<dynamic> criteriaList, String matiereName) {
    final List<Map<String, dynamic>> criteria = [];

    for (int i = 0; i < criteriaList.length; i++) {
      final criterion = criteriaList[i] as Map<String, dynamic>;
      final criteriaName = criterion['name']?.toString() ?? 'معيار ${i + 1}';

      // Récupérer les indicateurs
      final indicators = criterion['indicators'] as List<dynamic>? ?? [];

      // Filtrer les indicateurs non vides
      final List<String> indicatorStrings = indicators
          .map((indicator) => indicator.toString())
          .where((indicator) => indicator.trim().isNotEmpty)
          .toList();

      // Trier les indicateurs
      indicatorStrings.sort(_arabicStringComparator);

      // Créer l'entrée du critère
      criteria.add({
        'id': i + 1,
        'name': _isFrenchInterface
            ? DataTranslator.translateMatiere(criteriaName)
            : criteriaName,
        'originalName': criteriaName,
        'frenchName': DataTranslator.translateMatiere(criteriaName),
        'arabicName': criteriaName,
        'domaine': _getDomaineForMatiere(matiereName, _isFrenchInterface),
        'indicators': indicatorStrings,
        'indicators_count': indicatorStrings.length,
        'displayNumber': i + 1,
        'sortKey': _generateArabicSortKey(criteriaName),
      });
    }

    // Trier les critères selon la langue
    if (_isFrenchInterface) {
      criteria
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    } else {
      criteria.sort((a, b) => _arabicStringComparator(
            a['originalName'] as String,
            b['originalName'] as String,
          ));
    }

    // Mettre à jour les numéros d'affichage après tri
    for (int i = 0; i < criteria.length; i++) {
      criteria[i]['displayNumber'] = i + 1;
    }

    print('✅ ${criteria.length} critères traités avec succès');
    return criteria;
  }

// Méthode auxiliaire pour extraire les critères d'une classe
  List<Map<String, dynamic>> _extractCriteriaFromClassData(
      dynamic classData, String matiereName) {
    if (classData is Map<String, dynamic> &&
        classData.containsKey('subjects') &&
        classData['subjects'] is Map<String, dynamic>) {
      final subjects = classData['subjects'] as Map<String, dynamic>;

      if (subjects.containsKey(matiereName)) {
        final subjectData = subjects[matiereName];
        final bool hasCriteria = subjectData['has_criteria'] ?? false;

        if (hasCriteria && subjectData['criteria'] != null) {
          final criteriaList = subjectData['criteria'] as List<dynamic>;
          print('✅ Critères trouvés pour $matiereName: ${criteriaList.length}');

          return _processCriteriaList(criteriaList, matiereName);
        } else {
          print('⚠️ Pas de critères pour $matiereName ou has_criteria=false');
        }
      } else {
        print('❌ Matière non trouvée dans la classe: $matiereName');
        print('Matières disponibles: ${subjects.keys.join(', ')}');
      }
    }

    return [];
  }

// Méthode auxiliaire pour traiter la liste des critères
  List<Map<String, dynamic>> _processCriteriaList(
      List<dynamic> criteriaList, String matiereName) {
    List<Map<String, dynamic>> criteria = [];

    for (int i = 0; i < criteriaList.length; i++) {
      final criteriaData = criteriaList[i] as Map<String, dynamic>;
      final criteriaName = criteriaData['name']?.toString() ?? 'معيار ${i + 1}';
      final indicators = criteriaData['indicators'] as List<dynamic>? ?? [];

      // Trier les indicateurs par ordre alphabétique arabe
      final List<String> indicatorStrings = indicators
          .map((indicator) => indicator.toString())
          .where(
              (indicator) => indicator.isNotEmpty) // Exclure les chaînes vides
          .toList();

      // Trier les indicateurs
      indicatorStrings.sort(_arabicStringComparator);

      criteria.add({
        'name': _isFrenchInterface
            ? DataTranslator.translateMatiere(criteriaName)
            : criteriaName,
        'originalName': criteriaName,
        'domaine': _getDomaineForMatiere(matiereName, _isFrenchInterface),
        'indicators': indicatorStrings.map((indicator) {
          return _isFrenchInterface
              ? DataTranslator.translateMatiere(indicator)
              : indicator;
        }).toList(),
        'sortKey': _generateArabicSortKey(criteriaName),
      });
    }

    // Trier les critères
    criteria.sort((a, b) {
      if (_isFrenchInterface) {
        return (a['name'] as String).compareTo(b['name'] as String);
      } else {
        return _arabicStringComparator(
          a['originalName'] as String,
          b['originalName'] as String,
        );
      }
    });

    // Réassigner les numéros après le tri
    for (int i = 0; i < criteria.length; i++) {
      criteria[i]['displayNumber'] = i + 1;
    }

    return criteria;
  }

// Méthode pour extraire l'année arabe d'un nom de classe
  String _extractArabicYear(String className) {
    // Extrait "الأولى", "الثانية", etc.
    final patterns = [
      'الأولى',
      'الثانية',
      'الثالثة',
      'الرابعة',
      'الخامسة',
      'السادسة'
    ];

    for (final pattern in patterns) {
      if (className.contains(pattern)) {
        return pattern;
      }
    }

    return className;
  }

// Comparateur pour tri alphabétique arabe
  int _arabicStringComparator(String a, String b) {
    // Normaliser les chaînes
    final normalizedA = _normalizeArabicForSort(a);
    final normalizedB = _normalizeArabicForSort(b);

    // Ordre des lettres arabes
    const arabicAlphabet = 'اأإآبتثجحخدذرزسشصضطظعغفقكلمنهويىةؤئء';

    for (int i = 0; i < math.min(normalizedA.length, normalizedB.length); i++) {
      final charA = normalizedA[i];
      final charB = normalizedB[i];

      final indexA = arabicAlphabet.indexOf(charA);
      final indexB = arabicAlphabet.indexOf(charB);

      if (indexA != -1 && indexB != -1 && indexA != indexB) {
        return indexA - indexB;
      }

      // Comparaison Unicode comme fallback
      if (charA != charB) {
        return charA.codeUnitAt(0) - charB.codeUnitAt(0);
      }
    }

    return normalizedA.length - normalizedB.length;
  }

// Normalisation du texte arabe pour le tri
  String _normalizeArabicForSort(String text) {
    // Supprimer les diacritiques
    String normalized = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // Normaliser les formes de lettres
    final Map<String, String> normalizationMap = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ؤ': 'و',
      'ئ': 'ي',
      'ة': 'ه',
      'ى': 'ي',
      'ٱ': 'ا',
      'ٳ': 'ا',
      'ٲ': 'ا',
    };

    normalizationMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    return normalized.trim();
  }

// Générer une clé de tri pour l'arabe
  String _generateArabicSortKey(String text) {
    final normalized = _normalizeArabicForSort(text);
    final withoutSpaces = normalized.replaceAll(' ', '');
    return withoutSpaces.toLowerCase();
  }

  void _detectLanguage() async {
    try {
      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();

      String matiereName = matiereDoc['name'] ?? '';

      // Vérifier si c'est une matière en français
      bool isFrenchInterface;

      if (DataTranslator.isForeignMatiere(matiereName)) {
        isFrenchInterface = true;
      } else {
        // Vérifier le contenu de la matière
        final containsFrench =
            matiereName.contains(RegExp(r'[a-zA-Zéèêëàâäôöûüç]'));
        final containsArabic = matiereName.contains(RegExp(r'[\u0600-\u06FF]'));

        // Si contient du français mais pas d'arabe
        isFrenchInterface = containsFrench && !containsArabic;
      }

      setState(() {
        _matiereName = matiereName;
        _isFrenchInterface = isFrenchInterface;
        print('Détection langue - Matière: "$matiereName", '
            'Interface française: $isFrenchInterface');
      });
    } catch (e) {
      print('Erreur détection langue: $e');
      setState(() {
        _isFrenchInterface = false;
      });
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _accountStatusTimer?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  // CORRECTION : Méthode sécurisée pour lire les champs Firestore
  dynamic _getFieldSafe(
      DocumentSnapshot doc, String field, dynamic defaultValue) {
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

  void _setupUserListener() {
    if (currentUser == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (_isMounted && snapshot.exists) {
        setState(() {
          _remainingPrints = _getFieldSafe(snapshot, 'remainingPrints', 5);
          _isAccountActive = _getFieldSafe(snapshot, 'isActive', false);
          _profName = _getFieldSafe(snapshot, 'profName', '');
          _schoolName = _getFieldSafe(snapshot, 'schoolName', '');

          final expirationDate =
              _getFieldSafe(snapshot, 'accountExpiration', null);
          if (expirationDate != null && expirationDate is Timestamp) {
            _remainingTime = expirationDate.toDate().difference(DateTime.now());
          }
        });
      }
    });
  }

  void _showEvaluationInfoDialog(VoidCallback onConfirm) {
    TextEditingController periodeController =
        TextEditingController(text: _selectedPeriode);

    // Options pour le trimestre
    final trimestreOptions = ['الأول', 'الثاني', 'الثالث'];
    final trimestreTranslations = {
      'الأول': 'Premier',
      'الثاني': 'Deuxième',
      'الثالث': 'Troisième'
    };

    // Options pour le type d'évaluation
    final evaluationOptions = ['تقييم', 'امتحان'];
    final evaluationTranslations = {'تقييم': 'Évaluation', 'امتحان': 'Examen'};

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              _getTranslatedText(
                  'معلومات التقييم', 'Informations d\'évaluation'),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الثلاثي
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslatedText('الثلاثي:', 'Trimestre:'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTrimestre,
                      items: trimestreOptions
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  _isFrenchInterface
                                      ? trimestreTranslations[t] ?? t
                                      : t,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedTrimestre = v;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // الوحدة / الفترة
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslatedText(
                          'الوحدة / الفترة:', 'Unité / Période:'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: periodeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            _getTranslatedText('مثال: الوحدة 1', 'Ex: Unité 1'),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // نوع التقييم
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslatedText('نوع التقييم:', 'Type d\'évaluation:'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEvaluationType,
                      items: evaluationOptions
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  _isFrenchInterface
                                      ? evaluationTranslations[t] ?? t
                                      : t,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedEvaluationType = v;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTranslatedText('إلغاء', 'Annuler')),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedPeriode = periodeController.text.trim();
              });
              Navigator.pop(context);
              onConfirm(); // Appeler la fonction de callback
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text(_getTranslatedText('متابعة', 'Continuer')),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPrintCredit() async {
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists && _isMounted) {
        setState(() {
          _remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);
          _isAccountActive = _getFieldSafe(userDoc, 'isActive', false);
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification du crédit: $e');
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
    if (currentUser == null || !_isMounted) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
          .get();

      if (_isMounted && userDoc.exists) {
        final isActive = _getFieldSafe(userDoc, 'isActive', false);
        final expirationDate =
            _getFieldSafe(userDoc, 'accountExpiration', null);

        setState(() {
          _isAccountActive = isActive;
          if (expirationDate != null && expirationDate is Timestamp) {
            _remainingTime = expirationDate.toDate().difference(DateTime.now());
          }
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification du statut du compte: $e');
    }
  }

  Future<bool> _checkAndUpdatePrintCredit() async {
    if (currentUser == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
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

  // MODIFICATION : Traduction des textes selon la langue
  String _getTranslatedText(String arabicText, String frenchText) {
    return _isFrenchInterface ? frenchText : arabicText;
  }

  Future<void> _saveAndOpenPDF(Uint8List pdfBytes) async {
    try {
      if (kIsWeb) {
        // Pour le web
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'tableau_resultats.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Pour mobile/desktop
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/tableau_resultats.pdf');
        await file.writeAsBytes(pdfBytes);
        await OpenFile.open(file.path);
      }
    } catch (e) {
      print('Erreur sauvegarde PDF: $e');
      throw e;
    }
  }

  Future<void> _generateHTMLReport({bool downloadAsPDF = false}) async {
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
        builder: (BuildContext context) =>
            _buildLoadingDialog(isPDF: downloadAsPDF),
      );

      // Récupérer les données CORRECTEMENT
      final matiereName = await _getMatiereName();
      final className = await _getClassName();

      // DEBUG: Afficher les données avant envoi
      print('=== DONNÉES POUR RAPPORT HTML ===');
      print('Total étudiants: $totalStudents');
      print('Statistiques sumCriteriaMaxPerBareme:');
      sumCriteriaMaxPerBareme.forEach((key, value) {
        print('  $key: $value');
      });

      var data = {
        'profName': _profName,
        'matiereName': matiereName,
        'className': className,
        'schoolName': _schoolName,
        'baremes': await _getBaremes(),
        'students': await _getStudents(),
        'sumCriteriaMaxPerBareme': sumCriteriaMaxPerBareme,
        'totalStudents': totalStudents,
        'selectedClass': widget.selectedClass,
        'isFrenchInterface': _isFrenchInterface,
        'trimestre': _selectedTrimestre,
        'periode': _selectedPeriode,
        'evaluationType': _selectedEvaluationType,
      };

      // Générer le rapport (HTML ou PDF)
      await HTMLReportGenerator.generateAndDownloadReport(
        profName: _profName,
        matiereName: matiereName,
        className: className,
        schoolName: _schoolName,
        baremes: data['baremes'] as List<dynamic>,
        students: data['students'] as List<dynamic>,
        sumCriteriaMaxPerBareme:
            sumCriteriaMaxPerBareme, // IMPORTANT: envoyer les bonnes données
        totalStudents: totalStudents,
        isFrenchInterface: _isFrenchInterface,
        downloadAsPDF: downloadAsPDF,
        trimestre: _selectedTrimestre,
        periode: _selectedPeriode,
        evaluationType: _selectedEvaluationType,
      );

      // Dédure le crédit
      await _deductPrintCredit();

      _showSuccessSnackbar(downloadAsPDF
          ? _getTranslatedText('تم إنشاء PDF بنجاح', 'PDF généré avec succès')
          : _getTranslatedText(
              'تم إنشاء التقرير بنجاح', 'Rapport généré avec succès'));
    } catch (e) {
      _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء التقرير',
              'Erreur lors de la génération du rapport') +
          ': $e');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
      Navigator.of(context).pop();
    }
  }

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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child:
                Text(_getTranslatedText('تفعيل الحساب', 'Activer le compte')),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar(_getTranslatedText(
          'المستخدم غير مسجل الدخول.', 'Utilisateur non connecté.'));
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    bool success = false;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return _buildLoadingDialog();
        },
      );

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
        // Ajouter les informations du dialogue
        'trimestre': _selectedTrimestre,
        'periode': _selectedPeriode,
        'evaluationType': _selectedEvaluationType,
      };

      if (type == 'pdf') {
        success = await _sendDataToFlask(data);
      } else {
        success = await _sendHTMLDataToFlask(data);
      }

      // DÉDUCTION UNIQUEMENT SI RÉUSSITE
      if (success) {
        await _deductPrintCredit();
      }
    } catch (e) {
      _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء التقرير:',
              'Erreur lors de la génération du rapport:') +
          ' $e');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
      Navigator.of(context).pop();
    }
  }

  Widget _buildLoadingDialogForReport() {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 3,
              ),
              Icon(Icons.print, color: Colors.blue, size: 20),
            ],
          ),
          SizedBox(height: 20),
          Text(
            _getTranslatedText(
                "جاري إنشاء التقرير...", "Génération du rapport en cours..."),
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

  Future<bool> _sendDataToFlask(Map<String, dynamic> data) async {
    try {
      // IMPORTANT: S'assurer que les données envoyées au serveur sont en arabe
      // Créer une copie des données avec les valeurs originales arabes
      Map<String, dynamic> dataForServer = Map.from(data);

      // Remplacer les valeurs affichées par les valeurs originales arabes
      if (data['baremes'] != null) {
        List<dynamic> originalBaremes = [];
        for (var bareme in data['baremes']) {
          Map<String, dynamic> originalBareme = Map.from(bareme);
          // Utiliser la valeur originale arabe pour le serveur
          if (bareme['originalValue'] != null) {
            originalBareme['value'] = bareme['originalValue'];
          }
          originalBaremes.add(originalBareme);
        }
        dataForServer['baremes'] = originalBaremes;
      }

      // Ajouter les informations du dialogue (elles sont déjà en arabe)
      dataForServer['trimestre'] = _selectedTrimestre;
      dataForServer['periode'] = _selectedPeriode;
      dataForServer['evaluationType'] = _selectedEvaluationType;

      final url = Uri.parse('https://imprission.onrender.com/generate_pdf');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(dataForServer),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'tableau_resultats.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);

        _showSuccessSnackbar(
            _getTranslatedText('تم إنشاء PDF بنجاح', 'PDF généré avec succès'));
        return true;
      } else {
        _showErrorSnackbar(_getTranslatedText(
            'خطأ في إنشاء PDF', 'Erreur lors de la génération du PDF'));
        return false;
      }
    } on TimeoutException {
      _showErrorSnackbar(_getTranslatedText(
          'انتهت المهلة - استغرق الخادم وقتًا طويلاً للرد',
          'Timeout - Le serveur a mis trop de temps à répondre'));
      return false;
    } on SocketException {
      _showErrorSnackbar(_getTranslatedText(
          'خطأ في الاتصال - تحقق من اتصالك بالإنترنت',
          'Erreur de connexion - Vérifiez votre internet'));
      return false;
    } catch (e) {
      _showErrorSnackbar(_getTranslatedText('خطأ تقني:', 'Erreur technique:') +
          ' ${e.toString()}');
      return false;
    }
  }

  Future<bool> _sendHTMLDataToFlask(Map<String, dynamic> data) async {
    try {
      // Ajouter les informations du dialogue
      data['trimestre'] = _selectedTrimestre;
      data['periode'] = _selectedPeriode;
      data['evaluationType'] = _selectedEvaluationType;

      final url =
          Uri.parse('https://imprission.onrender.com/generate-html-report');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        html.Url.revokeObjectUrl(url);

        _showSuccessSnackbar(_getTranslatedText(
            'تم إنشاء التقرير بنجاح', 'Rapport généré avec succès'));
        return true; // SUCCÈS
      } else {
        _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء التقرير HTML:',
                'Erreur lors de la génération du rapport HTML:') +
            ' ${response.statusCode}');
        return false; // ÉCHEC
      }
    } on TimeoutException {
      _showErrorSnackbar(_getTranslatedText(
          'انتهت المهلة - استغرق الخادم وقتًا طويلاً للرد. يرجى المحاولة مرة أخرى.',
          'Timeout - Le serveur a mis trop de temps à répondre. Veuillez réessayer.'));
      return false;
    } on SocketException {
      _showErrorSnackbar(_getTranslatedText(
          'خطأ في الاتصال - تحقق من اتصالك بالإنترنت',
          'Erreur de connexion - Vérifiez votre connexion internet'));
      return false;
    } catch (e) {
      _showErrorSnackbar(_getTranslatedText('خطأ تقني:', 'Erreur technique:') +
          ' ${e.toString()}');
      return false;
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _deductPrintCredit() async {
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return;

      final bool isActive = _getFieldSafe(userDoc, 'isActive', false);
      final int remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);

      // Ne déduire que si le compte est inactif et qu'il reste des crédits
      if (!isActive && remainingPrints > 0) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser!.uid)
            .update({'remainingPrints': FieldValue.increment(-1)});

        setState(() {
          _remainingPrints = remainingPrints - 1;
        });

        print('✅ Crédit déduit - Nouveau solde: ${remainingPrints - 1}');
      }
    } catch (e) {
      print('Erreur lors de la déduction du crédit: $e');
    }
  }

  // MODIFICATION : Traduction des noms pour l'interface
  // MODIFICATION : Garder les noms arabes dans la BD, traduire uniquement pour l'affichage
  Future<String> _getMatiereName() async {
    try {
      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();

      String arabicName = _getFieldSafe(matiereDoc, 'name', 'غير معروف');
      // L'enregistrement en BD reste en arabe, on traduit uniquement pour l'affichage
      return _isFrenchInterface
          ? DataTranslator.translateMatiere(arabicName)
          : arabicName;
    } catch (e) {
      return _isFrenchInterface ? 'Inconnu' : 'غير معروف';
    }
  }

  Future<String> _getClassName() async {
    try {
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();

      String arabicName = _getFieldSafe(classDoc, 'name', 'غير معروف');
      // L'enregistrement en BD reste en arabe, on traduit uniquement pour l'affichage
      return _isFrenchInterface
          ? DataTranslator.translateClass(arabicName)
          : arabicName;
    } catch (e) {
      return _isFrenchInterface ? 'Inconnu' : 'غير معروف';
    }
  }

  Future<List<dynamic>> _getBaremes() async {
    try {
      final baremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      final List<dynamic> baremes = [];
      for (final baremeDoc in baremesSnapshot.docs) {
        final baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
        final baremeName = _getFieldSafe(baremeDoc, 'baremeName', 'غير معروف');
        final isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

        // IMPORTANT: Garder le nom arabe dans la BD, traduire uniquement pour l'affichage
        final displayedBaremeName = _isFrenchInterface
            ? DataTranslator.translateBareme(baremeName)
            : baremeName;

        if (isBaremeSelected) {
          baremes.add({
            'id': baremeId,
            'value': displayedBaremeName, // Affichage traduit
            'originalValue': baremeName, // Valeur originale arabe pour la BD
            'type': 'bareme',
          });
        }

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
          final sousBaremeName =
              _getFieldSafe(sousBaremeDoc, 'sousBaremeName', 'غير معروف');
          final isSousBaremeSelected =
              _getFieldSafe(sousBaremeDoc, 'selected', false);

          // IMPORTANT: Garder le nom arabe dans la BD, traduire uniquement pour l'affichage
          final displayedSousBaremeName = _isFrenchInterface
              ? DataTranslator.translateSousBareme(sousBaremeName)
              : sousBaremeName;

          if (isSousBaremeSelected) {
            baremes.add({
              'id': sousBaremeId,
              'value': displayedSousBaremeName, // Affichage traduit
              'originalValue':
                  sousBaremeName, // Valeur originale arabe pour la BD
              'type': 'sousBareme',
              'parentBaremeId': baremeId,
            });
          }
        }
      }

      return baremes;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> _getStudents() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(widget.selectedClass)
          .collection('students')
          .get();

      final List<dynamic> students = [];
      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentName = _getFieldSafe(studentDoc, 'name',
            _isFrenchInterface ? 'Élève inconnu' : 'تلميذ غير معروف');

        final baremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(widget.selectedClass)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .get();

        final Map<String, String> baremes = {};
        for (final baremeDoc in baremesSnapshot.docs) {
          final baremeId = baremeDoc.id;
          final marks = _getFieldSafe(baremeDoc, 'Marks', '( - - - )');
          baremes[baremeId] = marks;

          final sousBaremesSnapshot =
              await baremeDoc.reference.collection('sous_baremes').get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousMarks =
                _getFieldSafe(sousBaremeDoc, 'Marks', '( - - - )');
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
      return [];
    }
  }

  void _loadUserData() async {
    if (currentUser != null && _isMounted) {
      try {
        var userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser!.uid)
            .get();

        if (_isMounted && userDoc.exists) {
          setState(() {
            _profName = _getFieldSafe(userDoc, 'profName', '');
            _schoolName = _getFieldSafe(userDoc, 'schoolName', '');
            _remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);
            _isAccountActive = _getFieldSafe(userDoc, 'isActive', false);
            _isDialogCompleted = _profName.isNotEmpty && _schoolName.isNotEmpty;
          });
        }

        if (_isMounted && !_isDialogCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isMounted) {
              _showInputDialog();
            }
          });
        }
      } catch (e) {
        print('Erreur lors du chargement des données utilisateur: $e');
      }
    }
  }

  // MODIFICATION : Dialogues traduits
  void _showEditDialog() {
    TextEditingController profController =
        TextEditingController(text: _profName);
    TextEditingController schoolController =
        TextEditingController(text: _schoolName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                  _getTranslatedText(
                      'تعديل المعلومات', 'Modifier les informations'),
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: profController,
                decoration: InputDecoration(
                  labelText:
                      _getTranslatedText('اسم الأستاذ', 'Nom du professeur'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(
                  labelText:
                      _getTranslatedText('اسم المدرسة', 'Nom de l\'école'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_getTranslatedText('إلغاء', 'Annuler')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('Users')
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

                  _showSuccessSnackbar(_getTranslatedText(
                      'تم تحديث المعلومات', 'Informations mises à jour'));
                }
                Navigator.of(context).pop();
              },
              child: Text(_getTranslatedText('حفظ', 'Enregistrer')),
            ),
          ],
        );
      },
    );
  }

  void _showInputDialog() {
    TextEditingController profController = TextEditingController();
    TextEditingController schoolController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                  _getTranslatedText('معلومات جديدة', 'Nouvelles informations'),
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  _getTranslatedText('يرجى إكمال معلوماتك للمتابعة',
                      'Veuillez compléter vos informations pour continuer'),
                  style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 16),
              TextField(
                controller: profController,
                decoration: InputDecoration(
                  labelText:
                      _getTranslatedText('اسم الأستاذ', 'Nom du professeur'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(
                  labelText:
                      _getTranslatedText('اسم المدرسة', 'Nom de l\'école'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (profController.text.isEmpty ||
                    schoolController.text.isEmpty) {
                  _showErrorSnackbar(_getTranslatedText('يرجى ملء جميع الحقول',
                      'Veuillez remplir tous les champs'));
                  return;
                }

                if (currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(currentUser!.uid)
                      .set(
                    {
                      'profName': profController.text,
                      'schoolName': schoolController.text,
                      'remainingPrints': _remainingPrints,
                    },
                    SetOptions(merge: true),
                  );

                  setState(() {
                    _profName = profController.text;
                    _schoolName = schoolController.text;
                    _isDialogCompleted = true;
                  });

                  _showSuccessSnackbar(_getTranslatedText(
                      'تم حفظ المعلومات', 'Informations enregistrées'));
                }
                Navigator.of(context).pop();
              },
              child: Text(_getTranslatedText('حفظ', 'Enregistrer')),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchMarks() async {
    if (!_isMounted) return;

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      var studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_classes')
          .doc(widget.selectedClass)
          .collection('students')
          .get();

      if (_isMounted) {
        setState(() {
          totalStudents = studentsSnapshot.docs.length;
        });
      }

      var selectedBaremes = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      // Réinitialiser les compteurs
      sumCriteriaMaxPerBareme.clear();

      // DEBUG: Afficher les barèmes sélectionnés
      print('=== DEBUG fetchMarks ===');
      print('Total étudiants: $totalStudents');
      print('Barèmes sélectionnés: ${selectedBaremes.docs.length}');

      for (var baremeDoc in selectedBaremes.docs) {
        var baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
        var isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

        // DEBUG
        print('Barème $baremeId - sélectionné: $isBaremeSelected');

        // Initialiser le compteur pour le barème principal si sélectionné
        if (isBaremeSelected) {
          sumCriteriaMaxPerBareme[baremeId] = 0;
          print('  -> Compteur initialisé pour barème principal: $baremeId');
        }

        // Vérifier les sous-barèmes
        var sousBaremesSnapshot =
            await baremeDoc.reference.collection('sousBaremes').get();
        for (var sousBaremeDoc in sousBaremesSnapshot.docs) {
          var isSousBaremeSelected =
              _getFieldSafe(sousBaremeDoc, 'selected', false);
          if (isSousBaremeSelected) {
            var sousBaremeId = sousBaremeDoc.id;
            // Créer une clé unique pour le sous-barème
            var sousBaremeKey = '$baremeId-$sousBaremeId';
            sumCriteriaMaxPerBareme[sousBaremeKey] = 0;
            print('  -> Compteur initialisé pour sous-barème: $sousBaremeKey');
          }
        }
      }

      // Compter les élèves qui ont atteint chaque critère
      for (var studentDoc in studentsSnapshot.docs) {
        var studentId = studentDoc.id;

        for (var baremeDoc in selectedBaremes.docs) {
          var baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
          var isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

          if (isBaremeSelected) {
            // Vérifier le barème principal
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

            if (baremeSnapshot.exists) {
              var value = _getFieldSafe(baremeSnapshot, 'Marks', '');
              if (value == '( + + + )' || value == '( + + - )') {
                sumCriteriaMaxPerBareme[baremeId] =
                    (sumCriteriaMaxPerBareme[baremeId] ?? 0) + 1;
                print(
                    '  ✅ Étudiant $studentId - Barème $baremeId: $value -> COMPTÉ');
              } else {
                print(
                    '  ❌ Étudiant $studentId - Barème $baremeId: $value -> NON COMPTÉ');
              }
            } else {
              print('  📭 Étudiant $studentId - Barème $baremeId: NON TROUVÉ');
            }
          }

          // Vérifier les sous-barèmes
          var sousBaremesSnapshot =
              await baremeDoc.reference.collection('sousBaremes').get();
          for (var sousBaremeDoc in sousBaremesSnapshot.docs) {
            var isSousBaremeSelected =
                _getFieldSafe(sousBaremeDoc, 'selected', false);
            if (isSousBaremeSelected) {
              var sousBaremeId = sousBaremeDoc.id;
              var sousBaremeKey = '$baremeId-$sousBaremeId';

              // Vérifier la valeur du sous-barème
              var sousBaremeSnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('user_classes')
                  .doc(widget.selectedClass)
                  .collection('students')
                  .doc(studentId)
                  .collection('baremes')
                  .doc(baremeId)
                  .collection('sous_baremes')
                  .doc(sousBaremeId)
                  .get();

              if (sousBaremeSnapshot.exists) {
                var value = _getFieldSafe(sousBaremeSnapshot, 'Marks', '');
                if (value == '( + + + )' || value == '( + + - )') {
                  sumCriteriaMaxPerBareme[sousBaremeKey] =
                      (sumCriteriaMaxPerBareme[sousBaremeKey] ?? 0) + 1;
                  print(
                      '  ✅ Étudiant $studentId - Sous-barème $sousBaremeKey: $value -> COMPTÉ');
                } else {
                  print(
                      '  ❌ Étudiant $studentId - Sous-barème $sousBaremeKey: $value -> NON COMPTÉ');
                }
              } else {
                print(
                    '  📭 Étudiant $studentId - Sous-barème $sousBaremeKey: NON TROUVÉ');
              }
            }
          }
        }
      }

      // DEBUG: Afficher les résultats finaux
      print('=== RÉSULTATS FINAUX ===');
      sumCriteriaMaxPerBareme.forEach((key, value) {
        print('$key: $value étudiants');
      });

      if (_isMounted) {
        setState(() {});
      }
    } catch (e) {
      print('Erreur lors de la récupération des marques : $e');
    }
  }

  // MODIFICATION : Widgets avec textes traduits
  Widget _buildPrintCreditWidget() {
    Color backgroundColor;
    if (_remainingPrints == 0) {
      backgroundColor = Colors.red;
    } else if (_remainingPrints <= 2) {
      backgroundColor = Colors.orange;
    } else {
      backgroundColor = Colors.blue;
    }

    return Tooltip(
      message: _getTranslatedText(
          'الرصيد المتبقي للطباعة', 'Crédit d\'impression restant'),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print, size: 16, color: Colors.white),
            SizedBox(width: 6),
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
    );
  }

  Widget _buildAccountTimeRemaining() {
    if (_remainingTime.isNegative || !_isAccountActive) return SizedBox();

    Color timeColor = _remainingTime.inDays <= 7 ? Colors.orange : Colors.teal;

    return Tooltip(
      message: _getTranslatedText(
          'الوقت المتبقي قبل الانتهاء', 'Temps restant avant expiration'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: timeColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.white),
            SizedBox(width: 6),
            Text(
              '${_remainingTime.inDays}j ${_remainingTime.inHours % 24}h',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStatusIndicator() {
    return Tooltip(
      message: _isAccountActive
          ? _getTranslatedText('حساب نشط', 'Compte actif')
          : _getTranslatedText('حساب غير نشط', 'Compte inactif'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isAccountActive ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: Colors.white,
            ),
            SizedBox(width: 6),
            Text(
              _isAccountActive
                  ? _getTranslatedText('نشط', 'Actif')
                  : _getTranslatedText('غير نشط', 'Inactif'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return IconButton(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(Icons.person, color: Colors.white, size: 20),
      ),
      onPressed: _showEditDialog,
    );
  }

  Widget _buildPrintButton() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(
          Icons.print,
          color: Colors.white,
          size: 20,
        ),
      ),
      onSelected: _isGeneratingReport
          ? null
          : (value) {
              if (value == 'complete_report') {
                // NOUVELLE OPTION: Rapport complet
                _showCompleteReportDialog();
              } else if (value == 'baremes_table') {
                // Option existante: Tableau des barèmes
                _showClassAndMatiereSelectionDialog();
              } else {
                // Options existantes
                _showEvaluationInfoDialog(() {
                  if (value == 'html') {
                    _generateHTMLReport(downloadAsPDF: false);
                  } else if (value == 'pdf') {
                    _generateHTMLReport(downloadAsPDF: true);
                  }
                });
              }
            },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'html',
          child: Row(
            children: [
              Icon(Icons.description, color: Colors.blue),
              SizedBox(width: 8),
              Text(_getTranslatedText(
                  'طباعة الجدول (HTML)', 'Imprimer le tableau (HTML)')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red),
              SizedBox(width: 8),
              Text(_getTranslatedText(
                  'طباعة الجدول (PDF)', 'Imprimer le tableau (PDF)')),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'baremes_table',
          child: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green),
              SizedBox(width: 8),
              Text(_getTranslatedText(
                  'طباعة جدول المعايير', 'Imprimer tableau des critères')),
            ],
          ),
        ),
        PopupMenuDivider(),
        // NOUVELLE OPTION: Rapport complet
        PopupMenuItem<String>(
          value: 'complete_report',
          child: Row(
            children: [
              Icon(Icons.book, color: Colors.purple),
              SizedBox(width: 8),
              Text(_getTranslatedText('تقرير كامل', 'Rapport Complet')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton() {
    if (_isAccountActive) return SizedBox();

    return Tooltip(
      message: _getTranslatedText('تفعيل حسابك', 'Activer votre compte'),
      child: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(0.9),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Icon(Icons.upgrade, color: Colors.white, size: 20),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PaymentPage()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                  _getTranslatedText(
                      'المستخدم غير مسجل الدخول.', 'Utilisateur non connecté.'),
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_getTranslatedText('العودة', 'Retour')),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isDialogCompleted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                  _getTranslatedText('جاري تحميل معلوماتك...',
                      'Chargement de vos informations...'),
                  style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
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
          title: Text(
              _getTranslatedText(
                  'الجدول الجامع للنتائج', 'Tableau Global des Résultats'),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
          elevation: 4,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            _buildPrintCreditWidget(),
            if (_isAccountActive) _buildAccountTimeRemaining(),
            _buildAccountStatusIndicator(),
            _buildUpgradeButton(),
            _buildProfileButton(),
            _buildPrintButton(),
          ],
        ),
        body: Directionality(
          textDirection:
              _isFrenchInterface ? TextDirection.ltr : TextDirection.rtl,
          child: Column(
            children: [
              // Header amélioré
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildHeaderInfo(),
                    ),
                    _buildHeaderLogo(),
                  ],
                ),
              ),

              // Contenu principal
              Expanded(
                child: _buildMainContent(),
              ),

              // Footer amélioré
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border(
                    top: BorderSide(color: Colors.blue, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTranslatedText(
                          'تاريخ الإصدار: ${DateTime.now().toString().substring(0, 10)}',
                          'Date d\'émission: ${DateTime.now().toString().substring(0, 10)}'),
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    if (!_isAccountActive)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info,
                                size: 16, color: Colors.orange[800]),
                            SizedBox(width: 4),
                            Text(
                              _getTranslatedText(
                                  'حساب محدود - $_remainingPrints/5 طباعة',
                                  'Compte limité - $_remainingPrints/5 impressions'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return FutureBuilder<Map<String, String>>(
      future: _getClassAndMatiereNames(),
      builder: (context, snapshot) {
        String className = _isFrenchInterface ? 'Inconnu' : 'غير معروف';
        String matiereName = _isFrenchInterface ? 'Inconnu' : 'غير معروف';

        if (snapshot.connectionState == ConnectionState.waiting) {
          className = _isFrenchInterface ? 'Chargement...' : 'جاري التحميل...';
          matiereName =
              _isFrenchInterface ? 'Chargement...' : 'جاري التحميل...';
        } else if (snapshot.hasData) {
          className = snapshot.data!['className'] ??
              (_isFrenchInterface ? 'Inconnu' : 'غير معروف');
          matiereName = snapshot.data!['matiereName'] ??
              (_isFrenchInterface ? 'Inconnu' : 'غير معروف');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                _getTranslatedText('الأستاذ:', 'Professeur:'),
                _profName.isEmpty
                    ? (_isFrenchInterface ? 'Non renseigné' : 'غير محدد')
                    : _profName),
            SizedBox(height: 4),
            _buildInfoRow(
                _getTranslatedText('المادة:', 'Matière:'), matiereName),
            SizedBox(height: 4),
            _buildInfoRow(_getTranslatedText('القسم:', 'Classe:'), className),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderLogo() {
    return Column(
      children: [
        Image.asset(
          'lib/assets/icons/me/ministere.png',
          height: 70,
          errorBuilder: (context, error, stackTrace) {
            print("Erreur chargement image: $error");
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: Icon(Icons.school, size: 40, color: Colors.grey[400]),
            );
          },
        ),
        SizedBox(height: 8),
        Text(
          _getTranslatedText('مدرسة:', 'École:') + ' $_schoolName',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<Map<String, String>> _getClassAndMatiereNames() async {
    try {
      // Récupérer le nom de la classe
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();
      var className = classDoc['name'] ?? 'غير معروف';

      // Récupérer le nom de la matière
      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();
      var matiereName = matiereDoc['name'] ?? 'غير معروف';

      // Traduire si l'interface est en français
      if (_isFrenchInterface) {
        className = DataTranslator.translateClass(className);
        matiereName = DataTranslator.translateMatiere(matiereName);
      }

      return {
        'className': className,
        'matiereName': matiereName,
      };
    } catch (e) {
      return {
        'className': _isFrenchInterface ? 'Inconnu' : 'غير معروف',
        'matiereName': _isFrenchInterface ? 'Inconnu' : 'غير معروف',
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(_getTranslatedText(
                    'جاري تحميل الأقسام...', 'Chargement des classes...')),
              ],
            ),
          );
        }

        if (userClassesSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                    _getTranslatedText(
                        'خطأ في التحميل', 'Erreur de chargement'),
                    style: TextStyle(fontSize: 16, color: Colors.red)),
                SizedBox(height: 8),
                Text('${userClassesSnapshot.error}'),
              ],
            ),
          );
        }

        if (!userClassesSnapshot.hasData ||
            userClassesSnapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.class_, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                    _getTranslatedText(
                        'لم يتم العثور على أي قسم.', 'Aucune classe trouvée.'),
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text(
                    _getTranslatedText('يرجى إضافة أقسام أولاً.',
                        'Veuillez ajouter des classes d\'abord.'),
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          );
        }

        // Recherche de la classe correspondante
        for (var classDoc in userClassesSnapshot.data!.docs) {
          var classData = classDoc.data() as Map<String, dynamic>;
          var classIdFromFirestore = _getFieldSafe(classDoc, 'class_id', '');

          if (widget.selectedClass == classIdFromFirestore) {
            return StudentsTable(
              classDocId: classDoc.id,
              selectedClass: widget.selectedClass,
              selectedMatiere: widget.selectedMatiere,
              currentUser: currentUser!,
              sumCriteriaMaxPerBareme: sumCriteriaMaxPerBareme,
              totalStudents: totalStudents,
              navigateToClassificationPage: _navigateToClassificationPage,
              isFrenchInterface: _isFrenchInterface,
            );
          }
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                  _getTranslatedText('لم يتم العثور على أي قسم مطابق.',
                      'Aucune classe correspondante trouvée.'),
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text(
                  _getTranslatedText('القسم المحدد غير موجود.',
                      'La classe sélectionnée n\'existe pas.'),
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  // MODIFICATION : Navigation avec détection de langue
  void _navigateToClassificationPage(String baremeId,
      {String? sousBaremeId}) async {
    try {
      var classAndMatiereNames = await _getClassAndMatiereNames();

      var selectedBaremes = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      List<Map<String, dynamic>> baremesValues =
          await _getBaremesValues(selectedBaremes.docs);

      var selectedBareme = baremesValues.firstWhere(
        (bareme) => bareme['id'] == baremeId,
        orElse: () => {
          'id': baremeId,
          'value': _isFrenchInterface ? 'Inconnu' : 'غير معروف'
        },
      );

      String baremeName = selectedBareme['value'] ??
          (_isFrenchInterface ? 'Inconnu' : 'غير معروف');

      String? sousBaremeName;
      if (sousBaremeId != null) {
        var selectedSousBareme = baremesValues.firstWhere(
          (bareme) =>
              bareme['id'] == sousBaremeId &&
              bareme['parentBaremeId'] == baremeId,
          orElse: () => {
            'id': sousBaremeId,
            'value': _isFrenchInterface ? 'Inconnu' : 'غير معروف'
          },
        );

        sousBaremeName = selectedSousBareme['value'] ??
            (_isFrenchInterface ? 'Inconnu' : 'غير معروف');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassificationPage(
            selectedClass: widget.selectedClass,
            selectedBaremeId: baremeId,
            selectedSousBaremeId: sousBaremeId,
            currentUser: currentUser!,
            profName: _profName,
            schoolName: _schoolName,
            className: classAndMatiereNames['className'] ??
                (_isFrenchInterface ? 'Inconnu' : 'غير معروف'),
            matiereName: classAndMatiereNames['matiereName'] ??
                (_isFrenchInterface ? 'Inconnu' : 'غير معروف'),
            baremeName: baremeName,
            sousBaremeName: sousBaremeName,
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de la navigation vers la page de classification : $e');
      _showErrorSnackbar(
          _getTranslatedText('خطأ في التنقل', 'Erreur lors de la navigation'));
    }
  }
Future<List<Map<String, dynamic>>> _getBaremesValues(
    List<QueryDocumentSnapshot> selectedBaremes) async {
  final List<Map<String, dynamic>> result = [];
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  for (final baremeDoc in selectedBaremes) {
    final baremeId = baremeDoc.id;
    final baremeData = baremeDoc.data() as Map<String, dynamic>;
    
    // CORRECTION : Récupérer correctement le nom du barème
    final baremeName = baremeData['baremeName'] ?? baremeData['value'] ?? 'غير معروف';
    final isBaremeSelected = baremeData['selected'] ?? false;

    // CORRECTION : Récupérer les sous-barèmes
    final sousBaremesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('selections')
        .doc(widget.selectedClass)
        .collection(widget.selectedMatiere)
        .doc(baremeId)
        .collection('sousBaremes')
        .get();

    if (isBaremeSelected) {
      result.add({
        'id': baremeId,
        'value': _isFrenchInterface
            ? DataTranslator.translateBareme(baremeName)
            : baremeName,
        'originalValue': baremeName,
        'sousBaremes': [],
      });
    }

    // CORRECTION : Traiter les sous-barèmes
    for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
      final sousBaremeData = sousBaremeDoc.data() as Map<String, dynamic>;
      final isSousBaremeSelected = sousBaremeData['selected'] ?? false;
      final sousBaremeName = sousBaremeData['sousBaremeName'] ?? 'غير معروف';

      if (isSousBaremeSelected) {
        result.add({
          'id': sousBaremeDoc.id,
          'value': _isFrenchInterface
              ? DataTranslator.translateSousBareme(sousBaremeName)
              : sousBaremeName,
          'originalValue': sousBaremeName,
          'parentBaremeId': baremeId,
        });
      }
    }
  }
  
  return result;
}


}

// MODIFICATION : Ajouter le paramètre isFrenchInterface à StudentsTable
class StudentsTable extends StatefulWidget {
  final String classDocId;
  final String selectedClass;
  final String selectedMatiere;
  final User currentUser;
  final Map<String, int> sumCriteriaMaxPerBareme;
  final int totalStudents;
  final Function(String, {String? sousBaremeId}) navigateToClassificationPage;
  final bool isFrenchInterface; // Nouveau paramètre

  const StudentsTable({
    Key? key,
    required this.classDocId,
    required this.selectedClass,
    required this.selectedMatiere,
    required this.currentUser,
    required this.sumCriteriaMaxPerBareme,
    required this.totalStudents,
    required this.navigateToClassificationPage,
    required this.isFrenchInterface, // Nouveau paramètre
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
  final Map<String, Color> _headerColors = {};

  // États pour gérer le loading des boutons
  final Map<String, bool> _classificationLoadingStates = {};
  final Map<String, bool> _treatmentPlanLoadingStates = {};

  // Variables pour le cache des données
  List<QueryDocumentSnapshot>? _cachedStudents;
  List<QueryDocumentSnapshot>? _cachedSelections;
  bool _isMounted = false;

  // Couleurs modernes pour l'UI
  final Color _primaryColor = const Color(0xFF2E7D32);
  final Color _secondaryColor = const Color(0xFF4CAF50);
  final Color _accentColor = const Color(0xFF8BC34A);
  final Color _backgroundColor = const Color(0xFFF5F5F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF333333);
  final Color _borderColor = const Color(0xFFE0E0E0);

  // MODIFICATION : Méthode de traduction
  String _getTranslatedText(String arabicText, String frenchText) {
    return widget.isFrenchInterface ? frenchText : arabicText;
  }

  Color _getRandomColor() {
    final List<Color> predefinedColors = [
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFF009688),
      Color(0xFF795548),
      Color(0xFF607D8B),
    ];
    return predefinedColors[Random().nextInt(predefinedColors.length)];
  }

  // Fonction pour trier les barèmes par ordre alphabétique
  List<Map<String, dynamic>> _sortBaremesAlphabetically(
      List<Map<String, dynamic>> baremesValues) {
    baremesValues.sort((a, b) {
      String nameA = a['value'] ?? '';
      String nameB = b['value'] ?? '';
      return nameA.compareTo(nameB);
    });
    return baremesValues;
  }

  // Fonction modifiée pour grouper les barèmes triés
  // CORRECTION : Méthode groupBaremes sécurisée
  Map<String, List<Map<String, dynamic>>> groupBaremes(
      List<Map<String, dynamic>> baremesValues) {
    List<Map<String, dynamic>> sortedBaremes =
        _sortBaremesAlphabetically(baremesValues);
    Map<String, List<Map<String, dynamic>>> groupedBaremes = {};

    for (var bareme in sortedBaremes) {
      String baremeValue = bareme['value'] ?? '';
      String type = bareme['type'] ?? 'bareme';

      String key;
      if (type == 'sousBareme') {
        // Pour les sous-barèmes, utiliser le parent comme clé de groupe
        String parentId = bareme['parentBaremeId'] ?? '';
        key = parentId.isNotEmpty ? parentId : 'sousBaremes';
      } else {
        // Pour les barèmes principaux, utiliser les premiers caractères
        if (baremeValue.length >= 2) {
          key = baremeValue.substring(0, 2);
        } else if (baremeValue.isNotEmpty) {
          key = baremeValue;
        } else {
          key = 'autre';
        }
      }

      if (!groupedBaremes.containsKey(key)) {
        groupedBaremes[key] = [];
      }

      // CORRECTION: S'assurer qu'on n'ajoute pas les mêmes barèmes plusieurs fois
      bool alreadyExists = groupedBaremes[key]!
          .any((existingBareme) => existingBareme['id'] == bareme['id']);

      if (!alreadyExists) {
        groupedBaremes[key]!.add(bareme);
      }
    }

    return groupedBaremes;
  }

  // Fonction pour déterminer si c'est un barème principal ou sous-barème
  String _getBaremeDisplayName(
      Map<String, dynamic> bareme, Map<String, dynamic> subEntry) {
    String type = subEntry['type'] ?? 'bareme';

    if (type == 'sousBareme') {
      // Pour les sous-barèmes, afficher seulement le nom du sous-barème
      return subEntry['value'];
    } else {
      // Pour les barèmes principaux
      return bareme['value'];
    }
  }

  // Générer une clé unique pour chaque bouton
  String _getButtonKey(
      String baremeId, String? sousBaremeId, bool isClassification) {
    return '${baremeId}_${sousBaremeId ?? 'main'}_${isClassification ? 'classification' : 'treatment'}';
  }

  // Fonction pour démarrer le loading d'un bouton
  void _startLoading(String buttonKey, bool isClassification) {
    if (_isMounted) {
      setState(() {
        if (isClassification) {
          _classificationLoadingStates[buttonKey] = true;
        } else {
          _treatmentPlanLoadingStates[buttonKey] = true;
        }
      });
    }
  }

  // Fonction pour arrêter le loading d'un bouton
  void _stopLoading(String buttonKey, bool isClassification) {
    if (_isMounted) {
      setState(() {
        if (isClassification) {
          _classificationLoadingStates[buttonKey] = false;
        } else {
          _treatmentPlanLoadingStates[buttonKey] = false;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadStudentsOnce();
    _loadSelectionsOnce();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  // Méthode pour charger les étudiants une fois
  Future<void> _loadStudentsOnce() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(widget.classDocId)
          .collection('students')
          .get();

      if (_isMounted) {
        setState(() {
          _cachedStudents = snapshot.docs;
        });
      }
    } catch (e) {
      print('Erreur chargement étudiants: $e');
    }
  }

  // Méthode pour charger les sélections une fois
  Future<void> _loadSelectionsOnce() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      if (_isMounted) {
        setState(() {
          _cachedSelections = snapshot.docs;
        });
      }
    } catch (e) {
      print('Erreur chargement sélections: $e');
    }
  }

  // Méthode pour rafraîchir les données manuellement
  Future<void> _refreshData() async {
    await _loadStudentsOnce();
    await _loadSelectionsOnce();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_backgroundColor, Colors.white],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 16),
          Expanded(
            child: _buildContentWithCachedData(),
          ),
        ],
      ),
    );
  }

  // Nouvelle méthode pour utiliser les données en cache
  Widget _buildContentWithCachedData() {
    if (_cachedStudents == null) {
      return _buildLoadingIndicator();
    }

    if (_cachedStudents!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSelectionsTable(_cachedStudents!);
  }

  Widget _buildHeader() {
    return FutureBuilder<Map<String, String>>(
      future: _getClassAndMatiereNames(),
      builder: (context, snapshot) {
        String className = widget.isFrenchInterface ? 'Inconnu' : 'غير معروف';
        String matiereName = widget.isFrenchInterface ? 'Inconnu' : 'غير معروف';

        if (snapshot.connectionState == ConnectionState.waiting) {
          className =
              widget.isFrenchInterface ? 'Chargement...' : 'جاري التحميل...';
          matiereName =
              widget.isFrenchInterface ? 'Chargement...' : 'جاري التحميل...';
        } else if (snapshot.hasData) {
          className = snapshot.data!['className'] ??
              (widget.isFrenchInterface ? 'Inconnu' : 'غير معروف');
          matiereName = snapshot.data!['matiereName'] ??
              (widget.isFrenchInterface ? 'Inconnu' : 'غير معروف');
        }

        return Card(
          elevation: 3,
          margin: EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _refreshData,
                  tooltip: _getTranslatedText(
                      'تحديث البيانات', 'Rafraîchir les données'),
                ),
                SizedBox(width: 12),
                Icon(Icons.school, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTranslatedText(
                            'جدول التقييم', 'Tableau d\'évaluation'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$className - $matiereName',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.totalStudents} ' +
                        _getTranslatedText('تلميذ', 'élèves'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _getClassAndMatiereNames() async {
    try {
      // Récupérer le nom de la classe
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();
      var className = classDoc['name'] ?? 'غير معروف';

      // Récupérer le nom de la matière
      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();
      var matiereName = matiereDoc['name'] ?? 'غير معروف';

      // Traduire si l'interface est en français
      if (widget.isFrenchInterface) {
        className = DataTranslator.translateClass(className);
        matiereName = DataTranslator.translateMatiere(matiereName);
      }

      return {
        'className': className,
        'matiereName': matiereName,
      };
    } catch (e) {
      return {
        'className': widget.isFrenchInterface ? 'Inconnu' : 'غير معروف',
        'matiereName': widget.isFrenchInterface ? 'Inconnu' : 'غير معروف',
      };
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            _getTranslatedText(
                'جاري تحميل البيانات...', 'Chargement des données...'),
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(
            error,
            textDirection: widget.isFrenchInterface
                ? TextDirection.ltr
                : TextDirection.rtl,
            style: TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, color: Colors.grey, size: 64),
          SizedBox(height: 16),
          Text(
            _getTranslatedText(
                'لم يتم العثور على أي تلميذ.', 'Aucun élève trouvé.'),
            textDirection: widget.isFrenchInterface
                ? TextDirection.ltr
                : TextDirection.rtl,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionsTable(List<QueryDocumentSnapshot> studentsDocs) {
    if (_cachedSelections == null) {
      return _buildLoadingIndicator();
    }

    if (_cachedSelections!.isEmpty) {
      return _buildEmptyStateForCriteria();
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getBaremesValues(_cachedSelections!),
      builder: (context, baremesValuesSnapshot) {
        if (baremesValuesSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        if (baremesValuesSnapshot.hasError) {
          return _buildErrorWidget(
              '${_getTranslatedText('خطأ:', 'Erreur:')} ${baremesValuesSnapshot.error}');
        }
        if (!baremesValuesSnapshot.hasData ||
            baremesValuesSnapshot.data!.isEmpty) {
          return _buildEmptyStateForCriteria();
        }

        return _buildDataTable(studentsDocs, baremesValuesSnapshot.data!);
      },
    );
  }

  Widget _buildEmptyStateForCriteria() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, color: Colors.grey, size: 64),
          SizedBox(height: 16),
          Text(
            _getTranslatedText(
                'لم يتم العثور على أي معيار.', 'Aucun critère trouvé.'),
            textDirection: widget.isFrenchInterface
                ? TextDirection.ltr
                : TextDirection.rtl,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> studentsDocs,
      List<Map<String, dynamic>> baremesValues) {
    Map<String, List<Map<String, dynamic>>> groupedBaremes =
        groupBaremes(baremesValues);

    // DEBUG: Afficher le contenu de sumCriteriaMaxPerBareme
    print('=== STATISTIQUES DISPONIBLES ===');
    widget.sumCriteriaMaxPerBareme.forEach((key, value) {
      print('$key: $value');
    });

    // DEBUG: Afficher la structure des barèmes
    print('=== STRUCTURE DES BARÈMES POUR AFFICHAGE ===');
    groupedBaremes.forEach((key, baremes) {
      print('Groupe: $key');
      for (var bareme in baremes) {
        print(
            '  Barème: ${bareme['id']} - ${bareme['value']} - Type: ${bareme['type']}');
        if (bareme['type'] == 'bareme' && bareme['sousBaremes'] != null) {
          for (var sousBareme in (bareme['sousBaremes'] as List)) {
            print(
                '    Sous-barème: ${sousBareme['id']} - ${sousBareme['value']}');
          }
        }
      }
    });

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              dataRowColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return _accentColor.withOpacity(0.2);
                  }
                  return Colors.transparent;
                },
              ),
              columns: [
                DataColumn(
                  label: Container(
                    width: 160,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getTranslatedText('الاسم واللقب', 'Nom et prénom'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                // CORRECTION: Construction des colonnes simplifiée
                ..._buildTableColumns(groupedBaremes),
              ],
              rows: [
                ..._buildStudentRows(studentsDocs, groupedBaremes),
                _buildStatsRow(
                    _getTranslatedText('عدد التلاميذ المحققين',
                        'Nombre d\'élèves ayant atteint'),
                    groupedBaremes,
                    isPercentage: false),
                _buildStatsRow(
                    _getTranslatedText('النسبة المئوية', 'Pourcentage'),
                    groupedBaremes,
                    isPercentage: true),
                ..._buildButtonRows(groupedBaremes),
              ],
            ),
          ),
        ),
      ),
    );
  }

// NOUVELLE MÉTHODE: Construction des colonnes
  List<DataColumn> _buildTableColumns(
      Map<String, List<Map<String, dynamic>>> groupedBaremes) {
    List<DataColumn> columns = [];

    for (var entry in groupedBaremes.entries) {
      for (final bareme in entry.value) {
        if (bareme['type'] == 'bareme') {
          // Barème principal
          columns.add(DataColumn(
            label: _buildColumnHeader(bareme['value'], entry.key),
          ));

          // Sous-barèmes de ce barème
          for (final sousBareme
              in (bareme['sousBaremes'] as List<dynamic>? ?? [])) {
            columns.add(DataColumn(
              label: _buildColumnHeader(sousBareme['value'], entry.key),
            ));
          }
        } else {
          // Sous-barème seul
          columns.add(DataColumn(
            label: _buildColumnHeader(bareme['value'], entry.key),
          ));
        }
      }
    }

    return columns;
  }

// NOUVELLE MÉTHODE: Construction de l'en-tête de colonne
  Widget _buildColumnHeader(String title, String groupKey) {
    return Container(
      width: 110,
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _headerColors.putIfAbsent(groupKey, () => _getRandomColor()),
            _headerColors[groupKey]!.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

// NOUVELLE MÉTHODE: Construction des lignes étudiants
  List<DataRow> _buildStudentRows(List<QueryDocumentSnapshot> studentsDocs,
      Map<String, List<Map<String, dynamic>>> groupedBaremes) {
    return studentsDocs.asMap().entries.map((entry) {
      final index = entry.key;
      final studentDoc = entry.value;
      final studentId = studentDoc.id;
      final studentName =
          studentDoc['name'] ?? _getTranslatedText('غير معروف', 'Inconnu');

      return DataRow(
        color: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return index.isEven
                ? _backgroundColor.withOpacity(0.3)
                : Colors.transparent;
          },
        ),
        cells: [
          DataCell(_buildStudentNameCell(studentName)),
          ..._buildStudentCells(studentId, groupedBaremes),
        ],
      );
    }).toList();
  }

// NOUVELLE MÉTHODE: Cellule nom étudiant
  Widget _buildStudentNameCell(String studentName) {
    return Container(
      width: 160,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              studentName,
              textDirection: widget.isFrenchInterface
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

// NOUVELLE MÉTHODE: Cellules des barèmes pour un étudiant
  List<DataCell> _buildStudentCells(String studentId,
      Map<String, List<Map<String, dynamic>>> groupedBaremes) {
    List<DataCell> cells = [];

    for (var entry in groupedBaremes.entries) {
      for (final bareme in entry.value) {
        if (bareme['type'] == 'bareme') {
          // Barème principal
          cells.add(DataCell(_buildMarkCell(studentId, bareme['id'])));

          // Sous-barèmes
          for (final sousBareme
              in (bareme['sousBaremes'] as List<dynamic>? ?? [])) {
            cells.add(DataCell(_buildMarkCell(studentId, sousBareme['id'])));
          }
        } else {
          // Sous-barème seul
          cells.add(DataCell(_buildMarkCell(studentId, bareme['id'])));
        }
      }
    }

    return cells;
  }

// NOUVELLE MÉTHODE: Cellule de note
  Widget _buildMarkCell(String studentId, String baremeKey) {
    return Container(
      width: 110,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<String>(
        future: _getSelectedValue(studentId, baremeKey),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            );
          }
          final value = snapshot.data ?? _dropdownValues[0];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _getValueColor(value).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _getValueColor(value).withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: _getValueColor(value),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

// NOUVELLE MÉTHODE: Lignes de boutons
  List<DataRow> _buildButtonRows(
      Map<String, List<Map<String, dynamic>>> groupedBaremes) {
    return [
      _buildButtonRow(_getTranslatedText('تصنيف', 'Classer'), Colors.green,
          Colors.yellow, groupedBaremes,
          isClassification: true),
      _buildButtonRow(_getTranslatedText('خطة العلاج', 'Plan de traitement'),
          Colors.blue, Colors.white, groupedBaremes,
          isClassification: false),
    ];
  }

  Color _getValueColor(String value) {
    switch (value) {
      case '( + + + )':
        return Colors.green;
      case '( + + - )':
        return Colors.orange;
      case '( + - - )':
        return Colors.orangeAccent;
      case '( - - - )':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  DataRow _buildStatsRow(
      String title, Map<String, List<Map<String, dynamic>>> groupedBaremes,
      {required bool isPercentage}) {
    return DataRow(
      color: MaterialStateProperty.all(_primaryColor.withOpacity(0.05)),
      cells: [
        DataCell(
          Container(
            width: 160,
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
        ),
        for (var entry in groupedBaremes.entries)
          for (final bareme in entry.value)
            if (bareme['type'] == 'bareme')
              // Barème principal avec ses sous-barèmes
              for (final subEntry in [
                {'id': bareme['id'], 'type': 'bareme'},
                ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
              ])
                DataCell(
                  Container(
                    width: 110,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPercentage
                            ? _secondaryColor.withOpacity(0.1)
                            : _accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: _buildStatValue(subEntry['id'], isPercentage),
                      ),
                    ),
                  ),
                )
            else
              // Sous-barème seul
              DataCell(
                Container(
                  width: 110,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPercentage
                          ? _secondaryColor.withOpacity(0.1)
                          : _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: _buildStatValue(bareme['id'], isPercentage),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

// CORRECTION : Méthode améliorée pour afficher les statistiques
  Widget _buildStatValue(String baremeKey, bool isPercentage) {
    // DEBUG: Afficher la clé recherchée
    print('🔍 Recherche statistique pour: $baremeKey');

    // Rechercher la valeur dans sumCriteriaMaxPerBareme
    int? count = widget.sumCriteriaMaxPerBareme[baremeKey];

    // Si non trouvé, essayer de chercher avec différentes variations de la clé
    if (count == null) {
      // Essayer de trouver la clé dans les statistiques disponibles
      for (var key in widget.sumCriteriaMaxPerBareme.keys) {
        if (key.contains(baremeKey) || baremeKey.contains(key)) {
          count = widget.sumCriteriaMaxPerBareme[key];
          print('🔄 Clé trouvée avec variation: $key -> $count');
          break;
        }
      }
    }

    // Si toujours null, utiliser 0
    count ??= 0;

    print(
        '📊 Statistique finale - Clé: $baremeKey, Valeur: $count, Pourcentage: $isPercentage');

    if (isPercentage) {
      if (widget.totalStudents == 0) {
        return Text(
          _getTranslatedText('لا توجد درجات', 'Pas de notes'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _secondaryColor,
            fontSize: 12,
          ),
        );
      } else {
        final percentage = (count / widget.totalStudents * 100);
        return Text(
          '${percentage.toStringAsFixed(2)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _secondaryColor,
            fontSize: 12,
          ),
        );
      }
    } else {
      return Text(
        count.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _accentColor,
          fontSize: 12,
        ),
      );
    }
  }

  DataRow _buildButtonRow(String buttonText, Color backgroundColor,
      Color textColor, Map<String, List<Map<String, dynamic>>> groupedBaremes,
      {required bool isClassification}) {
    return DataRow(
      cells: [
        DataCell(Container()),
        for (var entry in groupedBaremes.entries)
          for (final bareme in entry.value)
            for (final subEntry in [
              {'id': bareme['id'], 'type': 'bareme', 'name': bareme['value']},
              ...(bareme['sousBaremes'] as List<dynamic>? ?? []).map((s) =>
                  {'id': s['id'], 'type': 'sousBareme', 'name': s['value']})
            ])
              DataCell(
                Container(
                  width: 110,
                  height: 48,
                  padding: EdgeInsets.all(4),
                  child: _buildLoadingButton(
                    bareme: bareme,
                    subEntry: subEntry,
                    buttonText: buttonText,
                    backgroundColor: backgroundColor,
                    textColor: textColor,
                    isClassification: isClassification,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildLoadingButton({
    required Map<String, dynamic> bareme,
    required Map<String, dynamic> subEntry,
    required String buttonText,
    required Color backgroundColor,
    required Color textColor,
    required bool isClassification,
  }) {
    final String buttonKey = _getButtonKey(
      bareme['id']!,
      subEntry['type'] == 'sousBareme' ? subEntry['id'] : null,
      isClassification,
    );

    final bool isLoading = isClassification
        ? _classificationLoadingStates[buttonKey] ?? false
        : _treatmentPlanLoadingStates[buttonKey] ?? false;

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () async {
              _startLoading(buttonKey, isClassification);
              try {
                if (isClassification) {
                  await _classifyStudentsByBarem(
                    bareme['id']!,
                    sousBaremeId: subEntry['type'] == 'sousBareme'
                        ? subEntry['id']
                        : null,
                  );
                } else {
                  await widget.navigateToClassificationPage(
                    bareme['id']!,
                    sousBaremeId: subEntry['type'] == 'sousBareme'
                        ? subEntry['id']
                        : null,
                  );
                }
              } catch (e) {
                print('Erreur: $e');
                if (_isMounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${_getTranslatedText('حدث خطأ:', 'Erreur:')} $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                _stopLoading(buttonKey, isClassification);
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isLoading ? Colors.grey : backgroundColor,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          : Text(
              buttonText,
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
    );
  }

  Future<List<Map<String, dynamic>>> _getBaremesValues(
      List<QueryDocumentSnapshot> selectedBaremes) async {
    final List<Map<String, dynamic>> result = [];
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    for (final baremeDoc in selectedBaremes) {
      final baremeId = baremeDoc['baremeId'];
      final baremeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .get();

      final isBaremeSelected = baremeSnapshot['selected'] ?? false;
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

      if (isBaremeSelected) {
        final baremeName = baremeSnapshot['baremeName'] ??
            _getTranslatedText('غير معروف', 'Inconnu');
        result.add({
          'id': baremeId,
          'value': baremeName,
          'sousBaremes': [],
        });
      } else if (selectedSousBaremes.isNotEmpty) {
        for (final sousBareme in selectedSousBaremes) {
          final sousBaremeName = sousBareme['sousBaremeName'] ??
              _getTranslatedText('غير معروف', 'Inconnu');
          result.add({
            'id': sousBareme.id,
            'value': sousBaremeName,
            'parentBaremeId': baremeId,
          });
        }
      }
    }
    return result;
  }

  Future<String> _getSelectedValue(String studentId, String baremeKey) async {
    try {
      // Vérifier si c'est un sous-barème (contient un tiret)
      if (baremeKey.contains('-')) {
        var parts = baremeKey.split('-');
        var baremeId = parts[0];
        var sousBaremeId = parts[1];

        var sousBaremeDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .collection('user_classes')
            .doc(widget.classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeId)
            .collection('sous_baremes')
            .doc(sousBaremeId)
            .get();

        if (sousBaremeDoc.exists) {
          return sousBaremeDoc.data()?['Marks']?.toString() ??
              _dropdownValues[0];
        }
      } else {
        // C'est un barème principal
        var baremeDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .collection('user_classes')
            .doc(widget.classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeKey)
            .get();

        if (baremeDoc.exists) {
          return baremeDoc.data()?['Marks']?.toString() ?? _dropdownValues[0];
        }
      }

      return _dropdownValues[0];
    } catch (e) {
      print('Erreur récupération valeur pour $baremeKey: $e');
      return _dropdownValues[0];
    }
  }

  Future<void> _classifyStudentsByBarem(String baremeId,
      {String? sousBaremeId}) async {
    try {
      var studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(widget.classDocId)
          .collection('students')
          .get();

      Map<String, List<String>> studentGroups = {
        _getTranslatedText('مجموعة العلاج', 'Groupe de traitement'): [],
        _getTranslatedText('مجموعة الدعم', 'Groupe de soutien'): [],
        _getTranslatedText('مجموعة التميز', 'Groupe d\'excellence'): [],
      };

      for (var studentDoc in studentsSnapshot.docs) {
        var studentId = studentDoc.id;
        var studentName = studentDoc['name'] ??
            _getTranslatedText('اسم غير معروف', 'Nom inconnu');

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
          if (value == '( + + + )') {
            studentGroups[_getTranslatedText(
                    'مجموعة التميز', 'Groupe d\'excellence')]!
                .add(studentName);
          } else if (value == '( + + - )') {
            studentGroups[
                    _getTranslatedText('مجموعة الدعم', 'Groupe de soutien')]!
                .add(studentName);
          } else if (value == '( + - - )' || value == '( - - - )') {
            studentGroups[_getTranslatedText(
                    'مجموعة العلاج', 'Groupe de traitement')]!
                .add(studentName);
          }
        }
      }

      if (_isMounted) {
        _showClassificationDialog(studentGroups);
      }
    } catch (e) {
      print('Erreur lors de la classification des élèves: $e');
      rethrow;
    }
  }

  void _showClassificationDialog(Map<String, List<String>> studentGroups) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;

        final dialogWidth = screenWidth * (isPortrait ? 0.9 : 0.7);
        final dialogMaxHeight = screenHeight * 0.8;
        final titleFontSize = screenWidth * 0.045;
        final groupTitleFontSize = screenWidth * 0.035;
        final studentFontSize = screenWidth * 0.03;

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: dialogMaxHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getTranslatedText(
                            'تصنيف التلاميذ', 'Classification des élèves'),
                        style: TextStyle(
                          fontSize: titleFontSize.clamp(18, 24),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...[
                            _getTranslatedText(
                                'مجموعة التميز', 'Groupe d\'excellence'),
                            _getTranslatedText(
                                'مجموعة الدعم', 'Groupe de soutien'),
                            _getTranslatedText(
                                'مجموعة العلاج', 'Groupe de traitement')
                          ].map((groupName) {
                            return _buildResponsiveGroupCard(
                              groupName,
                              studentGroups[groupName]!,
                              groupTitleFontSize: groupTitleFontSize,
                              studentFontSize: studentFontSize,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade300)),
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(screenWidth * 0.3, 50),
                        ),
                        child: Text(
                          _getTranslatedText('إغلاق', 'Fermer'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize.clamp(16, 20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveGroupCard(
    String groupName,
    List<String> students, {
    required double groupTitleFontSize,
    required double studentFontSize,
  }) {
    Color cardColor;
    Color textColor;

    if (groupName.contains(_getTranslatedText('التميز', 'excellence')) ||
        groupName.contains('excellence')) {
      cardColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
    } else if (groupName.contains(_getTranslatedText('الدعم', 'soutien')) ||
        groupName.contains('soutien')) {
      cardColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
    } else {
      cardColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          title: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: textColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  groupName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: groupTitleFontSize.clamp(14, 18),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  students.length.toString(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: groupTitleFontSize.clamp(12, 16),
                  ),
                ),
              ),
            ],
          ),
          children: students.map((student) {
            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person,
                    color: textColor.withOpacity(0.7), size: 16),
              ),
              title: Text(
                student,
                style: TextStyle(
                  color: _textColor,
                  fontSize: studentFontSize.clamp(12, 16),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
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
                child: Text(value),
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
