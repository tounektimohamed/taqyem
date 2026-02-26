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
import 'package:intl/intl.dart' show DateFormat;
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
// Dans la classe DataTranslator du code 2, ajoutez cette méthode statique :

  static String translateBaremeName(String baremeName, bool isFrenchInterface) {
    // Si le barème est déjà en français, ne pas le traduire
    if (baremeName.contains('C') && baremeName.contains('.')) {
      return baremeName; // C'est déjà la version française
    }

    // Si l'interface est en français et que le barème est en arabe, le traduire
    if (isFrenchInterface) {
      return translateBareme(baremeName);
    }

    // Sinon, garder le nom arabe
    return baremeName;
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
    "Langue": "Langue",
    "لغة انقليزية": "Anglais",
    "التاريخ": "Histoire",
    "الجغرافيا": "Géographie",
    "التربية المدنية": "Éducation civique"
  };
  static final Map<String, String> _baremeTranslations = {
    // Main bareme (1 to 7)
    "مع 1": "C1",
    "مع 2": "C2",
    "مع 3": "C3",
    "مع 4": "C4",
    "مع 5": "C5",
    "مع 6": "C6",
    "مع 7": "C7",

    // Sub-bareme for each (1 to 7 with أ، ب، ج، د)
    // Bareme 1 sub-levels
    "مع 1.أ": "C1.A",
    "مع 1.ب": "C1.B",
    "مع 1.ج": "C1.C",
    "مع 1.د": "C1.D",

    // Bareme 2 sub-levels
    "مع 2.أ": "C2.A",
    "مع 2.ب": "C2.B",
    "مع 2.ج": "C2.C",
    "مع 2.د": "C2.D",

    // Bareme 3 sub-levels
    "مع 3.أ": "C3.A",
    "مع 3.ب": "C3.B",
    "مع 3.ج": "C3.C",
    "مع 3.د": "C3.D",

    // Bareme 4 sub-levels
    "مع 4.أ": "C4.A",
    "مع 4.ب": "C4.B",
    "مع 4.ج": "C4.C",
    "مع 4.د": "C4.D",

    // Bareme 5 sub-levels
    "مع 5.أ": "C5.A",
    "مع 5.ب": "C5.B",
    "مع 5.ج": "C5.C",
    "مع 5.د": "C5.D",

    // Bareme 6 sub-levels
    "مع 6.أ": "C6.A",
    "مع 6.ب": "C6.B",
    "مع 6.ج": "C6.C",
    "مع 6.د": "C6.D",

    // Bareme 7 sub-levels
    "مع 7.أ": "C7.A",
    "مع 7.ب": "C7.B",
    "مع 7.ج": "C7.C",
    "مع 7.د": "C7.D"
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
// Variables pour la gestion des exercices AI sélectionnés
  Map<String, List<AIExerciseSelection>> _selectedAIExercises = {
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

// Ajoutez cette méthode dans votre classe _ClassificationPageState
  Future<List<Map<String, dynamic>>> _getSelectedAIExercises({
    required String groupKey,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Récupérer les exercices AI récents pour ce groupe
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('ai_generated_exercises')
          .where('groupKey', isEqualTo: groupKey)
          .where('className', isEqualTo: widget.className)
          .where('matiereName', isEqualTo: widget.matiereName)
          .orderBy('createdAt', descending: true)
          .limit(3) // Limiter aux 3 plus récents
          .get();

      List<Map<String, dynamic>> exercises = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        exercises.add({
          'id': doc.id,
          'aiResponse': data['aiResponse'] ?? '',
          'modifiedBaremeName': data['modifiedBaremeName'] ?? '',
          'createdAt': data['createdAt'],
          'selectedProblems': data['selectedProblems'] ?? [],
          'selectedOrigins': data['selectedOrigins'] ?? [],
        });
      }

      print(
          '📚 ${exercises.length} exercices  trouvés pour le groupe $groupKey');
      return exercises;
    } catch (e) {
      print('❌ Erreur lors de la récupération des exercices : $e');
      return [];
    }
  }

// Remplacez votre méthode _getSelectedAIExercises par celle-ci
  Future<List<AIExerciseSelection>> _getAvailableAIExercises({
    required String groupKey,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      print('🔍 RECHERCHE EXERCICES AI:');
      print('   - User ID: $userId');
      print('   - Group Key: $groupKey');
      print('   - Classe: ${widget.className}');
      print('   - Matière: ${widget.matiereName}');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('ai_generated_exercises')
          // .where('groupKey', isEqualTo: groupKey)
          // .where('className', isEqualTo: widget.className)
          // .where('matiereName', isEqualTo: widget.matiereName)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      print(
          '📊 TOTAL exercices trouvés (sans filtre): ${querySnapshot.docs.length}');

      // Afficher les premiers documents pour voir leur structure
      for (var doc in querySnapshot.docs) {
        print('📄 Document ID: ${doc.id}');
        print('   Données: ${doc.data()}');
      }

      // Appliquer les filtres manuellement pour voir ce qui correspond
      List<AIExerciseSelection> exercises = [];
      final selectedIds =
          _selectedAIExercises[groupKey]?.map((e) => e.id).toSet() ?? {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Vérifier les champs disponibles
        print('🔎 Vérification document:');
        print('   - groupKey dans doc: ${data['groupKey']}');
        print('   - className dans doc: ${data['className']}');
        print('   - matiereName dans doc: ${data['matiereName']}');

        // Vérifier si ce document correspond à nos critères
        bool matchesGroup = data['groupKey'] == groupKey;
        bool matchesClass = data['className'] == widget.className;
        bool matchesMatiere = data['matiereName'] == widget.matiereName;

        if (matchesGroup && matchesClass && matchesMatiere) {
          print('✅ Document correspond!');
          final exercise = AIExerciseSelection.fromFirestore(doc);
          exercise.isSelected = selectedIds.contains(exercise.id);
          exercises.add(exercise);
        } else {
          print('❌ Document ne correspond pas:');
          if (!matchesGroup) print('   - groupKey ne correspond pas');
          if (!matchesClass) print('   - className ne correspond pas');
          if (!matchesMatiere) print('   - matiereName ne correspond pas');
        }
      }

      print('📚 Total exercices correspondants: ${exercises.length}');
      return exercises;
    } catch (e) {
      print('❌ Erreur lors de la récupération des exercices : $e');
      return [];
    }
  }

