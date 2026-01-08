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
import 'package:Taqyem/taqyem/tableausduident.dart';
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

// Cache Manager
class FirestoreCache {
  static final FirestoreCache _instance = FirestoreCache._internal();
  factory FirestoreCache() => _instance;
  FirestoreCache._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = Duration(minutes: 10);
  
  T? getFromCache<T>(String key) {
    if (_cache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheDuration) {
        return _cache[key] as T;
      } else {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
    return null;
  }
  
  void addToCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }
  
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
  
  void removeFromCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }
}

// Optimized Firestore Helper
class FirestoreHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirestoreCache _cache = FirestoreCache();
  
  static Future<DocumentSnapshot> getUserDocument(String userId, {bool forceRefresh = false}) async {
    final cacheKey = 'user_$userId';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<DocumentSnapshot>(cacheKey);
      if (cached != null) return cached;
    }
    
    final doc = await _firestore.collection('Users').doc(userId).get();
    _cache.addToCache(cacheKey, doc);
    return doc;
  }
  
  static Future<QuerySnapshot> getCollectionWithCache(String collectionPath, 
      {String? cacheKey, bool forceRefresh = false}) async {
    final key = cacheKey ?? collectionPath.replaceAll('/', '_');
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<QuerySnapshot>(key);
      if (cached != null) return cached;
    }
    
    final snapshot = await _firestore.collection(collectionPath).get();
    _cache.addToCache(key, snapshot);
    return snapshot;
  }
  
  static Future<DocumentSnapshot> getDocumentWithCache(String collectionPath, String docId,
      {String? cacheKey, bool forceRefresh = false}) async {
    final key = cacheKey ?? '${collectionPath}_$docId';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<DocumentSnapshot>(key);
      if (cached != null) return cached;
    }
    
    final doc = await _firestore.collection(collectionPath).doc(docId).get();
    _cache.addToCache(key, doc);
    return doc;
  }
  
  static Future<List<DocumentSnapshot>> getSubcollectionWithCache(String parentPath, String parentId,
      String subcollection, {String? cacheKey, bool forceRefresh = false}) async {
    final key = cacheKey ?? '${parentPath}_$parentId$subcollection';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<List<DocumentSnapshot>>(key);
      if (cached != null) return cached;
    }
    
    final snapshot = await _firestore
        .collection(parentPath)
        .doc(parentId)
        .collection(subcollection)
        .get();
    
    _cache.addToCache(key, snapshot.docs);
    return snapshot.docs;
  }
  
  static void invalidateCache(String key) {
    _cache.removeFromCache(key);
  }
  
  static void invalidateAllCache() {
    _cache.clearCache();
  }
}

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

  static List<String> sortClassesByNumericalOrder(List<String> classes) {
    return List<String>.from(classes)
      ..sort((a, b) {
        final orderA = _getClassOrder(a);
        final orderB = _getClassOrder(b);

        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }

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

  static final List<String> _foreignMatieres = [
    "Expression orale et récitation",
    "Lecture",
    "Production écrite",
    "écriture",
    "dictée",
    "langue",
    "لغة انقليزية"
  ];

  static bool isForeignMatiere(String matiereName) {
    return _foreignMatieres.contains(matiereName);
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
  String _selectedEvaluationDisplay = 'character';
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
  
  // Cache pour les données fréquemment utilisées
  Map<String, dynamic> _criteriaCache = {};
  Map<String, dynamic> _studentsCache = {};
  Map<String, dynamic> _baremesCache = {};
  String? _lastClassMatiereKey;
  
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

  @override
  void dispose() {
    _isMounted = false;
    _accountStatusTimer?.cancel();
    _userSubscription?.cancel();
    FirestoreCache().clearCache();
    super.dispose();
  }

  String _getDomaineForMatiere(String matiereName, bool isFrenchInterface) {
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
    
    final domaines = isFrenchInterface ? domainesFrench : domainesArabic;

    for (var key in domaines.keys) {
      if (matiereName.contains(key) || key.contains(matiereName)) {
        return domaines[key]!;
      }
    }

    return isFrenchInterface ? 'Domaine Général' : 'المجال العام';
  }

  Map<String, Map<String, String>> _getEvaluationDisplayOptions() {
    return {
      'character': {
        'ar': 'حرفي',
        'fr': 'Caractère',
        'description_ar': '( - - - ), ( + - - ), ( + + - ), ( + + + )',
        'description_fr': '( - - - ), ( + - - ), ( + + - ), ( + + + )'
      },
      '1.3': {
        'ar': 'نظام 0-1.5',
        'fr': 'Système 0-1.5',
        'description_ar': '0, 0.5, 1, 1.5',
        'description_fr': '0, 0.5, 1, 1.5'
      },
      '0.6': {
        'ar': 'نظام 0-6',
        'fr': 'Système 0-6',
        'description_ar': '0, 2, 4, 6',
        'description_fr': '0, 2, 4, 6'
      },
      'costum': {
        'ar': 'مخصص',
        'fr': 'Personnalisé',
        'description_ar': 'تقييم مخصص',
        'description_fr': 'Évaluation personnalisée'
      },
      'ext': {
        'ar': 'مفصل',
        'fr': 'Détaillé',
        'description_ar': '( - - - ), ( + - - ), ( + + - ), ( + + + )',
        'description_fr': '( - - - ), ( + - - ), ( + + - ), ( + + + )'
      },
    };
  }

  String _getMappedEvaluation(String displayValue, String system,
      {List<String>? customNotes}) {
    if (system == 'custom' && customNotes != null && customNotes.isNotEmpty) {
      final index = customNotes.indexOf(displayValue);
      if (index == -1) return '( - - - )';
      if (index == 0) return '( - - - )';
      if (index == customNotes.length - 1) return '( + + + )';
      if (index <= customNotes.length ~/ 2) return '( + - - )';
      return '( + + - )';
    }

    switch (system) {
      case 'character':
        return displayValue;

      case 'note_0_1_5':
        switch (displayValue) {
          case '0':
            return '( - - - )';
          case '0.5':
            return '( + - - )';
          case '1':
            return '( + + - )';
          case '1.5':
            return '( + + + )';
          default:
            return '( - - - )';
        }

      case 'note_0_3':
        switch (displayValue) {
          case '0':
            return '( - - - )';
          case '1':
            return '( + - - )';
          case '2':
            return '( + + - )';
          case '3':
            return '( + + + )';
          default:
            return '( - - - )';
        }

      case 'note_0_6':
        switch (displayValue) {
          case '0':
            return '( - - - )';
          case '2':
            return '( + - - )';
          case '4':
            return '( + + - )';
          case '6':
            return '( + + + )';
          default:
            return '( - - - )';
        }

      default:
        return '( - - - )';
    }
  }

  String _getDisplayEvaluation(String storedValue, String system,
      {List<String>? customNotes}) {
    if (storedValue == 'غائب') {
      return 'غائب';
    }

    if (system == 'custom' && customNotes != null && customNotes.isNotEmpty) {
      if (storedValue == '( - - - )') return customNotes[0];
      if (storedValue == '( + - - )') {
        return customNotes.length > 1 ? customNotes[1] : customNotes[0];
      }
      if (storedValue == '( + + - )') {
        if (customNotes.length == 3) return customNotes[1];
        if (customNotes.length >= 3) return customNotes[2];
        return customNotes.isNotEmpty ? customNotes.last : '( + + - )';
      }
      if (storedValue == '( + + + )') return customNotes.last;
      return customNotes[0];
    }

    switch (system) {
      case 'character':
        return storedValue;

      case 'note_0_1_5':
        switch (storedValue) {
          case '( - - - )':
            return '0';
          case '( + - - )':
            return '0.5';
          case '( + + - )':
            return '1';
          case '( + + + )':
            return '1.5';
          default:
            return '0';
        }

      case 'note_0_3':
        switch (storedValue) {
          case '( - - - )':
            return '0';
          case '( + - - )':
            return '1';
          case '( + + - )':
            return '2';
          case '( + + + )':
            return '3';
          default:
            return '0';
        }

      case 'note_0_6':
        switch (storedValue) {
          case '( - - - )':
            return '0';
          case '( + - - )':
            return '2';
          case '( + + - )':
            return '4';
          case '( + + + )':
            return '6';
          default:
            return '0';
        }

      default:
        return storedValue;
    }
  }

  Future<String> _getEvaluationSystem(String classId, String matiereId) async {
    try {
      final cacheKey = 'eval_system_$classId-$matiereId';
      final cached = FirestoreCache().getFromCache<String>(cacheKey);
      if (cached != null) return cached;
      
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 'character';

      final systemDoc = await FirestoreHelper.getDocumentWithCache(
        'users/${currentUser.uid}/evaluation_systems',
        '$classId-$matiereId',
        cacheKey: cacheKey
      );

      String system = 'character';
      if (systemDoc.exists) {
        system = systemDoc['system'] ?? 'character';
      }
      
      FirestoreCache().addToCache(cacheKey, system);
      return system;
    } catch (e) {
      print('Erreur lors de la récupération du système: $e');
      return 'character';
    }
  }

  Future<List<String>> _loadCustomNotes(String classId, String matiereId) async {
    try {
      final cacheKey = 'custom_notes_$classId-$matiereId';
      final cached = FirestoreCache().getFromCache<List<String>>(cacheKey);
      if (cached != null) return cached;
      
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final doc = await FirestoreHelper.getDocumentWithCache(
        'users/${currentUser.uid}/custom_notes',
        '$classId-$matiereId',
        cacheKey: cacheKey
      );

      List<String> notes = [];
      if (doc.exists && (doc.data() as Map<String, dynamic>)['notes'] != null) {
        notes = List<String>.from((doc.data() as Map<String, dynamic>)['notes']);
      }
      
      FirestoreCache().addToCache(cacheKey, notes);
      return notes;
    } catch (e) {
      print('Erreur lors du chargement des notes personnalisées: $e');
      return [];
    }
  }

  void _showCompleteReportDialog() {
    TextEditingController periodeController =
        TextEditingController(text: _selectedPeriode);
    TextEditingController performanceAttendueController =
        TextEditingController();

    final trimestreOptions = ['الأول', 'الثاني', 'الثالث'];
    final trimestreTranslations = {
      'الأول': 'Premier',
      'الثاني': 'Deuxième',
      'الثالث': 'Troisième'
    };

    final evaluationOptions = ['تقييم', 'امتحان'];
    final evaluationTranslations = {'تقييم': 'Évaluation', 'امتحان': 'Examen'};

    String className = '';
    String matiereName = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> loadClassAndMatiereNames() async {
              try {
                // Utiliser FirestoreHelper avec cache
                var classDoc = await FirestoreHelper.getDocumentWithCache(
                  'classes',
                  widget.selectedClass,
                  cacheKey: 'class_${widget.selectedClass}'
                );
                
                String arabicClassName = classDoc['name'] ?? 'غير معروف';
                className = _isFrenchInterface
                    ? DataTranslator.translateClass(arabicClassName)
                    : arabicClassName;

                var matiereDoc = await FirestoreHelper.getDocumentWithCache(
                  'classes/${widget.selectedClass}/matieres',
                  widget.selectedMatiere,
                  cacheKey: 'matiere_${widget.selectedClass}_${widget.selectedMatiere}'
                );
                
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
                                _getTranslatedText(
                                    '(محدد تلقائياً من الصفحة الحالية)',
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
                                _getTranslatedText(
                                    '(محدد تلقائياً من الصفحة الحالية)',
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
                                    _getTranslatedText(
                                        'ملخص التقرير:', 'Résumé du Rapport:'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[800],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${_getTranslatedText('الثلاثي', 'Trimestre')}: ${_isFrenchInterface ? trimestreTranslations[_selectedTrimestre] ?? _selectedTrimestre : _selectedTrimestre}',
                                    style: TextStyle(color: Colors.purple[800]),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${_getTranslatedText('الفترة', 'Période')}: ${periodeController.text.isNotEmpty ? periodeController.text : _getTranslatedText('غير محدد', 'Non spécifié')}',
                                    style: TextStyle(color: Colors.purple[800]),
                                  ),
                                  SizedBox(height: 2),
                                  if (performanceAttendueController
                                      .text.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                              if (performanceAttendueController.text.isNotEmpty)
                                _buildReportContentItem('5. الأداء المنتظر',
                                    '5. Performance attendue'),
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
                            performanceAttendue: performanceAttendueController
                                .text
                                .trim(),
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

  Future<void> _generateCompleteReport(
    String classId,
    String matiereId,
    String className,
    String matiereName, {
    String performanceAttendue = '',
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

      // Vérifier le cache pour les critères
      final cacheKey = 'criteria_${classId}_$matiereId';
      List<Map<String, dynamic>> criteria;
      
      if (_criteriaCache.containsKey(cacheKey)) {
        criteria = List<Map<String, dynamic>>.from(_criteriaCache[cacheKey]);
      } else {
        criteria = await _getCriteriaFromJson(
            classId, matiereId, className, matiereName);
        _criteriaCache[cacheKey] = criteria;
      }

      final matiereDisplayName = _isFrenchInterface
          ? DataTranslator.translateMatiere(matiereName)
          : matiereName;
      final classDisplayName = _isFrenchInterface
          ? DataTranslator.translateClass(className)
          : className;

      final String evaluationSystem =
          await _getEvaluationSystem(classId, matiereId);
      final List<String> customNotes =
          await _loadCustomNotes(classId, matiereId);

      // Utiliser cache pour les barèmes
      final baremesCacheKey = 'baremes_report_${classId}_$matiereId';
      List<dynamic> baremes;
      
      if (_baremesCache.containsKey(baremesCacheKey)) {
        baremes = List<dynamic>.from(_baremesCache[baremesCacheKey]!);
      } else {
        baremes = await _getBaremesForCompleteReport(classId, matiereId);
        _baremesCache[baremesCacheKey] = baremes;
      }

      // Utiliser cache pour les étudiants
      final studentsCacheKey = 'students_report_${classId}_$matiereId';
      List<dynamic> students;
      
      if (_studentsCache.containsKey(studentsCacheKey)) {
        students = List<dynamic>.from(_studentsCache[studentsCacheKey]!);
      } else {
        students = await _getStudentsForCompleteReport(
          classId,
          matiereId,
          evaluationSystem: evaluationSystem,
          customNotes: customNotes,
        );
        _studentsCache[studentsCacheKey] = students;
      }

      final Map<String, int> sumCriteriaMaxPerBareme = {};
      int totalStudents = students.length;

      for (var bareme in baremes) {
        final baremeId = bareme['id'].toString();
        sumCriteriaMaxPerBareme[baremeId] = 0;
      }

      for (var student in students) {
        final studentBaremes = student['baremes'] as Map<String, dynamic>;

        for (var bareme in baremes) {
          final baremeId = bareme['id'].toString();
          final storedValue =
              studentBaremes[baremeId]?.toString() ?? '( - - - )';

          bool isAchieved = _isValueAchieved(
            storedValue,
            evaluationSystem,
            customNotes: customNotes,
          );

          if (isAchieved) {
            sumCriteriaMaxPerBareme[baremeId] =
                (sumCriteriaMaxPerBareme[baremeId] ?? 0) + 1;
          }
        }
      }

      if (baremes.isEmpty) {
        _showErrorSnackbar(_getTranslatedText(
            'Aucun barème sélectionné pour cette évaluation.',
            'No criteria selected for this evaluation.'));
        return;
      }

      if (students.isEmpty) {
        _showErrorSnackbar(_getTranslatedText(
            'Aucun élève trouvé pour cette classe.',
            'No students found for this class.'));
        return;
      }

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
        performanceAttendue: performanceAttendue,
      );

      await _deductPrintCredit();

      _showSuccessSnackbar(_getTranslatedText('تم إنشاء التقرير الكامل بنجاح',
          'Complete report generated successfully'));
    } catch (e, stackTrace) {
      print('❌ ERREUR FATALE dans _generateCompleteReport: $e');
      print('Stack trace: $stackTrace');

      _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء التقرير الكامل',
              'Error generating complete report') +
          ': ${e.toString()}');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });

      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<List<dynamic>> _getBaremesForCompleteReport(
      String classId, String matiereId) async {
    try {
      final cacheKey = 'baremes_complete_${classId}_$matiereId';
      final cached = FirestoreCache().getFromCache<List<dynamic>>(cacheKey);
      if (cached != null) return cached;
      
      final baremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
        'users/${currentUser!.uid}/selections',
        classId,
        matiereId,
        cacheKey: cacheKey
      );

      final List<dynamic> baremes = [];

      for (final baremeDoc in baremesSnapshot) {
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
            'parentBaremeId': null,
          });
        }

        final sousBaremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
          'users/${currentUser!.uid}/selections/${classId}/${matiereId}',
          baremeId,
          'sousBaremes',
          cacheKey: 'sousBaremes_${baremeId}'
        );

        for (final sousBaremeDoc in sousBaremesSnapshot) {
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

      FirestoreCache().addToCache(cacheKey, baremes);
      return baremes;
    } catch (e) {
      print('❌ Erreur récupération barèmes rapport complet: $e');
      return [];
    }
  }

  bool _isValueAchieved(String storedValue, String evaluationSystem,
      {List<String>? customNotes}) {
    if (storedValue == 'غائب') {
      return false;
    }

    switch (evaluationSystem) {
      case 'character':
        return storedValue == '( + + + )' || storedValue == '( + + - )';

      case 'note_0_1_5':
        try {
          final displayValue =
              _getDisplayEvaluation(storedValue, evaluationSystem);
          final doubleValue = double.tryParse(displayValue) ?? 0;
          return doubleValue >= 1.0;
        } catch (e) {
          return false;
        }

      case 'note_0_3':
        try {
          final displayValue =
              _getDisplayEvaluation(storedValue, evaluationSystem);
          final doubleValue = double.tryParse(displayValue) ?? 0;
          return doubleValue >= 2;
        } catch (e) {
          return false;
        }

      case 'note_0_6':
        try {
          final displayValue =
              _getDisplayEvaluation(storedValue, evaluationSystem);
          final doubleValue = double.tryParse(displayValue) ?? 0;
          return doubleValue >= 4;
        } catch (e) {
          return false;
        }

      case 'custom':
        if (customNotes != null && customNotes.isNotEmpty) {
          final Map<String, String> mapping = {
            '( - - - )': customNotes[0],
            '( + - - )':
                customNotes.length > 1 ? customNotes[1] : customNotes[0],
            '( + + - )':
                customNotes.length > 2 ? customNotes[2] : customNotes.last,
            '( + + + )': customNotes.last,
          };

          final String correspondingNote =
              mapping[storedValue] ?? customNotes[0];
          final int noteIndex = customNotes.indexOf(correspondingNote);

          return noteIndex >= customNotes.length - 2;
        }
        return storedValue == '( + + + )' || storedValue == '( + + - )';

      default:
        return storedValue == '( + + + )' || storedValue == '( + + - )';
    }
  }

  Future<List<dynamic>> _getStudentsForCompleteReport(
    String classId,
    String matiereId, {
    required String evaluationSystem,
    required List<String> customNotes,
  }) async {
    try {
      final cacheKey = 'students_complete_${classId}_$matiereId';
      final cached = FirestoreCache().getFromCache<List<dynamic>>(cacheKey);
      if (cached != null) return cached;
      
      final studentsSnapshot = await FirestoreHelper.getSubcollectionWithCache(
        'users/${currentUser!.uid}/user_classes',
        classId,
        'students',
        cacheKey: 'students_$classId'
      );

      final List<dynamic> students = [];

      for (final studentDoc in studentsSnapshot) {
        final studentId = studentDoc.id;
        final studentName = _getFieldSafe(studentDoc, 'name',
            _isFrenchInterface ? 'Élève inconnu' : 'تلميذ غير معروف');

        final baremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
          'users/${currentUser!.uid}/user_classes/$classId/students',
          studentId,
          'baremes',
          cacheKey: 'student_baremes_${studentId}'
        );

        final Map<String, String> baremes = {};

        for (final baremeDoc in baremesSnapshot) {
          final baremeId = baremeDoc.id;
          final storedValue = _getFieldSafe(baremeDoc, 'Marks', '( - - - )');

          final String displayValue = storedValue;
          baremes[baremeId] = displayValue;

          final sousBaremesSnapshot = await baremeDoc.reference.collection('sous_baremes').get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousStoredValue =
                _getFieldSafe(sousBaremeDoc, 'Marks', '( - - - )');

            final String sousDisplayValue = sousStoredValue;
            baremes['$baremeId-$sousBaremeId'] = sousDisplayValue;
          }
        }

        students.add({
          'id': studentId,
          'name': studentName,
          'baremes': baremes,
        });
      }

      students.sort((a, b) {
        String nameA = a['name'] ?? '';
        String nameB = b['name'] ?? '';

        if (!_isFrenchInterface && nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
          return _arabicStringComparator(nameA, nameB);
        }

        return nameA.compareTo(nameB);
      });

      FirestoreCache().addToCache(cacheKey, students);
      return students;
    } catch (e) {
      print('❌ Erreur récupération étudiants rapport complet: $e');
      return [];
    }
  }

  Future<List<dynamic>> _getStudentsForReport(
      String classId, String matiereId) async {
    try {
      final String evaluationSystem =
          await _getEvaluationSystem(classId, matiereId);
      final List<String> customNotes =
          await _loadCustomNotes(classId, matiereId);

      final studentsSnapshot = await FirestoreHelper.getSubcollectionWithCache(
        'users/${currentUser!.uid}/user_classes',
        classId,
        'students',
        cacheKey: 'students_report_$classId'
      );

      final List<dynamic> students = [];
      for (final studentDoc in studentsSnapshot) {
        final studentId = studentDoc.id;
        final studentName = _getFieldSafe(studentDoc, 'name',
            _isFrenchInterface ? 'Élève inconnu' : 'تلميذ غير معروف');

        final baremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
          'users/${currentUser!.uid}/user_classes/$classId/students',
          studentId,
          'baremes',
          cacheKey: 'student_baremes_${studentId}'
        );

        final Map<String, String> baremes = {};
        for (final baremeDoc in baremesSnapshot) {
          final baremeId = baremeDoc.id;
          final storedValue = _getFieldSafe(baremeDoc, 'Marks', '( - - - )');

          final displayValue = _getDisplayEvaluation(
            storedValue,
            evaluationSystem,
            customNotes: customNotes,
          );

          baremes[baremeId] = displayValue;

          final sousBaremesSnapshot =
              await baremeDoc.reference.collection('sous_baremes').get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousStoredValue =
                _getFieldSafe(sousBaremeDoc, 'Marks', '( - - - )');

            final sousDisplayValue = _getDisplayEvaluation(
              sousStoredValue,
              evaluationSystem,
              customNotes: customNotes,
            );

            baremes['$baremeId-$sousBaremeId'] = sousDisplayValue;
          }
        }

        students.add({
          'id': studentId,
          'name': studentName,
          'baremes': baremes,
        });
      }

      students.sort((a, b) {
        String nameA = a['name'] ?? '';
        String nameB = b['name'] ?? '';

        if (!_isFrenchInterface && nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
          return _arabicStringComparator(nameA, nameB);
        }

        return nameA.compareTo(nameB);
      });

      return students;
    } catch (e) {
      print('Erreur récupération étudiants: $e');
      return [];
    }
  }

  Future<List<dynamic>> _getBaremesForReport(
      String classId, String matiereId) async {
    try {
      final String evaluationSystem =
          await _getEvaluationSystem(classId, matiereId);
      final List<String> customNotes =
          await _loadCustomNotes(classId, matiereId);

      final baremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
        'users/${currentUser!.uid}/selections',
        classId,
        matiereId,
        cacheKey: 'baremes_report_${classId}_$matiereId'
      );

      final List<dynamic> baremes = [];
      for (final baremeDoc in baremesSnapshot) {
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
            'evaluationSystem': evaluationSystem,
            'customNotes': customNotes,
          });
        }

        final sousBaremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
          'users/${currentUser!.uid}/selections/${classId}/${matiereId}',
          baremeId,
          'sousBaremes',
          cacheKey: 'sousBaremes_${baremeId}'
        );

        for (final sousBaremeDoc in sousBaremesSnapshot) {
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
              'evaluationSystem': evaluationSystem,
              'customNotes': customNotes,
            });
          }
        }
      }

      return baremes;
    } catch (e) {
      print('Erreur récupération barèmes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getSummaryForReport(
      String classId, String matiereId) async {
    try {
      final studentsSnapshot = await FirestoreHelper.getSubcollectionWithCache(
        'users/${currentUser!.uid}/user_classes',
        classId,
        'students',
        cacheKey: 'students_summary_$classId'
      );

      final totalStudents = studentsSnapshot.length;
      final Map<String, int> sumCriteriaMaxPerBareme = {};

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

    final trimestreOptions = ['الأول', 'الثاني', 'الثالث'];
    final trimestreTranslations = {
      'الأول': 'Premier',
      'الثاني': 'Deuxième',
      'الثالث': 'Troisième'
    };

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
              onConfirm();
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
      final userDoc = await FirestoreHelper.getUserDocument(currentUser!.uid);

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
      final userDoc = await FirestoreHelper.getUserDocument(currentUser!.uid);

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
      final userDoc = await FirestoreHelper.getUserDocument(currentUser!.uid);

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

  String _getTranslatedText(String arabicText, String frenchText) {
    return _isFrenchInterface ? frenchText : arabicText;
  }

  Future<void> _saveAndOpenPDF(Uint8List pdfBytes) async {
    try {
      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'tableau_resultats.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
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

      final matiereName = await _getMatiereName();
      final className = await _getClassName();

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

      await HTMLReportGenerator.generateAndDownloadReport(
        profName: _profName,
        matiereName: matiereName,
        className: className,
        schoolName: _schoolName,
        baremes: data['baremes'] as List<dynamic>,
        students: data['students'] as List<dynamic>,
        sumCriteriaMaxPerBareme: sumCriteriaMaxPerBareme,
        totalStudents: totalStudents,
        isFrenchInterface: _isFrenchInterface,
        downloadAsPDF: downloadAsPDF,
        trimestre: _selectedTrimestre,
        periode: _selectedPeriode,
        evaluationType: _selectedEvaluationType,
      );

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
        'trimestre': _selectedTrimestre,
        'periode': _selectedPeriode,
        'evaluationType': _selectedEvaluationType,
      };

      if (type == 'pdf') {
        success = await _sendDataToFlask(data);
      } else {
        success = await _sendHTMLDataToFlask(data);
      }

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
      Map<String, dynamic> dataForServer = Map.from(data);

      if (data['baremes'] != null) {
        List<dynamic> originalBaremes = [];
        for (var bareme in data['baremes']) {
          Map<String, dynamic> originalBareme = Map.from(bareme);
          if (bareme['originalValue'] != null) {
            originalBareme['value'] = bareme['originalValue'];
          }
          originalBaremes.add(originalBareme);
        }
        dataForServer['baremes'] = originalBaremes;
      }

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
        return true;
      } else {
        _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء التقرير HTML:',
                'Erreur lors de la génération du rapport HTML:') +
            ' ${response.statusCode}');
        return false;
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
      final userDoc = await FirestoreHelper.getUserDocument(currentUser!.uid);

      if (!userDoc.exists) return;

      final bool isActive = _getFieldSafe(userDoc, 'isActive', false);
      final int remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);

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

  Future<String> _getMatiereName() async {
    try {
      var matiereDoc = await FirestoreHelper.getDocumentWithCache(
        'classes/${widget.selectedClass}/matieres',
        widget.selectedMatiere,
        cacheKey: 'matiere_${widget.selectedClass}_${widget.selectedMatiere}'
      );

      String arabicName = _getFieldSafe(matiereDoc, 'name', 'غير معروف');
      return _isFrenchInterface
          ? DataTranslator.translateMatiere(arabicName)
          : arabicName;
    } catch (e) {
      return _isFrenchInterface ? 'Inconnu' : 'غير معروف';
    }
  }

  Future<String> _getClassName() async {
    try {
      var classDoc = await FirestoreHelper.getDocumentWithCache(
        'classes',
        widget.selectedClass,
        cacheKey: 'class_${widget.selectedClass}'
      );

      String arabicName = _getFieldSafe(classDoc, 'name', 'غير معروف');
      return _isFrenchInterface
          ? DataTranslator.translateClass(arabicName)
          : arabicName;
    } catch (e) {
      return _isFrenchInterface ? 'Inconnu' : 'غير معروف';
    }
  }

  Future<List<dynamic>> _getBaremes() async {
    try {
      final cacheKey = 'baremes_${widget.selectedClass}_${widget.selectedMatiere}';
      final cached = FirestoreCache().getFromCache<List<dynamic>>(cacheKey);
      if (cached != null) return cached;
      
      final baremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
        'users/${currentUser!.uid}/selections',
        widget.selectedClass,
        widget.selectedMatiere,
        cacheKey: cacheKey
      );

      final List<dynamic> baremes = [];
      for (final baremeDoc in baremesSnapshot) {
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

        final sousBaremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
          'users/${currentUser!.uid}/selections/${widget.selectedClass}/${widget.selectedMatiere}',
          baremeId,
          'sousBaremes',
          cacheKey: 'sousBaremes_${baremeId}'
        );

        for (final sousBaremeDoc in sousBaremesSnapshot) {
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

      FirestoreCache().addToCache(cacheKey, baremes);
      return baremes;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> _getStudents() async {
    try {
      final cacheKey = 'students_${widget.selectedClass}';
      final cached = FirestoreCache().getFromCache<List<dynamic>>(cacheKey);
      if (cached != null) return cached;
      
      final studentsSnapshot = await FirestoreHelper.getSubcollectionWithCache(
        'users/${currentUser!.uid}/user_classes',
        widget.selectedClass,
        'students',
        cacheKey: cacheKey
      );

      final List<dynamic> students = [];
      for (final studentDoc in studentsSnapshot) {
        final studentId = studentDoc.id;
        final studentName = _getFieldSafe(studentDoc, 'name',
            _isFrenchInterface ? 'Élève inconnu' : 'تلميذ غير معروف');

        final baremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
          'users/${currentUser!.uid}/user_classes/${widget.selectedClass}/students',
          studentId,
          'baremes',
          cacheKey: 'student_baremes_${studentId}'
        );

        final Map<String, String> baremes = {};
        for (final baremeDoc in baremesSnapshot) {
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

      students.sort((a, b) {
        String nameA = a['name'] ?? '';
        String nameB = b['name'] ?? '';

        if (!_isFrenchInterface && nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
          return _arabicStringComparator(nameA, nameB);
        }

        return nameA.compareTo(nameB);
      });

      FirestoreCache().addToCache(cacheKey, students);
      return students;
    } catch (e) {
      return [];
    }
  }

  void _loadUserData() async {
    if (currentUser != null && _isMounted) {
      try {
        var userDoc = await FirestoreHelper.getUserDocument(currentUser!.uid);

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

      // Vérifier le cache pour les étudiants
      final studentsCacheKey = 'students_marks_${widget.selectedClass}';
      List<DocumentSnapshot> studentsSnapshot;
      
      final cachedStudents = FirestoreCache().getFromCache<List<DocumentSnapshot>>(studentsCacheKey);
      if (cachedStudents != null) {
        studentsSnapshot = cachedStudents;
      } else {
        final snapshot = await FirestoreHelper.getSubcollectionWithCache(
          'users/${currentUser.uid}/user_classes',
          widget.selectedClass,
          'students',
          cacheKey: studentsCacheKey
        );
        studentsSnapshot = snapshot;
      }

      if (_isMounted) {
        setState(() {
          totalStudents = studentsSnapshot.length;
        });
      }

      // Vérifier le cache pour les barèmes sélectionnés
      final baremesCacheKey = 'selected_baremes_${widget.selectedClass}_${widget.selectedMatiere}';
      List<DocumentSnapshot> selectedBaremes;
      
      final cachedBaremes = FirestoreCache().getFromCache<List<DocumentSnapshot>>(baremesCacheKey);
      if (cachedBaremes != null) {
        selectedBaremes = cachedBaremes;
      } else {
        final snapshot = await FirestoreHelper.getSubcollectionWithCache(
          'users/${currentUser.uid}/selections',
          widget.selectedClass,
          widget.selectedMatiere,
          cacheKey: baremesCacheKey
        );
        selectedBaremes = snapshot;
      }

      sumCriteriaMaxPerBareme.clear();

      print('=== DEBUG fetchMarks ===');
      print('Total étudiants: $totalStudents');
      print('Barèmes sélectionnés: ${selectedBaremes.length}');

      for (var baremeDoc in selectedBaremes) {
        var baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
        var isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

        if (isBaremeSelected) {
          sumCriteriaMaxPerBareme[baremeId] = 0;
        }

        var sousBaremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
          'users/${currentUser.uid}/selections/${widget.selectedClass}/${widget.selectedMatiere}',
          baremeId,
          'sousBaremes',
          cacheKey: 'sousBaremes_marks_${baremeId}'
        );
        
        for (var sousBaremeDoc in sousBaremesSnapshot) {
          var isSousBaremeSelected =
              _getFieldSafe(sousBaremeDoc, 'selected', false);
          if (isSousBaremeSelected) {
            var sousBaremeId = sousBaremeDoc.id;
            var sousBaremeKey = '$baremeId-$sousBaremeId';
            sumCriteriaMaxPerBareme[sousBaremeKey] = 0;
          }
        }
      }

      final String evaluationSystem = await _getEvaluationSystem(
          widget.selectedClass, widget.selectedMatiere);
      final List<String> customNotes =
          await _loadCustomNotes(widget.selectedClass, widget.selectedMatiere);

      print('Système d\'évaluation: $evaluationSystem');
      print('Notes personnalisées: $customNotes');

      // Utiliser des requêtes batch pour récupérer les notes
      for (var studentDoc in studentsSnapshot) {
        var studentId = studentDoc.id;

        for (var baremeDoc in selectedBaremes) {
          var baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
          var isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

          if (isBaremeSelected) {
            final baremeCacheKey = 'student_marks_${studentId}_$baremeId';
            final cachedMarks = FirestoreCache().getFromCache<DocumentSnapshot>(baremeCacheKey);
            
            DocumentSnapshot baremeSnapshot;
            if (cachedMarks != null) {
              baremeSnapshot = cachedMarks;
            } else {
              baremeSnapshot = await FirestoreHelper.getDocumentWithCache(
                'users/${currentUser.uid}/user_classes/${widget.selectedClass}/students/${studentId}/baremes',
                baremeId,
                cacheKey: baremeCacheKey
              );
            }

            if (baremeSnapshot.exists) {
              var storedValue =
                  _getFieldSafe(baremeSnapshot, 'Marks', '( - - - )');

              final displayValue = _getDisplayEvaluation(
                storedValue,
                evaluationSystem,
                customNotes: customNotes,
              );

              if (evaluationSystem.startsWith('note_')) {
                try {
                  final doubleValue = double.tryParse(displayValue) ?? 0;
                  if (doubleValue > 0) {
                    sumCriteriaMaxPerBareme[baremeId] =
                        (sumCriteriaMaxPerBareme[baremeId] ?? 0) + 1;
                  }
                } catch (e) {
                  print('  ❌ ERREUR conversion note: $e');
                }
              } else if (evaluationSystem == 'character') {
                if (storedValue == '( + + + )' || storedValue == '( + + - )') {
                  sumCriteriaMaxPerBareme[baremeId] =
                      (sumCriteriaMaxPerBareme[baremeId] ?? 0) + 1;
                }
              } else if (evaluationSystem == 'custom' && customNotes.isNotEmpty) {
                final Map<String, String> mapping = {
                  '( - - - )': customNotes[0],
                  '( + - - )':
                      customNotes.length > 1 ? customNotes[1] : customNotes[0],
                  '( + + - )': customNotes.length > 2
                      ? customNotes[2]
                      : customNotes.last,
                  '( + + + )': customNotes.last,
                };

                final String correspondingNote =
                    mapping[storedValue] ?? customNotes[0];
                final int noteIndex = customNotes.indexOf(correspondingNote);

                if (noteIndex > 0) {
                  sumCriteriaMaxPerBareme[baremeId] =
                      (sumCriteriaMaxPerBareme[baremeId] ?? 0) + 1;
                }
              }
            }
          }

          var sousBaremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
            'users/${currentUser.uid}/selections/${widget.selectedClass}/${widget.selectedMatiere}',
            baremeId,
            'sousBaremes',
            cacheKey: 'sousBaremes_list_${baremeId}'
          );
          
          for (var sousBaremeDoc in sousBaremesSnapshot) {
            var isSousBaremeSelected =
                _getFieldSafe(sousBaremeDoc, 'selected', false);
            if (isSousBaremeSelected) {
              var sousBaremeId = sousBaremeDoc.id;
              var sousBaremeKey = '$baremeId-$sousBaremeId';

              final sousBaremeCacheKey = 'student_sous_marks_${studentId}_${sousBaremeId}';
              final cachedSousMarks = FirestoreCache().getFromCache<DocumentSnapshot>(sousBaremeCacheKey);
              
              DocumentSnapshot sousBaremeSnapshot;
              if (cachedSousMarks != null) {
                sousBaremeSnapshot = cachedSousMarks;
              } else {
                sousBaremeSnapshot = await FirestoreHelper.getDocumentWithCache(
                  'users/${currentUser.uid}/user_classes/${widget.selectedClass}/students/${studentId}/baremes/${baremeId}/sous_baremes',
                  sousBaremeId,
                  cacheKey: sousBaremeCacheKey
                );
              }

              if (sousBaremeSnapshot.exists) {
                var storedValue =
                    _getFieldSafe(sousBaremeSnapshot, 'Marks', '( - - - )');

                final displayValue = _getDisplayEvaluation(
                  storedValue,
                  evaluationSystem,
                  customNotes: customNotes,
                );

                if (evaluationSystem.startsWith('note_')) {
                  try {
                    final doubleValue = double.tryParse(displayValue) ?? 0;
                    if (doubleValue > 0) {
                      sumCriteriaMaxPerBareme[sousBaremeKey] =
                          (sumCriteriaMaxPerBareme[sousBaremeKey] ?? 0) + 1;
                    }
                  } catch (e) {
                    print('  ❌ ERREUR conversion note sous-barème: $e');
                  }
                } else if (evaluationSystem == 'character') {
                  if (storedValue == '( + + + )' ||
                      storedValue == '( + + - )') {
                    sumCriteriaMaxPerBareme[sousBaremeKey] =
                        (sumCriteriaMaxPerBareme[sousBaremeKey] ?? 0) + 1;
                  }
                } else if (evaluationSystem == 'custom' &&
                    customNotes.isNotEmpty) {
                  final Map<String, String> mapping = {
                    '( - - - )': customNotes[0],
                    '( + - - )': customNotes.length > 1
                        ? customNotes[1]
                        : customNotes[0],
                    '( + + - )': customNotes.length > 2
                        ? customNotes[2]
                        : customNotes.last,
                    '( + + + )': customNotes.last,
                  };

                  final String correspondingNote =
                      mapping[storedValue] ?? customNotes[0];
                  final int noteIndex = customNotes.indexOf(correspondingNote);

                  if (noteIndex > 0) {
                    sumCriteriaMaxPerBareme[sousBaremeKey] =
                        (sumCriteriaMaxPerBareme[sousBaremeKey] ?? 0) + 1;
                  }
                }
              }
            }
          }
        }
      }

      sumCriteriaMaxPerBareme.forEach((key, value) {
        if (totalStudents > 0) {
          final percentage = (value / totalStudents * 100).toStringAsFixed(2);
          print('$key: $value/$totalStudents = $percentage%');
        } else {
          print('$key: $value/0 = N/A%');
        }
      });

      if (_isMounted) {
        setState(() {});
      }
    } catch (e) {
      print('Erreur lors de la récupération des marques : $e');
    }
  }

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
                _showCompleteReportDialog();
              } else if (value == 'baremes_table') {
                _showClassAndMatiereSelectionDialog();
              } else {
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

              Expanded(
                child: _buildMainContent(),
              ),

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
      var classDoc = await FirestoreHelper.getDocumentWithCache(
        'classes',
        widget.selectedClass,
        cacheKey: 'class_name_${widget.selectedClass}'
      );
      
      var className = classDoc['name'] ?? 'غير معروف';

      var matiereDoc = await FirestoreHelper.getDocumentWithCache(
        'classes/${widget.selectedClass}/matieres',
        widget.selectedMatiere,
        cacheKey: 'matiere_name_${widget.selectedClass}_${widget.selectedMatiere}'
      );
      
      var matiereName = matiereDoc['name'] ?? 'غير معروف';

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

  void _navigateToClassificationPage(String baremeId,
      {String? sousBaremeId}) async {
    try {
      var classAndMatiereNames = await _getClassAndMatiereNames();

      var selectedBaremes = await FirestoreHelper.getSubcollectionWithCache(
        'users/${currentUser!.uid}/selections',
        widget.selectedClass,
        widget.selectedMatiere,
        cacheKey: 'baremes_nav_${widget.selectedClass}_${widget.selectedMatiere}'
      );

      List<Map<String, dynamic>> baremesValues =
          await _getBaremesValues(selectedBaremes);

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
      List<DocumentSnapshot> selectedBaremes) async {
    final List<Map<String, dynamic>> result = [];
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    for (final baremeDoc in selectedBaremes) {
      final baremeId = baremeDoc.id;
      final baremeData = baremeDoc.data() as Map<String, dynamic>;

      final baremeName =
          baremeData['baremeName'] ?? baremeData['value'] ?? 'غير معروف';
      final isBaremeSelected = baremeData['selected'] ?? false;

      final sousBaremesSnapshot = await FirestoreHelper.getSubcollectionWithCache(
        'users/${userId}/selections/${widget.selectedClass}/${widget.selectedMatiere}',
        baremeId,
        'sousBaremes',
        cacheKey: 'sousBaremes_values_${baremeId}'
      );

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

      for (final sousBaremeDoc in sousBaremesSnapshot) {
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

  void _detectLanguage() async {
    try {
      var matiereDoc = await FirestoreHelper.getDocumentWithCache(
        'classes/${widget.selectedClass}/matieres',
        widget.selectedMatiere,
        cacheKey: 'matiere_lang_${widget.selectedClass}_${widget.selectedMatiere}'
      );

      String matiereName = matiereDoc['name'] ?? '';

      bool isFrenchInterface;

      if (DataTranslator.isForeignMatiere(matiereName)) {
        isFrenchInterface = true;
      } else {
        final containsFrench =
            matiereName.contains(RegExp(r'[a-zA-Zéèêëàâäôöûüç]'));
        final containsArabic = matiereName.contains(RegExp(r'[\u0600-\u06FF]'));

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

  void _showClassAndMatiereSelectionDialog() {
    TextEditingController classSearchController = TextEditingController();
    TextEditingController matiereSearchController = TextEditingController();

    List<Map<String, dynamic>> filteredClasses = [];
    List<Map<String, dynamic>> filteredMatieres = [];

    Map<String, dynamic>? selectedClass;
    Map<String, dynamic>? selectedMatiere;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> loadClasses() async {
              try {
                final classesSnapshot = await FirestoreHelper.getCollectionWithCache(
                  'classes',
                  cacheKey: 'all_classes'
                );

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

            Future<void> loadMatieres(String classId) async {
              try {
                final matieresSnapshot = await FirestoreHelper.getSubcollectionWithCache(
                  'classes',
                  classId,
                  'matieres',
                  cacheKey: 'matieres_$classId'
                );

                List<Map<String, dynamic>> matieres = [];
                for (var matiereDoc in matieresSnapshot) {
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

  Future<void> _generateBaremesTableReport(
    String classId,
    String matiereId,
    String className,
    String matiereName,
  ) async {
    final normalizedClassName = _mapClassToJsonBase(className);

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

      final criteria = await _getCriteriaFromJson(
          classId, matiereId, className, matiereName);

      await HTMLReportGenerator.generateAndDownloadReport(
        profName: _profName,
        matiereName: matiereName,
        className: className,
        schoolName: _schoolName,
        baremes: [],
        students: [],
        sumCriteriaMaxPerBareme: {},
        totalStudents: 0,
        isFrenchInterface: _isFrenchInterface,
        downloadAsPDF: true,
        trimestre: _selectedTrimestre,
        periode: _selectedPeriode,
        evaluationType: _selectedEvaluationType,
        selectedClass: classId,
        criteria: criteria,
      );

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

  String _mapClassToJsonBase(String classNameWithSection) {
    final Map<String, String> classMapping = {
      'السنة الأولى ابتدائي': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي أ': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي ب': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي ج': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي د': 'السنة الأولى ابتدائي',

      'السنة الثانية ابتدائي': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي أ': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي ب': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي ج': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي د': 'السنة الثانية ابتدائي',

      'السنة الثالثة ابتدائي': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي أ': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي ب': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي ج': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي د': 'السنة الثالثة ابتدائي',

      'السنة الرابعة ابتدائي': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي أ': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي ب': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي ج': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي د': 'السنة الرابعة ابتدائي',

      'السنة الخامسة ابتدائي': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي أ': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي ب': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي ج': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي د': 'السنة الخامسة ابتدائي',

      'السنة السادسة ابتدائي': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي أ': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي ب': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي ج': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي د': 'السنة السادسة ابتدائي',
    };

    return classMapping[classNameWithSection] ?? classNameWithSection;
  }

  Future<List<Map<String, dynamic>>> _getCriteriaFromJson(
    String classId,
    String matiereId,
    String className,
    String matiereName,
  ) async {
    try {
      final cacheKey = 'criteria_json_${classId}_$matiereId';
      final cached = _criteriaCache[cacheKey];
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      
      print('🎯 ===== DEBUT RECHERCHE CRITERES JSON =====');
      print('📌 Paramètres d\'entrée:');
      print('   • Classe originale: "$className"');
      print('   • Matière: "$matiereName"');

      final String jsonClassName = _mapClassToJsonBase(className);
      print('🔄 Classe mappée pour JSON: "$jsonClassName"');

      final jsonString =
          await rootBundle.loadString('assets/evaluation_excel.json');
      final jsonData = json.decode(jsonString);

      if (!jsonData.containsKey('classes')) {
        print('❌ ERREUR: Clé "classes" non trouvée dans JSON');
        return [];
      }

      final classes = jsonData['classes'] as Map<String, dynamic>;
      print('📚 Classes disponibles dans JSON: ${classes.keys.length}');

      print('   Liste des classes JSON:');
      classes.keys.toList().sort();
      for (final key in classes.keys) {
        print('   • $key');
      }

      if (!classes.containsKey(jsonClassName)) {
        print('❌ ERREUR: Classe "$jsonClassName" non trouvée dans JSON');

        for (final key in classes.keys) {
          if (key.contains(jsonClassName) || jsonClassName.contains(key)) {
            print('   🔍 Correspondance trouvée: "$key"');
            final result = _extractCriteriaForClass(classes[key], matiereName);
            _criteriaCache[cacheKey] = result;
            return result;
          }
        }

        print('   ❌ Aucune correspondance trouvée');
        return [];
      }

      print('✅ SUCCES: Classe "$jsonClassName" trouvée dans JSON');

      final classData = classes[jsonClassName];
      final result = _extractCriteriaForClass(classData, matiereName);
      _criteriaCache[cacheKey] = result;
      return result;
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

      if (!classData.containsKey('subjects') ||
          classData['subjects'] is! Map<String, dynamic>) {
        print('❌ Clé "subjects" non trouvée ou invalide');
        return [];
      }

      final subjects = classData['subjects'] as Map<String, dynamic>;
      print('📖 Matières disponibles dans la classe: ${subjects.keys.length}');

      print('   Liste des matières:');
      for (final key in subjects.keys) {
        print('   • $key');
      }

      if (!subjects.containsKey(matiereName)) {
        print('❌ Matière "$matiereName" non trouvée');
        print('   Chercher des correspondances...');

        for (final key in subjects.keys) {
          if (key.contains(matiereName) || matiereName.contains(key)) {
            print('   ✅ Matière trouvée par correspondance: "$key"');
            return _processSubjectData(subjects[key], key);
          }
        }

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

      for (int i = 0; i < criteriaList.length; i++) {
        final criterion = criteriaList[i] as Map<String, dynamic>;
        print(
            '   ${i + 1}. ${criterion['name']} (${criterion['indicators_count'] ?? 0} indicateurs)');
      }

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

      final indicators = criterion['indicators'] as List<dynamic>? ?? [];

      final List<String> indicatorStrings = indicators
          .map((indicator) => indicator.toString())
          .where((indicator) => indicator.trim().isNotEmpty)
          .toList();

      indicatorStrings.sort(_arabicStringComparator);

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

    if (_isFrenchInterface) {
      criteria
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    } else {
      criteria.sort((a, b) => _arabicStringComparator(
            a['originalName'] as String,
            b['originalName'] as String,
          ));
    }

    for (int i = 0; i < criteria.length; i++) {
      criteria[i]['displayNumber'] = i + 1;
    }

    print('✅ ${criteria.length} critères traités avec succès');
    return criteria;
  }

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

  List<Map<String, dynamic>> _processCriteriaList(
      List<dynamic> criteriaList, String matiereName) {
    List<Map<String, dynamic>> criteria = [];

    for (int i = 0; i < criteriaList.length; i++) {
      final criteriaData = criteriaList[i] as Map<String, dynamic>;
      final criteriaName = criteriaData['name']?.toString() ?? 'معيار ${i + 1}';
      final indicators = criteriaData['indicators'] as List<dynamic>? ?? [];

      final List<String> indicatorStrings = indicators
          .map((indicator) => indicator.toString())
          .where(
              (indicator) => indicator.isNotEmpty)
          .toList();

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

    for (int i = 0; i < criteria.length; i++) {
      criteria[i]['displayNumber'] = i + 1;
    }

    return criteria;
  }

  String _extractArabicYear(String className) {
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

  int _arabicStringComparator(String a, String b) {
    final normalizedA = _normalizeArabicForSort(a);
    final normalizedB = _normalizeArabicForSort(b);

    const arabicAlphabet = 'اأإآبتثجحخدذرزسشصضطظعغفقكلمنهويىةؤئء';

    for (int i = 0; i < math.min(normalizedA.length, normalizedB.length); i++) {
      final charA = normalizedA[i];
      final charB = normalizedB[i];

      final indexA = arabicAlphabet.indexOf(charA);
      final indexB = arabicAlphabet.indexOf(charB);

      if (indexA != -1 && indexB != -1 && indexA != indexB) {
        return indexA - indexB;
      }

      if (charA != charB) {
        return charA.codeUnitAt(0) - charB.codeUnitAt(0);
      }
    }

    return normalizedA.length - normalizedB.length;
  }

  String _normalizeArabicForSort(String text) {
    String normalized = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

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

  String _generateArabicSortKey(String text) {
    final normalized = _normalizeArabicForSort(text);
    final withoutSpaces = normalized.replaceAll(' ', '');
    return withoutSpaces.toLowerCase();
  }
}