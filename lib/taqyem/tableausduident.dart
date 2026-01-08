import 'dart:math';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'tableau.dart';

// Cache Manager pour StudentsTable
class StudentsCacheManager {
  static final StudentsCacheManager _instance = StudentsCacheManager._internal();
  factory StudentsCacheManager() => _instance;
  StudentsCacheManager._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = Duration(minutes: 5);

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

  void invalidateStudentData(String userId, String classId) {
    final keysToRemove = _cache.keys.where((key) => 
      key.contains('students_$userId') && key.contains('_$classId')).toList();
    
    for (final key in keysToRemove) {
      removeFromCache(key);
    }
  }
}

// Firestore Helper optimisé pour StudentsTable
class StudentsFirestoreHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final StudentsCacheManager _cache = StudentsCacheManager();

  static Future<List<QueryDocumentSnapshot>> getStudentsWithCache(
    String userId, 
    String classDocId,
    {bool forceRefresh = false}
  ) async {
    final cacheKey = 'students_${userId}_$classDocId';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<List<QueryDocumentSnapshot>>(cacheKey);
      if (cached != null) return cached;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_classes')
        .doc(classDocId)
        .collection('students')
        .get();

    final List<QueryDocumentSnapshot> sortedDocs = snapshot.docs.toList();
    
    _cache.addToCache(cacheKey, sortedDocs);
    return sortedDocs;
  }

  static Future<List<QueryDocumentSnapshot>> getSelectionsWithCache(
    String userId,
    String selectedClass,
    String selectedMatiere,
    {bool forceRefresh = false}
  ) async {
    final cacheKey = 'selections_${userId}_${selectedClass}_$selectedMatiere';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<List<QueryDocumentSnapshot>>(cacheKey);
      if (cached != null) return cached;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('selections')
        .doc(selectedClass)
        .collection(selectedMatiere)
        .get();

    _cache.addToCache(cacheKey, snapshot.docs);
    return snapshot.docs;
  }

  static Future<DocumentSnapshot> getStudentMarksWithCache(
    String userId,
    String classDocId,
    String studentId,
    String baremeId,
    {bool forceRefresh = false}
  ) async {
    final cacheKey = 'marks_${userId}_${studentId}_$baremeId';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<DocumentSnapshot>(cacheKey);
      if (cached != null) return cached;
    }

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_classes')
        .doc(classDocId)
        .collection('students')
        .doc(studentId)
        .collection('baremes')
        .doc(baremeId)
        .get();

    _cache.addToCache(cacheKey, doc);
    return doc;
  }

  static Future<DocumentSnapshot> getSousBaremeMarksWithCache(
    String userId,
    String classDocId,
    String studentId,
    String baremeId,
    String sousBaremeId,
    {bool forceRefresh = false}
  ) async {
    final cacheKey = 'sousmarks_${userId}_${studentId}_${baremeId}_$sousBaremeId';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<DocumentSnapshot>(cacheKey);
      if (cached != null) return cached;
    }

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_classes')
        .doc(classDocId)
        .collection('students')
        .doc(studentId)
        .collection('baremes')
        .doc(baremeId)
        .collection('sous_baremes')
        .doc(sousBaremeId)
        .get();

    _cache.addToCache(cacheKey, doc);
    return doc;
  }

  static Future<Map<String, DocumentSnapshot>> getBulkStudentMarks(
    String userId,
    String classDocId,
    String studentId,
    List<String> baremeIds,
  ) async {
    final Map<String, DocumentSnapshot> results = {};
    final List<String> toFetch = [];

    // Vérifier le cache pour chaque bareme
    for (final baremeId in baremeIds) {
      final cacheKey = 'marks_${userId}_${studentId}_$baremeId';
      final cached = _cache.getFromCache<DocumentSnapshot>(cacheKey);
      if (cached != null) {
        results[baremeId] = cached;
      } else {
        toFetch.add(baremeId);
      }
    }

    // Récupérer uniquement ceux qui ne sont pas en cache
    if (toFetch.isNotEmpty) {
      final batch = _firestore.batch();
      final Map<String, DocumentReference> refs = {};

      for (final baremeId in toFetch) {
        final ref = _firestore
            .collection('users')
            .doc(userId)
            .collection('user_classes')
            .doc(classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeId);
        
        refs[baremeId] = ref;
        // Note: WriteBatch does not support 'get'. Use individual 'get' calls instead.
        final docSnapshot = await ref.get();
      }

      final snapshots = await batch.commit();
      
      // Note: batch.commit() ne retourne pas les résultats, nous devons faire des requêtes séparées
      // Alternative: Utiliser Future.wait pour récupérer en parallèle
      final futures = toFetch.map((baremeId) async {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('user_classes')
            .doc(classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeId)
            .get();
        
        final cacheKey = 'marks_${userId}_${studentId}_$baremeId';
        _cache.addToCache(cacheKey, doc);
        results[baremeId] = doc;
        return doc;
      }).toList();

      await Future.wait(futures);
    }

    return results;
  }

  static Future<DocumentSnapshot> getClassDocument(String classId, {bool forceRefresh = false}) async {
    final cacheKey = 'class_$classId';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<DocumentSnapshot>(cacheKey);
      if (cached != null) return cached;
    }

    final doc = await _firestore.collection('classes').doc(classId).get();
    _cache.addToCache(cacheKey, doc);
    return doc;
  }

  static Future<DocumentSnapshot> getMatiereDocument(
    String classId, 
    String matiereId,
    {bool forceRefresh = false}
  ) async {
    final cacheKey = 'matiere_${classId}_$matiereId';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<DocumentSnapshot>(cacheKey);
      if (cached != null) return cached;
    }

    final doc = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('matieres')
        .doc(matiereId)
        .get();

    _cache.addToCache(cacheKey, doc);
    return doc;
  }

  static Future<String> getEvaluationSystemWithCache(
    String userId,
    String classId,
    String matiereId,
    {bool forceRefresh = false}
  ) async {
    final cacheKey = 'eval_system_${userId}_${classId}_$matiereId';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<String>(cacheKey);
      if (cached != null) return cached;
    }

    final systemDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('evaluation_systems')
        .doc('$classId-$matiereId')
        .get();

    String system = 'character';
    if (systemDoc.exists) {
      system = systemDoc['system'] ?? 'character';
    }

    _cache.addToCache(cacheKey, system);
    return system;
  }

  static Future<List<String>> getCustomNotesWithCache(
    String userId,
    String classId,
    String matiereId,
    {bool forceRefresh = false}
  ) async {
    final cacheKey = 'custom_notes_${userId}_${classId}_$matiereId';
    
    if (!forceRefresh) {
      final cached = _cache.getFromCache<List<String>>(cacheKey);
      if (cached != null) return cached;
    }

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_notes')
        .doc('$classId-$matiereId')
        .get();

    List<String> notes = [];
    if (doc.exists && doc.data()?['notes'] != null) {
      notes = List<String>.from(doc.data()!['notes']);
    }

    _cache.addToCache(cacheKey, notes);
    return notes;
  }

  static void invalidateCacheForUser(String userId, String classId) {
    _cache.invalidateStudentData(userId, classId);
  }

  static void clearAllCache() {
    _cache.clearCache();
  }
}