// Ajoutez cette méthode utilitaire
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _showAISelectionDialog({
    required String groupName,
    required String groupKey,
  }) async {
    // Charger les exercices disponibles
    final availableExercises =
        await _getAvailableAIExercises(groupKey: groupKey);

    if (availableExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText(
              'لا توجد تمارين  سابقة لهذه المجموعة',
              'Aucun exercice  précédent pour ce groupe')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Créer une copie locale des exercices pour la sélection
    // IMPORTANT: Créer de nouvelles instances pour éviter de modifier l'original directement
    List<AIExerciseSelection> tempSelections = availableExercises
        .map((e) => AIExerciseSelection(
              id: e.id,
              aiResponse: e.aiResponse,
              modifiedBaremeName: e.modifiedBaremeName,
              createdAt: e.createdAt,
              selectedProblems: e.selectedProblems,
              selectedOrigins: e.selectedOrigins,
              isSelected: e.isSelected, // Conserver l'état de sélection actuel
            ))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // En-tête
                    Container(
                      padding: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Colors.purple.shade700),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getTranslatedText(
                                  'اختر التمارين  للطباعة - $groupName',
                                  'Sélectionnez les exercices  à imprimer - $groupName'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade800,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.select_all,
                                color: Colors.purple.shade700),
                            onPressed: () {
                              setState(() {
                                bool allSelected = tempSelections.isEmpty
                                    ? false
                                    : tempSelections.every((e) => e.isSelected);
                                for (var exercise in tempSelections) {
                                  exercise.isSelected = !allSelected;
                                }
                              });
                            },
                            tooltip: _getTranslatedText(
                                'تحديد الكل', 'Tout sélectionner'),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Liste des exercices
                    Expanded(
                      child: tempSelections.isEmpty
                          ? Center(
                              child: Text(
                                _getTranslatedText('لا توجد تمارين متاحة',
                                    'Aucun exercice disponible'),
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: tempSelections.length,
                              itemBuilder: (context, index) {
                                final exercise = tempSelections[index];

                                return Card(
                                  margin: EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: exercise.isSelected
                                          ? Colors.purple
                                          : Colors.grey.shade300,
                                      width: exercise.isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        exercise.isSelected =
                                            !exercise.isSelected;
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Checkbox(
                                            value: exercise.isSelected,
                                            onChanged: (value) {
                                              setState(() {
                                                exercise.isSelected = value!;
                                              });
                                            },
                                            activeColor: Colors.purple,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .purple.shade50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        exercise.modifiedBaremeName
                                                                .isNotEmpty
                                                            ? exercise
                                                                .modifiedBaremeName
                                                            : _getTranslatedText(
                                                                'تمرين ',
                                                                'Exercice '),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .purple.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    if (exercise.createdAt !=
                                                        null)
                                                      Text(
                                                        DateFormat('dd/MM/yyyy')
                                                            .format(exercise
                                                                .createdAt!
                                                                .toDate()),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .grey.shade600,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  _truncateText(
                                                      exercise.aiResponse, 150),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (exercise.selectedProblems
                                                    .isNotEmpty) ...[
                                                  SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 4,
                                                    runSpacing: 4,
                                                    children: exercise
                                                        .selectedProblems
                                                        .take(2)
                                                        .map((problem) {
                                                      return Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .red.shade50,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: Text(
                                                          problem.length > 20
                                                              ? '${problem.substring(0, 20)}...'
                                                              : problem,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors
                                                                .red.shade700,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    SizedBox(height: 20),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Mettre à jour les sélections avec les exercices choisis
                              setState(() {
                                _selectedAIExercises[groupKey] = tempSelections
                                    .where((e) => e.isSelected)
                                    .toList();
                              });

                              Navigator.pop(context);

                              int selectedCount =
                                  _selectedAIExercises[groupKey]?.length ?? 0;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_getTranslatedText(
                                      'تم حفظ $selectedCount تمرين ',
                                      '$selectedCount exercice(s)  enregistré(s)')),
                                  backgroundColor: Colors.purple,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: Icon(Icons.save),
                            label: Text(_getTranslatedText(
                                'حفظ التحديدات', 'Enregistrer')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close),
                            label: Text(_getTranslatedText('إلغاء', 'Annuler')),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
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

  Future<void> _generateExercisesFromAI({
    required String groupKey,
  }) async {
    try {
      setState(() {
        _isGeneratingReport = true;
      });

      // VÉRIFICATION DU COMPTE ACTIF EN PREMIER
      if (!_isAccountActive) {
        // Si le compte n'est pas actif, vérifier le crédit
        if (!await _checkAndUpdatePrintCredit()) {
          _showCreditErrorDialog();
          setState(() {
            _isGeneratingReport = false;
          });
          return;
        }
      }

      // Collecter les sélections
      final selections = _groupSelections[groupKey] ?? [];

      final problems =
          selections.where((s) => s.isProblem).map((s) => s.text).toList();

      final origins =
          selections.where((s) => !s.isProblem).map((s) => s.text).toList();

      // Vérifier s'il y a des sélections
      if (problems.isEmpty && origins.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getTranslatedText(
                'يرجى تحديد أخطاء وأصول أخطاء أولاً',
                'Veuillez sélectionner des problèmes et solutions d\'abord')),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isGeneratingReport = false;
        });
        return;
      }

      // Demander à l'utilisateur s'il veut modifier le nom du barème
      String? modifiedBaremeName = await _showBaremeModificationDialog(
        currentBaremeName: widget.sousBaremeName ?? widget.baremeName,
      );

      if (modifiedBaremeName == null) {
        // L'utilisateur a annulé
        setState(() {
          _isGeneratingReport = false;
        });
        return;
      }

      // Afficher le dialogue de chargement avec indication du statut
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => _buildAILoadingDialog(
          isFreeGeneration: _isAccountActive,
        ),
      );

      // Envoyer la requête à Flask
      final response = await http
          .post(
            Uri.parse(
                "https://mohamedtsou-ai-taqyem.hf.space/generate-exercises"),
            headers: {
              "Content-Type": "application/json",
            },
            body: json.jsonEncode({
              "class": widget.className,
              "matiere": widget.matiereName,
              "bareme": modifiedBaremeName,
              "problems": problems,
              "origins": origins,
            }),
          )
          .timeout(const Duration(seconds: 45));

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      final data = json.jsonDecode(response.body);

      if (data["success"] == true && data["result"] != null) {
        String aiResponse = data["result"];

        // Enregistrer dans Firestore
        await _saveAIResponseToFirestore(
          aiResponse: aiResponse,
          groupKey: groupKey,
          problems: problems,
          origins: origins,
          modifiedBaremeName: modifiedBaremeName,
          metadata: data["metadata"],
        );

        // DÉDUIRE LE CRÉDIT SEULEMENT SI LE COMPTE N'EST PAS ACTIF
        if (!_isAccountActive) {
          await _deductPrintCredit(); // Utilise la méthode existante
        }

        // Mettre à jour le compteur de générations AI
        await _updateAIGenerationCount(isFree: _isAccountActive);

        // Afficher le résultat avec indication du statut
        _showAIResultDialog(
          aiResponse,
          wasFree: _isAccountActive,
        );
      } else {
        throw Exception(data["error"] ?? "Erreur AI");
      }
    } on TimeoutException catch (_) {
      Navigator.of(context).pop();
      _showErrorDialog(_getTranslatedText(
          'انتهت مهلة الطلب. قد يكون الخادم بطيئًا.',
          'Délai d\'attente dépassé. Le serveur est peut-être lent.'));
    } on SocketException catch (_) {
      Navigator.of(context).pop();
      _showErrorDialog(_getTranslatedText(
          'لا يمكن الاتصال بالخادم. تأكد من أن الخادم مشغل.',
          'Impossible de se connecter au serveur. Vérifiez que le serveur est lancé.'));
    } catch (e) {
      Navigator.of(context).pop();
      print("Erreur AI: $e");
      _showErrorDialog("Erreur: $e");
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
    }
  }

  Future<void> _updateAIGenerationCount({required bool isFree}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Mettre à jour le compteur de générations AI
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .update({
          'totalAIGenerations': FieldValue.increment(1),
          'freeAIGenerations':
              isFree ? FieldValue.increment(1) : FieldValue.increment(0),
          'paidAIGenerations':
              !isFree ? FieldValue.increment(1) : FieldValue.increment(0),
          'lastAIGeneration': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du compteur AI: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            SizedBox(width: 10),
            Text(_getTranslatedText('خطأ', 'Erreur')),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTranslatedText('حسناً', 'OK')),
          ),
        ],
      ),
    );
  }

  void _navigateToAIHistory() {
    // Vous pouvez créer une nouvelle page pour afficher l'historique
    // Ou simplement afficher un dialogue avec l'historique récent

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('ai_generated_exercises')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                        _getTranslatedText('جاري التحميل...', 'Chargement...')),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: Text(_getTranslatedText('خطأ', 'Erreur')),
                content: Text('${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              );
            }

            final exercises = snapshot.data?.docs ?? [];

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // En-tête
                    Row(
                      children: [
                        Icon(Icons.history, color: Colors.purple.shade700),
                        SizedBox(width: 10),
                        Text(
                          _getTranslatedText('آخر التمارين المولدة',
                              'Derniers exercices générés'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Liste des exercices
                    Expanded(
                      child: exercises.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    _getTranslatedText('لا توجد تمارين سابقة',
                                        'Aucun exercice précédent'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: exercises.length,
                              itemBuilder: (context, index) {
                                final exercise = exercises[index].data()
                                    as Map<String, dynamic>;
                                final timestamp =
                                    exercise['createdAt'] as Timestamp?;
                                final date = timestamp?.toDate();

                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.purple.shade100,
                                      child: Icon(
                                        Icons.auto_awesome,
                                        color: Colors.purple.shade700,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      exercise['modifiedBaremeName'] ??
                                          exercise['originalBaremeName'] ??
                                          'Sans nom',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${exercise['className']} - ${exercise['matiereName']}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        if (date != null)
                                          Text(
                                            _getTranslatedText(
                                                'تم في: ${date.day}/${date.month}/${date.year}',
                                                'Le: ${date.day}/${date.month}/${date.year}'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.visibility,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showAIResultDialog(
                                            exercise['aiResponse'] ?? '');
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showAIResultDialog(
                                          exercise['aiResponse'] ?? '');
                                    },
                                  ),
                                );
                              },
                            ),
                    ),

                    // Bouton fermer
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                        ),
                        child: Text(_getTranslatedText('إغلاق', 'Fermer')),
                      ),
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

  Future<String?> _showBaremeModificationDialog({
    required String currentBaremeName,
  }) async {
    TextEditingController controller =
        TextEditingController(text: currentBaremeName);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue.shade700),
              SizedBox(width: 10),
              Text(
                _getTranslatedText(
                    'تعديل اسم المعيار', 'Modifier le nom du critère'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTranslatedText(
                    'يمكنك تعديل اسم المعيار قبل إنشاء التمارين:',
                    'Vous pouvez modifier le nom du critère avant de générer les exercices:'),
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText:
                      _getTranslatedText('اسم المعيار', 'Nom du critère'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.score, color: Colors.blue.shade700),
                ),
                autofocus: true,
              ),
              SizedBox(height: 8),
              Text(
                _getTranslatedText('✏️ يمكنك تعديل الاسم أو ترجمته',
                    '✏️ Vous pouvez modifier le nom ou le traduire'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _getTranslatedText('إلغاء', 'Annuler'),
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                String newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.pop(context, newName);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_getTranslatedText(
                          'الرجاء إدخال اسم المعيار',
                          'Veuillez entrer le nom du critère')),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              child: Text(
                _getTranslatedText('موافق', 'OK'),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAIResponseToFirestore({
    required String aiResponse,
    required String groupKey,
    required List<String> problems,
    required List<String> origins,
    required String modifiedBaremeName,
    dynamic metadata,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      print('💾 SAUVEGARDE EXERCICE AI:');
      print('   - groupKey: $groupKey');
      print('   - className: ${widget.className}');
      print('   - matiereName: ${widget.matiereName}');

      // Déterminer le nom du groupe
      String groupName = '';
      switch (groupKey) {
        case 'treatment':
          groupName =
              _getTranslatedText('مجموعة العلاج', 'Groupe de traitement');
          break;
        case 'support':
          groupName = _getTranslatedText('مجموعة الدعم', 'Groupe de soutien');
          break;
        case 'excellence':
          groupName =
              _getTranslatedText('مجموعة التميز', 'Groupe d\'excellence');
          break;
      }

      // Préparer les données à sauvegarder
      Map<String, dynamic> aiExercisesData = {
        'userId': userId,
        'userName':
            FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
        'userEmail': FirebaseAuth.instance.currentUser?.email,
        'classId': widget.selectedClass,
        'className': widget.className,
        'matiereName': widget.matiereName,
        'originalBaremeName': widget.sousBaremeName ?? widget.baremeName,
        'modifiedBaremeName': modifiedBaremeName,
        'groupKey':
            groupKey, // ← Vérifiez que c'est bien 'groupKey' et non 'groupkey'
        'groupName': groupName,
        'selectedProblems': problems,
        'selectedOrigins': origins,
        'aiResponse': aiResponse,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'isFrenchInterface': _isFrenchInterface,
      };

      print('📦 Données sauvegardées:');
      aiExercisesData.forEach((key, value) {
        print('   - $key: $value');
      });

      // Sauvegarder dans la collection principale de l'utilisateur
      DocumentReference userDocRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('ai_generated_exercises')
          .add(aiExercisesData);

      print('✅ Exercice sauvegardé avec ID: ${userDocRef.id}');

      // Afficher une notification de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.save, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTranslatedText('تم حفظ التمارين في قاعدة البيانات',
                      'Exercices sauvegardés dans la base de données'),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText(
              'تم إنشاء التمارين لكن فشل الحفظ في قاعدة البيانات',
              'Exercices générés mais échec de la sauvegarde')),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _updateAICreditUsage() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final bool isActive = _getFieldSafe(userDoc, 'isActive', false);

        // Ne déduire que si le compte n'est pas actif
        if (!isActive) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .update({
            'aiGenerationsUsed': FieldValue.increment(1),
            'lastAIGeneration': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du crédit AI: $e');
    }
  }

  void _showAIResultDialog(String result, {bool wasFree = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // En-tête
                Container(
                  padding: EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: wasFree
                              ? Colors.green.shade50
                              : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: wasFree
                              ? Colors.green.shade700
                              : Colors.purple.shade700,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTranslatedText("تمارين علاجية ذكية",
                                  "Exercices de remédiation IA"),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: wasFree
                                    ? Colors.green.shade800
                                    : Colors.purple.shade800,
                              ),
                            ),
                            Row(
                              children: [
                                if (wasFree) ...[
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    _getTranslatedText("✅ تم إنشاؤها مجاناً",
                                        "✅ Généré gratuitement"),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ] else ...[
                                  Icon(Icons.payment,
                                      color: Colors.orange, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    _getTranslatedText(
                                        "💰 تم استخدام رصيد واحد",
                                        "💰 Un crédit utilisé"),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              _getTranslatedText("✅ تم حفظها في قاعدة البيانات",
                                  "✅ Sauvegardés dans la base de données"),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                // Contenu des exercices
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        result,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          fontFamily: 'Arial',
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bouton Copier
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: result));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_getTranslatedText(
                                'تم نسخ التمارين', 'Exercices copiés')),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: Icon(Icons.copy, size: 18),
                      label: Text(_getTranslatedText('نسخ', 'Copier')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

                    // Bouton Voir l'historique
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToAIHistory();
                      },
                      icon: Icon(Icons.history, size: 18),
                      label: Text(_getTranslatedText('السجل', 'Historique')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: wasFree
                            ? Colors.green.shade700
                            : Colors.purple.shade700,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),

                // Afficher le solde restant si compte non actif
                if (!_isAccountActive) ...[
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info,
                            size: 16, color: Colors.orange.shade700),
                        SizedBox(width: 4),
                        Text(
                          _getTranslatedText(
                              'الرصيد المتبقي: $_remainingPrints/5',
                              'Crédits restants: $_remainingPrints/5'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildAILoadingDialog({bool isFreeGeneration = false}) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFreeGeneration ? Colors.green : Colors.purple,
                ),
                strokeWidth: 3,
              ),
              Icon(
                Icons.auto_awesome,
                color: isFreeGeneration ? Colors.green : Colors.purple,
                size: 24,
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            _getTranslatedText("جاري إنشاء تمارين ذكية...",
                "Génération d'exercices intelligents..."),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isFreeGeneration) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                _getTranslatedText(
                    "✅ مجاني - حساب نشط", "✅ Gratuit - Compte actif"),
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                _getTranslatedText("💰 استخدام رصيد: $_remainingPrints/5",
                    "💰 Utilisation crédit: $_remainingPrints/5"),
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          SizedBox(height: 10),
          Text(
            _getTranslatedText("قد يستغرق هذا 30-45 ثانية",
                "Cela peut prendre 30-45 secondes"),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            backgroundColor: isFreeGeneration
                ? Colors.green.shade100
                : Colors.purple.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              isFreeGeneration ? Colors.green : Colors.purple,
            ),
          ),
        ],
      ),
    );
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

// Ajoutez cette méthode dans _ClassificationPageState
  bool _isBaremeNameInArabic(String baremeName) {
    // Vérifier si le nom contient des caractères arabes
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(baremeName);
  }

// Et cette méthode pour obtenir le nom affiché
  String _getDisplayBaremeName(String originalName) {
    if (_isFrenchInterface && _isBaremeNameInArabic(originalName)) {
      return DataTranslator.translateBareme(originalName);
    }
    return originalName;
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
    // Correction: 'matiereName' au lieu de 'matieneName'
    final userQuery = FirebaseFirestore.instance
        .collection('users_proposals')
        .doc(userId)
        .collection('user_proposals')
        .where('className', isEqualTo: widget.className)
        .where('matiereName', isEqualTo: widget.matiereName)  // CORRIGÉ
        .where('baremeName', isEqualTo: widget.baremeName);

    if (widget.sousBaremeName != null && widget.sousBaremeName!.isNotEmpty) {
      userQuery.where('sousBaremeName', isEqualTo: widget.sousBaremeName);
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

    // CORRECTION: même problème ici
    Query globalQuery = FirebaseFirestore.instance
        .collection('users_proposals')
        .doc('global_proposals')
        .collection('approved_proposals')
        .where('status', isEqualTo: 'approved')
        .where('className', isEqualTo: widget.className)
        .where('matiereName', isEqualTo: widget.matiereName)  // CORRIGÉ
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
    print(
        '🔍 Chargement des propositions pour le groupe: $groupName ($groupKey)');

    final proposals = await _getProposals();

    List<SolutionSelection> currentSelections =
        _groupSelections[groupKey] ?? [];

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
          isSelected: currentSelections
              .any((s) => s.text == jsonResult['solution'] && s.type == 'json'),
        ));
      }
      if (jsonResult['probleme']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: jsonResult['probleme'],
          type: 'json',
          isProblem: true,
          isSelected: currentSelections
              .any((s) => s.text == jsonResult['probleme'] && s.type == 'json'),
        ));
      }
    }

    final globalProposals =
        proposals.where((p) => p['source'] == 'global').toList();
    for (var proposal in globalProposals) {
      if (proposal['solution']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: proposal['solution'],
          type: 'global',
          isProblem: false,
          isSelected: currentSelections
              .any((s) => s.text == proposal['solution'] && s.type == 'global'),
        ));
      }
      if (proposal['probleme']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: proposal['probleme'],
          type: 'global',
          isProblem: true,
          isSelected: currentSelections
              .any((s) => s.text == proposal['probleme'] && s.type == 'global'),
        ));
      }
    }

    final personalProposals =
        proposals.where((p) => p['source'] == 'personal').toList();
    for (var proposal in personalProposals) {
      if (proposal['solution']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: proposal['solution'],
          type: 'personal',
          isProblem: false,
          isSelected: currentSelections.any(
              (s) => s.text == proposal['solution'] && s.type == 'personal'),
        ));
      }
      if (proposal['probleme']?.isNotEmpty == true) {
        allSelections.add(SolutionSelection(
          text: proposal['probleme'],
          type: 'personal',
          isProblem: true,
          isSelected: currentSelections.any(
              (s) => s.text == proposal['probleme'] && s.type == 'personal'),
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
                                  'تحديد الخطأ  و أصل  الخطأ لـ $groupName',
                                  'Sélection des solutions et problèmes pour $groupName'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.select_all,
                                color: Colors.blue.shade700),
                            onPressed: () {
                              bool allSelected =
                                  allSelections.every((s) => s.isSelected);
                              setState(() {
                                for (var selection in allSelections) {
                                  selection.isSelected = !allSelected;
                                }
                              });
                            },
                            tooltip: _getTranslatedText('تحديد/إلغاء الكل',
                                'Tout sélectionner/désélectionner'),
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
                                Icon(Icons.checklist,
                                    color: Colors.blue.shade700, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  _getTranslatedText(
                                      'اختر ما يناسب هذه المجموعة:',
                                      'Sélectionnez ce qui convient à ce groupe:'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
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
                                prefix =
                                    _getTranslatedText('موصى به', 'Recommandé');
                              } else if (selection.type == 'global') {
                                color = Colors.green;
                                icon = selection.isProblem
                                    ? Icons.analytics
                                    : Icons.check_circle;
                                prefix =
                                    _getTranslatedText('معتمد', 'Approuvé');
                              } else {
                                color = Colors.blue;
                                icon = selection.isProblem
                                    ? Icons.analytics_outlined
                                    : Icons.check_circle_outline;
                                prefix =
                                    _getTranslatedText('شخصي', 'Personnel');
                              }

                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: selection.isSelected
                                        ? color
                                        : Colors.grey.shade300,
                                    width: selection.isSelected ? 2 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selection.isSelected =
                                          !selection.isSelected;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: color
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                          color:
                                                              color.withOpacity(
                                                                  0.3)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(icon,
                                                            size: 12,
                                                            color: color),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          '$prefix • ${selection.isProblem ? _getTranslatedText('أصل الخطأ', 'Problème') : _getTranslatedText('خطأ', 'Solution')}',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                Icon(Icons.add_circle_outline,
                                    color: Colors.blue.shade700, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  _getTranslatedText(
                                      'أضف مقترحات جديدة لهذا المجموعة:',
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
                                  _getTranslatedText(
                                      'خطأ جديد:', 'Nouvelle solution:'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: solutionController,
                                  decoration: InputDecoration(
                                    hintText: _getTranslatedText(
                                        'أدخل اقتراحك للخطأ...',
                                        'Entrez votre suggestion de solution...'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade400),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.blue.shade600),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
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
                                  _getTranslatedText(
                                      'أصل الخطأ الجديد:', 'Nouveau problème:'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: problemeController,
                                  decoration: InputDecoration(
                                    hintText: _getTranslatedText(
                                        'أدخل اقتراحك  لأصل الخطأ...',
                                        'Entrez votre suggestion pour l\'origine du problème...'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade400),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.blue.shade600),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
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
                              _groupSelections[groupKey] = allSelections
                                  .where((s) => s.isSelected)
                                  .toList();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_getTranslatedText(
                                      'تم حفظ التحديدات لهذا المجموعة',
                                      'Sélections enregistrées pour ce groupe')),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.save, size: 20),
                            label: Text(
                              _getTranslatedText('حفظ التحديدات',
                                  'Enregistrer les sélections'),
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 207, 210, 25),
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
                                        'Propositions enregistrées avec succès')),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                Navigator.of(context).pop();
                                showSolutionAndProbleme(groupName, groupKey);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_getTranslatedText(
                                        'يرجى إدخال خطأ أو أصل الخطأ على الأقل',
                                        'Veuillez entrer au moins une solution ou un problème')),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.add, size: 20),
                            label: Text(
                              _getTranslatedText(
                                  'حفظ الجديد', 'Sauvegarder nouveau'),
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 169, 231, 133),
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

  // Dans _generateSingleGroupReport

  // Dans _generateSingleGroupReport, utilisez les exercices sélectionnés
  Future<void> _generateSingleGroupReport(
      String groupName, String groupKey) async {
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
            'Aucun étudiant trouvé dans la classe'));
      }

      // Récupérer les exercices AI SÉLECTIONNÉS pour ce groupe
      final selectedExercises = _selectedAIExercises[groupKey] ?? [];

      // Convertir en format pour le PDF
      final pdfAIExercises = selectedExercises.map((e) {
        return {
          'id': e.id,
          'aiResponse': e.aiResponse,
          'modifiedBaremeName': e.modifiedBaremeName,
          'createdAt': e.createdAt,
          'selectedProblems': e.selectedProblems,
          'selectedOrigins': e.selectedOrigins,
          'isSelected': true,
        };
      }).toList();

      // Préparer les données pour le PDF
      final Map<String, List<Map<String, dynamic>>> pdfGroupSelections = {
        groupKey: _groupSelections[groupKey]?.map((selection) {
              return {
                'text': selection.text,
                'source': selection.type,
                'isProblem': selection.isProblem,
                'isSelected': selection.isSelected,
              };
            }).toList() ??
            [],
      };

      // Map des exercices AI par groupe
      final Map<String, List<Map<String, dynamic>>> pdfAIExercisesMap = {
        groupKey: pdfAIExercises,
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
        aiExercises: pdfAIExercisesMap,
        isFrenchInterface: _isFrenchInterface,
        isCompleteReport: false,
        singleGroupName: groupName,
        singleGroupKey: groupKey,
      );

      // Déduire le crédit
      await _deductPrintCredit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText(
              'تم إنشاء التقرير للمجموعة $groupName بنجاح',
              'Rapport pour le groupe $groupName généré avec succès')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('[SingleGroupReport] ERREUR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText(
                  'خطأ في الإنشاء:', 'Erreur lors de la création:') +
              ' ${e.toString()}'),
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