// Classe utilitaire pour la traduction
class DataTranslator {
  static String translateClass(String arabicName) {
    final Map<String, String> translations = {
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
    return translations[arabicName] ?? arabicName;
  }

  static String translateMatiere(String arabicName) {
    final Map<String, String> translations = {
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
    return translations[arabicName] ?? arabicName;
  }
}

class StudentsTable extends StatefulWidget {
  final String classDocId;
  final String selectedClass;
  final String selectedMatiere;
  final User currentUser;
  final Map<String, int> sumCriteriaMaxPerBareme;
  final int totalStudents;
  final Function(String, {String? sousBaremeId}) navigateToClassificationPage;
  final bool isFrenchInterface;

  const StudentsTable({
    Key? key,
    required this.classDocId,
    required this.selectedClass,
    required this.selectedMatiere,
    required this.currentUser,
    required this.sumCriteriaMaxPerBareme,
    required this.totalStudents,
    required this.navigateToClassificationPage,
    required this.isFrenchInterface,
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

  // Cache pour les données fréquemment utilisées
  final Map<String, Map<String, DocumentSnapshot>> _studentMarksCache = {};
  final Map<String, List<Map<String, dynamic>>> _baremesValuesCache = {};
  final Map<String, Map<String, String>> _classAndMatiereNamesCache = {};
  
  // Couleurs modernes pour l'UI
  final Color _primaryColor = const Color(0xFF2E7D32);
  final Color _secondaryColor = const Color(0xFF4CAF50);
  final Color _accentColor = const Color(0xFF8BC34A);
  final Color _backgroundColor = const Color(0xFFF5F5F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF333333);
  final Color _borderColor = const Color(0xFFE0E0E0);

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

  List<Map<String, dynamic>> _sortBaremesAlphabetically(
      List<Map<String, dynamic>> baremesValues) {
    baremesValues.sort((a, b) {
      String nameA = a['value'] ?? '';
      String nameB = b['value'] ?? '';
      return nameA.compareTo(nameB);
    });
    return baremesValues;
  }

  List<QueryDocumentSnapshot> _sortStudentsAlphabetically(
      List<QueryDocumentSnapshot> students) {
    List<QueryDocumentSnapshot> sortedStudents = List.from(students);

    sortedStudents.sort((a, b) {
      String nameA = a['name'] ?? '';
      String nameB = b['name'] ?? '';

      if (!widget.isFrenchInterface && nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
        return _arabicStringComparator(nameA, nameB);
      }

      return nameA.compareTo(nameB);
    });

    return sortedStudents;
  }

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
        String parentId = bareme['parentBaremeId'] ?? '';
        key = parentId.isNotEmpty ? parentId : 'sousBaremes';
      } else {
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

      bool alreadyExists = groupedBaremes[key]!
          .any((existingBareme) => existingBareme['id'] == bareme['id']);

      if (!alreadyExists) {
        groupedBaremes[key]!.add(bareme);
      }
    }

    return groupedBaremes;
  }

  String _getButtonKey(
      String baremeId, String? sousBaremeId, bool isClassification) {
    return '${baremeId}_${sousBaremeId ?? 'main'}_${isClassification ? 'classification' : 'treatment'}';
  }

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
    StudentsFirestoreHelper.clearAllCache();
    super.dispose();
  }

  Future<void> _loadStudentsOnce() async {
    try {
      final students = await StudentsFirestoreHelper.getStudentsWithCache(
        widget.currentUser.uid,
        widget.classDocId,
      );

      if (_isMounted) {
        List<QueryDocumentSnapshot> sortedDocs = students.toList();
        sortedDocs.sort((a, b) {
          String nameA = a['name'] ?? '';
          String nameB = b['name'] ?? '';

          if (!widget.isFrenchInterface &&
              nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
            return _arabicStringComparator(nameA, nameB);
          }

          return nameA.compareTo(nameB);
        });

        setState(() {
          _cachedStudents = sortedDocs;
        });
      }
    } catch (e) {
      print('Erreur chargement étudiants: $e');
    }
  }

  Future<void> _loadSelectionsOnce() async {
    try {
      final selections = await StudentsFirestoreHelper.getSelectionsWithCache(
        widget.currentUser.uid,
        widget.selectedClass,
        widget.selectedMatiere,
      );

      if (_isMounted) {
        setState(() {
          _cachedSelections = selections;
        });
      }
    } catch (e) {
      print('Erreur chargement sélections: $e');
    }
  }

  Future<void> _refreshData() async {
    // Invalider le cache pour cet utilisateur et cette classe
    StudentsFirestoreHelper.invalidateCacheForUser(
      widget.currentUser.uid,
      widget.selectedClass,
    );
    
    // Recharger les données
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
          className = widget.isFrenchInterface ? 'Chargement...' : 'جاري التحميل...';
          matiereName = widget.isFrenchInterface ? 'Chargement...' : 'جاري التحميل...';
        } else if (snapshot.hasData) {
          className = snapshot.data!['className'] ??
              (widget.isFrenchInterface ? 'Inconnu' : 'غير معروف');
          matiereName = snapshot.data!['matiereName'] ??
              (widget.isFrenchInterface ? 'Inconnu' : 'غير معروف');
        }

        return Card(
          elevation: 3,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final cacheKey = '${widget.selectedClass}_${widget.selectedMatiere}';
    
    if (_classAndMatiereNamesCache.containsKey(cacheKey)) {
      return _classAndMatiereNamesCache[cacheKey]!;
    }

    try {
      final classDoc = await StudentsFirestoreHelper.getClassDocument(
        widget.selectedClass,
      );
      
      var className = classDoc['name'] ?? 'غير معروف';

      final matiereDoc = await StudentsFirestoreHelper.getMatiereDocument(
        widget.selectedClass,
        widget.selectedMatiere,
      );
      
      var matiereName = matiereDoc['name'] ?? 'غير معروف';

      if (widget.isFrenchInterface) {
        className = DataTranslator.translateClass(className);
        matiereName = DataTranslator.translateMatiere(matiereName);
      }

      final result = {
        'className': className,
        'matiereName': matiereName,
      };

      _classAndMatiereNamesCache[cacheKey] = result.cast<String, String>();
      return result.cast<String, String>();
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

    List<QueryDocumentSnapshot> sortedStudents =
        _sortStudentsAlphabetically(studentsDocs);

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

        return _buildDataTable(sortedStudents, baremesValuesSnapshot.data!);
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

  List<DataColumn> _buildTableColumns(
      Map<String, List<Map<String, dynamic>>> groupedBaremes) {
    List<DataColumn> columns = [];

    for (var entry in groupedBaremes.entries) {
      for (final bareme in entry.value) {
        if (bareme['type'] == 'bareme') {
          columns.add(DataColumn(
            label: _buildColumnHeader(bareme['value'], entry.key),
          ));

          for (final sousBareme
              in (bareme['sousBaremes'] as List<dynamic>? ?? [])) {
            columns.add(DataColumn(
              label: _buildColumnHeader(sousBareme['value'], entry.key),
            ));
          }
        } else {
          columns.add(DataColumn(
            label: _buildColumnHeader(bareme['value'], entry.key),
          ));
        }
      }
    }

    return columns;
  }

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

  List<DataCell> _buildStudentCells(String studentId,
      Map<String, List<Map<String, dynamic>>> groupedBaremes) {
    List<DataCell> cells = [];

    for (var entry in groupedBaremes.entries) {
      for (final bareme in entry.value) {
        if (bareme['type'] == 'bareme') {
          cells.add(DataCell(_buildMarkCell(studentId, bareme['id'])));

          for (final sousBareme
              in (bareme['sousBaremes'] as List<dynamic>? ?? [])) {
            cells.add(DataCell(_buildMarkCell(studentId, sousBareme['id'])));
          }
        } else {
          cells.add(DataCell(_buildMarkCell(studentId, bareme['id'])));
        }
      }
    }

    return cells;
  }

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

          final isAbsent = value == 'غائب';

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isAbsent
                  ? Colors.grey.withOpacity(0.2)
                  : _getValueColor(value).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isAbsent
                    ? Colors.grey
                    : _getValueColor(value).withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: isAbsent ? Colors.grey : _getValueColor(value),
                  fontWeight: FontWeight.bold,
                  fontSize: isAbsent ? 10 : 12,
                  fontStyle: isAbsent ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<DataRow> _buildButtonRows(
      Map<String, List<Map<String, dynamic>>> groupedBaremes) {
    return [
      _buildButtonRow(_getTranslatedText('تصنيف', 'Classer'), Colors.green,
          Colors.yellow, groupedBaremes,
          isClassification: true),
      _buildButtonRow(_getTranslatedText('تشخيص', 'Diagnostic'), Colors.blue,
          Colors.white, groupedBaremes,
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

  Widget _buildStatValue(String baremeKey, bool isPercentage) {
    int? count = widget.sumCriteriaMaxPerBareme[baremeKey];

    if (count == null) {
      for (var key in widget.sumCriteriaMaxPerBareme.keys) {
        if (key.contains(baremeKey) || baremeKey.contains(key)) {
          count = widget.sumCriteriaMaxPerBareme[key];
          break;
        }
      }
    }

    count ??= 0;

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
    final cacheKey = 'baremes_values_${widget.currentUser.uid}_${widget.selectedClass}_${widget.selectedMatiere}';
    
    if (_baremesValuesCache.containsKey(cacheKey)) {
      return _baremesValuesCache[cacheKey]!;
    }

    final List<Map<String, dynamic>> result = [];
    final String userId = widget.currentUser.uid;

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

    _baremesValuesCache[cacheKey] = result;
    return result;
  }

  Future<String> _getSelectedValue(String studentId, String baremeKey) async {
    try {
      final String evaluationSystem = await StudentsFirestoreHelper
          .getEvaluationSystemWithCache(
        widget.currentUser.uid,
        widget.selectedClass,
        widget.selectedMatiere,
      );
      
      final List<String> customNotes = await StudentsFirestoreHelper
          .getCustomNotesWithCache(
        widget.currentUser.uid,
        widget.selectedClass,
        widget.selectedMatiere,
      );

      String storedValue = _dropdownValues[0];

      if (baremeKey.contains('-')) {
        var parts = baremeKey.split('-');
        var baremeId = parts[0];
        var sousBaremeId = parts[1];

        var sousBaremeDoc = await StudentsFirestoreHelper
            .getSousBaremeMarksWithCache(
          widget.currentUser.uid,
          widget.classDocId,
          studentId,
          baremeId,
          sousBaremeId,
        );

        if (sousBaremeDoc.exists) {
          if ((sousBaremeDoc.data() as Map<String, dynamic>?)?['isAbsent'] == true) {
            return 'غائب';
          }
          storedValue =
              (sousBaremeDoc.data() as Map<String, dynamic>?)?['Marks']?.toString() ?? '( - - - )';
        }
      } else {
        var baremeDoc = await StudentsFirestoreHelper.getStudentMarksWithCache(
          widget.currentUser.uid,
          widget.classDocId,
          studentId,
          baremeKey,
        );

        if (baremeDoc.exists) {
          if ((baremeDoc.data() as Map<String, dynamic>?)?['isAbsent'] == true) {
            return 'غائب';
          }
          storedValue = (baremeDoc.data() as Map<String, dynamic>?)?['Marks']?.toString() ?? '( - - - )';
        }
      }

      return _getDisplayEvaluation(storedValue, evaluationSystem,
          customNotes: customNotes);
    } catch (e) {
      print('Erreur récupération valeur pour $baremeKey: $e');
      return _dropdownValues[0];
    }
  }

  Future<String> _getEvaluationSystem(String classId, String matiereId) async {
    return await StudentsFirestoreHelper.getEvaluationSystemWithCache(
      widget.currentUser.uid,
      classId,
      matiereId,
    );
  }

  Future<List<String>> _loadCustomNotes(
      String classId, String matiereId) async {
    return await StudentsFirestoreHelper.getCustomNotesWithCache(
      widget.currentUser.uid,
      classId,
      matiereId,
    );
  }

  String _getDisplayEvaluation(String storedValue, String system,
      {List<String>? customNotes}) {
    if (storedValue == 'غائب') {
      return 'غائب';
    }

    if (system == 'custom' && customNotes != null && customNotes.isNotEmpty) {
      final Map<String, String> mapping = {
        '( - - - )': customNotes[0],
        '( + - - )': customNotes.length > 1 ? customNotes[1] : customNotes[0],
        '( + + - )': customNotes.length > 2 ? customNotes[2] : customNotes.last,
        '( + + + )': customNotes.last,
      };
      return mapping[storedValue] ?? customNotes[0];
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

  List<String> _getDropdownValues(
      String evaluationSystem, List<String> customNotes) {
    switch (evaluationSystem) {
      case 'character':
        return ['( - - - )', '( + - - )', '( + + - )', '( + + + )'];

      case 'note_0_1_5':
        return ['0', '0.5', '1', '1.5'];

      case 'note_0_3':
        return ['0', '1', '2', '3'];

      case 'note_0_6':
        return ['0', '2', '4', '6'];

      case 'custom':
        return customNotes.isNotEmpty
            ? customNotes
            : ['( - - - )', '( + - - )', '( + + - )', '( + + + )'];

      default:
        return ['( - - - )', '( + - - )', '( + + - )', '( + + + )'];
    }
  }

  Future<void> _classifyStudentsByBarem(String baremeId,
      {String? sousBaremeId}) async {
    try {
      var studentsSnapshot = await StudentsFirestoreHelper.getStudentsWithCache(
        widget.currentUser.uid,
        widget.classDocId,
      );

      Map<String, List<String>> studentGroups = {
        _getTranslatedText('مجموعة العلاج', 'Groupe de traitement'): [],
        _getTranslatedText('مجموعة الدعم', 'Groupe de soutien'): [],
        _getTranslatedText('مجموعة التميز', 'Groupe d\'excellence'): [],
      };

      for (var studentDoc in studentsSnapshot) {
        var studentId = studentDoc.id;
        var studentName = studentDoc['name'] ??
            _getTranslatedText('اسم غير معروف', 'Nom inconnu');

        DocumentSnapshot snapshot;
        if (sousBaremeId != null) {
          snapshot = await StudentsFirestoreHelper.getSousBaremeMarksWithCache(
            widget.currentUser.uid,
            widget.classDocId,
            studentId,
            baremeId,
            sousBaremeId,
          );
        } else {
          snapshot = await StudentsFirestoreHelper.getStudentMarksWithCache(
            widget.currentUser.uid,
            widget.classDocId,
            studentId,
            baremeId,
          );
        }

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