// Dans _generateCompleteReport
// Dans _generateCompleteReport
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
              'يرجى تحديد خطأ وأصل الخطأ على الأقل لمجموعة واحدة',
              'Veuillez sélectionner des solutions et problèmes pour au moins un groupe')),
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
            'Aucun étudiant trouvé dans la classe'));
      }

      // Préparer les données pour le PDF
      final Map<String, List<Map<String, dynamic>>> pdfGroupSelections = {};
      final Map<String, List<Map<String, dynamic>>> pdfAIExercises = {};

      for (final groupKey in ['treatment', 'support', 'excellence']) {
        // Préparer les sélections de solutions/problèmes
        pdfGroupSelections[groupKey] =
            _groupSelections[groupKey]?.map((selection) {
                  return {
                    'text': selection.text,
                    'source': selection.type,
                    'isProblem': selection.isProblem,
                    'isSelected': selection.isSelected,
                  };
                }).toList() ??
                [];

        // Récupérer les exercices AI SÉLECTIONNÉS pour ce groupe
        final selectedExercises = _selectedAIExercises[groupKey] ?? [];

        // Convertir en format pour le PDF
        pdfAIExercises[groupKey] = selectedExercises.map((e) {
          return {
            'id': e.id,
            'aiResponse': e.aiResponse,
            'modifiedBaremeName': e.modifiedBaremeName,
            'createdAt': e.createdAt,
            'selectedProblems': e.selectedProblems,
            'selectedOrigins': e.selectedOrigins,
            'isSelected': true,
          };
        }).toList();

        // Log pour déboguer
        print(
            '📊 Groupe $groupKey: ${pdfAIExercises[groupKey]?.length} exercices AI sélectionnés');
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
        aiExercises: pdfAIExercises, // Utiliser les exercices sélectionnés
        isFrenchInterface: _isFrenchInterface,
        isCompleteReport: true,
      );

      // Déduire le crédit
      await _deductPrintCredit();

      // Afficher un résumé des exercices AI inclus
      int totalAIExercises =
          pdfAIExercises.values.fold(0, (sum, list) => sum + list.length);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText(
              'تم إنشاء التقرير الكامل بنجاح (تم تضمين $totalAIExercises تمرين AI)',
              'Rapport complet généré avec succès ($totalAIExercises exercices AI inclus)')),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('[CompleteReport] ERREUR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText(
                  'خطأ في الإنشاء:', 'Erreur lors de la création:') +
              ' ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
      Navigator.of(context).pop(); // Fermer le dialogue de chargement
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

  Future<Map<String, List<Map<String, dynamic>>>>
      _getGroupedStudentsData() async {
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
    } else if (groupName.contains(_getTranslatedText('الدعم', 'soutien'))) {
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    // Menu à 3 points pour les autres actions
                    PopupMenuButton<String>(
                      tooltip: _getTranslatedText(
                          'خيارات إضافية', 'Options supplémentaires'),
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                      offset: Offset(0, 40), // Position du menu
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'ai_select':
                            _showAISelectionDialog(
                                groupName: groupName, groupKey: groupKey);
                            break;
                          case 'print':
                            _generateSingleGroupReport(groupName, groupKey);
                            break;
                          case 'ai_generate':
                            _generateExercisesFromAI(groupKey: groupKey);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        // Option : Sélectionner les exercices AI
                        PopupMenuItem(
                          value: 'ai_select',
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: Colors.purple.shade300,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getTranslatedText(
                                      'تحديد التمارين ', 'Sélectionner exercice'),
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Option : Imprimer
                        PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.print,
                                  size: 18,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getTranslatedText('طباعة', 'Imprimer'),
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Option : Générer AI
                        PopupMenuItem(
                          value: 'ai_generate',
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: Colors.purple,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Générer AI",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Afficher le nombre d'exercices AI sélectionnés (optionnel)
                    if (_selectedAIExercises[groupKey]?.isNotEmpty ?? false)
                      Container(
                        margin: EdgeInsets.only(left: 4),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 12, color: Colors.purple.shade400),
                            SizedBox(width: 4),
                            Text(
                              '${_selectedAIExercises[groupKey]?.length ?? 0}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
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
                  final selectionCount = groupName
                          .contains(_getTranslatedText('العلاج', 'traitement'))
                      ? _groupSelections['treatment']?.length ?? 0
                      : groupName
                              .contains(_getTranslatedText('الدعم', 'soutien'))
                          ? _groupSelections['support']?.length ?? 0
                          : _groupSelections['excellence']?.length ?? 0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: groupName.contains(
                              _getTranslatedText('العلاج', 'traitement'))
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
                        Text(
                            '$count ${_getTranslatedText('تلميذ', count > 1 ? 'élèves' : 'élève')}'),
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
                      if (groupName.contains(
                          _getTranslatedText('العلاج', 'traitement'))) {
                        groupKey = 'treatment';
                      } else if (groupName
                          .contains(_getTranslatedText('الدعم', 'soutien'))) {
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
      var studentName =
          studentData['name'] ?? _getTranslatedText('غير معروف', 'Inconnu');

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
                        Text(_getTranslatedText(
                            'تقرير كامل', 'Rapport complet')),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getTranslatedText(
                                                'حدد خطأ  وأصل  الخطأ لكل مجموعة ثم اختر نوع التقرير:',
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
                                                '• تقرير مجموعة واحدة: يطبع مجموعة محددة مع طلابها و أخطائها ',
                                                '• Rapport groupe unique: imprime un groupe spécifique avec ses élèves et solutions'),
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _getTranslatedText(
                                                '• تقرير كامل: يطبع جميع المجموعات مع طلابها ',
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
                                        _getTranslatedText(
                                            'العلاج', 'traitement'))) {
                                      groupKey = 'treatment';
                                    } else if (group['name']
                                        .toString()
                                        .contains(_getTranslatedText(
                                            'الدعم', 'soutien'))) {
                                      groupKey = 'support';
                                    } else {
                                      groupKey = 'excellence';
                                    }

                                    int selectionCount =
                                        _groupSelections[groupKey]?.length ?? 0;

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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (selectionCount > 0)
                                                    Text(
                                                      '$selectionCount✓',
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
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

// Ajoutez cette classe après SolutionSelection
class AIExerciseSelection {
  final String id;
  final String aiResponse;
  final String modifiedBaremeName;
  final Timestamp? createdAt;
  final List<String> selectedProblems;
  final List<String> selectedOrigins;
  bool isSelected;

  AIExerciseSelection({
    required this.id,
    required this.aiResponse,
    required this.modifiedBaremeName,
    this.createdAt,
    required this.selectedProblems,
    required this.selectedOrigins,
    this.isSelected = false,
  });

  // Méthode pour créer depuis Firestore
  factory AIExerciseSelection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIExerciseSelection(
      id: doc.id,
      aiResponse: data['aiResponse'] ?? '',
      modifiedBaremeName: data['modifiedBaremeName'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      selectedProblems: List<String>.from(data['selectedProblems'] ?? []),
      selectedOrigins: List<String>.from(data['selectedOrigins'] ?? []),
    );
  }
}
